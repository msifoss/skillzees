# /brainstorm — Explore Before You Plan

Usage: `/brainstorm [feature idea or problem to explore]`

**Arguments:** $ARGUMENTS

---

## Purpose

Brainstorming answers **WHAT** to build through collaborative dialogue. It precedes `/pm plan`, which answers **HOW** to build it. The output is a structured brainstorm document that `/pm plan` and `/bolt-lfg` automatically discover and use as input.

> Inspired by compound engineering's brainstorm → plan pipeline. Each phase's output feeds the next phase's input structurally, not just conceptually.

---

## Instructions for Claude

### Phase 0: Assess Requirements Clarity

Evaluate whether brainstorming is needed based on $ARGUMENTS.

**Clear requirements indicators (suggest skipping):**
- Specific acceptance criteria provided
- Referenced existing patterns to follow
- Described exact expected behavior
- Constrained, well-defined scope

**If requirements are already clear:**
Ask: "Your requirements seem detailed enough to proceed directly to planning. Should I run `/pm plan` instead, or would you like to explore the idea further?"

If user wants to skip, stop here and suggest `/pm plan $ARGUMENTS`.

---

### Phase 1: Understand the Idea

#### 1.1 Lightweight Repository Research

Quick scan to understand existing patterns:

```bash
# Look for similar features, established patterns
ls CLAUDE.md README.md 2>/dev/null
git log --oneline -20
ls docs/solutions/ 2>/dev/null
ls docs/brainstorms/ 2>/dev/null
```

Read `CLAUDE.md` for project context, conventions, and architecture.

Search `docs/solutions/` for relevant past learnings — if we've solved something similar before, surface it now.

#### 1.2 Collaborative Dialogue

Ask questions **one at a time** using natural conversation. Do NOT batch 5 questions at once.

**Question strategy:**
- Prefer multiple-choice when natural options exist
- Start broad (purpose, users, why now) then narrow (constraints, edge cases)
- Validate assumptions explicitly ("I'm assuming X — correct?")
- Ask about success criteria early ("How will we know this is done?")

**YAGNI enforcement:**
- When complexity emerges, ask "Do we really need this right now?"
- Prefer the simplest approach that solves the stated problem
- Defer decisions not needed now

**Exit condition:** Continue until the idea is clear OR user says "proceed" or "that's enough."

---

### Phase 2: Explore Approaches

Propose **2-3 concrete approaches** based on research and conversation.

For each approach:

```
### Approach A: [Name]
[2-3 sentence description]

**Pros:**
- [Benefit]

**Cons:**
- [Drawback]

**Best when:** [Circumstances where this is the right choice]

**Effort:** [S/M/L/XL estimate]
```

Lead with your recommendation and explain why. Be honest about trade-offs. Reference codebase patterns when applicable.

Ask: "Which approach do you prefer? Or should we explore further?"

---

### Phase 3: Capture the Design

Ensure the brainstorms directory exists:
```bash
mkdir -p docs/brainstorms
```

Write to `docs/brainstorms/YYYY-MM-DD-[topic]-brainstorm.md`:

```markdown
---
date: YYYY-MM-DD
topic: [kebab-case-topic]
status: complete
---

# [Topic Title]

## What We're Building
[Concise description — 1-2 paragraphs max]

## Why This Approach
[Brief explanation of approaches considered, why this one was chosen]

## Key Decisions
- **[Decision 1]:** [Rationale]
- **[Decision 2]:** [Rationale]

## Constraints & Requirements
- [Constraint discovered during brainstorming]
- [Requirement that emerged]

## Success Criteria
- [How we'll know this is done]
- [Measurable outcome]

## Open Questions
- [Unresolved questions for the planning phase]

## Next Steps
Run `/pm plan` or `/bolt-lfg` to turn this into an implementation plan.
This document will be auto-discovered and used as the foundation for planning.
```

---

### Phase 4: Handoff

Present options:
1. **Proceed to planning** — run `/pm plan` now with this brainstorm as input
2. **Run the full pipeline** — run `/bolt-lfg` which will discover this brainstorm
3. **Refine further** — keep brainstorming
4. **Done for now** — save and come back later

If user chooses option 1 or 2, invoke the respective command immediately.

---

## Integration

This command integrates with the AI-DLC bolt pipeline:

- `/bolt-lfg` checks `docs/brainstorms/` before planning (Step 1)
- `/pm plan` can auto-discover brainstorm documents matching the feature
- Captain's logs can reference brainstorm decisions
- Brainstorm documents serve as traceability artifacts (IDEA level in IDEA → INTENT → UNIT → BOLT hierarchy)
