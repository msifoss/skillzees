---
name: qb
description: Log questions for Bryant (Group CEO / interim BUL). Deduplicates, categorizes, prioritizes, and optionally consults /exec-review for strategic questions.
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Skill, Agent
argument-hint: "<question or topic>"
---

# /qb — Questions for Bryant

Log, categorize, and manage questions for Bryant (Group CEO, interim BUL at 97 Display, passing torch to Todd). Questions accumulate between meetings and are reviewed in aggressive March cadence, then biweekly.

## Trigger

User invokes `/qb <question>` with a question, topic, or concern.

Special modes:
- `/qb` (no args) — Show current batch summary
- `/qb review` — Review all pending questions, suggest priority order for next meeting
- `/qb answered <QB-ID> <notes>` — Mark a question as answered with brief notes
- `/qb defer <QB-ID>` — Move to deferred
- `/qb archive` — Move all ANSWERED/DEFERRED to archive section

## Process

### Step 1 — Read Current State
Read `docs/strats/questions4bryant.md` to understand:
- What questions already exist (avoid duplicates)
- Current categories and priorities
- What's been answered recently (context)

### Step 2 — Check for Duplicates
Compare the new question against all existing questions (current + archive). If a similar question exists:
- If it's in current batch: note it and ask if user wants to update/merge
- If it's in archive with an answer: surface the answer — it may already be resolved
- If it's genuinely new: proceed

### Step 3 — Categorize
Assign one category:
- **FIN** — Financial (COGS, budgets, QSR, contracts, pricing)
- **OPS** — Operational (platform access, vendors, team decisions, processes)
- **STR** — Strategic (merger, investments, direction, positioning, major pivots)
- **TECH** — Technical (infrastructure, 97CMS, platform architecture, tooling)

### Step 4 — Assess Priority
- **PRIORITY** — Blocks a decision, time-sensitive, or needed before next QSR/meeting
- **NEW** — Important but not blocking anything right now

### Step 5 — Strategic Check
If the question involves:
- Changing strategic direction
- Challenging an assumption Bryant/Todd have made
- A recommendation that seems off-base or risky
- A major investment or cost decision

Then flag: *"This question touches strategy. Want me to run it through /exec-review first to sharpen the framing?"*

Only invoke /exec-review if the user confirms. Most questions are straightforward and don't need a panel.

### Step 6 — Ask Clarifying Questions (if needed)
If the question is vague or missing context:
- Ask for specifics (dollar amounts, dates, names)
- Ask what decision this question enables
- Ask what Chris already knows vs. what Bryant uniquely can answer

Keep it brief — 1-2 clarifying questions max. Don't interrogate.

### Step 7 — Log the Question
Add to the **Current Batch** section of `docs/strats/questions4bryant.md` in this format:

```markdown
### QB-[NNN]: [Short title]
**Status:** NEW | PRIORITY | RAISED | ANSWERED | DEFERRED
**Category:** FIN | OPS | STR | TECH
**Date added:** YYYY-MM-DD
**Impact $:** [Dollar amount at stake — annual if recurring, one-time if not. Use "TBD" if unknown. Helps prioritize.]
**Related:** [QB-NNN, QB-NNN — linked questions on the same topic]
**Owner:** [Who follows up — defaults to Chris unless someone else is better positioned]
**Question:** [The question, clearly framed for Bryant]
**Context:** [Why this matters — 1-2 sentences max. Reference related docs if relevant.]
**Enables:** [What decision or action this answer unlocks]
**Meeting:** [Blank until raised. Then: date of meeting where it was discussed.]
**Date answered:** [Blank until answered.]
**Notes:**
```

Number sequentially (QB-001, QB-002, etc.). Check the file for the last used number.

### Step 8 — Confirm
Show the user the logged question and ask if the framing is right. Bryant is a CEO — questions should be:
- Concise (not paragraphs)
- Decision-oriented (not FYI)
- Framed with context he needs (not internal jargon he wouldn't know)
- Clear about what answer is needed (yes/no, a number, a decision, an introduction)

## Review Mode (`/qb review`)

When invoked with `review`:
1. Read all current batch questions
2. Group by category
3. Suggest priority order for the next meeting
4. Flag any questions that may be obsolete (check if they've been answered by recent work)
5. Estimate meeting time needed (1-2 min per question)
6. Output a clean agenda format Bryant can scan in 30 seconds

## Answer Mode (`/qb answered <ID> <notes>`)

1. Find the question by ID
2. Change status to **ANSWERED**
3. Add the answer/notes
4. Set **Date answered:** to today
5. Set **Meeting:** if it was answered in a meeting
6. Check if the answer affects any config.yaml values or strategic plan assumptions — if so, flag for update
7. Check if the answer resolves any **Related** questions — if so, flag those too

## Archive Mode (`/qb archive`)

1. Move all ANSWERED and DEFERRED questions from Current Batch to Archive
2. Archive format: same as current but grouped by meeting date
3. Keep the Current Batch section clean for the next round

## Quality Standards

- **Frame for Bryant, not for Claude.** Bryant is a CEO transitioning out. Questions should be clear, actionable, and respect his time.
- **Reference docs.** If a question arose from specific analysis, link to it: "Per the COGS breakdown in docs/key_insights/hosting_cost_matrix.md..."
- **One question per entry.** If a topic has sub-questions, break them out or note them as follow-ups.
- **Don't over-categorize.** If it's borderline FIN/STR, pick the one that matters more.
- **Track what the answer enables.** This makes it easy to prioritize — questions that block $100K decisions outrank curiosity questions.
