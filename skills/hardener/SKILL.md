---
name: hardener
description: Ops readiness agent — runs 47-item checklist automatically, scores and reports, groups hardening bolts
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "check | plan | score | category"
---

# /hardener — Ops Readiness Agent

Runs the 47-item ops readiness checklist from AI-DLC Phase 4. Scores each item, produces a scored report, and groups remediation work into hardening bolts.

> "Phase 4 is the dedicated phase between Construction and Operations that traditional SDLC skips." — AI-DLC

## Trigger

User invokes `/hardener [action]` or at Phase 4 entry.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `check` | Run full 47-item ops readiness checklist | `/hardener check` |
| `plan` | Generate hardening bolt plan from check results | `/hardener plan` |
| `score` | Show current readiness score | `/hardener score` |
| `category [name]` | Run checks for a specific category | `/hardener category logging` |

---

## Action: `check`

### The 47-Item Checklist

8 categories, each with multiple items scored 0/1/2:

#### Category 1: Logging (6 items)
1. Structured JSON logging in all services
2. Correlation IDs propagated across calls
3. Log levels used correctly (ERROR/WARN/INFO/DEBUG)
4. PII excluded from logs
5. Log retention policy defined
6. Central log aggregation configured

#### Category 2: Monitoring (7 items)
7. Health check endpoints for all services
8. Latency metrics collected (p50/p95/p99)
9. Error rate alarms configured
10. Throughput metrics collected
11. Resource utilization tracked
12. Dashboards created and accessible
13. Synthetic canary tests scheduled

#### Category 3: Alerting (6 items)
14. Alarms on all critical paths
15. Escalation paths defined
16. Alert fatigue mitigated (no noise)
17. Alarm actions configured (auto-scale, circuit break)
18. Notification channels tested
19. Runbooks linked to alarms

#### Category 4: Error Handling (6 items)
20. All external calls have timeouts
21. Retry logic with exponential backoff
22. Circuit breakers on critical dependencies
23. DLQs configured on async processors
24. Graceful degradation paths
25. Error responses don't leak internals

#### Category 5: Data Integrity (6 items)
26. Database backups automated
27. Backup restoration tested
28. Data validation at boundaries
29. Idempotency for critical operations
30. Transaction isolation appropriate
31. Data migration rollback tested

#### Category 6: Security (6 items)
32. Secrets in vault (not env vars or code)
33. IAM least-privilege verified
34. Encryption at rest enabled
35. Encryption in transit (TLS) verified
36. Dependency vulnerability scan clean
37. SRI hashes on frontend assets

#### Category 7: Deployment (5 items)
38. Zero-downtime deployment tested
39. Rollback procedure documented
40. Rollback tested successfully
41. Canary deployment supported
42. Feature flags for risky changes

#### Category 8: Documentation (5 items)
43. Runbooks for all failure scenarios
44. Architecture diagram current
45. API documentation complete
46. On-call procedures documented
47. Incident response plan ready

### Scoring

Each item scored 0-2:
- **0:** Not implemented
- **1:** Partially implemented
- **2:** Fully implemented

**Maximum score: 94** (47 items x 2 points)
**Production threshold: 85/94** (90%)

### Check Execution

For automatable items, run verification commands:

```bash
# Item 1: Structured logging
grep -rn "structlog\|json_logger\|winston\|pino\|slog" src/ 2>/dev/null

# Item 20: Timeouts on external calls
grep -rn "timeout\|Timeout\|TIMEOUT" src/ 2>/dev/null

# Item 32: Secrets not in code
grep -rn "password\s*=\|api_key\s*=\|secret\s*=" src/ 2>/dev/null | grep -v test
```

For judgment items, present the question and record the assessor's answer.

### Report

```markdown
## Ops Readiness Report

**Date:** YYYY-MM-DD
**Project:** [name]
**Score:** [X]/94 ([Y]%)
**Verdict:** READY / NOT READY (threshold: 85)

### Category Scores

| Category | Score | Max | % |
|----------|-------|-----|---|
| Logging | 10 | 12 | 83% |
| Monitoring | 12 | 14 | 86% |
| Alerting | 8 | 12 | 67% |
| Error Handling | 11 | 12 | 92% |
| Data Integrity | 10 | 12 | 83% |
| Security | 12 | 12 | 100% |
| Deployment | 8 | 10 | 80% |
| Documentation | 6 | 10 | 60% |

### Items Scoring Below 2

| # | Item | Score | Category | Remediation |
|---|------|-------|----------|------------|
| 14 | Alarms on critical paths | 1 | Alerting | Add CloudWatch alarms for API latency |
```

---

## Action: `plan`

Generate hardening bolts from check results:

```markdown
## Hardening Bolt Plan

Based on ops readiness score of [X]/94:

### H1: Monitoring & Alerting (8 items, ~4 hours)
- Items 7-13, 14-19

### H2: Security Fixes (4 items, ~2 hours)
- Items 32-37

### H3: Cost Controls (3 items, ~2 hours)
- Kill switch, budget dashboard, alerts

### H4: Ops Verification (6 items, ~3 hours)
- Items 38-47

**Total: ~11 hours across 4 hardening bolts**
```

---

## Integration Points

- **Sentinel:** Security findings feed into Category 6 checks
- **Costkeeper:** Cost controls feed into Phase 4 hardening
- **Gatekeeper:** GATE-P4-02 (ops readiness >= 85/94)
- **Deployer:** Hardener must pass before deployment
- **State:** Updates quality pillar with ops readiness score
