# /bolt-lfg — Autonomous Bolt Pipeline

Usage: `/bolt-lfg [feature description or goal]`

**Arguments:** $ARGUMENTS

---

## Purpose

Full autonomous engineering pipeline that chains the AI-DLC bolt workflow end-to-end. Modeled on compound engineering's `/lfg` with our bolt methodology, governance gates, and knowledge capture loop.

> Each step has a gate. The pipeline cannot proceed until the gate passes. This prevents "code first, think later."

---

## Pipeline

```
brainstorm → plan → work → review → captainslog → close
```

CRITICAL: Execute every step below IN ORDER. Do NOT skip any step. Do NOT jump ahead to coding. The brainstorm and planning phases MUST complete before work begins.

---

## Step 1: Brainstorm (if needed)

**Gate:** Determine if brainstorming is needed before planning.

Check if $ARGUMENTS describes a clear, well-scoped task:

**Clear requirements indicators (skip brainstorm):**
- Specific acceptance criteria provided
- Referenced existing patterns to follow
- Described exact expected behavior
- Constrained, well-defined scope (e.g., "fix bug X in file Y")

**Unclear requirements indicators (brainstorm first):**
- Vague goal ("improve the auth system")
- Multiple possible approaches
- New feature with no existing pattern
- User asks to "explore" or "figure out"

**If brainstorming needed:**
```
/brainstorm $ARGUMENTS
```

GATE: STOP. Verify that a brainstorm document exists at `docs/brainstorms/`. If no brainstorm file was created, the brainstorm did not complete — run it again. Do NOT proceed to Step 2 until a brainstorm document exists OR requirements were clear enough to skip.

**If skipping brainstorm:** Announce "Requirements are clear — skipping brainstorm, proceeding to planning." and continue to Step 2.

---

## Step 2: Plan the Bolt

```
/pm plan
```

During planning:
- If a brainstorm document exists in `docs/brainstorms/` matching this feature, reference it
- Pull items from the backlog or create new ones based on $ARGUMENTS
- Define the bolt goal, items, and success criteria

GATE: STOP. Verify that `docs/pm/CURRENT-SPRINT.md` has been updated with a new bolt. If not, planning did not complete — run `/pm plan` again. Do NOT proceed to Step 2b without an active bolt.

---

## Step 2b: Deepen the Plan

```
/deepen-plan
```

This launches 4 parallel research agents to stress-test the plan:
- **Learnings Researcher** — searches docs/solutions/ and docs/captains_log/ for relevant past decisions
- **Codebase Researcher** — finds existing patterns, reusable code, and potential conflicts
- **Best Practices Researcher** — identifies pitfalls, security concerns, and performance anti-patterns
- **Framework Compliance Researcher** — checks AI-DLC phase requirements and governance gates

GATE: STOP. Verify that the plan in CURRENT-SPRINT.md now has a "Research Summary" section with amendments applied. If /deepen-plan found "Must Address" items, they must be integrated before work begins. Do NOT proceed to Step 3 without a research-hardened plan.

---

## Step 3: Work the Bolt

### 3a. Setup Isolation

Before writing code, set up an isolated environment:

```bash
# Check current branch
current_branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$default_branch" ]; then
  default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
fi
```

**If on default branch:** Create a feature branch:
```bash
git checkout -b bolt/$(date +%Y%m%d)-$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 40)
```

**If already on a feature branch:** Ask user whether to continue here or create a new branch.

### 3b. Execute Work Items

For each item in the bolt:
1. Read the plan and any brainstorm documents for context
2. Search `docs/captains_log/` and `docs/solutions/` for relevant past learnings (knowledge retrieval loop)
3. Implement the item following existing codebase patterns
4. Write tests alongside implementation
5. Run the test suite after each logical unit
6. Commit incrementally with conventional messages

### 3c. System-Wide Check (before marking item done)

For each completed item, verify:

| Check | Action |
|-------|--------|
| What fires when this runs? | Trace callbacks, middleware, observers 2 levels out |
| Do tests exercise the real chain? | Ensure integration tests with real objects, not just mocks |
| Can failure leave orphaned state? | Test the failure path for cleanup |
| What other interfaces expose this? | Grep for the method in related classes |
| Do error strategies align? | Verify rescue/catch lists match what lower layers raise |

**Skip when:** Leaf-node changes with no callbacks, no state persistence, no parallel interfaces.

GATE: STOP. Verify that code changes were made (not just planning). Run `git diff --stat` to confirm files were created or modified. Tests must pass. Do NOT proceed to Step 4 if no code changes exist or tests are failing.

---

## Step 4: Review

```
/five-persona-review
```

The review will:
- Run 5 independent persona analyses
- Produce a consolidated findings report at `docs/reviews/`
- Classify findings by severity (Critical/High/Medium/Low)

GATE: STOP. Verify that a review document was created in `docs/reviews/`. If Critical findings exist, fix them before proceeding. High findings should be fixed or explicitly deferred with rationale.

### 4b. Fix Findings

If the review found Critical or High issues:
1. Fix all Critical findings immediately
2. Fix High findings or create backlog items for them
3. Re-run affected tests
4. Commit fixes with references to finding IDs (e.g., "fix: resolve F1 from five-persona review")

---

## Step 5: Capture Knowledge

```
/captainslog new $(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 40)
```

The captain's log will:
- Gather git context (recent commits, branch, changes)
- Reference the previous log for continuity
- Document decisions made, issues encountered, lessons learned
- Record next steps

GATE: STOP. Verify that a captain's log was created in `docs/captains_log/`. If not, knowledge capture failed — the most valuable part of compound engineering is lost. Run `/captainslog new` again.

---

## Step 6: Close the Bolt

```
/pm close
```

This will:
- Gather final metrics (commits, tests, deploys)
- Archive the bolt to `SPRINT-LOG.md` with retrospective
- Move completed backlog items to done
- Update `CURRENT-SPRINT.md` status to COMPLETE

### 6b. Push and PR (if on a feature branch)

```bash
# Push the branch
git push -u origin $(git branch --show-current)

# Create PR
gh pr create --title "Bolt: $ARGUMENTS" --body "$(cat <<'EOF'
## Summary
[Auto-generated from bolt items]

## Review
- Five-persona review completed — see docs/reviews/
- Critical findings: [count] (all fixed)
- Captain's log: docs/captains_log/[latest]

## Test Plan
- [ ] All tests pass
- [ ] Review findings addressed
- [ ] Captain's log captured

Generated with Claude Code
EOF
)"
```

---

## Step 7: Compound (Optional)

If this bolt solved a non-trivial problem:

1. Check if the solution is worth documenting (multiple investigation attempts, tricky debugging, non-obvious fix)
2. If yes, create a solution document:

```bash
mkdir -p docs/solutions
```

Write to `docs/solutions/YYYY-MM-DD-[topic].md`:

```markdown
---
date: YYYY-MM-DD
topic: [kebab-case-topic]
bolt: [bolt number]
tags: [relevant-tags]
---

# [Problem Title]

## Symptom
[What was observed]

## Root Cause
[What actually caused it]

## Solution
[What fixed it]

## Prevention
[How to avoid in future]
```

3. If 3+ similar solutions exist in `docs/solutions/`, promote to a pattern document

---

## Pipeline Summary

| Step | Command | Gate | Deliverable |
|------|---------|------|-------------|
| 1 | `/brainstorm` (conditional) | Brainstorm doc exists OR skip justified | `docs/brainstorms/*.md` |
| 2 | `/pm plan` | Active bolt in CURRENT-SPRINT.md | `docs/pm/CURRENT-SPRINT.md` |
| 2b | `/deepen-plan` | Research summary + amendments applied | Research-hardened plan |
| 3 | (implementation) | Code changes + tests pass | Modified source files |
| 4 | `/five-persona-review` | Review doc + critical findings fixed | `docs/reviews/*.txt` |
| 5 | `/captainslog new` | Captain's log created | `docs/captains_log/*.txt` |
| 6 | `/pm close` + PR | Bolt archived, PR created | `docs/pm/SPRINT-LOG.md` |
| 7 | (compound, optional) | Solution doc if non-trivial | `docs/solutions/*.md` |

Start with Step 1 now. Remember: brainstorm/plan FIRST, then work. Never skip the gates.
