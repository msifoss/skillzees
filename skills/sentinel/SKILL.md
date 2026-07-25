---
name: sentinel
description: Security pillar agent — triages five-persona findings, tracks dispositions in SECURITY.md, flags regressions
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "triage | track | status | regression"
---

# /sentinel — Security Pillar Agent

Bridges the gap between five-persona review output and actionable security tracking. Triages findings by severity, maintains disposition records, tracks remediation progress, and flags regressions.

> "The five-persona review produces 200+ findings. Without triage automation, they become noise." — Friction Analysis

## Trigger

User invokes `/sentinel [action]` or after `/five-persona-review` completes.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `triage` | Triage findings from latest review into SECURITY.md | `/sentinel triage` |
| `track` | Update disposition of specific findings | `/sentinel track SEC-001 fixed` |
| `status` | Show security posture summary | `/sentinel status` |
| `regression` | Check for reintroduced vulnerabilities | `/sentinel regression` |

---

## Action: `triage`

### Step 1: Find Review Output

```bash
ls -t docs/reviews/*five-persona* docs/reviews/*security* 2>/dev/null | head -5
```

Read the most recent review file. Parse findings by severity.

### Step 2: Extract Findings

For each finding, extract:
- Severity (Critical, High, Medium, Low, Informational)
- Location (file, line number)
- Description
- Persona that found it (Attacker, Auditor, Ops, Cost, User)
- Recommended fix

### Step 3: Assign IDs and Write SECURITY.md

```markdown
# Security Findings Tracker

**Last review:** YYYY-MM-DD
**Source:** docs/reviews/[filename]
**Total findings:** [count]

## Summary

| Severity | Count | Fixed | Accepted | Deferred | Open |
|----------|-------|-------|----------|----------|------|
| Critical | 0 | 0 | 0 | 0 | 0 |
| High | 3 | 1 | 0 | 0 | 2 |
| Medium | 12 | 5 | 2 | 1 | 4 |
| Low | 8 | 0 | 3 | 5 | 0 |

## Findings

### SEC-001: [Title] — CRITICAL
- **Severity:** Critical
- **Location:** src/auth/login.py:42
- **Persona:** Attacker
- **Description:** [what's wrong]
- **Recommendation:** [how to fix]
- **Disposition:** OPEN | FIXED | ACCEPTED | DEFERRED
- **Resolution:** [what was done, with commit hash if fixed]
- **Date resolved:** YYYY-MM-DD
```

### Step 4: Update State

```yaml
pillars:
  security:
    last_review: YYYY-MM-DD
    open_findings:
      critical: [count]
      high: [count]
      medium: [count]
      low: [count]
```

---

## Action: `track`

Update a specific finding's disposition:

```
/sentinel track SEC-001 fixed
/sentinel track SEC-005 accepted "Risk accepted per ADR-003"
/sentinel track SEC-012 deferred 2026-05-01 "Scheduled for Phase 4 hardening"
```

Valid dispositions: `fixed`, `accepted`, `deferred`, `open`

### Disposition Rules (per security audit [H2], [M4])

| Severity | Can DEFER? | Can ACCEPT? | Requirements |
|----------|-----------|-------------|-------------|
| CRITICAL | **NO** | YES | Mandatory justification + human gate |
| HIGH | YES (max 30 days) | YES | Justification required |
| MEDIUM | YES (max 90 days) | YES | Reason required |
| LOW | YES (no limit) | YES | Reason required |

**Deferral rules:**
- `deferred` disposition REQUIRES a follow-up date (YYYY-MM-DD)
- Syntax: `/sentinel track SEC-NNN deferred YYYY-MM-DD "reason"`
- If no date provided, Sentinel refuses the deferral
- CRITICAL findings CANNOT be deferred — only FIXED or ACCEPTED
- Deferred findings are tracked individually in the state file:

```yaml
# Added to .ai-dlc.state.yaml
pillars:
  security:
    deferred_findings:
      - id: SEC-012
        severity: high
        deferred_at: 2026-04-04
        follow_up_by: 2026-05-01
        reason: "Scheduled for Phase 4 hardening"
```

**Gatekeeper integration:** At every phase gate, Gatekeeper checks for overdue
deferred findings (`follow_up_by < today`). Overdue deferrals FAIL the gate.

Update SECURITY.md and state file (both counts and individual deferred findings).

---

## Action: `status`

Quick security posture summary reading from SECURITY.md and state file.

---

## Action: `regression`

Compare current code against previously fixed findings:

1. Read all `fixed` findings from SECURITY.md
2. For each, check if the vulnerable pattern still exists in the codebase
3. Flag any regressions

---

## Integration Points

- **Handoff from /five-persona-review:** Auto-discovers review output in docs/reviews/
- **Gatekeeper:** GATE-P1-06 (no critical unresolved), GATE-P4-01 (zero critical/high)
- **State:** Updates security pillar metrics
- **Hardener:** Sentinel's findings feed into hardening bolt planning
