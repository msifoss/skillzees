# Project Management Update

Usage: `/pm [action]`

**Arguments:** $ARGUMENTS

---

## Purpose

Manages the Bolt-based sprint framework. Keeps PM artifacts (`docs/pm/`) in sync with actual work. This is the lightweight-but-rigorous process that kept callhero on track through 16 Bolts, 155 security findings, and production deployment.

---

## Instructions for Claude

### 0. Parse Arguments

Extract `action` from: `$ARGUMENTS`

**Actions:**
- `status` — Show current Bolt status, progress, and blockers
- `plan` — Start a new Bolt (Monday planning)
- `close` — Close current Bolt and archive (Friday review)
- `backlog` — Show and groom the backlog
- `update` — Update current sprint checkboxes based on recent work
- `metrics` — Show Bolt metrics (commits, tests, deploys, blocked %)

If no action provided, default to `status`.

### 1. Ensure PM Directory Exists

```bash
mkdir -p docs/pm
```

Check for existence of all PM files:
- `docs/pm/FRAMEWORK.md`
- `docs/pm/CURRENT-SPRINT.md`
- `docs/pm/SPRINT-LOG.md`
- `docs/pm/BACKLOG.md`

If any are missing, offer to create them from template.

---

## Action: `status`

1. Read `docs/pm/CURRENT-SPRINT.md`
2. Read `docs/pm/BACKLOG.md` (blocked items only)
3. Display:

```
📊 Bolt [N] — [Name] ([dates])
Goal: [one-sentence goal]
Status: [IN PROGRESS / COMPLETE / BLOCKED]

Progress:
  ✅ [completed items count] / [total items count]
  🟢 [in-progress items]
  🔴 [blocked items with ticket numbers]

Blockers:
  [List any blocked items with ticket/dependency info]

Key Metrics:
  Commits: [count since bolt start]
  Tests: [current count] (Δ [change])
  Deploys: [count]
```

---

## Action: `plan`

### Step 1: Archive Previous Bolt (if exists)
If `CURRENT-SPRINT.md` has content, offer to archive it first (runs `close` action).

### Step 2: Gather Context
```bash
# Recent commits
git log --oneline -20

# Current test count
[language-specific test count command]

# Any open blocked items from backlog
```

### Step 3: Read Backlog
Read `docs/pm/BACKLOG.md` and identify top executable (🟢) items.

### Step 4: Ask Planning Questions
1. What's the Bolt Goal? (one sentence describing the shippable outcome)
2. Which backlog items are we pulling in? (show top candidates)
3. Any new items to add?
4. Any blockers to track?

### Step 5: Write CURRENT-SPRINT.md

```markdown
# Bolt [N] — [Name] ([date range])

**Goal:** [one-sentence goal]

**Status:** IN PROGRESS

---

## Items

| Item | Size | Status |
|------|------|--------|
| [item] | [S/M/L/XL] | 🟢 |

## Blockers

| Ticket | Title | Priority | Days Open | Impact |
|--------|-------|----------|-----------|--------|

---

## Key Metrics

| Metric | Start | Current |
|--------|-------|---------|
| Tests | [count] | [count] |
| Deploys | [count] | [count] |
```

---

## Action: `close`

### Step 1: Gather Final Metrics
```bash
git log --oneline --since="[bolt start date]" | wc -l
[test count]
```

### Step 2: Read Current Sprint
Read `docs/pm/CURRENT-SPRINT.md` for final status.

### Step 3: Write Review

Update `CURRENT-SPRINT.md` status to COMPLETE, then append to `docs/pm/SPRINT-LOG.md`:

```markdown
---

## Bolt [N] — [Name] ([dates])

**Goal:** [goal]
**Outcome:** [what actually shipped]

### Completed
| Item | Size |
|------|------|
| [items] | [sizes] |

### Not Completed
| Item | Reason |
|------|--------|
| [items] | [why] |

### Metrics
| Metric | Value |
|--------|-------|
| Commits | [count] |
| Tests Δ | [+N] (now [total]) |
| Deploys | [count] |
| Blocked % | [percentage] |

### Retro — One Improvement
[What to do differently next Bolt]
```

### Step 4: Update Backlog
Move completed items to ✅ done in `docs/pm/BACKLOG.md`.

---

## Action: `backlog`

1. Read `docs/pm/BACKLOG.md`
2. Display summary grouped by phase and priority
3. Offer grooming options:
   - Add new item
   - Reprioritize
   - Change status (blocked ↔ executable)
   - Move to Won't Do
4. After changes, update the file

---

## Action: `update`

1. Read `docs/pm/CURRENT-SPRINT.md`
2. Check recent git activity:
   ```bash
   git log --oneline -10
   git diff --stat HEAD~3
   ```
3. Identify which sprint items may have been completed
4. Ask user to confirm status changes
5. Update checkboxes in `CURRENT-SPRINT.md`

---

## Action: `metrics`

Gather and display metrics for the current Bolt:

```bash
# Commits since bolt start
git log --oneline --since="[bolt start date]" | wc -l

# Test count
[language-specific test count]

# Files changed
git diff --stat [bolt start commit]..HEAD | tail -1
```

Display:
```
📈 Bolt [N] Metrics

| Metric | Value | Trend |
|--------|-------|-------|
| Commits | [N] | — |
| Tests | [N] (Δ +[N]) | ↑ |
| Deploys | [N] | — |
| Blocked % | [N]% | — |
| Files changed | [N] | — |
| Lines added | +[N] | — |
| Lines removed | -[N] | — |
```
