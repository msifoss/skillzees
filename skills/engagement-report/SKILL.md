---
name: engagement-report
description: Leadership engagement report — measures contribution by deliverables, decisions, and accountability across repos. Jim Collins voice. Invokes /exec-review.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, Skill
argument-hint: "[timeframe] [--roles role1,role2] [--names name1,name2]"
---

# /engagement-report — Leadership Engagement Report

Generate a fact-based leadership engagement report from git history across all tracked repos. Measures what matters: deliverables shipped, decisions made, tasks owned, and engagement gaps. Written in Jim Collins' voice — confronting brutal facts with discipline.

> "Greatness is not a function of circumstance. Greatness is largely a matter of conscious choice, and discipline." The report surfaces who is choosing to engage and who is not, without editorializing — the facts speak.

## Trigger

- `/engagement-report` — Since last report to today, default roles
- `/engagement-report 2026-03-16 2026-04-05` — Explicit date range
- `/engagement-report --roles "CGO,BUL"` — Filter to specific roles
- `/engagement-report --names "Todd,Bryant,Chris"` — Include names in output (otherwise roles only)
- `/engagement-report last 14 days` — Natural language timeframe

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `timeframe` | Date range: `YYYY-MM-DD YYYY-MM-DD`, or `last N days`, or `since YYYY-MM-DD` | Since last report (scans `docs/reports/`) |
| `--roles` | Comma-separated roles to include | `CGO, Group CEO / BUL (outgoing), BUL (incoming)` |
| `--names` | Comma-separated names — triggers name+role display in output | Omitted = roles only (per NO NAMES rule) |

## Phase 0 — Determine Timeframe

### 0a. "Since Last Report" Detection

1. Scan `docs/reports/` for files matching `*-engagement-*.md`
2. Sort by filename (date-prefixed, newest first)
3. Parse the end date from the filename slug (e.g., `engagement-mar16-apr05.md` → `2026-04-05`)
4. If no prior report exists, use the earliest commit date across all tracked repos
5. End date is always today unless explicitly specified

```
Example filenames:
  20260405-1300-engagement-mar16-apr05.md  → end date = Apr 5
  20260420-0900-engagement-apr06-apr20.md  → end date = Apr 20
```

### 0b. Load Configuration

Read `config.yaml` for:
- `repos:` — which repos to scan (paths relative to `~/repos/`)
- `collaborators:` — display_name, role, git_names[], git_emails[] for author matching

Verify each repo path exists. Skip repos that don't exist locally with a warning.

### 0c. Resolve Roles and Names

- If `--names` provided: match names to collaborators in config.yaml. Output uses "Name (Role)" format.
- If `--roles` provided: filter to matching roles only
- Default: include all collaborators with git activity in the timeframe. Output uses role only.

---

## Phase 1 — Collect Git Data

For each tracked repo and each collaborator, collect:

### 1a. Activity Metrics

```bash
# For each repo, for each git_name in collaborator's git_names[]:
git log --all --format="%H|%an|%aI|%s" --author="<git_name>" --since="<start>" --until="<end>"
```

Deduplicate across git_name aliases (Bryant has 2).

### 1b. Compute Per-Person Metrics

For each person, compute:

| Metric | How |
|--------|-----|
| **Active Days** | Unique dates with commits (across all repos) |
| **Last Activity** | Most recent commit date |
| **Repos Touched** | Which repos have commits from this person |
| **Deliverables** | Categorize commits into bodies of work (see Phase 2) |
| **Decisions Made** | Commits that unblock, answer, approve, close, or decide |

### 1c. Compute Task Metrics

From `docs/todo/teamtodo.md`:

| Metric | How |
|--------|-----|
| **Open Tasks** | Count rows where person appears as owner AND status is NOT_STARTED or IN_PROGRESS |
| **Overdue Tasks** | Open tasks with due date before today |

---

## Phase 2 — Categorize Deliverables

Do NOT count commits. Group them into deliverables by category:

### For strategy repos (97plan):

| Category | Pattern |
|----------|---------|
| Panel reviews | commit msg contains: panel, exec review, staff panel, fin audit, design panel |
| PRDs | commit msg contains: PRD, prd |
| Dashboards | commit msg contains: dashboard, html, insights, portal, blueprint |
| Meeting notes | commit msg contains: meeting, alignment, kickoff, intro, re-intro |
| Financial analysis | commit msg contains: forecast, EBITA, financial, board, QSR, P&L, COGS |
| Strategy docs | commit msg contains: strategy, STATE, STRATEGY, config, architecture |
| Task management | commit msg contains: todo, triage, task, sprint, close, reassign |
| Hiring/HR | commit msg contains: hire, PPL, candidate, transition, termination, severance |

### For platform repos (crm98, webengine, 98agents):

| Category | Pattern |
|----------|---------|
| Features shipped | commit msg starts with `feat:` |
| Bug fixes | commit msg starts with `fix:` |
| Documentation | commit msg starts with `docs:` |
| Tests | commit msg starts with `test:` |
| CI/CD | commit msg starts with `ci:` |

### Decisions Made

A "decision" is a commit that moved state forward. Match on:
`approved, answered, decided, closed, DONE, resolved, adopted, alignment, GATE, greenlight, restructure, forecast v`

---

## Phase 3 — Build the Report

### Voice: Jim Collins

The report is written in Jim Collins' voice. Key principles:
- **Confront the brutal facts.** State what happened and what didn't. No spin.
- **The Stockdale Paradox.** Maintain faith in the outcome while being ruthlessly honest about the current reality.
- **First Who, Then What.** The people question comes before the strategy question.
- **Culture of Discipline.** Disciplined people don't need to be managed. The report surfaces who is self-managing and who isn't.
- **No adjectives that editorialize.** Don't say "impressive" or "disappointing." Let the numbers speak. The reader draws conclusions.

**Tone:** A board observer's field notes. Factual. Measured. Devastating only because the facts are.

### Report Structure

```markdown
# 97 Display — Leadership Engagement Report

**Period:** [start date] – [end date] ([N] days)
**Source:** Git history across [repo list]
**Generated:** [timestamp]

---

## At a Glance

| Role | Repos | Active Days | Last Activity | Deliverables | Decisions | Open Tasks | Overdue |
|------|------:|------------:|---------------|-------------:|----------:|-----------:|--------:|
| ... | ... | ... | ... | ... | ... | ... | ... |

---

## What Each Role Delivered

### [Role 1]

[1-sentence engagement pattern assessment — factual, not judgmental]

| Deliverable | When |
|-------------|------|
| ... | ... |

**What still needs this role's attention (due in next 7-10 days):**

| Task | Due | Why It Matters |
|------|-----|---------------|
| ... | ... | ... |

[Repeat for each role]

---

### [Role with concentration risk — typically CGO]

[Show the bus factor problem with data]

**The concentration problem:**

| Repo | Contributors | Lines of Code | Bus Factor |
|------|-------------:|--------------:|-----------:|
| ... | ... | ... | ... |

---

## What Matters This Week

[Next 7-10 days. Only tasks that are NOT_STARTED and have real consequences if missed.]

| # | Task | Owner | Due | Consequence of Miss |
|---|------|-------|-----|---------------------|
| ... | ... | ... | ... | ... |

---

## Engagement Gaps

[For any person with >7 days of inactivity, show what milestones they missed]

| Date | Milestone | [Role] Involvement |
|------|-----------|-------------------|
| ... | ... | None / [what they did] |

---

## Appendix: Critical Dates

[Timeline of upcoming dates that matter — terminations, hires, gates, handoffs]
```

---

## Phase 4 — Exec Review

Invoke `/exec-review` with the completed report as context. Ask the panel:

> "Review this leadership engagement report for a vertical SaaS turnaround. Is it fair? Is it missing anything? Are the metrics the right ones? What would Jim Collins add or remove?"

Incorporate the panel's feedback into the final report. Add a brief `## Panel Notes` section at the end with any material additions.

---

## Phase 5 — Save and Offer Commit

### 5a. Save the Report

Save to: `docs/reports/YYYYMMDD-HHMM-engagement-[start-slug]-[end-slug].md`

Date slug format: `marDD` or `aprDD` (lowercase month abbreviation + day).

Examples:
- `20260405-1300-engagement-mar16-apr05.md`
- `20260420-0900-engagement-apr06-apr20.md`

### 5b. Offer Commit

After saving, ask the user:

> "Report saved to `docs/reports/[filename]`. Commit and push? (This anchors the 'since last report' date for next run.)"

If yes: commit with message `Engagement report: [start] to [end]` and push.
If no: report exists on disk but won't anchor the next run's timeframe (warn the user).

---

## Quality Standards

### The report is good if:

1. **A Group CEO can read it in 2 minutes** and know who's engaged, who's not, and what's at risk
2. **A BUL can read their section** and know exactly what's waiting for them, with due dates and consequences
3. **A CGO can use it as evidence** for the single-point-of-failure argument without it reading like a complaint
4. **Every number is derived from git history or the task tracker** — nothing subjective
5. **The Jim Collins voice is consistent** — measured, factual, devastating only because the facts are
6. **No names appear unless `--names` was passed**

### The report is bad if:

- It reads like a performance review (it's an engagement instrument, not HR)
- It uses editorializing adjectives ("impressive output", "disappointing silence")
- Commit counts appear anywhere (deliverables and decisions, never commits)
- It's longer than 2 pages of rendered markdown
- It doesn't include "What Matters This Week" with consequences
- It's unfair to burst-mode contributors (some roles legitimately engage in focused windows)

---

## Adaptation Notes

- **Roles change.** When Todd fully takes over as BUL, update config.yaml roles. The skill reads roles from config, not hardcoded.
- **Repos change.** When new repos are added, add them to `config.yaml > repos`. The skill scans all listed repos.
- **The /exec-review invocation is the expensive part.** If the user wants a quick version without the panel, they can say `/engagement-report --quick` and Phase 4 is skipped.
- **Multiple people can share a role.** If Bryant and Todd are both tagged as BUL variants, the report handles them as separate entries.
