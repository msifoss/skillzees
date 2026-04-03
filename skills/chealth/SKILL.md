# /chealth — CallHero Comprehensive Health Check

> **CONFIDENTIAL** — Contains internal infrastructure references. Do not share outside the team.

> Read-only diagnostic skill. No writes, no deploys. Pure observability.

## When to Use
- Pre-deploy health gate
- Post-deploy verification
- Incident triage
- Daily/weekly health review
- Verifying CloudFront + WAF are operational

## Platform

macOS (BSD date, zsh). Commands use macOS syntax with Linux fallback where noted.

## Instructions

Run all diagnostic sections below and present results as a formatted dashboard. Flag any unhealthy items with WARN or FAIL markers. If AWS credentials are expired, stop immediately and instruct the user to run `aws sso login --profile default`.

**Execution strategy:** Run independent sections in parallel using multiple Bash tool calls. Group results into a single dashboard at the end. Add `timeout 15` before each AWS CLI command.

**Important:** This skill runs actual HTTP requests against live endpoints. It does NOT modify any resources.

---

## Section 0 — Pre-flight: AWS Identity

```bash
aws sts get-caller-identity --output json
```

If this fails with `ExpiredTokenException`, STOP and tell the user:
> Your AWS session is expired. Run: `aws sso login --profile default`

---

## Section 1 — Stack Health

```bash
for stack in callhero-dev callhero-prod; do
  timeout 15 aws cloudformation describe-stacks --stack-name "$stack" \
    --query "Stacks[0].{Status:StackStatus,Updated:LastUpdatedTime,DriftStatus:DriftInformation.StackDriftStatus}" \
    --output json 2>/dev/null || echo "{\"Error\": \"$stack unreachable\"}"
done
```

Flag if status is not `*_COMPLETE`.

---

## Section 2 — Endpoint HTTP Probes

Hit every public endpoint with a lightweight HTTP request. This is the ground truth — CloudFormation can say COMPLETE while the endpoint is dead.

```bash
# Resolve Function URLs dynamically from CloudFormation outputs
DEV_URLS=$(timeout 15 aws cloudformation describe-stacks --stack-name callhero-dev \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output text 2>/dev/null)
PROD_URLS=$(timeout 15 aws cloudformation describe-stacks --stack-name callhero-prod \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output text 2>/dev/null)

# Extract specific URLs from outputs
get_output() {
  echo "$1" | grep "$2" | awk '{print $2}'
}

# Dev endpoints
DEV_SUBMITLINK=$(get_output "$DEV_URLS" "SubmitLinkFunctionUrl")
DEV_CLOUDFRONT=$(get_output "$DEV_URLS" "SubmitLinkCloudFrontUrl")
DEV_COSTDASH=$(get_output "$DEV_URLS" "CostDashboardUrl")
DEV_ANALYTICS=$(get_output "$DEV_URLS" "AnalyticsDashboardUrl")
DEV_SYSHEALTH=$(get_output "$DEV_URLS" "SystemHealthUrl")

# Prod endpoints
PROD_SUBMITLINK=$(get_output "$PROD_URLS" "SubmitLinkFunctionUrl")
PROD_CLOUDFRONT=$(get_output "$PROD_URLS" "SubmitLinkCloudFrontUrl")
PROD_COSTDASH=$(get_output "$PROD_URLS" "CostDashboardUrl")
PROD_ANALYTICS=$(get_output "$PROD_URLS" "AnalyticsDashboardUrl")
PROD_SYSHEALTH=$(get_output "$PROD_URLS" "SystemHealthUrl")

# Probe each endpoint — GET dashboards, POST for SubmitLink (expect 4xx, not 5xx/timeout)
probe() {
  local name="$1" url="$2" method="${3:-GET}"
  if [ -z "$url" ] || [ "$url" = "None" ]; then
    echo "$name: SKIP (not deployed)"
    return
  fi
  local start=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
  if [ "$method" = "POST" ]; then
    HTTP_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
      -H "Content-Type: application/json" -d '{"contact_id":"health-check","ticket_id":"0"}' 2>/dev/null)
  else
    HTTP_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
  fi
  local end=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
  local ms=$(( (end - start) / 1000000 ))
  # 2xx/3xx/4xx = endpoint alive (4xx is expected for auth-required endpoints)
  # 5xx or 000 (timeout) = endpoint down
  if [ "$HTTP_CODE" = "000" ]; then
    echo "$name: FAIL (timeout) ${ms}ms"
  elif [ "${HTTP_CODE:0:1}" = "5" ]; then
    echo "$name: FAIL (HTTP $HTTP_CODE) ${ms}ms"
  else
    echo "$name: OK (HTTP $HTTP_CODE) ${ms}ms"
  fi
}

echo "=== DEV ENDPOINTS ==="
probe "SubmitLink-dev" "$DEV_SUBMITLINK" POST
probe "CloudFront-dev" "$DEV_CLOUDFRONT" POST
probe "CostDashboard-dev" "$DEV_COSTDASH"
probe "AnalyticsDash-dev" "$DEV_ANALYTICS"
probe "SystemHealth-dev" "$DEV_SYSHEALTH"

echo "=== PROD ENDPOINTS ==="
probe "SubmitLink-prod" "$PROD_SUBMITLINK" POST
probe "CloudFront-prod" "$PROD_CLOUDFRONT" POST
probe "CostDashboard-prod" "$PROD_COSTDASH"
probe "AnalyticsDash-prod" "$PROD_ANALYTICS"
probe "SystemHealth-prod" "$PROD_SYSHEALTH"
```

**Status rules:**
- HTTP 2xx/3xx = OK (healthy)
- HTTP 4xx = OK (endpoint alive, auth/validation working as expected)
- HTTP 5xx = FAIL (server error)
- HTTP 000 = FAIL (timeout / DNS failure / endpoint dead)
- Latency > 5000ms = WARN

---

## Section 3 — CloudFront & WAF

```bash
# CloudFront distributions
for stack in callhero-dev callhero-prod; do
  CF_DOMAIN=$(timeout 15 aws cloudformation describe-stacks --stack-name "$stack" \
    --query "Stacks[0].Outputs[?OutputKey=='SubmitLinkCloudFrontDomain'].OutputValue" \
    --output text 2>/dev/null)
  if [ -n "$CF_DOMAIN" ] && [ "$CF_DOMAIN" != "None" ]; then
    # Get distribution ID from domain
    DIST_ID=$(timeout 15 aws cloudfront list-distributions \
      --query "DistributionList.Items[?DomainName=='${CF_DOMAIN}'].{Id:Id,Status:Status,Enabled:Enabled}" \
      --output json 2>/dev/null)
    echo "${stack} CloudFront: domain=${CF_DOMAIN} dist=${DIST_ID}"
  else
    echo "${stack} CloudFront: not deployed"
  fi
done

# WAF WebACLs
for stack in callhero-dev callhero-prod; do
  WAF_ARN=$(timeout 15 aws cloudformation describe-stacks --stack-name "$stack" \
    --query "Stacks[0].Outputs[?OutputKey=='SubmitLinkWafWebAclArn'].OutputValue" \
    --output text 2>/dev/null)
  if [ -n "$WAF_ARN" ] && [ "$WAF_ARN" != "None" ]; then
    # WAF for CloudFront must be queried in us-east-1 with CLOUDFRONT scope
    WAF_INFO=$(timeout 15 aws wafv2 get-web-acl \
      --name "$(echo $WAF_ARN | awk -F/ '{print $(NF-1)}')" \
      --scope CLOUDFRONT --id "$(echo $WAF_ARN | awk -F/ '{print $NF}')" \
      --region us-east-1 \
      --query "WebACL.{Name:Name,Rules:length(Rules),Capacity:Capacity}" \
      --output json 2>/dev/null)
    echo "${stack} WAF: ${WAF_INFO}"
  else
    echo "${stack} WAF: not deployed"
  fi
done
```

Flag if CloudFront status is not `Deployed` or WAF is missing.

---

## Section 4 — CloudWatch Alarms

```bash
# All callhero alarms grouped by state
timeout 15 aws cloudwatch describe-alarms --alarm-name-prefix callhero \
  --query "{
    OK: MetricAlarms[?StateValue=='OK'].AlarmName,
    ALARM: MetricAlarms[?StateValue=='ALARM'].{Name:AlarmName,Reason:StateReason},
    INSUFFICIENT: MetricAlarms[?StateValue=='INSUFFICIENT_DATA'].AlarmName
  }" --output json 2>/dev/null
```

Report counts by state. List any alarms in ALARM state with their reason.

---

## Section 5 — SQS Queues & DLQs

```bash
for stage in dev prod; do
  for queue in callhero-queue callhero-dlq callhero-analytics-queue callhero-analytics-dlq; do
    url=$(timeout 10 aws sqs get-queue-url --queue-name "${queue}-${stage}" --query QueueUrl --output text 2>/dev/null)
    if [ -n "$url" ] && [ "$url" != "None" ]; then
      attrs=$(timeout 10 aws sqs get-queue-attributes --queue-url "$url" \
        --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
        --query "Attributes" --output json 2>/dev/null)
      echo "${queue}-${stage}: $attrs"
    fi
  done
done
```

Flag if any DLQ has messages > 0.

---

## Section 6 — RDS Health

```bash
for db in callhero-analytics-dev callhero-analytics-prod; do
  timeout 15 aws rds describe-db-instances --db-instance-identifier "$db" \
    --query "DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Version:EngineVersion,Class:DBInstanceClass,Storage:AllocatedStorage,FreeStorage:FreeStorageSpace}" \
    --output json 2>/dev/null || echo "{\"Error\": \"$db unreachable\"}"
done
```

Flag if status is not `available`.

---

## Section 7 — Lambda Health

```bash
for stage in dev prod; do
  # List all callhero functions with their state and concurrency
  timeout 15 aws lambda list-functions \
    --query "Functions[?starts_with(FunctionName, 'callhero-') && ends_with(FunctionName, '-${stage}')].{Name:FunctionName,State:State,Concurrency:ReservedConcurrentExecutions,Runtime:Runtime,Memory:MemorySize,LastModified:LastModified}" \
    --output json 2>/dev/null
done
```

Report function count per stage. Flag any with:
- State != `Active`
- Concurrency = 0 (kill-switch engaged)

---

## Section 8 — VPC Endpoints

```bash
CH_VPC=$(timeout 10 aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=callhero" \
  --query "Vpcs[0].VpcId" --output text 2>/dev/null)

if [ -n "$CH_VPC" ] && [ "$CH_VPC" != "None" ]; then
  timeout 15 aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$CH_VPC" \
    --query "VpcEndpoints[].{Service:ServiceName,Type:VpcEndpointType,State:State}" \
    --output json 2>/dev/null
else
  echo "WARN: Could not find callhero VPC by tag"
fi
```

Report count and flag any not in `available` state.

---

## Section 9 — SNS Subscriptions

```bash
for stage in dev prod; do
  TOPIC_ARN=$(timeout 10 aws sns list-topics \
    --query "Topics[?contains(TopicArn, 'callhero-admin-notifications-${stage}')].TopicArn" \
    --output text 2>/dev/null)
  if [ -n "$TOPIC_ARN" ] && [ "$TOPIC_ARN" != "None" ]; then
    SUBS=$(timeout 10 aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
      --query "Subscriptions[].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" \
      --output json 2>/dev/null)
    echo "SNS-${stage}: topic=${TOPIC_ARN}"
    echo "$SUBS"
  fi
done
```

Flag if no confirmed subscriptions exist.

---

## Section 10 — API Key Validation

```bash
# Check API keys exist in DynamoDB (don't expose the actual keys)
for stage in dev prod; do
  COUNT=$(timeout 10 aws dynamodb scan --table-name "callhero-api-keys-${stage}" \
    --select COUNT \
    --query "Count" --output text 2>/dev/null)
  echo "api-keys-${stage}: ${COUNT:-0} keys"

  # List key prefixes and status (without exposing hashes)
  timeout 10 aws dynamodb scan --table-name "callhero-api-keys-${stage}" \
    --projection-expression "key_prefix,description,created_at,revoked" \
    --output json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data.get('Items', []):
    prefix = item.get('key_prefix', {}).get('S', '?')
    desc = item.get('description', {}).get('S', '')
    revoked = item.get('revoked', {}).get('BOOL', False)
    status = 'REVOKED' if revoked else 'active'
    print(f'  {prefix}... ({desc}) [{status}]')
" 2>/dev/null
done
```

Flag if any stage has 0 active keys.

---

## Section 11 — Cost MTD

```bash
TODAY=$(date -u +%Y-%m-%d)
DAY=$(date -u +%d)
if [ "$DAY" = "01" ]; then
  END_DATE=$(date -u -v+1d +%Y-%m-%d 2>/dev/null || date -u -d "+1 day" +%Y-%m-%d)
else
  END_DATE="$TODAY"
fi

timeout 15 aws ce get-cost-and-usage \
  --time-period "Start=$(date -u +%Y-%m-01),End=$END_DATE" \
  --granularity MONTHLY \
  --filter '{"Tags":{"Key":"Project","Values":["callhero"]}}' \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost" \
  --output json 2>/dev/null
```

Report MTD and extrapolated monthly. Flag if projected > $80/month.

---

## Section 12 — Version, Tests & Deploys

```bash
REPO="${CALLHERO_HOME:-$HOME/repos/callhero}"

# Version
LAST_TAG=$(git -C "$REPO" describe --tags --abbrev=0 2>/dev/null || echo "none")
COMMITS_SINCE=$(git -C "$REPO" rev-list "${LAST_TAG}..HEAD" --count 2>/dev/null || echo "?")
VERSION=$(grep "^version" "$REPO/pyproject.toml" 2>/dev/null | head -1)
DIRTY=$(git -C "$REPO" status --short 2>/dev/null | wc -l | tr -d ' ')

echo "Version: ${VERSION}"
echo "Last tag: ${LAST_TAG}"
echo "Commits since tag: ${COMMITS_SINCE}"
echo "Uncommitted files: ${DIRTY}"

# Test count
TEST_COUNT=$(find "$REPO/tests" -name "test_*.py" -o -name "*_test.py" 2>/dev/null | wc -l | tr -d ' ')
echo "Test files: ${TEST_COUNT}"

# Deploy counts (from git tags and stack update times)
TAG_COUNT=$(git -C "$REPO" tag -l "v*" 2>/dev/null | wc -l | tr -d ' ')
echo "Release tags: ${TAG_COUNT}"

# Recent deploys from CloudFormation events
for stack in callhero-dev callhero-prod; do
  LAST_DEPLOY=$(timeout 10 aws cloudformation describe-stacks --stack-name "$stack" \
    --query "Stacks[0].LastUpdatedTime" --output text 2>/dev/null)
  echo "Last deploy ${stack}: ${LAST_DEPLOY}"
done
```

---

## Section 13 — Dashboard & Report Links

Resolve all dynamic URLs from CloudFormation outputs and combine with known static URLs.

```bash
REPO="${CALLHERO_HOME:-$HOME/repos/callhero}"
PORTAL="http://callhero-insights-653614598774.s3-website-us-east-1.amazonaws.com"

# Resolve dynamic Lambda Function URLs from stack outputs
DEV_URLS=$(aws cloudformation describe-stacks --stack-name callhero-dev \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output text 2>/dev/null)
PROD_URLS=$(aws cloudformation describe-stacks --stack-name callhero-prod \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output text 2>/dev/null)
get_output() { echo "$1" | grep "$2" | awk '{print $2}'; }

echo "=== DYNAMIC DASHBOARDS (Lambda) ==="
echo "CostDashboard-dev: $(get_output "$DEV_URLS" "CostDashboardUrl")"
echo "CostDashboard-prod: $(get_output "$PROD_URLS" "CostDashboardUrl")"
echo "AnalyticsDashboard-dev: $(get_output "$DEV_URLS" "AnalyticsDashboardUrl")"
echo "AnalyticsDashboard-prod: $(get_output "$PROD_URLS" "AnalyticsDashboardUrl")"
echo "SystemHealth-dev: $(get_output "$DEV_URLS" "SystemHealthUrl")"
echo "SystemHealth-prod: $(get_output "$PROD_URLS" "SystemHealthUrl")"
echo "CloudFront-dev: $(get_output "$DEV_URLS" "SubmitLinkCloudFrontUrl")"
echo "CloudFront-prod: $(get_output "$PROD_URLS" "SubmitLinkCloudFrontUrl")"

echo "=== STATIC REPORTS (S3 Insights Portal) ==="
echo "Portal Home: ${PORTAL}/"
# List all HTML files in docs/insights/ to discover reports
find "$REPO/docs/insights" -name "*.html" -exec basename {} \; 2>/dev/null | sort | while read -r f; do
  echo "  ${PORTAL}/${f}"
done

echo "=== AWS CONSOLE ==="
# Use SSO start URL for federated console access (account 653614598774)
SSO="https://membersolutions.awsapps.com/start/#/console?account_id=653614598774&role_name=AWSPowerUserAccess&destination="
echo "CloudWatch Dashboard (dev): ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards/dashboard/CallHero-dev",safe=""))')"
echo "CloudWatch Dashboard (prod): ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards/dashboard/CallHero-prod",safe=""))')"
echo "CloudWatch Alarms: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:",safe=""))')"
echo "Lambda Functions: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions",safe=""))')"
echo "SQS Queues: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/sqs/v3/home?region=us-east-1#/queues",safe=""))')"
echo "RDS Instances: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/rds/home?region=us-east-1#databases:",safe=""))')"
echo "CloudFront Distributions: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/cloudfront/v4/home#/distributions",safe=""))')"
echo "WAF Web ACLs: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/wafv2/homev2/web-acls?region=global",safe=""))')"
echo "Cost Explorer: ${SSO}$(python3 -c 'import urllib.parse; print(urllib.parse.quote("https://us-east-1.console.aws.amazon.com/cost-management/home?region=us-east-1#/cost-explorer",safe=""))')"
```

---

## Output Format

Present all results as a clean dashboard. Use this structure:

```
## CallHero Health Dashboard
### Generated: YYYY-MM-DD HH:MM (local)

### Infrastructure
| Check               | Dev           | Prod          |
|---------------------|---------------|---------------|
| Stack Status        | OK / WARN     | OK / WARN     |
| Last Deploy         | <timestamp>   | <timestamp>   |
| Lambda Count        | N active      | N active      |
| Kill-Switch         | OK / WARN     | OK / WARN     |
| RDS                 | available     | available     |
| VPC Endpoints       | N/N available | (shared w/dev)|
| CloudFront          | OK / N/A      | OK / N/A      |
| WAF                 | OK / N/A      | OK / N/A      |

### Endpoint Probes
| Endpoint            | Dev (HTTP/ms) | Prod (HTTP/ms)|
|---------------------|---------------|---------------|
| SubmitLink          | 401 / 234ms   | 401 / 189ms   |
| CloudFront          | 401 / 156ms   | N/A           |
| CostDashboard       | 200 / 312ms   | 200 / 287ms   |
| AnalyticsDashboard  | 200 / 298ms   | 200 / 276ms   |
| SystemHealth        | 200 / 345ms   | 200 / 301ms   |

### Monitoring
| Check               | Status        | Details       |
|---------------------|---------------|---------------|
| Alarms              | N OK / N ALARM| (list any)    |
| Main Queue (dev)    | 0 msgs        |               |
| Main Queue (prod)   | 0 msgs        |               |
| Main DLQ (dev)      | 0 msgs        |               |
| Main DLQ (prod)     | 0 msgs        |               |
| Analytics Queue     | 0 msgs        |               |
| Analytics DLQ       | 0 msgs        |               |
| SNS (dev)           | N subs        |               |
| SNS (prod)          | N subs        |               |

### Security
| Check               | Dev           | Prod          |
|---------------------|---------------|---------------|
| API Keys            | N active      | N active      |
| WAF Rules           | N rules       | N rules       |
| CloudFront OAC      | OK / N/A      | OK / N/A      |

### Project
| Metric              | Value         |
|---------------------|---------------|
| Version             | vX.Y.Z        |
| Last Tag            | vX.Y.Z        |
| Commits Since Tag   | N             |
| Test Files          | N             |
| Release Tags        | N             |
| Uncommitted Files   | N             |
| Cost MTD            | $X.XX         |
| Est. Monthly        | ~$XX.XX       |

### Dynamic Dashboards
| Dashboard          | Dev | Prod |
|--------------------|-----|------|
| Cost Dashboard     | [link] | [link] |
| Analytics Dashboard| [link] | [link] |
| System Health      | [link] | [link] |
| CloudFront         | [link] | N/A    |

### Insights Portal (Static Reports)
`http://callhero-insights-653614598774.s3-website-us-east-1.amazonaws.com/`
| Report | Link |
|--------|------|
| Portal Home | [link] |
| Executive Report | [link] |
| Agent Scorecard | [link] |
| COO Report | [link] |
| Monthly Brief | [link] |
| Cubiic Recovery | [link] |
| Support Breakdown | [link] |
| Talk-Track Analysis | [link] |
| OctaveBytes Comparison | [link] |
| Connect AI Pricing | [link] |
| Comprehensive Report | [link] |

### AWS Console Quick Links
| Resource | Link |
|----------|------|
| CloudWatch Dashboard (dev) | [link] |
| CloudWatch Dashboard (prod) | [link] |
| CloudWatch Alarms | [link] |
| Lambda Functions | [link] |
| SQS Queues | [link] |
| RDS Instances | [link] |
| CloudFront | [link] |
| WAF Web ACLs | [link] |
| Cost Explorer | [link] |

### Warnings
(list any WARN/FAIL items with remediation hints)

### Alarms in ALARM State
(list or "None")

### DLQ Messages
(list or "None — all queues empty")
```

## Status Rules

| Condition | Status | Remediation |
|-----------|--------|-------------|
| Stack not `*_COMPLETE` | WARN | Check CFn events |
| Endpoint HTTP 5xx or timeout | FAIL | Check Lambda logs |
| Endpoint latency > 5000ms | WARN | Check cold starts / VPC |
| CloudFront not `Deployed` | WARN | Check distribution status |
| WAF missing when CloudFront exists | FAIL | WAF should always accompany CF |
| Any alarm in ALARM state | WARN | Check alarm metric + runbook |
| Lambda concurrency = 0 | WARN | Kill-switch engaged |
| RDS not `available` | WARN | Check RDS events |
| VPC endpoint not `available` | WARN | Check endpoint status |
| DLQ messages > 0 | WARN | Inspect + replay or investigate |
| API keys = 0 for a stage | FAIL | Create keys with manage-api-keys.py |
| SNS no confirmed subs | WARN | Confirm subscription |
| Cost projected > $80/mo | WARN | Review per-service costs |
| Uncommitted files > 0 | INFO | Commit or stash |
