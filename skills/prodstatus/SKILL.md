# /prodstatus — CallHero Production Health Dashboard

> **CONFIDENTIAL** — This skill contains internal infrastructure references (resource names, stack identifiers, queue names). Do not share outside the team or commit to public repositories.

> Read-only diagnostic skill. No writes, no deploys, no doc updates. Pure observability.

## When to Use
- Quick health check before a deploy
- After a deploy to verify both stacks
- Investigating an alarm or incident
- Weekly status review

## Platform

This skill targets **macOS** (BSD date, zsh). Linux requires different date flags (`date -d` instead of `date -v`). Commands use macOS syntax with Linux fallback where noted.

## Instructions

Run all diagnostic commands below and present results as a formatted dashboard. Flag any unhealthy items with a warning marker. If AWS credentials are expired, stop immediately and instruct the user to run `aws sso login --profile default`.

### Execution Order

Run commands in parallel where possible. Group by section and present results as they complete. Add `timeout 15` before each AWS CLI command. If a command times out, mark that section as ERROR in the dashboard and continue with remaining sections.

---

### 1. Pre-flight: AWS Identity

```bash
aws sts get-caller-identity --output json
```

If this fails with `ExpiredTokenException` or `UnauthorizedAccess`, STOP and tell the user:
> Your AWS session is expired. Run: `aws sso login --profile default`

---

### 2. Stack Health (both stages)

```bash
# Dev stack
aws cloudformation describe-stacks --stack-name callhero-dev \
  --query "Stacks[0].{Status:StackStatus,Updated:LastUpdatedTime,DriftStatus:DriftInformation.StackDriftStatus}" \
  --output json

# Prod stack
aws cloudformation describe-stacks --stack-name callhero-prod \
  --query "Stacks[0].{Status:StackStatus,Updated:LastUpdatedTime,DriftStatus:DriftInformation.StackDriftStatus}" \
  --output json

# Resource counts
aws cloudformation describe-stack-resources --stack-name callhero-dev \
  --query "length(StackResources)" --output text
aws cloudformation describe-stack-resources --stack-name callhero-prod \
  --query "length(StackResources)" --output text
```

Present as a table. Flag if status is not `*_COMPLETE`.

---

### 3. Canary (both stages)

```bash
# Write payload to temp file; parse metadata separately to avoid mixing stdout
for stage in dev prod; do
  TMPFILE=$(mktemp)
  RESULT=$(aws lambda invoke --function-name "callhero-canary-${stage}" "$TMPFILE" --output json 2>/dev/null)
  STATUS=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('StatusCode','ERROR'))" 2>/dev/null)
  PAYLOAD=$(cat "$TMPFILE" 2>/dev/null)
  rm -f "$TMPFILE"
  echo "canary-${stage}: StatusCode=${STATUS}, Payload=${PAYLOAD}"
done
```

Report status code from each. Flag if StatusCode is not 200.

---

### 4. Alarms

```bash
# Alarms in ALARM state (both stages share the same account)
aws cloudwatch describe-alarms --state-value ALARM \
  --alarm-name-prefix callhero \
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}" \
  --output json

# Count by state
aws cloudwatch describe-alarms --alarm-name-prefix callhero \
  --query "{OK: length(MetricAlarms[?StateValue=='OK']), ALARM: length(MetricAlarms[?StateValue=='ALARM']), INSUFFICIENT: length(MetricAlarms[?StateValue=='INSUFFICIENT_DATA'])}" \
  --output json
```

Present alarm counts. If any are in ALARM state, list them with their reason.

---

### 5. Lambda Concurrency (kill-switch detection)

```bash
# Batch check: single API call per stage instead of 9 individual calls
for stage in dev prod; do
  aws lambda list-functions \
    --query "Functions[?starts_with(FunctionName, 'callhero-') && ends_with(FunctionName, '-${stage}')].{Name:FunctionName,Concurrency:ReservedConcurrentExecutions}" \
    --output json 2>/dev/null | \
    python3 -c "
import json, sys
fns = json.load(sys.stdin)
killed = [f['Name'] for f in fns if f.get('Concurrency') == 0]
if killed:
    for k in killed: print(f'KILLED: {k}')
else:
    print(f'All callhero-*-${stage} functions active ({len(fns)} found)')
" 2>/dev/null || echo "WARN: Could not list ${stage} functions"
done
```

Report "All Lambdas active" or list killed functions. Flag any with concurrency=0.

---

### 6. RDS (both stages)

```bash
aws rds describe-db-instances --db-instance-identifier callhero-analytics-dev \
  --query "DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Version:EngineVersion,Class:DBInstanceClass,Storage:AllocatedStorage,MultiAZ:MultiAZ}" \
  --output json

aws rds describe-db-instances --db-instance-identifier callhero-analytics-prod \
  --query "DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Version:EngineVersion,Class:DBInstanceClass,Storage:AllocatedStorage,MultiAZ:MultiAZ}" \
  --output json
```

Flag if status is not `available`.

---

### 7. VPC Endpoints (dev only — owner)

```bash
# Look up the VPC ID dynamically by Project tag
CH_VPC=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=callhero" \
  --query "Vpcs[0].VpcId" --output text 2>/dev/null)

if [ -n "$CH_VPC" ] && [ "$CH_VPC" != "None" ]; then
  aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$CH_VPC" \
    --query "VpcEndpoints[].{Service:ServiceName,Type:VpcEndpointType,State:State}" \
    --output json
else
  echo "WARN: Could not find callhero VPC by tag. Check VPC tagging."
fi
```

Report total count and types. Flag if any are not `available`.

---

### 8. Queues (both stages)

```bash
for stage in dev prod; do
  for queue in callhero-queue callhero-dlq callhero-analytics-queue callhero-analytics-dlq; do
    url=$(aws sqs get-queue-url --queue-name "${queue}-${stage}" --query QueueUrl --output text 2>/dev/null)
    if [ -n "$url" ] && [ "$url" != "None" ]; then
      attrs=$(aws sqs get-queue-attributes --queue-url "$url" \
        --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
        --query "Attributes" --output json 2>/dev/null)
      echo "${queue}-${stage}: $attrs"
    fi
  done
done
```

Present as a table with visible + in-flight counts. Flag if DLQ has messages > 0.

---

### 9. Cost (MTD) — $0.01 per API call

> Cost data updates daily. If this dashboard was already run today, reuse the previously reported MTD figure instead of making another API call.

```bash
# Guard: on day 1, End must be > Start; use tomorrow's date
TODAY=$(date -u +%Y-%m-%d)
DAY=$(date -u +%d)
if [ "$DAY" = "01" ]; then
  END_DATE=$(date -u -v+1d +%Y-%m-%d 2>/dev/null || date -u -d "+1 day" +%Y-%m-%d)
else
  END_DATE="$TODAY"
fi

# Current month-to-date spend
aws ce get-cost-and-usage \
  --time-period "Start=$(date -u +%Y-%m-01),End=$END_DATE" \
  --granularity MONTHLY \
  --filter '{"Tags":{"Key":"Project","Values":["callhero"]}}' \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost" \
  --output json
```

Report MTD spend and extrapolate to estimated monthly total (MTD / day-of-month * days-in-month). Add caveat if day-of-month < 10: "Early-month extrapolation — accuracy improves after day 10."

---

### 10. Version & Release

```bash
# Git tags
git -C ${CALLHERO_HOME:-$HOME/repos/callhero} tag -l -n1

# Commits since last tag
LAST_TAG=$(git -C ${CALLHERO_HOME:-$HOME/repos/callhero} describe --tags --abbrev=0 2>/dev/null || echo "none")
if [ "$LAST_TAG" != "none" ]; then
  git -C ${CALLHERO_HOME:-$HOME/repos/callhero} log --oneline "${LAST_TAG}..HEAD"
else
  echo "No tags found"
fi

# pyproject.toml version
grep "^version" ${CALLHERO_HOME:-$HOME/repos/callhero}/pyproject.toml

# Working tree status
git -C ${CALLHERO_HOME:-$HOME/repos/callhero} status --short
```

Report current version, last tag, commits since tag, and whether the working tree is clean.

---

## Output Format

Present results as a dashboard with clear sections:

```
## CallHero Production Health Dashboard
### Generated: <timestamp>

| Section           | Status | Details                        |
|-------------------|--------|--------------------------------|
| AWS Identity      | OK     | <user> @ <account-id>          |
| Stack: dev        | OK     | UPDATE_COMPLETE, N resources    |
| Stack: prod       | OK     | CREATE_COMPLETE, N resources    |
| Canary: dev       | OK     | 200                            |
| Canary: prod      | OK     | 200                            |
| Alarms            | OK     | N OK, 0 ALARM, N INSUF         |
| Lambda Kill-Switch| OK     | All functions active            |
| RDS: dev          | OK     | available, <instance-class>     |
| RDS: prod         | OK     | available, <instance-class>     |
| VPC Endpoints     | OK     | N/N available                   |
| Queues            | OK     | 0 in DLQs                      |
| Cost MTD          | OK     | $X.XX / ~$XX.XX est monthly    |
| Version           | OK     | vX.Y.Z, N commits since tag    |

### Alarms in ALARM State
(none — or list them)

### DLQ Messages
(none — or list queue names with counts)
```

Use "WARN" status (not OK) for:

| Condition | Status | Remediation Hint |
|-----------|--------|-----------------|
| Stack status not `*_COMPLETE` | WARN | Check CloudFormation events for failure reason |
| Canary not returning 200 | WARN | Check canary Lambda logs in CloudWatch |
| Any alarm in ALARM state | WARN | Check alarm's linked runbook or metric dashboard |
| Any Lambda with concurrency=0 | WARN | Re-enable via `aws lambda put-function-concurrency` |
| RDS not `available` | WARN | Check RDS events for maintenance or failure |
| VPC endpoint not `available` | WARN | Check endpoint status in VPC console |
| DLQ message count > 0 | WARN | Inspect DLQ messages; replay or investigate source |
| Estimated monthly cost > $65 | WARN | Review per-service costs; check for orphaned resources |
| Uncommitted changes in working tree | WARN | Commit or stash changes before deploy |
