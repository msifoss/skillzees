# /compose — Pipeline Composer

Usage: `/compose <task description or Mission Brief path>`

**Arguments:** $ARGUMENTS

---

## Purpose

Analyze a task or Mission Brief and recommend the optimal sequence of AI-DLC skills to execute it. Outputs a pipeline with rationale, then optionally executes it.

> Like a project architect who knows every tool in the shop. Describe what you need built, get a build plan using the right commands in the right order.

---

## Instructions for Claude

### Step 1: Understand the Task

Read $ARGUMENTS:

**If it's a file path** (ends in `.md`, contains `/`):
```bash
cat $ARGUMENTS
```
Parse goals, acceptance criteria, constraints, and scope.

**If it's a description:** Parse the intent directly.

Classify the task:
- **Single focused task** (bug fix, one feature) → likely `/bolt-lfg`
- **Multiple independent tasks** (batch changes, several features) → likely `/slfg`
- **Full project lifecycle** (new project, major initiative) → likely `/dlc-loop`
- **Review/audit only** (check quality, assess health) → likely review skills
- **Strategic/business question** → likely `/exec-review`
- **Exploration/research** → likely `/brainstorm`

### Step 2: Read the Skill Catalog

```bash
cat skills/README.md 2>/dev/null || cat ~/.claude/skills/README.md 2>/dev/null
```

Build a mental model of available commands and their capabilities.

### Step 3: Compose the Pipeline

Select skills and order them based on the task classification. Apply these composition rules:

**Ordering rules:**
1. Exploration before planning (`/brainstorm` before `/pm plan`)
2. Planning before execution (`/pm plan` before work)
3. Research before building (`/deepen-plan` before implementation)
4. Building before review (`implementation` before `/five-persona-review`)
5. Review before shipping (`/five-persona-review` before PR)
6. Capture before closing (`/captainslog` before `/pm close`)

**Selection rules:**
- Include `/brainstorm` if requirements are vague or multiple approaches exist
- Include `/staff-panel` if architectural decisions are needed
- Include `/exec-review` if strategic/business decisions are needed
- Include `/deepen-plan` if the task is complex (M/L/XL effort)
- Include `/security-audit` if the task touches auth, data, or external APIs
- Include `/five-persona-review` if code changes are involved
- Include `/captainslog` always (knowledge capture is non-negotiable)

**Parallelization rules:**
- Skills that don't depend on each other can note `parallel: true`
- Review skills can run in parallel (security + five-persona)
- Analysis panels can run in parallel (staff-panel + exec-review if both needed)

### Step 4: Present the Pipeline

```markdown
## Recommended Pipeline for: [task summary]

| # | Step | Command | Why | Parallel? |
|---|------|---------|-----|-----------|
| 1 | [phase] | `/command` | [rationale] | — |
| 2 | [phase] | `/command` | [rationale] | — |
| 3a | [phase] | `/command` | [rationale] | YES (with 3b) |
| 3b | [phase] | `/command` | [rationale] | YES (with 3a) |
| 4 | [phase] | `/command` | [rationale] | — |

**Estimated pipeline:** [S/M/L/XL]
**Alternative:** [simpler pipeline if task might be simpler than assumed]
```

### Step 5: Offer Execution

Present options:
1. **Run this pipeline** — execute commands in order (you confirm each gate)
2. **Run autonomously** — execute as `/bolt-lfg` with this as the plan
3. **Modify** — adjust the pipeline before running
4. **Save** — write pipeline to `docs/pm/` for later

If user chooses 1, execute each command in sequence, announcing each step.
If user chooses 2, invoke `/bolt-lfg` with the task description.

---

## Common Pipeline Templates

### Bug Fix (S)
```
/bolt-lfg "fix: [bug description]"
```
Single command — bolt-lfg handles the full pipeline internally.

### New Feature (M)
```
1. /brainstorm [feature]
2. /pm plan
3. /deepen-plan
4. (implementation)
5. /five-persona-review
6. /captainslog
7. /pm close
```

### Architectural Decision (M)
```
1. /brainstorm [decision context]
2. /staff-panel [specific question]
3. /pm plan (incorporating panel decision)
4. (implementation)
5. /five-persona-review
6. /captainslog
7. /pm close
```

### Strategic Initiative (L/XL)
```
1. /brainstorm [initiative]
2. /exec-review [strategic question]
3. /staff-panel [technical approach]
4. /pm plan
5. /deepen-plan
6. /slfg [parallel implementation]
7. /security-audit (if applicable)
8. /five-persona-review
9. /captainslog
10. /pm close
```

### Full Lifecycle (XL)
```
1. Fill out templates/MISSION-BRIEF.md
2. /dlc-loop
```

### Review Only
```
1. /five-persona-review [scope]
2. /security-audit [scope] (parallel)
3. /arch-audit [scope] (parallel)
```

---

## Integration

- `/dlc-loop` Step 0 can invoke `/compose` logic to determine which skills each phase needs
- `/bolt-lfg` can invoke `/compose` if the task is ambiguous
- Pipeline output can be saved as a plan artifact in `docs/pm/`
- The skill catalog in `skills/README.md` is the source of truth
