---
name: costkeeper
description: Cost pillar agent — tracks infrastructure costs, alerts on anomalies, maintains budget dashboard, designs kill switches
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch
argument-hint: "estimate | dashboard | alert | killswitch"
---

# /costkeeper — Cost Pillar Agent

Makes cost a first-class citizen from day one. Tracks infrastructure costs, alerts on anomalies, maintains budget dashboards, and designs kill switches to prevent runaway spend.

> "Cost management designed from day one, not bolted on post-deployment." — AI-DLC Pillar 4

## Trigger

User invokes `/costkeeper [action]` or during Phase 4 hardening.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `estimate` | Estimate infrastructure costs for the architecture | `/costkeeper estimate` |
| `dashboard` | Generate cost tracking dashboard spec | `/costkeeper dashboard` |
| `alert` | Configure cost alert thresholds | `/costkeeper alert` |
| `killswitch` | Design kill switch for cost runaway | `/costkeeper killswitch` |

---

## Action: `estimate`

### Step 1: Read Architecture

```bash
# Find infrastructure definitions
find . -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "serverless.*" 2>/dev/null | grep -v node_modules
cat docs/technical-spec.md 2>/dev/null
```

### Step 2: Identify Cost Drivers

For each infrastructure component:
- Compute (Lambda invocations, ECS tasks, EC2 instances)
- Storage (S3, RDS, DynamoDB)
- Data transfer (API Gateway, CloudFront, cross-region)
- Third-party APIs (Stripe, Twilio, SendGrid)

### Step 3: Produce Estimate

```markdown
# Cost Estimate

**Date:** YYYY-MM-DD
**Architecture:** [summary]

## Monthly Cost Breakdown

| Component | Service | Tier | Monthly Est. | Notes |
|-----------|---------|------|-------------|-------|
| API | Lambda | 1M requests | $20 | Includes 400k free tier |
| Database | RDS t3.micro | Single AZ | $15 | Dev; prod needs Multi-AZ ($30) |
| Storage | S3 | 10GB | $0.23 | Plus $0.09/GB transfer |

## Totals

| Environment | Monthly | Annual |
|-------------|---------|--------|
| Dev | $50 | $600 |
| Staging | $50 | $600 |
| Production | $150 | $1,800 |
| **Total** | **$250** | **$3,000** |

## Cost Optimization Opportunities

1. [Specific recommendation with savings estimate]
```

Save to `docs/budget/cost-estimate.md`.

---

## Action: `dashboard`

Generate specification for a cost monitoring dashboard following the AI-DLC budget management pattern: Monitor -> Dashboard -> Alert -> Kill Switch.

---

## Action: `alert`

Configure alert thresholds:
- 50% budget: INFO
- 75% budget: WARNING
- 90% budget: URGENT
- 100% budget: CRITICAL
- 2x daily anomaly: IMMEDIATE

---

## Action: `killswitch`

Design mechanisms to immediately stop/throttle resources generating unexpected costs:
- Compute termination (stop ECS tasks, throttle Lambda)
- Storage lifecycle (move to Glacier, stop writes)
- API rate limiting (hard limits on third-party calls)
- Approval workflow (human gate before resuming)

---

## Integration Points

- **Gatekeeper:** GATE-P4-03 (cost dashboard + alarms active)
- **State:** Updates cost pillar metrics (budget_status, monthly_estimate)
- **Hardener:** Kill switch design feeds into hardening bolts
- **Deployer:** Cost monitoring deployed alongside application
