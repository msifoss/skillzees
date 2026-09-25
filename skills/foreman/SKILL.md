---
name: foreman
description: Construction supervisor — coordinates bolt execution, detects parallelism, manages blockers
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "supervise | parallel | blocker | status"
---

# /foreman — Construction Supervisor

Coordinates Phase 3 construction. Manages bolt execution across items, detects work that can run in parallel, tracks blockers, and ensures test-paired development.

> "Every bolt needs a foreman. The foreman doesn't write code — they make sure the right code gets written in the right order." — AI-DLC Phase 3

## Trigger

User invokes `/foreman [action]` or during Phase 3 bolt execution.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `supervise` | Full construction supervision for current bolt | `/foreman supervise` |
| `parallel` | Detect parallel-eligible work and dispatch | `/foreman parallel` |
| `blocker` | Track or resolve a blocker | `/foreman blocker add "waiting on API docs"` |
| `status` | Show construction progress | `/foreman status` |

---

## Action: `supervise`

### Step 1: Read Current Bolt

```bash
cat docs/pm/CURRENT-SPRINT.md
cat docs/user-stories.md 2>/dev/null
```

### Step 2: Determine Work Order

For each bolt item:
1. Check dependencies (does this item depend on another?)
2. Check parallel eligibility (can this run alongside other items?)
3. Estimate whether test-paired development applies (code + test together)

### Step 3: Execute Items

For each item in dependency order:
1. Announce: "Working on [item] — [story reference]"
2. Implement the item following existing patterns
3. Write tests alongside implementation (test-paired)
4. Run tests after each logical unit
5. **Security checkpoint** — run lightweight security scan on changed files:
   - Check for hardcoded secrets: `grep -rn "password\s*=\|api_key\s*=\|secret\s*=" [changed files] | grep -v test`
   - Check for security bypasses: `grep -rn "noqa.*security\|nosec\|disable_ssl\|verify=False" [changed files]`
   - Check for dangerous patterns: `grep -rn "eval(\|exec(\|innerHTML\|dangerouslySetInnerHTML\|__import__" [changed files]`
   - If any findings: create a security blocker (see `blocker` action) — do NOT proceed without resolution
6. Commit incrementally with conventional messages referencing story IDs
7. Trigger QualityGate Ascent check for the completed item
8. Record changed file scope (`git diff --name-only`) for handoff to five-persona-review

### Step 4: Parallel Detection

If 2+ items have no shared state or sequential dependencies:

```markdown
## Parallel Work Detected

Items [A] and [B] are independent:
- No shared files
- No dependency relationship
- Different feature areas

**Recommendation:** Run in parallel via `/slfg` for [X]% faster completion.
Dispatch? (y/n)
```

If approved, dispatch via Agent tool with subagent isolation.

---

## Action: `parallel`

Analyze current bolt items for parallelism:

```markdown
## Parallel Analysis

| Item | Dependencies | Shared Files | Parallel Eligible |
|------|-------------|-------------|------------------|
| Feature A | None | src/auth/ | YES |
| Feature B | None | src/api/ | YES |
| Feature C | Feature A | src/auth/ | NO (depends on A) |

**Recommendation:** Run A + B in parallel. Then C sequentially.
**Time savings:** ~40% (estimated)
```

---

## Action: `blocker`

### Track a Blocker

```
/foreman blocker add "Waiting on API documentation from vendor"
/foreman blocker resolve B-003-BLK-001 "Received API docs via email"
/foreman blocker list
```

Blocker protocol from AI-DLC:
1. Identify the blocker
2. Time-box investigation (30 minutes)
3. If unresolved: document, switch to another bolt item
4. Track days-open and escalation status

**Security blockers** (added per security audit [C2]):
- Security blockers CANNOT be deferred to another bolt item
- Security blockers must be resolved before the bolt can close
- If a security checkpoint finds hardcoded secrets, dangerous patterns, or
  security bypasses, the finding becomes a security blocker
- Security blockers are tagged with `[SECURITY]` in the blocker table

### Blocker Record

```markdown
## Active Blockers

| ID | Description | Since | Days Open | Status |
|----|-------------|-------|-----------|--------|
| BLK-001 | Waiting on API docs | 2026-04-03 | 1 | open |
| BLK-002 | CI pipeline flaky | 2026-04-04 | 0 | investigating |
```

Update `docs/pm/CURRENT-SPRINT.md` blockers table.

---

## Action: `status`

Construction progress dashboard:

```markdown
## Construction Status

**Bolt:** B-003 — [name]
**Phase:** 3 (Construction)
**Progress:** 4/7 items complete (57%)

| Item | Story | Status | Tests | Notes |
|------|-------|--------|-------|-------|
| Auth login | US-001 | DONE | 5 pass | — |
| Auth signup | US-002 | IN PROGRESS | 3 pass | — |
| API endpoints | US-003 | PLANNED | — | Depends on auth |

**Blockers:** 1 active (BLK-001: API docs)
**Coverage:** 78% (target: 80%)
**Ascent:** 4/6 criteria verified
```

---

## Integration Points

- **QualityGate:** Triggers Ascent verification before item completion
- **Tracer:** Requests traceability scan after bolt
- **Handoff:** Receives stories from Speccer, passes scope to five-persona-review
- **State:** Updates sprint status, blocker counts
- **/bolt-lfg:** Foreman is the intelligent supervisor within bolt-lfg's Step 3
- **/slfg:** Dispatches parallel-eligible work
