# Budget Tracker

Usage: `/budget [action]`

**Arguments:** $ARGUMENTS

---

## Purpose

Creates and maintains a detailed infrastructure cost analysis following the callhero budget standard. This standard provides per-resource cost breakdowns, volume scaling projections, cost optimization tracking, and budget recommendations — the level of detail that lets you catch cost surprises before they hit your bill.

---

## Instructions for Claude

### 0. Parse Arguments

Extract `action` from: `$ARGUMENTS`

**Actions:**
- `init` — Create initial `docs/budget/BUDGET.md` from infrastructure analysis
- `update` — Update budget with current resource inventory
- `review` — Review current costs and flag risks
- `optimize` — Identify cost optimization opportunities

If no action, default to `review`.

### 1. Action: `init`

Analyze the project's infrastructure to build a cost estimate:

1. **Read infrastructure definitions:**
   - SAM/CloudFormation templates
   - Terraform files
   - CDK constructs
   - Docker Compose files
   - Any cloud resource definitions

2. **Catalog every cost-generating resource:**
   - Compute (Lambda, EC2, ECS, etc.)
   - Storage (S3, EBS, RDS)
   - Networking (VPC endpoints, NAT Gateway, data transfer)
   - Messaging (SQS, SNS, EventBridge)
   - Monitoring (CloudWatch alarms, dashboards, logs)
   - Security (KMS, WAF, Secrets Manager)
   - External APIs (with pricing tiers)

3. **Generate `docs/budget/BUDGET.md`** following this template:

```markdown
# [Project Name] — Budget Overview

**Last updated:** [date]
**Baseline assumption:** [expected volume/traffic]

---

## [Phase/Environment Name]

| Service | What It Does | Monthly Cost | Notes |
|---|---|---|---|
| [resource] | [purpose] | $[amount] | [free tier, scaling notes] |
| **Total** | | **$[amount]** | |

### Where the money goes

```
[Resource]              $[amount]   [percentage]%  [bar chart]
[Resource]              $[amount]   [percentage]%  [bar chart]
```

---

## Combined Budget Summary

| Scenario | Monthly Cost | Annual Cost |
|---|---|---|
| [minimal config] | $[amount] | $[amount] |
| [full config] | $[amount] | $[amount] |

---

## Volume Scaling

| Volume | Monthly Cost | Notes |
|---|---|---|
| [low] | $[amount] | [free tier notes] |
| [baseline] | $[amount] | **Current estimate** |
| [high] | $[amount] | [scaling triggers] |

---

## Cost Optimization Options

### Already Implemented
- [list optimizations already in place]

### Available If Needed
| Optimization | Savings | Trade-off |
|---|---|---|

---

## Budget Recommendation

```
Monthly budget:    $[amount]
Expected spend:    $[amount]
Buffer:            $[amount] ([percentage]% headroom)
```
```

### 2. Action: `update`

1. Re-read infrastructure definitions
2. Compare with current `docs/budget/BUDGET.md`
3. Identify new, changed, or removed resources
4. Update cost estimates
5. Update the "Last updated" date
6. Flag any costs that increased significantly

### 3. Action: `review`

1. Read `docs/budget/BUDGET.md`
2. Check for:
   - Resources without cost monitoring
   - Missing budget alerts/alarms
   - Resources that could be stopped in non-prod
   - Data transfer costs that scale unexpectedly
   - Resources running 24/7 that could be scheduled
3. Present findings and recommendations

### 4. Action: `optimize`

1. Read infrastructure and budget docs
2. Check each resource against these optimization patterns:
   - **Free tier utilization** — are we within free tier for any services?
   - **Right-sizing** — are instances oversized for actual load?
   - **Reserved/savings plans** — any committed-use discounts available?
   - **Gateway vs Interface endpoints** — Gateway endpoints are free
   - **NAT Gateway alternatives** — VPC endpoints are often cheaper
   - **Serverless vs always-on** — could fixed resources become on-demand?
   - **Storage tiering** — can old data move to cheaper storage classes?
   - **Log retention** — are logs kept longer than needed?
   - **Alarm consolidation** — can alarms be reduced without losing coverage?
3. Present optimization opportunities with savings estimates
