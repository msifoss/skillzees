# Development Lifecycle Compliance Monitor

Usage: `/motherhen`

**Arguments:** $ARGUMENTS

---

## Purpose

Assess where the project stands against its chosen standards and tell you exactly what needs attention. Knows the full AI-DLC framework, all standards docs, and the current project state.

> Think of Mother Hen as the team lead who reads every document, checks every box, and clucks when something is out of compliance.

---

## Instructions for Claude

### Phase 1 — Gather Current State

Read these files to understand where things stand:

**Project state:**
- `CLAUDE.md` — architecture, deployment state, conventions
- `CHANGELOG.md` — version history, unreleased changes
- `pyproject.toml` or `package.json` — current version number
- `docs/pm/CURRENT-SPRINT.md` — active bolt or holding pattern
- `docs/pm/BACKLOG.md` — what's done, executable, blocked
- `docs/pm/SPRINT-LOG.md` — last 2 bolt entries (for recency context)

**Standards & compliance docs:**
- `docs/REQUIREMENTS.md` — formal requirements (FR/NFR/SEC)
- `docs/TRACEABILITY-MATRIX.md` — requirement-to-code-to-test mapping
- `docs/standards/OPS-READINESS-CHECKLIST.md` — production checklist
- `SECURITY.md` — security controls and audit status

**Process docs:**
- `docs/standards/SOLO-AI-WORKFLOW-GUIDE.md` — bolt cadence, Five Questions, context hygiene
- `docs/standards/SECURITY-REVIEW-PROTOCOL.md` — review round cadence
- `docs/manuals/RELEASE_RUNBOOK.md` — release workflow and doc sync matrix

**Runtime checks:**
```bash
# Test health (adjust for your language/framework)
pytest tests/ --co -q 2>/dev/null | tail -1

# Recent commits
git log --oneline -10

# Uncommitted changes
git status --short

# Current version tag alignment
git describe --tags --abbrev=0 2>/dev/null
grep "^version" pyproject.toml 2>/dev/null || grep '"version"' package.json 2>/dev/null
```

---

### Phase 2 — Run the Seven Compliance Checks

Work through each check sequentially. For each, produce a **PASS**, **WARN**, or **FAIL** with a one-line explanation. If a check requires reading additional files, do so.

---

#### Check 1: Requirements Traceability

**Standard:** Every functional requirement (FR-###) in `docs/REQUIREMENTS.md` must trace to code, tests, and a deployment artifact in `docs/TRACEABILITY-MATRIX.md`.

**Evaluate:**
- Are all FR-### IDs present in the traceability matrix?
- Does the test count in the matrix match the actual test count?
- Are there any new features in `CLAUDE.md` or `CHANGELOG.md` that lack a corresponding requirement?

**Pass criteria:** All requirements traced, test count matches, no orphan features.

---

#### Check 2: Test Health

**Standard:** All tests pass. Test count in `CLAUDE.md`, `TRACEABILITY-MATRIX.md`, and project config should be consistent.

**Evaluate:**
- Get actual test count from your test runner
- Compare against documented counts in `CLAUDE.md` and `docs/TRACEABILITY-MATRIX.md`
- Check if any test files exist that aren't accounted for

**Pass criteria:** All tests collected, counts match docs, no missing entries.

---

#### Check 3: Operational Readiness

**Standard:** Score >= 90% on the checklist in `docs/standards/OPS-READINESS-CHECKLIST.md`.

**Evaluate:**
- Re-score the checklist against current project state
- Check if any previously-passing items have regressed
- Check if any previously-failing items are now passing

**Pass criteria:** Score >= 90%, no regressions from last scored value.

---

#### Check 4: Security Review Currency

**Standard:** A security review should be conducted at least once per quarter, before every production deployment, and after any major feature addition.

**Evaluate:**
- When was the last security review? (Check `docs/security/` and `docs/reviews/` for dated files)
- Have there been code changes (not just docs) since the last review?
- Has there been a prod deployment since the last review?
- Are there any open Critical or High findings?

**Pass criteria:** Review within last 30 days (or no code changes since last review), no open Critical/High findings.

---

#### Check 5: Release Hygiene

**Standard:** Version in project config matches the latest git tag. `CHANGELOG.md` has entries for all changes since the last tagged release.

**Evaluate:**
- Compare project config version vs `git describe --tags --abbrev=0`
- Check if `[Unreleased]` section in `CHANGELOG.md` has entries (meaning untagged work exists)
- Are there commits since the last tag? If so, is `[Unreleased]` populated?
- Is the working tree clean?
- Check doc sync: Do CLAUDE.md metrics, README test counts, and guides reflect current state?

**Pass criteria:** Version matches tag (or [Unreleased] properly documents delta), working tree clean, doc sync current.

---

#### Check 6: Process Adherence

**Standard:** The development workflow and PM framework are being followed.

**Evaluate:**
- Is `CLAUDE.md` current? (Check date references, test counts, deploy counts against actuals)
- Is the current bolt properly tracked in `CURRENT-SPRINT.md`?
- Was the last completed bolt archived in `SPRINT-LOG.md` with metrics and retro?
- Are blocker tickets tracked with days-open counts?
- Has the backlog been groomed recently? (Check `Last groomed` date in `BACKLOG.md`)

**Pass criteria:** CLAUDE.md current, sprint tracking up to date, last bolt archived, blockers tracked, backlog groomed within 7 days.

---

#### Check 7: AI-DLC Framework Alignment

**Standard:** The project should demonstrate compliance with AI-DLC phases and address known shortcomings.

**Evaluate against 10 common shortcomings:**

| # | Shortcoming | Addressed By | Check |
|---|------------|-------------|-------|
| 1 | No formal Inception docs | `docs/REQUIREMENTS.md`, `docs/USER-STORIES.md` | Do docs exist and are they current? |
| 2 | No traceability matrix | `docs/TRACEABILITY-MATRIX.md` | Does matrix cover all FRs? |
| 3 | No structured elaboration | Five Questions pattern in workflow guide | Is the pattern being used? |
| 4 | No CI/CD for deployment | `docs/standards/CICD-DEPLOYMENT-PROPOSAL.md` | Does proposal exist? |
| 5 | No multi-dev patterns | `docs/standards/MULTI-DEVELOPER-GUIDE.md` | Does guide exist? |
| 6 | Infrastructure undocumented | `docs/standards/INFRASTRUCTURE-PLAYBOOK.md` | Does playbook exist? |
| 7 | Cost management absent | `docs/standards/COST-MANAGEMENT-GUIDE.md` | Does guide exist? |
| 8 | Security underspecified | `docs/standards/SECURITY-REVIEW-PROTOCOL.md` | Does protocol exist? |
| 9 | Ops readiness one-liner | `docs/standards/OPS-READINESS-CHECKLIST.md` | Does checklist exist and is it scored? |
| 10 | Solo+AI not addressed | `docs/standards/SOLO-AI-WORKFLOW-GUIDE.md` | Does guide exist? |

**Pass criteria:** All 10 shortcomings have corresponding documents that exist and are not stale (modified within the last 60 days or no relevant changes since creation).

---

### Phase 3 — Present the Compliance Dashboard

Format results as a clear dashboard:

```
## Mother Hen Compliance Report
### Generated: <date>

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Requirements Traceability | PASS/WARN/FAIL | [one-line explanation] |
| 2 | Test Health | PASS/WARN/FAIL | [one-line explanation] |
| 3 | Operational Readiness | PASS/WARN/FAIL | [score]/[total] ([pct]%) |
| 4 | Security Review Currency | PASS/WARN/FAIL | [one-line explanation] |
| 5 | Release Hygiene | PASS/WARN/FAIL | [one-line explanation] |
| 6 | Process Adherence | PASS/WARN/FAIL | [one-line explanation] |
| 7 | AI-DLC Alignment | PASS/WARN/FAIL | [count]/10 shortcomings addressed |

**Overall: [X]/7 checks passing**
```

Use these status definitions:
- **PASS** — Fully compliant, no action needed
- **WARN** — Minor drift detected, should fix soon (within current or next bolt)
- **FAIL** — Out of compliance, needs immediate attention

---

### Phase 4 — Action Items

After the dashboard, list specific action items sorted by priority:

```
### Action Items

**Immediate (fix now):**
- [FAIL items — specific actions to resolve]

**Soon (next bolt):**
- [WARN items — specific actions to resolve]

**Healthy (no action):**
- [PASS items — brief confirmation]
```

For each action item, be specific:
- Name the file(s) that need updating
- State what the current value is vs what it should be
- Estimate size (S/M/L) per the PM framework

---

### Phase 5 — Offer to Fix

After presenting the report, ask the user:

1. **Fix all items now** — work through Immediate + Soon items
2. **Fix immediate only** — just the FAIL items
3. **Just the report** — no changes, informational only
4. **Open a bolt** — if there are enough items, create a new bolt to address them

If the user chooses to fix, work through items by priority (FAIL first, then WARN), updating the compliance dashboard as each is resolved.

---

## Scoring Guidelines

### When to WARN vs FAIL

| Situation | Status |
|-----------|--------|
| Test count in docs is off by 1-5 | WARN |
| Test count in docs is off by >5 | FAIL |
| Tests actually failing | FAIL |
| Unreleased changes exist but are documented | WARN |
| Unreleased changes exist and undocumented | FAIL |
| Last security review >30 days but no code changes since | PASS |
| Last security review >30 days with code changes since | WARN |
| Last security review >90 days | FAIL |
| CLAUDE.md date is stale but content is accurate | WARN |
| CLAUDE.md has inaccurate information | FAIL |
| Backlog not groomed in 7-14 days | WARN |
| Backlog not groomed in >14 days | FAIL |
| OPS checklist 90-95% | WARN |
| OPS checklist <90% | FAIL |
| Working tree has uncommitted changes | WARN |
| Project version doesn't match latest tag | WARN (if [Unreleased] is populated), FAIL (if not) |
