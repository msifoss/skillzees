# /slfg — Swarm Mode Autonomous Pipeline

Usage: `/slfg [--speed] [feature description or goal]`

**Arguments:** $ARGUMENTS

---

## Purpose

Parallel execution variant of `/bolt-lfg`. Breaks work into independent items and executes them simultaneously using background agents, then consolidates. For when speed matters and items are parallelizable.

> Like `/bolt-lfg` but with a turbocharger. Same gates, same quality — parallel execution where the dependency graph allows.

---

## Instructions for Claude

### Step 0: Parse Mode and Assess Parallelizability

**Speed mode:** If $ARGUMENTS contains `--speed`, enable speed mode:
- Skip brainstorm (requirements assumed clear)
- Use `/deepen-plan` with only 4 core agents instead of 10 (learnings, codebase, best practices, compliance)
- Skip captain's log (capture knowledge post-merge)
- Reduce review to 5 core personas instead of 12
- Total overhead: ~60% less than full mode

**Full mode (default):** All 10 research agents, 12 review personas, full knowledge capture.

Read $ARGUMENTS (excluding flags) and determine if the work can be parallelized:

**Parallelizable indicators:**
- Multiple independent files to create/modify
- Several unrelated features or fixes
- Batch operations across similar components
- Multiple test suites to write

**NOT parallelizable (fall back to /bolt-lfg):**
- Sequential dependencies between items
- Single complex feature in one file
- Refactoring with cascading changes
- Database migrations with ordering requirements

**If not parallelizable:** Announce "This work has sequential dependencies — switching to `/bolt-lfg` for ordered execution." Then run `/bolt-lfg $ARGUMENTS` and stop.

---

### Step 1: Brainstorm (if needed)

Same gate as `/bolt-lfg` Step 1:

Check if $ARGUMENTS describes a clear, well-scoped task. If brainstorming needed:
```
/brainstorm $ARGUMENTS
```

GATE: Brainstorm doc exists OR requirements are clear enough to skip.

---

### Step 2: Plan + Deepen (Ultrathink Mode)

Run planning and research:
```
/pm plan
```

Then immediately deepen the plan with all 10 research agents:
```
/deepen-plan
```

**Ultrathink mode:** During deepening, each research agent uses extended thinking — exploring multiple approaches, reasoning through trade-offs, and producing deeper analysis than standard mode. This is the key differentiator: quantity (10 agents) x quality (extended reasoning) = comprehensive plan coverage.

GATE: Active bolt in CURRENT-SPRINT.md with research-hardened plan from 10 agents.

---

### Step 3: Decompose into Parallel Work Items

Read the plan and decompose into independent work items. For each item, determine:

| Item | Files Touched | Dependencies | Can Parallel? |
|------|--------------|-------------|---------------|
| [Item 1] | [files] | None | YES |
| [Item 2] | [files] | None | YES |
| [Item 3] | [files] | Item 1 | NO — after Item 1 |

**Rules for decomposition:**
- Items touching the SAME file cannot run in parallel
- Items with import/dependency relationships must be sequential
- Test writing CAN parallel with implementation if tests are in separate files
- Each item must be self-contained enough to commit independently

Announce: "Decomposed into [N] parallel items and [M] sequential items."

---

### Step 4: Swarm Execution

#### 4a. Launch Parallel Agents

For each parallelizable item, launch a background agent using the Agent tool with `run_in_background: true`:

```
Agent prompt for each item:

You are implementing work item [N] of a bolt sprint.

**Item:** [description]
**Files to modify:** [list]
**Plan context:** [relevant section of the plan]
**Codebase patterns:** [from deepen-plan research]
**Test strategy:** [from deepen-plan research]

Instructions:
1. Read all files you'll modify first
2. Implement the change following existing patterns
3. Write tests in the appropriate test file
4. Run tests to verify: [test command from .ai-dlc.local.yaml or auto-detected]
5. Stage and commit with a conventional commit message

Do NOT modify files outside your assigned list.
Do NOT push to remote.
Report: files changed, tests passed/failed, commit hash.
```

#### 4b. Execute Sequential Items

After parallel agents complete, execute sequential items in dependency order. Each sequential item gets the same agent treatment but waits for its dependency.

#### 4c. Consolidation

After ALL agents complete:
1. Check for merge conflicts between parallel changes
2. If conflicts exist, resolve them (prefer the change that matches the plan)
3. Run the **full validation suite** (not just tests):

```bash
# Auto-detect and run all available validation
# Tests
[test command from .ai-dlc.local.yaml, or auto-detected]

# Linting (if configured)
[lint command if available — eslint, ruff, rubocop, clippy, etc.]

# Type checking (if configured)
[type check command if available — tsc --noEmit, mypy, etc.]

# Build verification
[build command if available — ensure the project compiles/bundles]
```

4. If any validation fails, identify which agent's changes caused the failure and fix
5. Re-run failed validations after fixes

GATE: All items implemented. Full validation suite passes (tests + lint + types + build). No unresolved conflicts.

---

### Step 5: Review

```
/five-persona-review
```

GATE: Review doc created. Critical findings fixed.

---

### Step 6: Fix Findings (Parallel)

If the review found Critical or High issues, fix them in parallel:

For each finding that can be fixed independently, launch a background agent:
```
Fix finding [ID]: [description]
File: [path]
Lines: [range]
Fix: [specific fix from review]

Apply the fix, run tests, commit with message: "fix: resolve [ID] from five-persona review"
```

After all fix agents complete, run full test suite again.

---

### Step 7: Capture + Close

Run sequentially (these are inherently sequential):
```
/captainslog new [topic]
/pm close
```

Push and create PR if on a feature branch.

---

### Step 8: Compound (Optional)

Same as `/bolt-lfg` Step 7 — document non-trivial solutions.

---

## Pipeline Summary

| Step | Command | Parallel? | Gate |
|------|---------|-----------|------|
| 0 | Assess parallelizability | — | Can decompose into independent items |
| 1 | `/brainstorm` (conditional) | No | Brainstorm doc or skip justified |
| 2 | `/pm plan` + `/deepen-plan` | No | Research-hardened plan |
| 3 | Decompose | No | Items mapped with dependencies |
| 4 | Swarm execution | **YES** | All items done, tests pass |
| 5 | `/five-persona-review` | No | Review doc, criticals fixed |
| 6 | Fix findings | **YES** | All findings fixed, tests pass |
| 7 | `/captainslog` + `/pm close` | No | Knowledge captured, bolt closed |
| 8 | Compound (optional) | No | Solution doc if non-trivial |

## Speed Comparison

| Pipeline | 5 independent items | 3 items + 2 sequential |
|----------|--------------------|-----------------------|
| `/bolt-lfg` | Sequential: ~5x time | Sequential: ~5x time |
| `/slfg` | Parallel: ~1x time + overhead | Parallel 3 + sequential 2: ~3x time |

The speedup scales with the number of independent items.

---

## Integration

- Uses all the same skills as `/bolt-lfg` (brainstorm, pm, deepen-plan, five-persona-review, captainslog)
- Adds `/deepen-plan` automatically (research-hardened plans prevent parallel work from diverging)
- Parallel fix resolution after review (like CE's /resolve_pr_parallel)
- Falls back to `/bolt-lfg` gracefully when work isn't parallelizable
