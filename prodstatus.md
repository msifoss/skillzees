# Production Health Dashboard

Usage: `/prodstatus`

**Arguments:** $ARGUMENTS

---

## Purpose

Read-only diagnostic command. No writes, no deploys, no doc updates. Pure observability. Runs all health checks against your AWS infrastructure and presents a formatted dashboard.

**When to use:**
- Quick health check before a deploy
- After a deploy to verify both stacks
- Investigating an alarm or incident
- Weekly status review

---

## Instructions for Claude

Run all diagnostic commands below and present results as a formatted dashboard. Flag any unhealthy items with a warning marker. If AWS credentials are expired, stop immediately and instruct the user to run `aws sso login --profile default`.

### Execution Order

Run commands in parallel where possible. Group by section and present results as they complete.

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
aws lambda invoke --function-name callhero-canary-dev /dev/stdout 2>/dev/null
aws lambda invoke --function-name callhero-canary-prod /dev/stdout 2>/dev/null
```

Report status code from each. Flag if not 200.

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
# Check all dev + prod functions for reserved concurrency = 0 (killed)
for stage in dev prod; do
  for fn in submit-link process-call-link analytics-ingestion canary weekly-report transcript-search cost-monitor cost-dashboard analytics-dashboard; do
    result=$(aws lambda get-function-configuration --function-name "callhero-${fn}-${stage}" \
      --query "ReservedConcurrentExecutions" --output text 2>/dev/null)
    if [ "$result" = "0" ]; then
      echo "KILLED: callhero-${fn}-${stage}"
    fi
  done
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

### 7. VPC Endpoints

```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-04b59b3136e4a04e3" \
  --query "VpcEndpoints[].{Service:ServiceName,Type:VpcEndpointType,State:State}" \
  --output json
```

Report count (expect 6: 5 interface + 1 gateway). Flag if any are not `available`.

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

### 9. Cost (MTD)

```bash
# Current month-to-date spend
aws ce get-cost-and-usage \
  --time-period "Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d)" \
  --granularity MONTHLY \
  --filter '{"Tags":{"Key":"Project","Values":["callhero"]}}' \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost" \
  --output json
```

Report MTD spend and extrapolate to estimated monthly total (MTD / day-of-month * days-in-month).

---

### 10. Version & Release

```bash
# Git tags
git tag -l -n1

# Commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
if [ "$LAST_TAG" != "none" ]; then
  git log --oneline "${LAST_TAG}..HEAD"
else
  echo "No tags found"
fi

# Project version
grep "^version" pyproject.toml 2>/dev/null || grep '"version"' package.json 2>/dev/null

# Working tree status
git status --short
```

Report current version, last tag, commits since tag, and whether the working tree is clean.

---

## Output Format

Present results as a dashboard with clear sections:

```
## Production Health Dashboard
### Generated: <timestamp>

| Section           | Status | Details                        |
|-------------------|--------|--------------------------------|
| AWS Identity      | OK     | user @ account-id              |
| Stack: dev        | OK     | UPDATE_COMPLETE, N resources   |
| Stack: prod       | OK     | CREATE_COMPLETE, N resources   |
| Canary: dev       | OK     | 200                            |
| Canary: prod      | OK     | 200                            |
| Alarms            | OK     | N OK, 0 ALARM, N INSUF        |
| Lambda Kill-Switch| OK     | All N functions active         |
| RDS: dev          | OK     | available, db.t4g.micro        |
| RDS: prod         | OK     | available, db.t4g.micro        |
| VPC Endpoints     | OK     | 6/6 available                  |
| Queues            | OK     | 0 in DLQs                      |
| Cost MTD          | OK     | $X.XX / ~$XX.XX est monthly    |
| Version           | OK     | vX.X.X, N commits since tag    |

### Alarms in ALARM State
(none — or list them)

### DLQ Messages
(none — or list queue names with counts)
```

Use "WARN" status (not OK) for:
- Stack status not `*_COMPLETE`
- Canary not returning 200
- Any alarm in ALARM state
- Any Lambda with concurrency=0
- RDS not `available`
- VPC endpoint not `available`
- DLQ message count > 0
- Estimated monthly cost > $65 (budget threshold)
- Uncommitted changes in working tree
