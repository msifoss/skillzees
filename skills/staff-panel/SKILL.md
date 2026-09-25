---
name: staff-panel
description: Staff Engineer Panel — 4 staff engineers + Will Larson (moderator) analyze technical problems behind EZFacility's growth-plan execution (platform decisions, build-vs-buy, scaling, integration risk)
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, EnterWorktree, ExitWorktree
argument-hint: "<technical problem or file path>"
reads: []  # Reads whatever files the user references
---

# /staff-panel — Staff Engineer Panel Analysis

Convene a panel of 4 staff engineers from top tech companies + Will Larson as moderator to independently analyze a technical problem, debate options, and produce a consensus decision with implementation plan.

> Like a real Staff Engineer round-table: each engineer brings their company's culture and battle scars. They disagree, challenge assumptions, find latent bugs, and converge on the smallest change that eliminates the actual risk.

## Trigger

User invokes `/staff-panel <problem>` with a description of the technical problem to analyze.

## Arguments

| Argument | Description |
|----------|-------------|
| `<problem>` | A technical problem, architectural question, or investigation finding to analyze. Can be a sentence, a file path, or a reference to a prior finding. |

Examples:
- `/staff-panel "Should we extract shared code into a Lambda Layer?"`
- `/staff-panel "Our enrichment pipeline has been silently disabled since v1.5.3"`
- `/staff-panel lambdas/analytics_ingestion/analytics_handler.py — the db_exec whitelist is getting complex`
- `/staff-panel F7 from the five-persona review`

---

## Phase 0 — Understand the Problem

### 0a. Setup Review Environment

**Worktree isolation (recommended for code analysis):** If the problem references specific code files, consider using an isolated worktree to avoid disrupting the main working directory:

- If the problem involves reading/analyzing production code, use `EnterWorktree` for isolation
- If the problem is purely strategic/architectural (no code files referenced), proceed in-place
- If Will's decision in Phase 5 includes an implementation plan, suggest executing it in a worktree

### 0b. Check Per-Project Config

```bash
ls .ai-dlc.local.yaml 2>/dev/null
```

If `.ai-dlc.local.yaml` exists, read it for project-specific context that should inform the panel (infrastructure constraints, team topology, deployment model, etc.).

### 0c. Deep Problem Understanding

Before convening the panel, deeply understand the problem:

1. **Read all referenced files** — if the problem mentions files, code, or prior findings, read them in full
2. **Trace the data flow** — understand what calls what, what depends on what, what breaks if X changes
3. **Quantify the impact** — how many users/calls/requests are affected? What's the cost of inaction?
4. **Identify the constraints** — budget, team size, deployment model, existing patterns, timeline
5. **Map the options space** — list 3-6 plausible approaches before the panel convenes
6. **Search past learnings** — check `docs/solutions/` and `docs/captains_log/` for relevant prior decisions

Produce a **Problem Statement** with:
- What's happening (or not happening)
- Why it matters (impact table with metrics)
- Root cause chain (A → B → C → D)
- Constraints that limit the solution space

---

## Phase 1 — Convene the Panel

### The Panelists

Each panelist is a real archetype with a distinct engineering philosophy. They analyze the problem **independently** — do NOT let one panelist's analysis influence another.

#### Tim — Staff Engineer, SpaceX
**Philosophy:** "The best part is no part." Ruthless simplification. Thinks in failure modes and blast radius.
**Strengths:** Risk quantification (Probability x Consequence matrices), eliminating unnecessary complexity, finding the minimal viable fix
**Signature move:** Calculates risk scores for each option, kills the ones with bad ratios
**On abstractions:** Deeply skeptical. Every new layer is a layer that can fail. Prefers explicit over implicit.
**Typical output:** "Fix the 65 dangerous lines. Leave the 650 stable ones alone."

#### Rob — Staff Engineer, Roblox
**Philosophy:** "Deduplicate based on the cost of divergence, not the existence of duplication." Thinks in developer cognitive load and real-world failure modes.
**Strengths:** Finding latent bugs hiding in "harmless" duplication, developer experience, practical risk assessment
**Signature move:** Discovers that what looks like a cosmetic issue is actually a live bug
**On patterns:** Cares about what breaks when copies diverge, not whether copies exist
**Typical output:** "You don't have a code duplication problem. You have a risk prioritization question."

#### Fran — Staff Engineer, Facebook/Meta
**Philosophy:** "Move fast with stable infra." Finds the 80/20 split. Knows when copy-paste is fine and when it's a liability.
**Strengths:** Pragmatic bucketing (dangerous vs aesthetic), CI/CD integration, team scaling patterns
**Signature move:** Sorts everything into "fix yesterday" vs "don't care" with clear criteria
**On enforcement:** "Pre-commit is a developer convenience; CI is the contract."
**Typical output:** Two clean buckets with no ambiguity about which is which.

#### Al — Staff Engineer, AWS (relevant service team)
**Philosophy:** Deep platform knowledge. Has seen thousands of customer architectures. Knows the sharp edges of the services involved.
**Strengths:** Platform-specific expertise, under-documented features, deployment coupling analysis, scaling concerns
**Signature move:** Reframes the problem from a platform perspective ("this is a deployment coupling problem, not a code hygiene problem")
**On architecture:** Thinks in terms of the right long-term pattern, but willing to concede when scope doesn't justify it
**Typical output:** The architecturally correct approach + honest assessment of whether the project needs it yet.

#### Will Larson — Moderator
**Role:** Does NOT analyze the problem independently. Instead:
1. Listens to all four panelists
2. Asks clarifying questions that expose hidden assumptions
3. Identifies where panelists agree and disagree
4. Makes the final ruling with explicit rationale
5. **Challenges wrong assumptions** — if panelists assume something about the codebase (e.g., "no CI pipeline"), verify it before ruling

---

## Phase 2 — Independent Analysis

Each panelist independently produces:

### Per-Panelist Output

```
### [Name] — Staff Engineer, [Company]

**Risk assessment:**
[Their analysis of the problem — what's dangerous, what's not, what breaks]

**Options evaluated:**
[Which options they favor, which they reject, and why]

**Key quote:**
"[One memorable line that captures their position]"

**Recommendation:**
[Their preferred approach + effort estimate]

**On [key debate topic]:**
"[Their position on the main point of contention]"

**Unique contribution:**
[Something only this panelist noticed — a latent bug, a platform edge case, a simpler approach]
```

### Rules for Independent Analysis
- Each panelist MUST have a **unique contribution** — something the others missed
- Panelists CAN disagree — disagreement is valuable signal
- Panelists should reference specific files, line numbers, and code when possible
- Each panelist's recommendation should include an effort estimate
- Platform expertise should be authentic — Al should know Lambda/S3/RDS internals, Tim should think in failure modes, etc.

---

## Phase 3 — Consensus Matrix

After all 4 panelists have spoken, produce a consensus matrix:

```
## Consensus Matrix

| Question | Tim (SpaceX) | Rob (Roblox) | Fran (Meta) | Al (AWS) |
|----------|-------------|-------------|-------------|----------|
| [Key decision 1] | YES/NO | YES/NO | YES/NO | YES/NO |
| [Key decision 2] | YES/NO | YES/NO | YES/NO | YES/NO |
| ...
| Guard mechanism | [their pref] | [their pref] | [their pref] | [their pref] |
| Total effort | [estimate] | [estimate] | [estimate] | [estimate] |

**Unanimous agreements:**
1. [Things all 4 agree on]

**Majority agreements (3-of-4):**
2. [Things 3 agree on, with the dissenter noted]

**Key disagreements:**
3. [Where they split, and on what dimension]
```

---

## Phase 4 — Will Larson's Clarifying Questions

Before ruling, Will asks questions that expose hidden assumptions:

```
### Clarifying Questions & Answers

| Question | Answer | Impact on Decision |
|----------|--------|--------------------|
| [Question about the codebase/infra] | [Verified answer] | [How it changes the calculus] |
```

**IMPORTANT:** Actually investigate the answers. If Will asks "Is there a CI pipeline?", go check. If he asks "How often has this code been modified?", run `git log`. If he asks "Is password rotation enabled?", check the CloudFormation template. Wrong assumptions lead to wrong decisions.

If a clarifying question reveals that a panelist's assumption was wrong, **reconvene the panel** for a reassessment round (Phase 4b).

---

## Phase 4b — Reassessment (if needed)

If Phase 4 reveals wrong assumptions:

1. Present the new information to each panelist
2. Each panelist states whether their recommendation changes
3. Update the consensus matrix
4. Note what changed and why

This phase is what makes the panel valuable — it catches the "we assumed X but actually Y" errors that cause bad architectural decisions.

---

## Phase 5 — Will Larson's Decision

Will synthesizes the panel's input into a final ruling:

```
## Will Larson's Decision

**Scope:** [Which panelist's approach, with whose scope]

| Step | What | Why | Effort |
|------|------|-----|--------|
| 1 | [Specific action] | [Rationale tied to panel finding] | [Time] |
| 2 | ... | ... | ... |

**Total: [hours]. [One-line summary of the approach.]**

### What's explicitly deferred

| Item | Rationale | Revisit When |
|------|-----------|--------------|
| [Rejected option] | [Why, citing which panelist] | [Trigger condition] |

### Key takeaways

> "[Quotable insight from the panel]" — [Panelist]

[2-4 takeaways that generalize beyond this specific problem]
```

---

## Phase 6 — Output Document

Save the full analysis to `docs/captains_log/YYYY-MM-DD-[topic-slug]-staff-panel.md` with this structure:

```markdown
# [Topic] — Staff Engineer Panel Analysis

**Date:** YYYY-MM-DD
**Panel:** Tim (SpaceX), Rob (Roblox), Fran (Meta), Al (AWS), Will Larson (Moderator)
**Trigger:** [What prompted this analysis]

---

## Problem Statement
[From Phase 0]

## Panel Analysis
[From Phase 2 — all 4 panelists]

## Consensus Matrix
[From Phase 3]

## Clarifying Questions
[From Phase 4]

## [Reassessment — if Phase 4b occurred]

## Will Larson's Decision
[From Phase 5]

## Key Takeaways
[Generalizable insights]

## Files Referenced
[Table of files discussed with their roles]

## Implementation Plan
[Numbered steps with file paths, line numbers, effort]

## Findings to Fix
[Numbered findings — each with File, Lines, Description, Fix]
```

---

## Quality Standards

### What makes a good panel analysis

1. **Independent thinking** — each panelist arrives at their position from their own philosophy, not by reacting to others
2. **Unique contributions** — every panelist discovers something the others didn't
3. **Concrete references** — file paths, line numbers, specific code, not vague generalities
4. **Quantified risk** — probability x consequence, not just "this is risky"
5. **Honest disagreement** — panelists should disagree where their philosophies diverge
6. **Assumption verification** — Will's questions actually get investigated, not hand-waved
7. **Minimal viable fix** — the decision should be the smallest change that eliminates the actual risk
8. **Deferred items** — explicitly state what's NOT being done and when to revisit

### What makes a bad panel analysis

- All panelists agree on everything (unrealistic, means the personas aren't differentiated enough)
- Vague recommendations ("improve the architecture") instead of specific actions
- Skipping Will's clarifying questions (the assumption-checking is the most valuable part)
- Over-engineering the solution (the panel should push back on scope creep, not enable it)
- Ignoring cost/effort constraints
- Not actually reading the code being discussed

### Panelist voice calibration

- **Tim** should sound like someone who's shipped rockets — direct, quantitative, zero tolerance for unnecessary complexity
- **Rob** should sound like someone who runs systems at massive scale — practical, bug-hunting, developer-experience focused
- **Fran** should sound like someone from Meta's "move fast" culture — pragmatic bucketing, clear heuristics, CI-focused
- **Al** should sound like an AWS service team engineer — deep platform knowledge, architectural correctness, honest about trade-offs
- **Will** should sound like a VP of Engineering — synthesizing, questioning assumptions, making the call

---

## Adaptation Notes

- **Al's expertise adapts** to the problem domain. If the problem involves databases, Al is from the RDS/Aurora team. If it involves networking, Al is from the VPC team. If it involves containers, Al is from ECS/EKS. Always the AWS service team most relevant to the problem.
- **Panel size is fixed at 4+moderator.** Don't add panelists. The value comes from depth of analysis per persona, not breadth of opinions.
- **The document is the deliverable.** The panel analysis should be self-contained — someone reading it 6 months later should understand the problem, the options, the reasoning, and the decision without additional context.

## Panel roster (spec §7.3)

- **Moderator:** Will Larson
- **Panelists:** Tim (SpaceX), Rob (Roblox), Fran (Meta), Al (AWS)
- Use this skill for technical / platform / build-vs-buy questions inside the EZFacility growth plan. For strategic questions, use `/exec-jam` or `/exec-review`.
