---
name: changeloggy
description: Date-bucketed git activity analysis across one or more repos, exec-level reports with follow-up Q&A, and a running reference log for cross-session continuity
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch
argument-hint: "[start-date] [end-date] [--repos repo1,repo2] [--audience exec|team|technical] [--cross-repo]"
---

# /changeloggy — Date-Bucketed Activity Report with Reference Log

Analyzes git history across a date range, produces a date-bucketed executive report, supports iterative Q&A, and maintains a running reference log so future runs have full context on what's already been covered.

> Born from the pattern: "What have we done since March 1?" — a question that requires deep git analysis, chronological bucketing, key metrics, and follow-up dialogue. This skill captures that entire workflow.

## Trigger

- `/changeloggy` — Current repo, last report date to today (or last 30 days if first run)
- `/changeloggy 2026-03-01 2026-04-05` — Explicit date range
- `/changeloggy --cross-repo` — Scan all repos with activity in range
- `/changeloggy --audience technical` — Technical-depth report (default: exec)
- `/changeloggy --repos 98agents,crm98,webengine` — Specific repos

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `start-date` | Start of date range (YYYY-MM-DD) | Last report end date, or 30 days ago |
| `end-date` | End of date range (YYYY-MM-DD) | Today |
| `--repos` | Comma-separated repo names | Current repo only |
| `--audience` | `exec`, `team`, or `technical` | `exec` |
| `--cross-repo` | Auto-discover all repos with activity | Off |
| `--no-qa` | Skip the Q&A loop, just produce the report | Off |

---

## Phase 1: Setup & Discovery

### Step 1.1: Parse Arguments and Resolve Date Range

Parse the invocation arguments into `start_date` and `end_date`.

**Auto-detect start date:** If no start date provided, check for the most recent activity log:

```bash
ls -t docs/activity-logs/????????-????-activity-report.md 2>/dev/null | head -1
```

If a previous report exists, read its frontmatter for `end_date` and use that as the new `start_date`. If no previous report exists, default to 30 days ago.

**Resolve audience:** Default `exec`. The audience controls detail level throughout:

| Audience | Commit detail | Code references | Metrics depth | Jargon level |
|----------|--------------|-----------------|---------------|--------------|
| `exec` | Grouped by theme | None | Key metrics table | Plain English |
| `team` | Grouped by date | File-level | Extended metrics | Some technical |
| `technical` | Individual commits | Line-level | Full stats | Full technical |

Report: "Analyzing activity from **{start_date}** to **{end_date}**, audience: **{audience}**"

### Step 1.2: Determine Repo Scope

**Single-repo (default):** Use the current working directory.

**Explicit repos (`--repos`):** For each named repo, check sibling directories:
```bash
for repo in $REPOS; do
  ls -d "../${repo}" ~/repos/"${repo}" 2>/dev/null | head -1
done
```

**Auto-discovery (`--cross-repo`):** Two-pass approach:

**Pass 1 — Config-driven (fast):** Check CLAUDE.md, config.yaml, or related project files for declared related repos:
```bash
grep -i "pillar\|related.*repo\|sibling" CLAUDE.md config.yaml 2>/dev/null
```

**Pass 2 — GitHub API (comprehensive):** Scan all user repos for activity in the date range:
```bash
gh api "/user/repos?per_page=100&sort=pushed&direction=desc&affiliation=owner" \
  --jq '.[].name'
```

For each repo, check for commits:
```bash
gh api "/repos/{username}/{repo}/commits?author={username}&since={since_iso}&until={until_iso}&per_page=1" \
  --jq 'length' 2>/dev/null
```

**Smart suggestion:** If running single-repo mode but CLAUDE.md references other repos (pillars, dependencies), ask:

> "This repo references {related_repos}. Should I include those in the report? (y/N)"

GATE: At least one repo with commits in range must exist. If none found, report "No activity found in the date range" and stop.

### Step 1.3: Check for Previous Activity Logs

Read the activity log index if it exists:

```bash
cat docs/activity-logs/INDEX.md 2>/dev/null
```

This gives context on what's already been reported. Note any overlap with the current date range — the report should focus on NEW activity, not re-cover old ground.

---

## Phase 2: Git Analysis

### Step 2.1: Collect Raw Data Per Repo

For each repo in scope, gather:

**Commit log with dates and stats:**
```bash
git -C {repo_path} log --since="{start_date}" --until="{end_date_plus_1}" \
  --format="%h %ad %s" --date=short --reverse
```

**Aggregate stats:**
```bash
git -C {repo_path} log --since="{start_date}" --until="{end_date_plus_1}" \
  --shortstat --format="" | awk '{ins+=$4; del+=$6; files+=$1} END {print files, ins, del}'
```

**Commit count:**
```bash
git -C {repo_path} log --since="{start_date}" --until="{end_date_plus_1}" \
  --format="%h" | wc -l
```

**Commits per day:**
```bash
git -C {repo_path} log --since="{start_date}" --until="{end_date_plus_1}" \
  --format="%ad" --date=short | sort | uniq -c | sort -rn
```

**Active contributors:**
```bash
git -C {repo_path} log --since="{start_date}" --until="{end_date_plus_1}" \
  --format="%aN" | sort -u
```

### Step 2.2: Identify Themes and Milestones

Read through commit messages and identify:

1. **Feature themes** — group related commits into logical deliverables
2. **Milestones** — look for keywords: "E2E", "production", "deploy", "launch", "complete", "working"
3. **Bolt/sprint references** — extract bolt numbers, sprint names, or version tags
4. **Breaking changes** — look for "breaking", "migrate", "refactor"
5. **Bug fix clusters** — sequential fix: commits often indicate integration work

### Step 2.3: Date Bucketing

Group all activity into chronological buckets. Bucket granularity depends on the date range:

| Range | Bucket size | Example |
|-------|-------------|---------|
| <= 7 days | Per day | "2026-03-29 — Foundation Sprint" |
| 8-30 days | Per day (skip empty) | Same, but only days with commits |
| 31-90 days | Per week | "Week of Mar 29 — Foundation & Deploy" |
| 91+ days | Per month | "March 2026 — Platform Bootstrap" |

Each bucket gets:
- A descriptive title (derived from dominant theme)
- Commit count
- Key deliverables (bullet points)
- Metrics (lines changed, files touched)

---

## Phase 3: Report Generation

### Step 3.1: Compose the Report

Structure varies by audience:

#### Exec Audience (default)

```markdown
## {Repo Name} — Activity Report
**{start_date} to {end_date}**

### TL;DR
[3-5 bullet points. The absolute essentials.]

### Key Metrics

| Metric | Value |
|---|---|
| Commits | {n} |
| Active days | {n} of {total_days} |
| Lines added | {n} |
| Lines removed | {n} |
| Net new code | {n} |
| {Domain-specific metrics} | {value} |

### Chronological Delivery

#### {date_bucket} — {Theme Title} ({n} commits)

- {Deliverable 1}
- {Deliverable 2}
- {Deliverable 3}

[Repeat for each date bucket]

### Architecture State
[Current state of the system — what's built, what's wired, what's running]

### What's Next
[Forward-looking items derived from TODOs, open issues, or trajectory]
```

**Domain-specific metrics:** Scan the repo for meaningful countable things:
- Agents/services built (look for agent.json, service directories)
- Tests (count test files)
- API endpoints (grep for route definitions)
- Packages/modules (count workspace entries)
- Deployment targets (check deploy configs)
- Security reviews (grep for "review", "audit", "hardening" in commits)

#### Team Audience

Same as exec, plus:
- Individual contributor breakdown
- Blocked/unblocked items
- Dependencies between repos (if cross-repo)
- File-level change summary per bucket

#### Technical Audience

Same as team, plus:
- Individual commit listings per bucket
- File paths and line references
- Architecture diagrams (ASCII)
- API contract changes
- Schema migrations
- Dependency updates

### Step 3.2: Cross-Repo Report (if multiple repos)

When reporting across repos, add:

```markdown
## Cross-Repo Summary
**{start_date} to {end_date}** | {n} repos | {total_commits} commits

### Repo Overview

| Repo | Role | Commits | Net Lines | Key Milestone |
|---|---|---|---|---|
| {repo} | {purpose} | {n} | {n} | {milestone} |

### Timeline (All Repos)

#### {date_bucket}

**{repo1}:**
- {deliverable}

**{repo2}:**
- {deliverable}

### Cross-Repo Dependencies
[How work in one repo enabled or blocked work in another]

### Integration Points
[Where repos touch — APIs, shared types, event contracts, deploy dependencies]
```

### Step 3.3: Present to User

Output the full report to screen. Do NOT save yet — the Q&A phase may refine it.

---

## Phase 4: Q&A Loop

**Skip if `--no-qa` flag is set.**

After presenting the report, enter a Q&A loop:

> "Report complete. This will be saved to `docs/activity-logs/` when we're done."
>
> "Questions from stakeholders? Paste them and I'll research answers against the codebase. Type **done** when finished."

### Handling Questions

For each question or batch of questions:

1. **Research the codebase** — use Agent (Explore subtype) to investigate code, not just git history. The value is in giving answers backed by actual implementation state.
2. **Answer with specifics** — file paths, function names, actual behavior (not theoretical).
3. **Flag unknowns honestly** — if a question requires information outside this repo (operational plans, business decisions), say so.
4. **Append Q&A to the report** — each Q&A round gets appended as a section.

### Q&A Report Section

```markdown
### Exec Q&A

**Q: {question}**

{detailed answer with evidence from codebase}

---

**Q: {next question}**

{detailed answer}
```

### Exit Condition

When user types **done**, **save**, **that's it**, or similar — proceed to Phase 5.

---

## Phase 5: Save & Index

### Step 5.1: Create Activity Logs Directory

```bash
mkdir -p docs/activity-logs
```

### Step 5.2: Save the Full Report

**Filename:** `{YYYYMMDD}-{HHMM}-activity-report.md` (using current timestamp)

**Frontmatter:**

```markdown
---
date: {YYYY-MM-DD}
start_date: {start_date}
end_date: {end_date}
repos: [{repo_list}]
audience: {audience}
commits: {total_commits}
lines_added: {total_added}
lines_removed: {total_removed}
---
```

Write the full report (including Q&A) to `docs/activity-logs/{filename}`.

### Step 5.3: Update the Index

Create or update `docs/activity-logs/INDEX.md`:

```markdown
# Activity Log Index

Running index of /changeloggy reports. Each entry links to the full report.

| Date | Range | Repos | Commits | Key Theme | Report |
|---|---|---|---|---|---|
| {YYYY-MM-DD} | {start} to {end} | {repos} | {n} | {theme} | [{filename}](./{filename}) |
```

**Rules:**
- Append new entries at the top (most recent first)
- Keep the table header intact
- If a previous entry covers an overlapping date range, note it but don't remove it

### Step 5.4: Cross-Repo References (if applicable)

When a report covers multiple repos, create a lightweight reference file in EACH repo:

For each repo that was analyzed (other than the current one):

```bash
mkdir -p {repo_path}/docs/activity-logs
```

Write a cross-reference file `{repo_path}/docs/activity-logs/{YYYYMMDD}-{HHMM}-xref.md`:

```markdown
---
type: cross-reference
source_repo: {current_repo}
source_report: docs/activity-logs/{filename}
date_range: {start_date} to {end_date}
---

# Cross-Repo Activity Reference

A comprehensive activity report covering this repo was generated in **{source_repo}**.

**Full report:** `{source_repo}/docs/activity-logs/{filename}`

## This Repo's Summary
{Repo-specific section extracted from the full report}
```

Also update or create `{repo_path}/docs/activity-logs/INDEX.md` with a cross-reference entry.

### Step 5.5: Confirm Save

Report:

```
Saved:
  Report: docs/activity-logs/{filename}
  Index:  docs/activity-logs/INDEX.md updated
  {If cross-repo: Cross-refs written to: {repo1}, {repo2}, ...}

Next run will auto-detect {end_date} as the start date.
```

---

## Phase 6: Staff Panel Consultation (Future Automation)

**This phase runs only when explicitly requested or when the Q&A loop surfaces questions that suggest automation would help.**

Invoke `/staff` with this prompt:

> "We have /changeloggy producing date-bucketed activity reports with interactive Q&A. The exec asks follow-up questions that require deep codebase investigation. We want to automate the Q&A piece so each repo can have its own agent that answers questions about its activity autonomously.
>
> Constraints:
> - Each repo has different domain context (CRM vs agents vs websites)
> - Questions often require cross-repo awareness
> - Answers need to be backed by actual code state, not just git history
> - The human should be able to review/edit before forwarding to the exec
>
> Recommend an architecture for automated Q&A across repos."

Surface the staff panel recommendations to the user.

---

## Quality Standards

### What makes a good /changeloggy report

1. **Date buckets tell a story.** Not just "these commits happened on this day" — group by theme, name the bucket after the narrative ("Foundation Sprint", "Production Hardening").
2. **Metrics that matter.** Don't dump raw git stats. Pick domain-specific metrics: agents built, endpoints wired, security reviews completed.
3. **TL;DR is genuinely useful.** If the exec reads only the TL;DR, they understand the trajectory.
4. **Chronological but not exhaustive.** Skip empty days. Merge low-activity days. The reader shouldn't feel like they're reading a git log.
5. **Q&A answers are backed by code.** Never speculate — investigate. If you can't confirm from the codebase, say "this requires confirmation outside the repo."
6. **Cross-repo reports show connections.** Don't just list repos side by side — show how work in one enabled or depended on another.

### What makes a bad report

- Raw commit listings with no grouping
- Metrics without context ("15,260 insertions" means nothing without "went from zero to production")
- Missing the "so what" — every section should answer "why does this matter"
- Covering the same ground as a previous report without noting what's new
- Q&A answers that are generic or theoretical rather than code-backed

---

## Integration

- **Inputs from:** Git history, CLAUDE.md (for repo context), previous activity logs (for continuity)
- **Outputs to:** `docs/activity-logs/` (reports + index), cross-repo xref files
- **Chains with:** `/staff` (for automation recommendations), `/sitrep` (activity report feeds situation reports), `/exec-review` (activity report as input to strategic review)
- **Consumed by:** Future per-repo agents that auto-answer Q&A against their own codebase

---

## Adaptation Notes

This skill is **flexible** — adapt the report structure to the repo's domain:
- A CRM repo might emphasize API endpoints, schema changes, integration contracts
- A website repo might emphasize pages built, performance metrics, SEO scores
- An agents repo might emphasize workflows, event types, deployment state
- An infrastructure repo might emphasize uptime, deploy frequency, incident count

Read CLAUDE.md at the start to understand the domain and tailor metrics accordingly.
