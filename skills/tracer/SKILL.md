---
name: tracer
description: Traceability agent — auto-maintains REQ->Story->Code->Test->Deploy matrix from git commits and test output
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "scan | report | matrix | orphans"
---

# /tracer — Traceability Agent

Automates the traceability matrix that nobody maintains manually. Parses git commits, test files, requirements docs, and user stories to build and maintain the full REQ->Story->Code->Test->Deploy chain.

> "The traceability matrix is the most-skipped pillar artifact. Automate it or it won't happen." — Rob, Roblox

## Trigger

User invokes `/tracer [action]` or Gatekeeper requests traceability data during a gate check.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `scan` | Scan codebase and rebuild traceability matrix | `/tracer scan` |
| `report` | Show traceability coverage summary | `/tracer report` |
| `matrix` | Display the full traceability matrix | `/tracer matrix` |
| `orphans` | Find orphan code (no requirement) and orphan tests (no story) | `/tracer orphans` |

---

## Phase 0: Read Project State

```bash
cat .ai-dlc.state.yaml 2>/dev/null
```

If no state file exists, warn and proceed with defaults. Tracer works without a state file but can't update it.

---

## Action: `scan`

Rebuild the traceability matrix by scanning all project artifacts.

### Step 1: Discover Requirements

Search for requirement IDs in the project:

```bash
# Find requirement documents
find docs/ -name "*.md" -exec grep -l "REQ-[0-9]" {} \; 2>/dev/null

# Extract all REQ-NNN IDs
grep -roh "REQ-[0-9]\{1,4\}" docs/ 2>/dev/null | sort -u
```

For each REQ-NNN found, record:
- ID
- Title (text following the ID on the same line)
- Source file
- Category (functional=0XX, data=1XX, integration=2XX, non-functional=3XX, security=4XX, operational=5XX, constraint=9XX)

### Step 2: Discover User Stories

```bash
# Find user story documents
find docs/ -name "*.md" -exec grep -l "US-[0-9]" {} \; 2>/dev/null

# Extract all US-NNN IDs
grep -roh "US-[0-9]\{1,4\}" docs/ 2>/dev/null | sort -u

# Find which REQ each story traces to
grep -n "Traces to\|REQ-[0-9]" docs/user-stories.md 2>/dev/null
```

For each US-NNN, record:
- ID
- Title
- Source file
- Linked REQ-NNN (from "Traces to" field)

### Step 3: Discover Code Mappings

Trace code files to stories via commit messages and inline references:

```bash
# Find commits referencing story IDs
git log --all --oneline --grep="US-[0-9]" 2>/dev/null

# Find commits referencing requirement IDs
git log --all --oneline --grep="REQ-[0-9]" 2>/dev/null

# Find inline references in source code
grep -rn "US-[0-9]\{1,4\}\|REQ-[0-9]\{1,4\}" src/ 2>/dev/null
```

For each referenced story/requirement, record:
- Code file path
- Commit hash
- Story/requirement ID

### Step 4: Discover Test Mappings

```bash
# Find test files
find tests/ -name "test_*" -o -name "*_test.*" -o -name "*.test.*" -o -name "*.spec.*" 2>/dev/null

# Find test files referencing stories or requirements
grep -rn "US-[0-9]\{1,4\}\|REQ-[0-9]\{1,4\}\|TEST-[0-9]" tests/ 2>/dev/null

# Count tests per file
for f in $(find tests/ -name "test_*" -o -name "*_test.*" -o -name "*.test.*" -o -name "*.spec.*" 2>/dev/null); do
  count=$(grep -c "def test_\|it(\|test(\|func Test" "$f" 2>/dev/null || echo 0)
  echo "$f: $count tests"
done
```

For each test, record:
- Test file path
- Test count
- Linked story/requirement IDs (from file content or naming convention)

### Step 5: Discover Deploy Mappings

```bash
# Find deploy tags
git tag -l "v*" 2>/dev/null

# Find deploy-related commits
git log --all --oneline --grep="deploy\|release\|shipped" 2>/dev/null | head -10
```

### Step 6: Build Matrix

Combine all discoveries into a traceability matrix:

```markdown
# Traceability Matrix

**Generated:** YYYY-MM-DD HH:MM
**Project:** [name]
**Scanner:** /tracer scan

| REQ | Story | Spec | Code Path | Test ID | Deploy |
|-----|-------|------|-----------|---------|--------|
| REQ-001 | US-001 | spec-auth.md | src/auth/ | tests/test_auth.py | v1.0.0 |
| REQ-002 | US-003 | spec-api.md | src/api/ | tests/test_api.py | v1.0.0 |
| REQ-003 | — | — | — | — | — |
```

### Step 7: Save Matrix

Write to `docs/traceability-matrix.md` (create or overwrite).

### Step 8: Update State File

```yaml
traceability:
  requirements: [count]
  stories: [count]
  specs: [count]
  tests: [count]
  coverage_pct: [percentage of requirements with full chain]
```

---

## Action: `report`

Generate a coverage summary without rebuilding the full matrix.

```markdown
## Traceability Report

**Project:** [name]
**Date:** YYYY-MM-DD HH:MM
**Phase:** [current phase]

### Coverage Summary

| Metric | Count | Coverage |
|--------|-------|----------|
| Requirements (REQ-NNN) | 12 | — |
| User Stories (US-NNN) | 18 | 100% (all REQs have stories) |
| Specifications | 8 | 67% (8/12 REQs have specs) |
| Code Paths | 15 | 83% (10/12 REQs have code) |
| Tests | 45 | 83% (10/12 REQs have tests) |
| Deployments | 1 | 50% (6/12 REQs deployed) |

### Full Chain Coverage

**[X]% of requirements have complete REQ->Story->Code->Test chain**

### Gap Analysis

| REQ | Missing |
|-----|---------|
| REQ-003 | No story, no code, no tests |
| REQ-007 | Has story but no code or tests |

### Recommendations

1. [Specific action to improve coverage]
2. [...]
```

---

## Action: `matrix`

Display the full traceability matrix from `docs/traceability-matrix.md`.

If the file doesn't exist or is older than the latest commit, suggest running `/tracer scan` first.

---

## Action: `orphans`

Find artifacts that aren't connected to any requirement chain.

### Orphan Code

Source files in `src/` not referenced by any commit that mentions a REQ or US:

```bash
# All source files
find src/ -type f -not -name "*.pyc" -not -name "__pycache__" 2>/dev/null

# Source files referenced in traceability matrix
# (compare against matrix Code Path column)
```

### Orphan Tests

Test files not linked to any story or requirement:

```bash
# Tests with no REQ/US reference
for f in $(find tests/ -name "test_*" -o -name "*_test.*" 2>/dev/null); do
  if ! grep -q "US-\|REQ-\|TEST-" "$f" 2>/dev/null; then
    echo "ORPHAN: $f"
  fi
done
```

### Orphan Requirements

Requirements with no downstream artifacts:

```bash
# REQs not referenced in any commit, code, or test
# (compare REQ list against git log and code search)
```

### Report Format

```markdown
## Orphan Report

**Date:** YYYY-MM-DD HH:MM

### Orphan Code (no requirement chain)
| File | Last Modified | Suggested Action |
|------|---------------|-----------------|
| src/utils/helpers.py | 2026-03-15 | Link to REQ or mark as infrastructure |

### Orphan Tests (no story/requirement link)
| File | Test Count | Suggested Action |
|------|-----------|-----------------|
| tests/test_helpers.py | 5 | Add US-NNN reference in docstring |

### Orphan Requirements (no implementation)
| REQ | Title | Suggested Action |
|-----|-------|-----------------|
| REQ-003 | Export API | Implement in next bolt or defer |

### Summary
- Orphan code files: [count]
- Orphan test files: [count]
- Orphan requirements: [count]
- **Health score: [X]%** (100% = zero orphans)
```

---

## Naming Convention Detection

Tracer auto-detects how the project links artifacts:

| Pattern | Detection | Example |
|---------|-----------|---------|
| Commit message references | `git log --grep="US-"` | `feat(US-003): add login endpoint` |
| Inline code comments | `grep -rn "REQ-" src/` | `# Implements REQ-001` |
| Test docstrings | `grep -rn "US-\|REQ-" tests/` | `"""Tests US-003 acceptance criteria"""` |
| File naming | `test_us003_*.py` | Convention-based mapping |
| Traceability matrix | `docs/traceability-matrix.md` | Existing manual matrix |

If no convention is detected, Tracer suggests establishing one:

```
No traceability convention detected. Recommended approach:
1. Reference story IDs in commit messages: feat(US-001): description
2. Add REQ/US references in test docstrings
3. Run /tracer scan after each bolt to update the matrix
```

---

## Integration Points

### With Gatekeeper
- Gatekeeper checks GATE-P2-04 (traceability links REQ->Story->Spec)
- Gatekeeper checks GATE-P3-05 (matrix fully populated)
- Tracer provides coverage data for these checks

### With State Agent
- Writes traceability metrics to `.ai-dlc.state.yaml`
- Reads current phase to adjust scan depth

### With QualityGate
- QualityGate uses orphan data to assess test coverage quality
- Orphan tests may indicate untested requirements

### With Foreman
- Foreman can request `/tracer report` before closing a bolt
- Ensures new code is linked to stories

### With /bolt-lfg
- Suggest `/tracer scan` after Step 3 (work) completes
- Include traceability coverage in bolt metrics

---

## Quality Standards

- Matrix must be regenerable from source (git + docs + tests)
- Orphan detection must be conservative (flag uncertain, don't auto-link)
- Coverage percentage must be accurate (count only full chains)
- State file must be updated after every scan
- Report must include actionable recommendations, not just metrics
