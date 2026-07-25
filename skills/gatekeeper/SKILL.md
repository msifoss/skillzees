---
name: gatekeeper
description: Phase gate enforcer — validates AI-DLC exit criteria before phase transitions, supports batch-mode Mission Briefs
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "check | advance | status | brief"
---

# /gatekeeper — Phase Gate Enforcer

The contract that all AI-DLC agents must respect. No phase transition without passing the gate.

> "Pre-commit is developer convenience; CI is the contract." — Fran, Meta

## Trigger

User invokes `/gatekeeper [action]` or another agent requests a gate check.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `check` | Validate current phase exit criteria | `/gatekeeper check` |
| `check [N]` | Validate specific phase exit criteria | `/gatekeeper check 2` |
| `advance` | Check gate + advance to next phase if passed | `/gatekeeper advance` |
| `status` | Show gate status for all phases | `/gatekeeper status` |
| `brief` | Generate a Mission Brief for autonomous execution | `/gatekeeper brief` |

---

## Phase 0: Read State

Before any action, read the project state:

```bash
# Read state file
cat .ai-dlc.state.yaml 2>/dev/null
```

If no state file exists:
1. Check if CLAUDE.md exists (might be a pre-state-file project)
2. If yes: "This project doesn't have a state file yet. Run `/lfg bootstrapper` or create `.ai-dlc.state.yaml` manually."
3. If no: "No AI-DLC project detected. Run `/init-project` to get started."

Extract `phase.current` — this is the phase whose exit criteria we're checking.

---

## Action: `check`

### Step 1: Load Criteria

Read the phase criteria from `src/gates/phase-criteria.yaml` (if in ai-lfg repo) or use the embedded criteria below.

For the current phase, iterate through each criterion.

### Step 2: Run Automatable Checks

For each criterion where `type: automatable`:

1. Run the check command
2. Evaluate the pass condition
3. Record PASS or FAIL with evidence

```bash
# Example: GATE-P0-01 — Context file exists
test -f CLAUDE.md && grep -q 'What This Project Is' CLAUDE.md
```

**Important:** If a check command is a placeholder (`# comment`), treat it as judgment-based for now and ask the user.

### Step 2b: Security Gate Verification (per security audit [M5])

Before evaluating ANY criterion with `security_enforced: true`:

1. Read `SECURITY.md` if it exists — parse finding counts by severity and disposition
2. Read `.ai-dlc.state.yaml` pillars.security section
3. Check for overdue deferred findings (`follow_up_by < today`)
4. Use ACTUAL counts from SECURITY.md, not judgment answers
5. If SECURITY.md and state file disagree, trust SECURITY.md (it has individual findings)

**This step is mandatory.** Security gates cannot be evaluated by judgment alone.
Evidence from Sentinel's tracked findings is required.

### Step 3: Ask Judgment Questions

For each criterion where `type: judgment`:

Present the question to the user and record their answer:

```
GATE-P1-02: Requirements are testable
  Question: Does every requirement have measurable acceptance criteria?
  
  Your assessment (pass/fail/skip): ___
```

**Solo-AI governance shortcut:** If the project uses `solo-ai` governance, present all judgment questions at once as a checklist rather than one-by-one.

### Step 4: Produce Gate Report

```markdown
## Gate Check: Phase [N] — [Name]

**Date:** YYYY-MM-DD HH:MM
**Project:** [project name from state]
**Governance:** [model from state]

### Automated Checks

| ID | Criterion | Result | Evidence |
|----|-----------|--------|----------|
| GATE-P0-01 | Context file exists | PASS | CLAUDE.md found, contains project identity |
| GATE-P0-04 | Linting passes | FAIL | ruff returned 3 errors |

### Judgment Checks

| ID | Criterion | Result | Assessor |
|----|-----------|--------|----------|
| GATE-P1-02 | Requirements testable | PASS | Developer |

### Human Decision Gates

| ID | Gate | Status | Decision Maker |
|----|------|--------|----------------|
| HGATE-P0-01 | Governance Model Selection | PASSED | Developer chose solo-ai |

### Summary

| Category | Pass | Fail | Skip | Total |
|----------|------|------|------|-------|
| Automated | X | Y | 0 | A |
| Judgment | X | Y | Z | B |
| Human Gates | X | Y | 0 | C |
| **Total** | **X** | **Y** | **Z** | **N** |

### Verdict

**[PASS / FAIL / CONDITIONAL PASS]**

- PASS: All required criteria met (100% of required items pass)
- CONDITIONAL PASS: All required criteria met, some optional items failed
- FAIL: One or more required criteria failed

### Failed Criteria (if any)

| ID | Criterion | Remediation |
|----|-----------|------------|
| GATE-P0-04 | Linting passes | Run `ruff check --fix .` and commit |
```

### Step 5: Update State File

After the gate check, update `.ai-dlc.state.yaml`:

```yaml
gates:
  phase_N:
    status: passed  # or failed
    passed_at: YYYY-MM-DD  # if passed
    checklist:
      - item: "GATE-P0-01: Context file exists"
        passed: true
      - item: "GATE-P0-04: Linting passes"
        passed: false
        note: "3 ruff errors remaining"
```

---

## Action: `advance`

1. Run `check` for current phase
2. If PASS or CONDITIONAL PASS:
   - Update `phase.current` to next phase number
   - Add history entry for completed phase
   - Report: "Phase [N] gate PASSED. Advanced to Phase [N+1]: [Name]."
3. If FAIL:
   - Report: "Phase [N] gate FAILED. Cannot advance. Fix [count] failed criteria."
   - List the failed criteria with remediation suggestions

```yaml
# State update on advance
phase:
  current: N+1
  history:
    - phase: N
      entered: [original date]
      exited: YYYY-MM-DD
      status: completed
    - phase: N+1
      entered: YYYY-MM-DD
      status: in_progress
```

**Phase 6 special case:** Phase 6 (Evolution) is a continuous loop. `advance` from Phase 6 creates a new learning cycle entry, not a new phase.

---

## Action: `status`

Read the state file and produce a dashboard:

```markdown
## Gate Status Dashboard

**Project:** [name]
**Current Phase:** [N] — [Name]

| Phase | Name | Status | Criteria | Passed | Failed |
|-------|------|--------|----------|--------|--------|
| 0 | Foundation | PASSED | 7 | 7 | 0 |
| 1 | Inception | PASSED | 8 | 8 | 0 |
| 2 | Elaboration | IN PROGRESS | 7 | 4 | 1 |
| 3 | Construction | NOT STARTED | 9 | — | — |
| 4 | Hardening | NOT STARTED | 10 | — | — |
| 5 | Operations | NOT STARTED | 9 | — | — |
| 6 | Evolution | NOT STARTED | 7 | — | — |

**Next action:** Fix 1 failed criterion in Phase 2, then `/gatekeeper advance`.
```

---

## Action: `brief`

Generate a Mission Brief that pre-answers all human decision gates for autonomous execution. This front-loads judgment into a single document so `/dlc-loop` can run without interruption.

### Step 1: Identify Upcoming Gates

Starting from the current phase, list all human decision gates through Phase 6.

### Step 2: Generate Mission Brief Template

```markdown
# Mission Brief — [Project Name]

**Date:** YYYY-MM-DD
**Author:** [developer]
**Scope:** Phase [current] through Phase [target]
**Governance:** [model]

## Pre-Authorized Decisions

For each human gate, the developer pre-authorizes a decision:

### Phase [N]: [Name]

#### HGATE-PN-01: [Gate Name]
- **Question:** [question]
- **Pre-authorized answer:** [YES/NO/CONDITIONAL]
- **Conditions:** [any conditions on the pre-authorization]
- **Override trigger:** [what would cause this to need re-authorization]

[... repeat for all gates ...]

## Constraints

- Maximum budget: $[amount]/month
- Performance targets: p99 < [value]ms
- Security: No critical/high findings at deployment
- Timeline: Complete by [date]

## Abort Conditions

Stop autonomous execution and alert the developer if:
- Any abort condition is met
- A decision falls outside pre-authorized scope
- Cost exceeds [X]% of budget
- Security scan finds a critical vulnerability
```

### Step 3: Save Brief

Write to `docs/mission-briefs/YYYYMMDD-HHMM-[scope]-mission-brief.md`

---

## Embedded Phase Criteria (Fallback)

When `src/gates/phase-criteria.yaml` is not available (Gatekeeper used outside ai-lfg repo), use these embedded criteria:

### Phase 0: Foundation
1. CLAUDE.md exists and is project-specific
2. Repository structure matches documented layout
3. Governance model recorded
4. Linting passes
5. Pre-commit hooks configured (optional)
6. CI skeleton exists (optional)
7. All deliverables committed

### Phase 1: Inception
1. All requirements have REQ-NNN IDs
2. Requirements are testable
3. At least one ADR exists
4. ADRs reference requirements
5. Security review complete
6. No critical security findings unresolved
7. CLAUDE.md reflects Phase 1 decisions
8. All human gates passed

### Phase 2: Elaboration
1. All requirements have user stories
2. Stories have Given-When-Then criteria
3. Tech spec covers all architecture components
4. Traceability matrix links REQ -> Story -> Spec
5. No gaps in traceability
6. Five Questions completed per feature
7. CLAUDE.md updated

### Phase 3: Construction
1. All user stories implemented
2. Every story has passing tests
3. Coverage >= 80%
4. CI pipeline green
5. Traceability matrix complete (through Code + Test)
6. No open spec/decision blockers
7. Captain's logs for every bolt
8. CLAUDE.md current
9. No known critical bugs

### Phase 4: Hardening
1. Security review: zero critical, zero high
2. Ops readiness >= 85/94
3. Cost dashboard + alarms active
4. Kill switches deployed and tested
5. Critical path alarms test-fired
6. Dependency scan clean
7. Encryption verified
8. IAM least-privilege confirmed
9. Performance targets met
10. Rollback tested

### Phase 5: Operations
1. Deployment pipeline operational
2. All environments running
3. Zero-downtime deployment
4. Monitoring dashboard live
5. Alarms verified
6. Runbooks created
7. Rollback tested
8. Incident response plan documented
9. System stable 72+ hours

### Phase 6: Evolution (per learning cycle)
1. Production feedback reviewed
2. Patterns extracted
3. Context files updated
4. Quarterly security re-review (if due)
5. Drift assessment complete
6. Retrospective conducted
7. Previous action items resolved

---

## Integration Points

### With State Agent
- Reads `phase.current` to determine which gate to check
- Writes gate results to `gates.phase_N` in state file
- Reads `governance.model` to adjust ceremony level

### With Other Agents
- **Tracer** can provide traceability coverage data for Phase 2-3 checks
- **Sentinel** can provide security finding counts for Phase 1, 4 checks
- **QualityGate** can provide coverage metrics for Phase 3 checks
- **Costkeeper** can provide budget status for Phase 4 checks

### With /bolt-lfg
- Gatekeeper is NOT invoked during bolt-level work (that's QualityGate)
- Gatekeeper is invoked at phase transitions only
- `/bolt-lfg` may suggest `/gatekeeper check` when all sprint items are complete

### With /dlc-loop
- `/dlc-loop` reads the Mission Brief before starting autonomous execution
- At each phase transition, `/dlc-loop` invokes `/gatekeeper advance`
- If gate fails, `/dlc-loop` fixes the failures and retries

---

## Quality Standards

- Gate reports must be specific — "FAIL: 3 ruff errors" not "FAIL: linting"
- Evidence must be provided for every automated check
- Judgment questions must be answered by a human (or pre-authorized via Mission Brief)
- State file must be updated after every gate check (even failed ones)
- No phase transition without a gate check — this is the contract
