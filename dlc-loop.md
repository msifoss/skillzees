# /dlc-loop — Autonomous Full-Lifecycle DLC Execution

Usage: `/dlc-loop [--start-phase N] [--end-phase N] [--skip-phase N,N] [mission brief path]`

**Arguments:** $ARGUMENTS

---

## Purpose

Execute the complete AI-DLC lifecycle (Phase 0 through Phase 6) autonomously in a single session. Reads a Mission Brief for all human decisions upfront, replaces human gates with automated verification, and loops through phases until the project is complete.

> Like `/bolt-lfg` but for the ENTIRE lifecycle, not just one bolt. The Mission Brief is your authorization — fill it out once, then let it run.

---

## Prerequisites

Before running `/dlc-loop`, verify:

1. **Mission Brief exists** — the Mission Brief contains all pre-approved decisions
2. **Allowlist configured** — `.claude/settings.local.json` has comprehensive permissions
3. **Git is clean** — no uncommitted changes that could be lost

```bash
# Check for Mission Brief
ls MISSION-BRIEF.md 2>/dev/null || ls docs/MISSION-BRIEF.md 2>/dev/null

# Check allowlist coverage
jq '.permissions.allow | length' .claude/settings.local.json 2>/dev/null

# Check git status
git status --short
```

If no Mission Brief exists, tell the user:
> "No Mission Brief found. Create one first: `cp templates/MISSION-BRIEF.md MISSION-BRIEF.md` and fill it out. The Mission Brief contains all the decisions I'd normally ask you about — architecture, constraints, acceptance criteria, risk boundaries. Without it, I can't run autonomously."

---

## Instructions for Claude

### Step 0: Initialize State

Parse $ARGUMENTS:
- `--start-phase N` — begin at phase N (default: auto-detect)
- `--end-phase N` — stop after phase N (default: 6)
- `--skip-phase N,N` — comma-separated phases to skip
- Remaining argument — path to mission brief (default: `MISSION-BRIEF.md`)

```bash
# Create state directory
mkdir -p .dlc-state

# Check for existing state
cat .dlc-state/current.json 2>/dev/null || echo "No prior state — fresh start"
```

Read the Mission Brief in full. This is your authorization document — every decision you need is in here.

Read `.ai-dlc.local.yaml` if it exists for project-specific configuration.

Determine the starting phase:
1. If `--start-phase` provided, use that
2. If `.dlc-state/current.json` exists, resume from the next incomplete phase
3. Otherwise, start at Phase 0

Write initial state:
```json
{
  "phase": 0,
  "status": "initializing",
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ",
  "mission_brief": "MISSION-BRIEF.md",
  "phases_planned": [0, 1, 2, 3, 4, 5, 6],
  "phases_completed": [],
  "phases_skipped": []
}
```

GATE: Mission Brief must exist and be readable. State directory must exist.

---

### Step 1: Execute Phase Loop

For each phase from start to end (skipping any in `--skip-phase`):

#### 1a. Read Phase Guide

```bash
# Phase guides follow this naming pattern
ls docs/framework/PHASE-${PHASE_NUMBER}-*.md
```

Read the phase guide to understand:
- What this phase produces (deliverables)
- Entry criteria (verify before starting)
- Exit criteria (verify before advancing)
- Human decision gates (replace with Mission Brief decisions)

#### 1b. Check Entry Criteria

Verify all entry criteria from the phase guide are met. If a previous phase's deliverable is missing, either:
- Execute the missing phase first (if it wasn't skipped)
- Log a warning and proceed (if the Mission Brief says to skip)

#### 1c. Execute the Phase

Each phase maps to specific DLC commands:

| Phase | Primary Action | DLC Commands Used |
|-------|---------------|-------------------|
| 0 — Foundation | Bootstrap project structure, CLAUDE.md, governance | `/init-project` (if new), `/setup` |
| 1 — Inception | Requirements, architecture decisions, threat model | Read Mission Brief → write `docs/requirements.md`, ADRs |
| 2 — Elaboration | User stories, specifications, traceability | Write specs, create traceability matrix, Five Questions (self-answer from Mission Brief) |
| 3 — Construction | Build in bolts | `/bolt-lfg` for each major feature (this runs the full bolt pipeline internally) |
| 4 — Hardening | Security, monitoring, ops readiness | `/five-persona-review`, fix findings, ops checklist |
| 5 — Operations | Deploy pipeline, monitoring, runbooks | Write deployment docs, create runbooks (skip actual deploy — queue for human) |
| 6 — Evolution | Learnings, context update, patterns | `/captainslog`, update CLAUDE.md, extract patterns |

**Phase 3 Special Handling:**
Phase 3 (Construction) is the longest phase. It consists of multiple bolts. For each feature/story from Phase 2:
1. Run `/bolt-lfg [feature description]` — this handles the full bolt cycle (brainstorm → plan → deepen → work → review → captainslog → close)
2. After each bolt, verify the feature's acceptance criteria from the Mission Brief
3. Continue until all features are built

If work items are parallelizable, use `/slfg` instead of `/bolt-lfg`.

**Replacing Human Gates:**
When the phase guide says "Human Decision Gate", handle it as follows:

| Gate Type | How to Handle Autonomously |
|-----------|---------------------------|
| Requirements approval | Verify against Mission Brief goals and acceptance criteria |
| Architecture sign-off | Use Mission Brief pre-approved decisions |
| Scope change approval | Check if change is within Mission Brief scope — if not, log and defer |
| Security acceptance | Zero critical + zero high findings = auto-approve. Otherwise, check Mission Brief risk boundaries |
| Deploy approval | Queue for human — write to `.dlc-state/deploy-queue.json` |
| Go-live confirmation | Queue for human — never auto-deploy to production |

#### 1d. Write Phase Checkpoint

After completing a phase, write evidence:

```json
// .dlc-state/phase-N-complete.json
{
  "phase": N,
  "phase_name": "PhaseName",
  "status": "complete",
  "timestamp": "YYYY-MM-DDTHH:MM:SSZ",
  "evidence": {
    "deliverables": ["list", "of", "files", "created"],
    "tests_passed": 142,
    "tests_failed": 0,
    "coverage": 87.3,
    "critical_findings": 0,
    "high_findings": 0,
    "entry_criteria_met": true,
    "exit_criteria_met": true,
    "gates_automated": ["list of gates that were auto-verified"],
    "gates_deferred": ["list of gates queued for human review"],
    "notes": "Summary of what was accomplished"
  }
}
```

Update `.dlc-state/current.json` to reflect the next phase.

#### 1e. Verify Exit Criteria

Before advancing to the next phase, verify ALL exit criteria from the phase guide:
- If all met → proceed to next phase
- If not met → attempt to fix (up to 3 retries)
- If still not met → write error to `.dlc-state/error.json` and HALT

GATE: Phase checkpoint exists with `"status": "complete"` and all exit criteria verified.

---

### Step 2: Completion

After all phases complete (or the end phase is reached):

#### 2a. Write Completion Report

Write `.dlc-state/completion-report.md`:

```markdown
# DLC Loop Completion Report

**Date:** YYYY-MM-DD HH:MM
**Phases:** N → M
**Duration:** [estimated from timestamps]

## Summary
[What was built, key decisions, notable outcomes]

## Phase Results
[For each phase: deliverables, evidence, any deferred items]

## Deferred for Human Review
- [ ] [Items queued in deploy-queue.json]
- [ ] [Scope changes detected and deferred]
- [ ] [Risk boundary items that need human judgment]

## Post-Loop Checklist
- [ ] Review all changes: `git log --oneline`
- [ ] Review state: `ls -la .dlc-state/`
- [ ] Push when ready: `git push -u origin $(git branch --show-current)`
- [ ] Create PR: `gh pr create`
- [ ] Run `/motherhen` for health check
- [ ] Run `/dlc-audit` for compliance score
```

#### 2b. Final Health Check

Run a quick `/motherhen quick` to verify overall project health.

#### 2c. Report to User

Display:
```
DLC Loop Complete ✓

Phases executed: [list]
Phases skipped: [list]
Total deliverables: [count]
Tests: [passed/total]
Security findings: [critical/high/medium/low]
Deferred items: [count]

Completion report: .dlc-state/completion-report.md

Next steps:
1. Review changes: git diff main...HEAD
2. Push and PR when ready
3. Items deferred for your review: [count]
```

---

## Halt Conditions

The loop HALTS (does not retry) when:

| Condition | Action |
|-----------|--------|
| Mission Brief not found | HALT — cannot run without authorization |
| 3+ consecutive failures on same phase | HALT — write error.json with diagnosis |
| Risk boundary exceeded (from Mission Brief) | HALT — write error.json with boundary that was hit |
| Git conflict that can't be auto-resolved | HALT — human must resolve |
| External service required but unavailable | HALT — document what's needed |
| Scope creep detected beyond Mission Brief | HALT — log the expansion, defer to human |

Recovery: Fix the issue, then run `/dlc-loop --start-phase N` to resume.

---

## State Files Reference

| File | Purpose |
|------|---------|
| `.dlc-state/current.json` | Current phase, status, session tracking |
| `.dlc-state/phase-N-complete.json` | Evidence checkpoint per completed phase |
| `.dlc-state/progress.log` | Human-readable log of all phase transitions |
| `.dlc-state/error.json` | Last error details and recovery instructions |
| `.dlc-state/completion-report.md` | Final report with all evidence and next steps |
| `.dlc-state/deploy-queue.json` | Operations queued for human execution (deploys, pushes) |

---

## Integration

- **Consumes:** Mission Brief (`templates/MISSION-BRIEF.md`), phase guides (`docs/framework/PHASE-*.md`)
- **Orchestrates:** `/init-project`, `/setup`, `/bolt-lfg`, `/slfg`, `/five-persona-review`, `/captainslog`, `/pm`, `/motherhen`
- **Produces:** `.dlc-state/` directory with full execution evidence
- **Config:** Reads `.ai-dlc.local.yaml` for project-specific thresholds
- **Shell variant:** `scripts/dlc-loop.sh` provides the same loop as an external orchestrator for multi-session execution

---

## Shell Orchestrator vs Skill

This `/dlc-loop` command runs **within a single Claude session**. For very large projects that may exceed context limits, use the shell orchestrator instead:

```bash
bash scripts/dlc-loop.sh --mission MISSION-BRIEF.md
```

The shell script invokes Claude once per phase with `claude -p --continue`, surviving context window limits and session crashes. Same state files, same checkpoints, same Mission Brief.

| Approach | Best For | Context | Recovery |
|----------|----------|---------|----------|
| `/dlc-loop` (this skill) | Small-medium projects, single features | Single session | Re-run with --start-phase |
| `scripts/dlc-loop.sh` | Large projects, full products | Multi-session | Automatic resume from state |

---

## Pipeline Summary

```
Mission Brief → Phase 0 → checkpoint → Phase 1 → checkpoint → ... → Phase 6 → checkpoint → Report
                  │                       │                            │
                  ├── /init-project       ├── Requirements doc         ├── /captainslog
                  └── /setup              └── ADRs                     └── Context update
                                                    │
                                          Phase 3 (Construction)
                                          ├── /bolt-lfg [feature 1]
                                          ├── /bolt-lfg [feature 2]
                                          ├── /slfg [parallel features]
                                          └── ... until all stories done
                                                    │
                                          Phase 4 (Hardening)
                                          ├── /five-persona-review
                                          ├── Fix Critical/High
                                          └── Ops readiness checklist
```

Start now. Read the Mission Brief, initialize state, and begin Phase 0 (or resume from the last checkpoint).
