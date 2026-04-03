---
name: sitrep
description: Situation report — pulls from all project docs to produce a concise executive summary of current state, decisions, open items, costs, timeline, and next actions.
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Agent, Write, Edit
argument-hint: "[focus area] or no args for full sitrep"
---

# /sitrep — Situation Report

Produces a concise, actionable summary of where the 97 Display strategic plan stands right now. Pulls from every relevant document — config, worklogs, trackers, timelines, Bryant questions, memory — and synthesizes into a 1-2 page report.

> Think of this as the briefing doc Chris opens Monday morning, shares with Todd biweekly, and uses to prep for Bryant meetings. Everything important, nothing wasted.

## Trigger

- `/sitrep` — Full situation report across all workstreams
- `/sitrep migration` — Migration-focused report
- `/sitrep bryant` — Bryant meeting prep (open questions + context)
- `/sitrep costs` — Financial summary (COGS, savings, program costs)
- `/sitrep team` — People/task status (who's doing what, what's blocked)
- `/sitrep timeline` — Timeline status (pace, gates, risks)
- `/sitrep week` — This week only — what happened, what's next, what's blocked

## Process

### Step 1 — Gather Current State

Read these files (skip any that don't exist):

**Master config:**
- `config.yaml` — migration_program, search_atlas, cogs_trajectory, financial_model sections

**Worklogs (Q&A sessions):**
- `docs/worklog/*.md` — All worklog files. Check status of each question (OPEN/ANSWERED/DECIDED).

**Trackers:**
- `docs/todo/teamtodo.md` — Scoreboard, active tasks, blocked tasks
- `docs/strats/questions4bryant.md` — Open questions, status, impact

**Strategic docs:**
- `docs/key_insights/migration_detailed_timeline.md` — Phase, week, pace
- `docs/key_insights/results_report_product_spec.md` — Results report status
- `docs/key_insights/strategic_plan_30_60_90.md` — Overall plan status

**Key findings (most recent):**
- `docs/key_findings/` — Glob for most recent files. Read titles and dates to identify what's new since last sitrep.

**Memory:**
- Check MEMORY.md for any recent updates

### Step 2 — Produce the Report

Output format (to screen, not saved to file unless user asks):

```markdown
# SITREP — [Date]

## TL;DR
[3-5 bullet points. The absolute essentials. If Todd reads nothing else, he reads this.]

## Scoreboard
[Pull directly from teamtodo.md scoreboard section]

## Key Decisions Since Last Report
[Table: Decision | Date | Impact | Source doc]

## Open Items Requiring Action
[Table: Item | Owner | Due | Blocked By | Impact $]
Pull from: teamtodo.md (BLOCKED + P0 tasks) + questions4bryant.md (PRIORITY status)

## Financial Snapshot
| Metric | Value | Trend |
|--------|-------|-------|
| Migration program total | $X | — |
| Per-site cost | $X | — |
| Monthly COGS (current) | $X | ↑↓→ |
| Monthly COGS (post-migration) | $X | — |
| Annual savings identified | $X | — |
| Hosting (current vs future) | $X → $X | — |

## Timeline Status
| Phase | Status | Sites Done | Target | On Track? |
Current phase, pace vs plan, next gate date.

## People Status
[Table: Person | Current Focus | Utilization | Blockers/Notes]
Pull from timeline people allocation tables + teamtodo task assignments.

## Risks & Warnings
[Top 3-5 active risks from the risk register. Only those that are currently relevant — not the full list.]

## Bryant Questions Status
[Summary table from questions4bryant.md — how many open, priority, total $ at stake]

## This Week's Priorities
[Top 5 tasks for the coming week, from teamtodo.md P0/P1 items]

## Documents Updated Recently
[List of files modified in the last 7 days, from git or file timestamps]
```

### Step 3 — Focus Area Filtering

If a focus area is specified, produce only the relevant sections:

| Focus | Sections Included |
|-------|------------------|
| `migration` | TL;DR, Scoreboard, Timeline, People (migration roles only), Risks (migration only) |
| `bryant` | TL;DR, Bryant Questions (full detail), Open Items (Bryant-blocked), Financial Snapshot (for context) |
| `costs` | TL;DR, Financial Snapshot (expanded with COGS breakdown), Annual savings, Program costs, Hosting comparison |
| `team` | TL;DR, Scoreboard, People Status (expanded), Blocked tasks, Help needed items |
| `timeline` | TL;DR, Scoreboard, Timeline (expanded with week-by-week), Gates, Pace analysis |
| `week` | TL;DR, This week's completed tasks (from archive), Next week's priorities, Blocked items, Scoreboard |

### Step 4 — Save Option

If user says "save it" or "log it":
- Save to `docs/sitreps/YYYYMMDD-HHmm-sitrep.md`
- Create `docs/sitreps/` directory if it doesn't exist
- Add to a running index at `docs/sitreps/README.md`

If not asked to save, output to screen only. Most sitreps are ephemeral — the value is in the current snapshot, not the history. Save only when it's for a Todd update or Bryant meeting prep.

## Quality Standards

### What makes a good sitrep
1. **Scannable in 60 seconds.** TL;DR + scoreboard should tell the story. Everything else is drill-down.
2. **Numbers, not narratives.** "$28K program, $221K/yr savings, 0/549 migrated" beats "we're making good progress on the migration plan."
3. **Blocked items front and center.** If something is stuck, it's in the top 5 lines.
4. **Owner on every item.** No orphan tasks or vague "we need to" language.
5. **Honest about pace.** If we're behind, say so. If we're ahead, say so. Don't hedge.
6. **Links to source docs.** Every claim should be traceable to a worklog, key finding, or config section.

### What makes a bad sitrep
- Rehashing decisions already made (that's what the worklog is for)
- Including every task (that's what the tracker is for)
- Optimistic framing of bad numbers
- No action items (sitrep should always end with "here's what happens next")
- Longer than 2 pages (if it takes more than 2 minutes to read, it's not a sitrep)
