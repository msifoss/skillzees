---
name: lfg
description: Team router — reads project state, determines current phase, suggests or dispatches the right teammate for what's needed next
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "[teammate] | assess | status | team | help"
---

# /lfg — Team Router

The single entry point for the ai-lfg team. Reads project state, determines what phase you're in, and suggests or dispatches the right teammate for what's needed next.

> "The best team is invisible. You shouldn't have to think about which agent to call — the system should know." — Fran, Meta

## Trigger

User invokes `/lfg` (for guidance) or `/lfg [teammate]` (for direct dispatch).

## Usage

```
/lfg                    # What should I do next? (quick assess + route)
/lfg assess             # Full project assessment with scored dashboard
/lfg assess --deep      # Deep assessment — delegates to /motherhen + /dlc-audit
/lfg assess --summary   # One-paragraph summary only
/lfg status             # Show project state dashboard
/lfg team               # Show all teammates and their status
/lfg help               # Show available commands
/lfg gatekeeper check   # Dispatch Gatekeeper with 'check' action
/lfg tracer scan        # Dispatch Tracer with 'scan' action
/lfg sentinel triage    # Dispatch Sentinel with 'triage' action
```

---

## Phase 0: Read State

```bash
cat .ai-dlc.state.yaml 2>/dev/null
```

**If no state file:**
Run a quick cold scan (from `assess` Step 2-3) to infer the project's phase and state. Then:
```
No .ai-dlc.state.yaml found. Quick scan suggests this is a [language]
project effectively at Phase [N] ([name]).

Options:
1. Create a state file → run /lfg bootstrapper upgrade
2. Full assessment → run /lfg assess
3. This is the ai-lfg repo → this IS the team, not a project to manage
```

**If state file exists:** Extract phase, sprint status, pillar health, gate status. Run a quick verification of key claims (test count, phase, review dates) against filesystem reality. If divergences found, note them in the routing output.

---

## Action: No Arguments (Route)

The core intelligence. Analyze the project state and recommend the next action.

### Routing Logic

Execute these checks in priority order. Recommend the FIRST match:

#### Priority 1: Urgent Issues

```
IF pillars.security.open_findings.critical > 0
  → "CRITICAL: You have [N] critical security findings. Run /lfg sentinel triage NOW"

IF pillars.security.open_findings.high > 5
  → "WARNING: You have [N] high security findings (threshold: 5). Run /lfg sentinel status"

IF pillars.security.deferred_findings has any with follow_up_by < today
  → "OVERDUE: Deferred security findings past follow-up date. Run /lfg sentinel status"

IF pillars.quality.coverage_pct < 80 AND phase.current >= 3
  → "Test coverage is [X]% (below 80% threshold). Run /lfg qualitygate coverage"

IF pillars.cost.budget_status == "red"
  → "Budget status is RED. Run /lfg costkeeper alert"
```

#### Priority 2: Gate Failures

```
IF gates.phase_N.status == "failed"
  → "Phase [N] gate failed. Run /lfg gatekeeper check to see unmet criteria"
```

#### Priority 3: Stale Artifacts

```
IF traceability.coverage_pct < 90
  → "Traceability is [X]%. Run /lfg tracer scan to update the matrix"

IF CLAUDE.md is older than 14 days AND phase.current >= 3
  → "CLAUDE.md may be stale. Run /lfg evolver stale to check"

IF last captain's log is older than current bolt
  → "No captain's log for current bolt. Run /captainslog new [bolt-name]"
```

#### Priority 4: Phase-Appropriate Work

```
IF phase.current == 0
  → "Phase 0 (Foundation). Checklist:
     - [ ] CLAUDE.md exists and is specific
     - [ ] Governance model selected
     - [ ] CI skeleton configured
     Ready to advance? Run /lfg gatekeeper advance"

IF phase.current == 1
  → "Phase 1 (Inception). Next steps:
     - If no requirements: run /lfg reqs extract
     - If requirements exist but no ADRs: document architecture decisions
     - If ready: run /lfg gatekeeper check 1"

IF phase.current == 2
  → "Phase 2 (Elaboration). Next steps:
     - If no user stories: run /lfg speccer stories
     - If stories exist but no spec: run /lfg speccer spec
     - If spec exists: run /lfg speccer validate
     - If validated: run /lfg gatekeeper check 2"

IF phase.current == 3
  → "Phase 3 (Construction). Next steps:
     - If bolt has items: run /lfg foreman supervise
     - If bolt is done: run /lfg qualitygate check
     - If quality passes: run /captainslog new [name], then /pm close
     - If all stories done: run /lfg gatekeeper check 3"

IF phase.current == 4
  → "Phase 4 (Hardening). Next steps:
     - If no security review: run /five-persona-review
     - If review done: run /lfg sentinel triage
     - If findings triaged: run /lfg hardener check
     - If ops score < 85: run /lfg hardener plan
     - If ops score >= 85: run /lfg gatekeeper check 4"

IF phase.current == 5
  → "Phase 5 (Operations). Next steps:
     - If no pipeline: run /lfg deployer pipeline
     - If pipeline exists: run /lfg deployer verify
     - If verified: run /lfg deployer runbook
     - If deployed: run /lfg gatekeeper check 5"

IF phase.current == 6
  → "Phase 6 (Evolution). Ongoing:
     - Run /lfg evolver evolve to update context
     - Run /lfg scribe search [topic] to find prior decisions
     - Run /lfg librarian recall [topic] for full context
     - Run /lfg gatekeeper check 6 when learning cycle complete"
```

#### Priority 4b: Suggest Existing Skills (Skill Awareness)

LFG is the universal router for both ai-lfg teammates AND existing skillzees skills. When context suggests an existing skill would help, recommend it:

```
# Technical decisions
IF user faces architectural trade-off OR "should we..." question
  → "This is a technical decision. Run /staff for staff engineer panel analysis"

# Strategic decisions
IF user faces business/positioning/go-to-market question
  → "Strategic question. Run /exec-review for executive panel analysis"

# Frontend/UI work
IF phase.current == 3 AND work involves UI, frontend, web pages, or design
  → "Frontend work detected. Run /design-panel for visual/UX review"

# Sprint management
IF bolt starting OR ending OR user asks "what's the status"
  → "Run /pm for sprint status and bolt management"

# Security review
IF phase.current >= 3 AND no recent review in docs/reviews/
  → "No recent security review. Run /five-persona-review"

# Compliance check
IF phase.current >= 3 AND user asks about compliance or audit
  → "Run /dlc-audit for AI-DLC compliance scoring"

# Cost estimation
IF user asks about cost, budget, or infrastructure pricing
  → "Run /cost-estimate for development effort and infrastructure cost projection"

# Architecture review
IF user asks about architecture quality or patterns
  → "Run /arch-audit for multi-persona architectural audit"

# Knowledge capture
IF bolt just completed OR user says "that worked" / "fixed" / "done"
  → "Capture the context. Run /captainslog new [topic]"

# Brainstorming
IF user has a vague idea or says "explore" / "figure out" / "what if"
  → "Explore first. Run /brainstorm to think before building"

# Documentation
IF phase.current >= 3 AND no README or docs are stale
  → "Docs need attention. Run /docs to generate or update documentation"
```

**Note:** These are SUGGESTIONS, not dispatches. LFG recommends the skill but the user invokes it directly. LFG teammates (the 17 agents) can be dispatched via `/lfg [name]`. External skills are invoked via their own `/command`.

#### Priority 5: Default

```
→ "Project looks healthy. Run /lfg status for a full dashboard."
```

---

## Action: `assess`

Full project assessment. Works on ANY repo — with or without AI-DLC history.

> "Assess fast. Delegate deep. Synthesize once." — Tim, SpaceX
> "Any git repo has a story. Read the filesystem, read the history, infer the phase." — Rob, Roblox
> "Lead with the paragraph. Nobody reads a 200-line report unless they asked for it." — Fran, Meta

### Flags

| Flag | Effect |
|------|--------|
| (none) | Standard assessment — cold scan + state verification + scored dashboard |
| `--deep` | Standard + delegates to `/motherhen` and `/dlc-audit assess` |
| `--summary` | One-paragraph summary only (override for quick answer) |

### Step 1: Check Memory

Before scanning, check for project context in Claude's memory system:

```bash
# Check for project-specific memory
ls ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null
```

If memory exists for this project, read it for context: user role, past decisions, known issues, feedback preferences. This informs the assessment — a returning user gets context-aware recommendations, not generic advice.

### Step 2: Cold Scan (works on any repo)

Scan the filesystem and git history to understand the project WITHOUT relying on any AI-DLC artifacts:

```bash
# Project identity
ls package.json pyproject.toml go.mod Cargo.toml *.csproj pom.xml 2>/dev/null
cat package.json 2>/dev/null | head -5  # name, version
cat pyproject.toml 2>/dev/null | head -10

# Git health
git log --oneline -1 2>/dev/null  # has commits?
git log --oneline --since="30 days ago" | wc -l  # recent activity
git branch -a 2>/dev/null | wc -l  # branch count
git tag -l 2>/dev/null | tail -5  # release history

# Code structure
find . -maxdepth 2 -type d -not -path '*/\.*' -not -path '*/node_modules/*' | head -30

# Test infrastructure
find . -path '*/test*' -name '*.py' -o -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.go' 2>/dev/null | wc -l
ls jest.config* pytest.ini pyproject.toml vitest.config* 2>/dev/null

# CI/CD
ls .github/workflows/*.yml .gitlab-ci.yml azure-pipelines.yml buildspec.yml Makefile 2>/dev/null

# Documentation
ls README.md CLAUDE.md SECURITY.md CHANGELOG.md docs/ 2>/dev/null

# Security posture
ls .pre-commit-config.yaml .snyk .gitleaks.toml .trivyignore 2>/dev/null
grep -rl "password\|api_key\|secret" --include="*.env*" . 2>/dev/null | head -5

# AI-DLC artifacts
ls .ai-dlc.state.yaml docs/pm/CURRENT-SPRINT.md docs/captains_log/ docs/reviews/ 2>/dev/null

# Dependencies
ls package-lock.json yarn.lock pnpm-lock.yaml poetry.lock Pipfile.lock go.sum Cargo.lock 2>/dev/null
```

### Step 3: Infer Phase (if no state file)

If `.ai-dlc.state.yaml` doesn't exist, infer the project's effective AI-DLC phase from filesystem signals:

| Signal | Inferred Phase |
|--------|---------------|
| Empty repo / no code | Phase 0 (Foundation) |
| Has code but no docs, no tests | Phase 0 (needs foundation) |
| Has README + code but no requirements | Phase 1 (needs inception) |
| Has requirements/ADRs but no user stories | Phase 2 (needs elaboration) |
| Has code + tests, active development | Phase 3 (construction) |
| Has code + tests + security review, preparing for deploy | Phase 4 (hardening) |
| Has deployment pipeline, running in production | Phase 5 (operations) |
| Stable in production, focus on maintenance/improvement | Phase 6 (evolution) |

### Step 4: State File Verification (if state file exists)

If `.ai-dlc.state.yaml` exists, verify key claims against filesystem reality:

| Claim | Verification | Action if Divergent |
|-------|-------------|-------------------|
| `pillars.quality.test_count: N` | `find tests/ -name 'test_*' ... \| wc -l` | Flag: "State says N tests, found M" |
| `phase.current: N` | Infer from Step 3 signals | Flag: "State says Phase N but signals suggest Phase M" |
| `teammates.implemented: N` | `ls skills/*/SKILL.md \| wc -l` | Flag: "State says N teammates, found M skill files" |
| `pillars.security.last_review` | `ls -t docs/reviews/*security* docs/reviews/*five-persona*` | Flag: "State says last review [date], most recent file is [date]" |
| `sprint.status` | Check if CURRENT-SPRINT.md matches | Flag: "State says [status], sprint doc says [other]" |
| `gates.phase_N.checklist` | Re-run automatable checks from phase-criteria.yaml | Flag specific items that changed |

For each divergence: report it, offer to fix the state file.

### Step 5: Score the Pillars

Produce a health score for each AI-DLC pillar based on what was found:

```markdown
### Pillar Health

| Pillar | Score | Evidence |
|--------|-------|----------|
| Security | [0-10] | [what was found: reviews, SECURITY.md, pre-commit, scans] |
| Quality | [0-10] | [tests found, coverage config, linting, CI] |
| Traceability | [0-10] | [requirements, stories, matrix, commit conventions] |
| Cost | [0-10] | [budget docs, monitoring, alerts, kill switches] |
```

**Scoring rubric:**

| Score | Meaning |
|-------|---------|
| 0-2 | Not started — no evidence of this pillar |
| 3-4 | Minimal — some artifacts exist but incomplete |
| 5-6 | Developing — basics in place, gaps remain |
| 7-8 | Operational — solid implementation, minor gaps |
| 9-10 | Exemplary — comprehensive, verified, maintained |

### Step 6: Identify Gaps and Recommend Actions

Compare what EXISTS against what the current phase REQUIRES (from phase-criteria.yaml):

```markdown
### Gap Analysis

| Gap | Phase Required | Priority | Recommended Action |
|-----|---------------|----------|-------------------|
| No CLAUDE.md | Phase 0 | HIGH | Run /lfg bootstrapper init |
| No security review | Phase 1+ | HIGH | Run /five-persona-review |
| Tests exist but no coverage config | Phase 3 | MEDIUM | Run /lfg qualitygate coverage |
| No captain's logs | Phase 3+ | MEDIUM | Run /captainslog new |
| No traceability matrix | Phase 2+ | MEDIUM | Run /lfg tracer scan |
| No cost tracking | Phase 4+ | LOW | Run /lfg costkeeper estimate |
```

### Step 7: Produce Output

#### If `--summary` flag: One Paragraph

```
[Project name] is a [language/framework] project effectively at Phase [N]
([name]). [Strongest pillar] is solid ([score]/10) but [weakest pillar]
needs attention ([score]/10). Top priority: [action 1]. Also consider:
[action 2], [action 3]. [If state file stale: "Note: state file has
[N] divergences from reality — run /lfg assess to see details."]
```

#### Standard output (no flags): Scored Dashboard

```markdown
## Project Assessment: [name]

**Date:** YYYY-MM-DD
**Language:** [detected]
**Phase:** [N] — [Name] [inferred / from state file]
**State file:** [present + verified / present + stale / missing]

### One-Line Summary
[The paragraph from --summary mode]

### Pillar Health
[Table from Step 5]

### State File Verification
[Table from Step 4 — only if divergences found]

### Top 5 Actions (Priority Order)
1. [Action] — [why] — run: [command]
2. [Action] — [why] — run: [command]
3. [Action] — [why] — run: [command]
4. [Action] — [why] — run: [command]
5. [Action] — [why] — run: [command]

### Phase Gate Status
[If state file exists, show gate checklist for current phase]

### Skill Suggestions
[Based on gaps, suggest specific existing skills: /staff, /brainstorm, etc.]
```

**If no state file exists:** Offer to create one:
```
No .ai-dlc.state.yaml found. Based on this assessment, your project is
effectively at Phase [N]. Want me to create a state file? (Run /lfg bootstrapper upgrade)
```

#### If `--deep` flag: Delegate and Synthesize

After producing the standard dashboard:

1. Run `/motherhen` for operational health checks
2. Run `/dlc-audit assess` for 9-dimension compliance scoring
3. Synthesize all three results into a unified report:

```markdown
## Deep Assessment: [name]

### Quick Dashboard
[Standard output from above]

### Operational Health (via /motherhen)
[7 checks with PASS/WARN/FAIL]

### AI-DLC Compliance (via /dlc-audit)
[9-dimension scorecard with grades]
[Overall maturity rating]

### Unified Recommendations
[Merged and deduplicated action items from all three sources,
sorted by priority, with effort estimates]
```

### Cross-Repo Assessment

If the user asks to assess across multiple repos:

```
/lfg assess ../repo-a ../repo-b ../repo-c
```

Run the standard assessment on each, then produce a comparison:

```markdown
## Cross-Repo Assessment

| Repo | Phase | Security | Quality | Traceability | Cost | Top Action |
|------|-------|----------|---------|-------------|------|-----------|
| repo-a | 6 | 8/10 | 9/10 | 7/10 | 6/10 | Cost tracking |
| repo-b | 3 | 4/10 | 6/10 | 2/10 | 0/10 | Security review |
| repo-c | 0 | 0/10 | 0/10 | 0/10 | 0/10 | Foundation bootstrap |
```

---

## Action: `status`

Full project dashboard:

```markdown
## Project Status Dashboard

**Project:** [name] v[version]
**Phase:** [N] — [Name]
**Governance:** [model]
**Current Bolt:** [bolt-name] ([X]/[Y] items complete)

### Pillar Health

| Pillar | Status | Details |
|--------|--------|---------|
| Security | [status] | [N] open findings ([critical]/[high]/[medium]/[low]) |
| Quality | [status] | [X]% coverage, [N] tests, lint [pass/fail] |
| Traceability | [status] | [X]% coverage, [N] orphans |
| Cost | [status] | $[X]/month, budget [green/yellow/red] |

### Phase Progress

| Phase | Status | Gate |
|-------|--------|------|
| 0 Foundation | COMPLETE | PASSED |
| 1 Inception | COMPLETE | PASSED |
| 2 Elaboration | IN PROGRESS | 4/7 criteria met |
| 3 Construction | NOT STARTED | — |
| ...

### Team Activity

| Teammate | Last Active | Action |
|----------|------------|--------|
| Tracer | 2026-04-04 | scan |
| Gatekeeper | 2026-04-04 | check |

### Recommendations

1. [First priority action]
2. [Second priority action]
```

---

## Action: `team`

Show all 17 teammates with implementation status:

```markdown
## The Team

| # | Name | Role | Status | Phase |
|---|------|------|--------|-------|
| 1 | State | Project State Manager | IMPLEMENTED | Cross-cutting |
| 2 | Handoff | Inter-Skill Connector | IMPLEMENTED | Cross-cutting |
| 3 | Gatekeeper | Phase Gate Enforcer | IMPLEMENTED | Cross-cutting |
| 4 | Tracer | Traceability Agent | IMPLEMENTED | Cross-cutting |
| ...

**Implemented:** [X]/17
**Invoke:** /lfg [name] [action]
```

---

## Action: `help`

```markdown
## /lfg — Team Router

**Usage:**
  /lfg                         What should I do next? (quick assess + route)
  /lfg assess                  Full project assessment with scored dashboard
  /lfg assess --deep           Deep assessment (delegates to /motherhen + /dlc-audit)
  /lfg assess --summary        One-paragraph summary only
  /lfg assess ../other-repo    Assess a different repo
  /lfg status                  Full project dashboard
  /lfg team                    Show all teammates
  /lfg help                    This help message

**Dispatch a teammate:**
  /lfg gatekeeper check        Check phase gate
  /lfg gatekeeper advance      Advance to next phase
  /lfg tracer scan             Rebuild traceability matrix
  /lfg tracer orphans          Find orphan code/tests
  /lfg reqs extract            Extract requirements from docs
  /lfg speccer stories         Generate user stories
  /lfg speccer five-questions  Run Five Questions Pattern
  /lfg foreman supervise       Supervise bolt execution
  /lfg foreman parallel        Detect parallel work
  /lfg sentinel triage         Triage security findings
  /lfg sentinel status         Security posture summary
  /lfg costkeeper estimate     Estimate infrastructure costs
  /lfg qualitygate check       Full quality check
  /lfg qualitygate ascent      Verify acceptance criteria
  /lfg hardener check          Run ops readiness checklist
  /lfg deployer pipeline       Generate deployment config
  /lfg evolver evolve          Propose CLAUDE.md updates
  /lfg evolver stale           Detect stale context
  /lfg scribe search [query]   Search captain's logs
  /lfg librarian find [query]  Search all knowledge
  /lfg handoff gaps            Show handoff gaps
  /lfg bootstrapper init       Bootstrap new project
```

---

## Action: Direct Dispatch

When a teammate name is provided, dispatch directly:

```
/lfg [teammate] [action] [args...]
```

1. Validate the teammate name exists in the roster
2. Validate the action is supported by that teammate
3. Invoke the teammate's skill with the specified action

If the teammate name is ambiguous or invalid:
```
Unknown teammate: "[name]"

Did you mean one of these?
- gatekeeper — Phase gate enforcer
- qualitygate — Quality pillar agent

Run /lfg team to see all teammates.
```

---

## Integration Points

- **State:** Reads `.ai-dlc.state.yaml` for all routing decisions
- **All teammates:** Can dispatch any teammate via `/lfg [name] [action]`
- **Gatekeeper:** Route checks gate status before recommending phase work
- **/bolt-lfg:** LFG can suggest bolt-lfg as the execution mechanism
- **/dlc-loop:** LFG provides the same routing intelligence for autonomous loops

---

## Quality Standards

- Routing must be deterministic — same state produces same recommendation
- Priority checks must run in order — urgent issues before routine work
- Dispatch must validate teammate + action before invoking
- Status dashboard must be current (read state file, don't cache)
- Help must list all available teammate commands
