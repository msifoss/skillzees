---
name: motherhen
description: Project health and compliance monitor — adaptive checks for documentation drift, test health, release hygiene, and AI-DLC foundation
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: [quick | full | focus:<check-name>]
---

# /motherhen — Project Health & Compliance Monitor

Quick, adaptive health check that scans your project for drift, staleness, and hygiene issues. Adapts its checks to what actually exists in the repo — a markdown-only project gets different checks than a full-stack Python app.

> Think of Mother Hen as the team lead who reads every document, checks every box, and clucks when something is out of compliance. She's fast, opinionated, and never misses a stale date.

## Trigger

User invokes `/motherhen` with optional arguments.

## Arguments

| Argument | Description |
|----------|-------------|
| *(none)* or `full` | Run all applicable checks (~10-20K tokens depending on project size) |
| `quick` | Run only universal checks (context, release, foundation) — skip project-type-specific checks (~5-8K tokens) |
| `focus:<check>` | Run a single check only (e.g., `focus:tests`, `focus:security`, `focus:sprint`) |

Parse `$ARGUMENTS` to determine mode. If empty or unrecognized, default to `full`.

---

## Phase 0 — Detect Project Type

Before running any checks, determine what kind of project this is by scanning for markers. This determines which checks are applicable.

**Run these detection steps:**

```bash
# Check for project metadata files
ls pyproject.toml setup.py setup.cfg 2>/dev/null          # Python
ls package.json 2>/dev/null                                # Node/JS/TS
ls go.mod 2>/dev/null                                      # Go
ls Cargo.toml 2>/dev/null                                  # Rust
find . -maxdepth 3 -name "*.sln" -o -name "*.csproj" 2>/dev/null | head -3  # .NET
ls Makefile 2>/dev/null                                    # Make-based
ls Gemfile 2>/dev/null                                     # Ruby

# Check for test infrastructure
ls -d tests/ test/ spec/ __tests__/ 2>/dev/null            # Test directories
ls pytest.ini .pytest.ini conftest.py 2>/dev/null          # pytest
ls jest.config.* vitest.config.* 2>/dev/null               # JS test runners

# Check for AI-DLC / PM structure
ls -d docs/pm/ 2>/dev/null                                 # PM framework
ls -d docs/standards/ 2>/dev/null                          # Standards docs
ls -d docs/security/ docs/reviews/ 2>/dev/null             # Security/review archive

# Check for ops/deploy infrastructure
ls Dockerfile docker-compose.yml 2>/dev/null               # Container
ls serverless.yml template.yaml samconfig.toml 2>/dev/null # Serverless/SAM
ls terraform/ *.tf 2>/dev/null                             # Terraform
ls .github/workflows/ 2>/dev/null                          # CI/CD
```

**Classify the project into one of these types** (can be multiple):

| Type | Markers | Unlocks |
|------|---------|---------|
| **python** | `pyproject.toml`, `setup.py`, `requirements.txt` | Test Health (pytest), version from pyproject |
| **node** | `package.json` | Test Health (jest/vitest/npm test), version from package.json |
| **go** | `go.mod` | Test Health (go test) |
| **rust** | `Cargo.toml` | Test Health (cargo test), version from Cargo.toml |
| **dotnet** | `*.csproj`, `*.sln` | Test Health (dotnet test) |
| **docs-only** | No code markers, mostly `.md` files | Skip Test Health, Skip Ops Readiness |
| **has-pm** | `docs/pm/` exists | Sprint/PM Health check |
| **has-standards** | `docs/standards/` exists | Full AI-DLC foundation check |
| **has-security** | `docs/security/` or `docs/reviews/` exists | Security Review Currency check |
| **has-ops** | Dockerfile, serverless.yml, template.yaml, terraform/ | Ops Readiness check |
| **has-ci** | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile` | CI/CD health sub-check |

Record detected types and report them in the dashboard header.

---

## Phase 0b — Read Per-Project Config

Check for `.ai-dlc.local.yaml` in the project root:

```bash
ls .ai-dlc.local.yaml 2>/dev/null
```

**If found:** Read it and apply overrides:
- `health.context_freshness` → override the 30-day default for Check 1
- `health.security_review` → override the 30-day default for Check 6
- `health.backlog_grooming` → override the 7-day default for Check 5
- `health.foundation_docs` → override the 60-day default for Check 7
- `testing.command` → override auto-detected test runner for Check 3

Report in dashboard header: "Config: `.ai-dlc.local.yaml` loaded" or "Config: using defaults (run `/setup` to create per-project config)"

---

## Phase 1 — Gather Current State

Read these files **if they exist** (don't fail if missing — their absence is itself a finding):

**Always read:**
- `CLAUDE.md` — project identity, architecture, conventions, current status
- `CHANGELOG.md` — version history, unreleased changes
- `README.md` — project overview, documented metrics

**Version source (based on detected type):**
- Python: `pyproject.toml` → `version = "X.Y.Z"`
- Node: `package.json` → `"version": "X.Y.Z"`
- Rust: `Cargo.toml` → `version = "X.Y.Z"`
- Go: latest git tag
- Docs-only: latest git tag (if any)

**PM state (if has-pm):**
- `docs/pm/CURRENT-SPRINT.md` — active bolt or holding pattern
- `docs/pm/BACKLOG.md` — what's queued, what's blocked
- `docs/pm/SPRINT-LOG.md` — last 2 entries for recency

**Security state (if has-security):**
- `SECURITY.md` — security controls
- Most recent file in `docs/security/` or `docs/reviews/`

**Git state (always):**
```bash
git log --oneline -10
git status --short
git describe --tags --abbrev=0 2>/dev/null
```

---

## Phase 2 — Run Applicable Checks

Run each check that is applicable based on Phase 0 detection. For each, produce **PASS**, **WARN**, or **FAIL** with a one-line explanation.

Checks marked **UNIVERSAL** always run. Others run only when their prerequisites are detected.

---

### Check 1: Context Freshness (UNIVERSAL)

**What it checks:** Is CLAUDE.md present, current, and accurate?

**Evaluate:**
- Does `CLAUDE.md` exist? (FAIL if not)
- Does it have a "Current Status" or date reference? Is the date within 30 days?
- Do any numbers mentioned (test counts, deploy counts, version numbers) match actuals?
- Does the architecture section match the actual project structure? (spot-check: do key files/directories mentioned actually exist?)

**Scoring:**
| Situation | Status |
|-----------|--------|
| No CLAUDE.md | FAIL |
| CLAUDE.md exists, date > 30 days stale, content inaccurate | FAIL |
| CLAUDE.md exists, date > 30 days stale but content accurate | WARN |
| CLAUDE.md exists, date within 30 days, content accurate | PASS |
| CLAUDE.md exists, no date reference but content accurate | WARN |

---

### Check 2: Documentation Drift (UNIVERSAL)

**What it checks:** Do numbers and metrics across docs match reality?

**Evaluate:**
- Collect all numeric claims across CLAUDE.md, README.md, CHANGELOG.md (test counts, version numbers, deploy counts, metric values)
- Cross-reference against each other — do they agree?
- Cross-reference against actuals (test runner output, git tags, package version)
- Check for stale "Current Status" sections that reference past dates as current

**Scoring:**
| Situation | Status |
|-----------|--------|
| Numbers consistent across all docs and match actuals | PASS |
| 1-2 minor discrepancies (off by 1-5) | WARN |
| >2 discrepancies or any off by >5 | FAIL |
| Docs reference features/files that no longer exist | FAIL |

---

### Check 3: Test Health (requires: test infrastructure detected)

**What it checks:** Do tests exist, pass, and match documented counts?

**Auto-detect test runner and run:**

> **Code execution warning:** Test collection commands import modules and can execute code. On untrusted repositories, prefer the file-based fallback (count test files instead of running test collection).

| Type | Collection Command | Fallback (file-based, safer) | Count Extraction |
|------|-------------------|------------------------------|-----------------|
| Python (pytest) | `find tests/ -name "test_*.py" -o -name "*_test.py" 2>/dev/null \| wc -l` | Same | Count test files |
| Node (jest) | `npx jest --listTests 2>/dev/null \| wc -l` | `find . -name "*.test.js" -o -name "*.test.ts" \| wc -l` | Count test files |
| Node (vitest) | `npx vitest --list 2>/dev/null \| wc -l` | `find . -name "*.test.ts" -o -name "*.spec.ts" \| wc -l` | Count test files |
| Go | `go test ./... -list '.*' 2>/dev/null \| grep -c '^Test'` | `find . -name "*_test.go" \| wc -l` | Count test functions/files |
| Rust | `cargo test -- --list 2>/dev/null \| grep -c ': test'` | `find . -name "*.rs" -path "*/tests/*" \| wc -l` | Count tests/files |
| .NET | `dotnet test --list-tests 2>/dev/null \| grep -c '^ '` | `find . -maxdepth 5 -name "*Tests.cs" -o -name "*Test.cs" \| wc -l` | Count tests/files |

**Evaluate:**
- Can tests be collected without errors?
- Does the collected count match counts documented in CLAUDE.md, README.md, or traceability matrix?
- Are there test files that exist but aren't collected (misconfigured test paths)?

**Scoring:**
| Situation | Status |
|-----------|--------|
| Tests collect cleanly, count matches docs | PASS |
| Tests collect but count differs from docs by 1-5 | WARN |
| Tests collect but count differs by >5 | FAIL |
| Tests fail to collect (errors) | FAIL |
| No test runner detected (docs-only project) | SKIP |

---

### Check 4: Release Hygiene (UNIVERSAL)

**What it checks:** Version alignment, changelog currency, working tree cleanliness.

**Evaluate:**
- Compare version in project config vs latest git tag (`git describe --tags --abbrev=0`)
- Does `CHANGELOG.md` exist? Does it have an `[Unreleased]` section?
- Are there commits since the last tag? If so, is `[Unreleased]` populated?
- Is the working tree clean? (`git status --short`)
- If no tags exist at all and no versioning is used, note it but don't FAIL

**Scoring:**
| Situation | Status |
|-----------|--------|
| Version matches tag, CHANGELOG current, tree clean | PASS |
| Unreleased changes exist but documented in CHANGELOG | WARN |
| Unreleased changes exist and NOT documented | FAIL |
| Version mismatch between config and tag (no [Unreleased]) | FAIL |
| Version mismatch but [Unreleased] populated | WARN |
| Working tree has uncommitted changes | WARN |
| No versioning system in use (docs-only repo, no tags) | PASS (with note) |

---

### Check 5: Sprint/PM Health (requires: has-pm)

**What it checks:** Is sprint management active and current?

**Evaluate:**
- Is there an active sprint in `CURRENT-SPRINT.md`? Or is a holding pattern documented?
- If active sprint: how long has it been open? (> 2 weeks = stale)
- Was the last completed bolt archived in `SPRINT-LOG.md` with metrics and retro?
- Are blocker tickets tracked with days-open counts?
- Has the backlog been groomed? Check for a "Last groomed" date in `BACKLOG.md`

**Scoring:**
| Situation | Status |
|-----------|--------|
| Sprint tracked, current, backlog groomed within 7 days | PASS |
| Sprint stale (> 2 weeks) or backlog not groomed in 7-14 days | WARN |
| No sprint tracking, backlog not groomed in > 14 days | FAIL |
| No docs/pm/ directory | SKIP |

---

### Check 6: Security Review Currency (requires: has-security OR code changes exist)

**What it checks:** Is there a recent security review? Are findings managed?

**Evaluate:**
- Find the most recent security review file in `docs/security/`, `docs/reviews/`
- When was the last review? (Extract date from filename or file content)
- Have there been code changes since the last review? (`git log --since="<review-date>" --oneline -- "*.py" "*.js" "*.ts" "*.go" "*.rs" "*.java"`)
- Are there open Critical or High findings in `SECURITY.md`?

**Scoring:**
| Situation | Status |
|-----------|--------|
| Review within 30 days (or no code changes since), no open Critical/High | PASS |
| Review > 30 days but no code changes since | PASS |
| Review > 30 days with code changes since | WARN |
| Review > 90 days | FAIL |
| Open Critical or High findings | FAIL |
| No security review ever conducted (but project has code) | FAIL |
| Docs-only project with no security review | WARN (suggest baseline review) |

---

### Check 7: AI-DLC Foundation (UNIVERSAL)

**What it checks:** How many of the AI-DLC foundational documents exist? This is a *presence and freshness* check — not a deep process audit (that's what `/dlc-audit` is for).

**Check for these 14 foundational documents** (search multiple paths, first match wins):

| # | Document | Search Paths (check all, first match wins) |
|---|----------|---------------------------------------------|
| 1 | Requirements | `docs/REQUIREMENTS.md`, `REQUIREMENTS.md` |
| 2 | Traceability Matrix | `docs/TRACEABILITY-MATRIX.md`, `TRACEABILITY-MATRIX.md` |
| 3 | User Stories | `docs/USER-STORIES.md`, `USER-STORIES.md` |
| 4 | AI Context File | `CLAUDE.md` |
| 5 | Security Controls | `SECURITY.md`, `docs/SECURITY.md` |
| 6 | PM Framework | `docs/pm/FRAMEWORK.md`, `docs/PM-FRAMEWORK.md`, `PM-FRAMEWORK.md` |
| 7 | Workflow Guide | `docs/standards/SOLO-AI-WORKFLOW-GUIDE.md`, `docs/SOLO-AI-WORKFLOW-GUIDE.md`, `SOLO-AI-WORKFLOW-GUIDE.md` |
| 8 | CI/CD Proposal | `docs/standards/CICD-DEPLOYMENT-PROPOSAL.md`, `docs/CICD-DEPLOYMENT-PROPOSAL.md`, `CICD-DEPLOYMENT-PROPOSAL.md` |
| 9 | Multi-Developer Guide | `docs/standards/MULTI-DEVELOPER-GUIDE.md`, `docs/MULTI-DEVELOPER-GUIDE.md`, `MULTI-DEVELOPER-GUIDE.md` |
| 10 | Infrastructure Playbook | `docs/standards/INFRASTRUCTURE-PLAYBOOK.md`, `docs/INFRASTRUCTURE-PLAYBOOK.md`, `INFRASTRUCTURE-PLAYBOOK.md` |
| 11 | Cost Management Guide | `docs/standards/COST-MANAGEMENT-GUIDE.md`, `docs/COST-MANAGEMENT-GUIDE.md`, `COST-MANAGEMENT-GUIDE.md` |
| 12 | Security Review Protocol | `docs/standards/SECURITY-REVIEW-PROTOCOL.md`, `docs/SECURITY-REVIEW-PROTOCOL.md`, `SECURITY-REVIEW-PROTOCOL.md` |
| 13 | Ops Readiness Checklist | `docs/standards/OPS-READINESS-CHECKLIST.md`, `docs/OPS-READINESS-CHECKLIST.md`, `OPS-READINESS-CHECKLIST.md` |
| 14 | AI-DLC Case Study | `docs/standards/CALLHERO-AI-DLC-CASE-STUDY.md`, `docs/AI-DLC-CASE-STUDY.md`, `AI-DLC-CASE-STUDY.md` |

**Evaluate:**
- Count how many exist
- For those that exist, check staleness (modified within 60 days, or no changes needed since creation)
- Flag any that are empty stubs or contain only TODO markers

**Scoring:**
| Situation | Status |
|-----------|--------|
| 12-14 documents present and current | PASS |
| 8-11 documents present | WARN |
| 4-7 documents present | WARN (suggest `/dlc-audit init` to bootstrap missing ones) |
| 0-3 documents present | FAIL (strongly suggest `/dlc-audit init`) |

**Important:** This check is intentionally shallow. If the score is WARN or FAIL, recommend the user run `/dlc-audit` for a deep 9-dimension process assessment with scoring. Mother Hen detects gaps; `/dlc-audit` diagnoses and fixes them.

**Approximate mapping to `/dlc-audit` D1 scores:** PASS (12-14 docs) ≈ D1 score 7-10. WARN (4-11 docs) ≈ D1 score 3-7. FAIL (0-3 docs) ≈ D1 score 0-3. These are rough equivalents — dlc-audit evaluates content quality, not just presence.

---

## Phase 3 — Present the Dashboard

Format results as a clear, scannable dashboard. Only include checks that were run (skip those marked SKIP).

```
## Mother Hen Health Report
### Generated: <date>
### Project: <project name from CLAUDE.md or directory name>
### Detected Type: <type1>, <type2>, ... (e.g., "python, has-pm, has-security")

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Context Freshness | PASS/WARN/FAIL | [one-line explanation] |
| 2 | Documentation Drift | PASS/WARN/FAIL | [one-line explanation] |
| 3 | Test Health | PASS/WARN/FAIL/SKIP | [one-line explanation] |
| 4 | Release Hygiene | PASS/WARN/FAIL | [one-line explanation] |
| 5 | Sprint/PM Health | PASS/WARN/FAIL/SKIP | [one-line explanation] |
| 6 | Security Review | PASS/WARN/FAIL/SKIP | [one-line explanation] |
| 7 | AI-DLC Foundation | PASS/WARN/FAIL | [N]/14 documents present |

**Result: [X] PASS / [Y] WARN / [Z] FAIL** (of [N] applicable checks)
```

Use these status definitions:
- **PASS** — Fully compliant, no action needed
- **WARN** — Minor drift detected, should fix soon
- **FAIL** — Out of compliance, needs immediate attention
- **SKIP** — Not applicable to this project type

---

## Phase 4 — Action Items

After the dashboard, list specific action items sorted by priority:

```
### Action Items

**Immediate (fix now):**
- [FAIL items — specific file, current value vs expected, what to change]

**Soon (next sprint/bolt):**
- [WARN items — specific file, what's drifting, suggested fix]

**Healthy (no action):**
- [PASS items — brief confirmation]

**Not Applicable:**
- [SKIP items — why they were skipped]
```

For each action item, be specific:
- Name the file(s) that need updating
- State what the current value is vs what it should be
- Estimate effort: **S** (< 15 min), **M** (15-60 min), **L** (1-4 hours)

**Effort calibration examples:**
- **S:** Update a version number in CLAUDE.md, fix a stale date, update a test count
- **M:** Write missing CHANGELOG entries, groom a backlog, run and triage a security review
- **L:** Bootstrap multiple missing foundation docs, restructure PM docs, resolve compound drift across files

### Cross-Skill Recommendations

Based on findings, suggest other skills when appropriate:

| Finding | Suggestion |
|---------|-----------|
| AI-DLC Foundation WARN/FAIL | "Run `/dlc-audit` for deep process assessment and to bootstrap missing docs" |
| AI-DLC Foundation FAIL (< 4 docs) | "Run `/dlc-audit init` to create skeleton templates for missing foundational docs" |
| Security Review FAIL (never reviewed) | "Run `/security-audit` or `/five-persona-review` to establish a security baseline" |
| Sprint/PM stale or missing | "Run `/pm status` to review current sprint state" |
| Multiple FAIL items | "Consider opening a bolt (`/pm plan`) to address these systematically" |

---

## Phase 5 — Offer to Fix

After presenting the report, ask the user:

1. **Fix all items now** — work through Immediate + Soon items
2. **Fix immediate only** — just the FAIL items
3. **Just the report** — no changes, informational only
4. **Open a bolt** — if there are enough items, create a new sprint/bolt to address them

If the user chooses to fix, work through items by priority (FAIL first, then WARN), and report what was changed after each fix.

---

## Scoring Guidelines Summary

### Universal Rules

| Situation | Status |
|-----------|--------|
| No CLAUDE.md | FAIL |
| CLAUDE.md has inaccurate information | FAIL |
| CLAUDE.md date stale but content accurate | WARN |
| Test count in docs off by 1-5 | WARN |
| Test count in docs off by > 5 | FAIL |
| Tests actually failing | FAIL |
| Unreleased changes exist but documented | WARN |
| Unreleased changes exist and undocumented | FAIL |
| Security review > 30 days, no code changes since | PASS |
| Security review > 30 days, code changes since | WARN |
| Security review > 90 days | FAIL |
| Backlog not groomed in 7-14 days | WARN |
| Backlog not groomed in > 14 days | FAIL |
| Working tree has uncommitted changes | WARN |
| Version mismatch + [Unreleased] populated | WARN |
| Version mismatch + no [Unreleased] | FAIL |
| AI-DLC foundation 0-3 docs | FAIL |
| AI-DLC foundation 4-7 docs | WARN |
| AI-DLC foundation 8-11 docs | WARN |
| AI-DLC foundation 12-14 docs | PASS |

---

## Important Notes

- **Repo-agnostic:** Works on any project type. Auto-detects stack, adapts checks, skips what doesn't apply.
- **Non-destructive by default:** The report is read-only. Only makes changes if the user opts in during Phase 5.
- **Fast, not deep:** Motherhen is a quick hygiene sweep (2-5 minutes). For deep process assessment, use `/dlc-audit` (9 dimensions, numeric scoring, maturity rating).
- **Honest reporting:** If something looks wrong, say so. Don't mask issues behind PASS when the data says WARN or FAIL.
- **AI-DLC aware:** Checks for foundational document presence and recommends `/dlc-audit` when gaps are significant. Does not duplicate dlc-audit's deep scoring.
- **Complementary to /dlc-audit:** Motherhen catches drift and staleness in day-to-day work. DLC-audit evaluates process adherence and maturity at milestone boundaries. Run motherhen frequently; run dlc-audit at phase transitions.
- **Staleness threshold rationale:**
  - **7 days** (backlog grooming): Backlogs go stale within a sprint; weekly grooming prevents orphan items.
  - **14 days** (sprint duration): Standard bolt/sprint cadence is 1-2 weeks; exceeding this suggests scope creep.
  - **30 days** (context file, security review): Monthly cadence catches drift before it compounds. Aligns with typical bolt cadence.
  - **60 days** (foundation docs): Structural documents change less often; 60 days balances freshness with realistic update frequency.
  - **90 days** (security review hard limit): Aligns with quarterly review cadence and common compliance requirements.
