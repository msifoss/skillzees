---
name: qualitygate
description: Quality pillar agent — enforces coverage thresholds, pre-commit compliance, runs Ascent verification against acceptance criteria
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "check | ascent | coverage | compliance"
---

# /qualitygate — Quality Pillar Agent

Enforces the quality pillar at bolt level. Runs coverage checks, validates pre-commit compliance, and executes the Ascent — verifying that acceptance criteria are actually met by tests, not just assumed.

> "Works 60-70% without The Ascent; 95%+ with it." — AI-DLC Phase 3

## Trigger

User invokes `/qualitygate [action]` or Foreman triggers before bolt completion.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `check` | Full quality check (coverage + compliance + Ascent) | `/qualitygate check` |
| `ascent` | Run Ascent verification only | `/qualitygate ascent` |
| `coverage` | Check test coverage against thresholds | `/qualitygate coverage` |
| `compliance` | Check pre-commit and linting compliance | `/qualitygate compliance` |

---

## Action: `check`

Run all three checks in sequence: compliance → coverage → ascent.

---

## Action: `ascent`

The Ascent is the critical quality gate that most teams skip. It verifies acceptance criteria are actually tested.

### Step 1: Read Acceptance Criteria

```bash
cat docs/user-stories.md 2>/dev/null
```

Extract all Given-When-Then acceptance criteria.

### Step 2: Map Criteria to Tests

For each acceptance criterion:
1. Search test files for a test that exercises this criterion
2. Check test name matches the criterion semantically
3. Verify the test actually asserts the expected outcome

### Step 3: Run Tests and Verify

```bash
# Run full test suite
# Language-specific: pytest, npm test, go test, etc.
```

### Step 4: Produce Ascent Report

```markdown
## Ascent Verification Report

**Date:** YYYY-MM-DD
**Stories checked:** [count]
**Criteria checked:** [count]

| Story | Criterion | Test | Passes | Verified |
|-------|-----------|------|--------|----------|
| US-001 | Given valid creds, when login, then session created | test_login_success | YES | YES |
| US-001 | Given invalid creds, when login, then 401 returned | test_login_invalid | YES | YES |
| US-002 | Given expired token, when API call, then 401 | — | — | NO — no test found |

### Verdict
- Criteria with tests: [X]/[Y] ([Z]%)
- All tests pass: YES/NO
- **Ascent: PASS/FAIL**

### Gaps
| Story | Missing Criterion | Suggested Test |
|-------|------------------|---------------|
| US-002 | Expired token handling | test_expired_token_returns_401 |
```

---

## Action: `coverage`

### Thresholds (from AI-DLC Quality Pillar)

| Metric | Threshold | Level |
|--------|-----------|-------|
| Overall coverage | 80% | Required |
| New code coverage | 90% | Required |
| Critical path coverage | 100% | Required |

### Detection

```bash
# Python
pytest --cov=src --cov-report=term-missing 2>/dev/null

# Node
npx jest --coverage 2>/dev/null

# Go
go test -cover ./... 2>/dev/null
```

---

## Action: `compliance`

Check for bypasses of quality gates:

```bash
# No-verify commits
git log --oneline -20 | grep -i "no.verify\|skip.hook" || echo "Clean"

# Suppressed warnings
grep -rn "noqa\|noinspection\|@ts-ignore\|eslint-disable" src/ 2>/dev/null

# Missing type annotations (if TypeScript/mypy)
# Run type checker in strict mode
```

Report any `--no-verify`, `# noqa`, `// @ts-ignore`, `eslint-disable` without documented justification.

---

## Integration Points

- **Foreman:** Triggers QualityGate before bolt completion
- **Gatekeeper:** GATE-P3-02 (tests pass), GATE-P3-03 (coverage >= 80%)
- **Tracer:** Uses orphan test data from QualityGate
- **State:** Updates quality pillar metrics (test_count, coverage_pct, lint_passing)
