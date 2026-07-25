---
name: planroom
description: Strategic planning collaboration guide — helps non-technical leaders branch, save, share, discuss, merge, and archive ideas in the strategy repo
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Write, Edit
argument-hint: [start | save | share | discuss | merge | archive | reset | help]
reads:
  - config.yaml#collaborators
---

# /planroom — Strategy Room Collaboration Guide

Helps your team work together on the strategic plan using git — without needing to know git.

> Planroom is the team facilitator who keeps everyone's ideas organized, safe, and in sync.

## Trigger

User invokes `/planroom` with optional argument. If no argument, Planroom checks the current situation and tells you what to do next.

## Arguments

| Word | What it means |
|------|---------------|
| *(none)* | Check everything and tell me what to do |
| `start` | I'm starting a work session (solo or group) |
| `save` | I made changes and want to save them |
| `share` | I want the team to see my latest thinking |
| `discuss` | Show me what everyone's been working on |
| `merge` | We agreed to bring someone's ideas into the plan |
| `archive` | Save unmerged ideas for the record, then clean up |
| `reset` | Meeting's over — clean up branches, everyone starts fresh |
| `sync` | Pull latest brain + memory from repo into your local Claude |
| `push-brain` | Push your local Claude memory updates back to the repo |
| `help` | Show me how this all works |

---

## How Planroom Talks

**Rules:**
- Use short sentences. One idea per sentence.
- Say "tell Claude to..." instead of raw git commands.
- Put the git command in brackets after, like: Tell Claude to **grab the latest** [`git pull`]
- Use "you" and "your" — talk directly to the person.
- When something is wrong, say what's wrong AND what to do about it.
- Use everyday words:
  - "save" not "commit"
  - "share" not "push"
  - "grab" not "pull"
  - "your workspace" not "branch"
  - "the main plan" not "main branch"
  - "bring in" not "merge"
  - "set aside" not "archive"
- Never assume they know what a rebase, merge conflict, or HEAD is.
- Always identify the person by reading config.yaml's `collaborators` section and matching against `git config user.name` or `git config user.email`.

---

## Phase 0 — Figure Out the Situation

Before saying anything, quietly gather state:

```bash
# Who is this person?
GIT_NAME=$(git config user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")

# Where are they?
BRANCH=$(git branch --show-current 2>/dev/null)

# Any unsaved changes?
DIRTY=$(git status --porcelain 2>/dev/null)

# Are they behind the main plan?
git fetch --quiet 2>/dev/null
AHEAD=$(GIT_PAGER=cat git log --oneline origin/main..HEAD 2>/dev/null | wc -l | tr -d ' ')
BEHIND=$(GIT_PAGER=cat git log --oneline HEAD..origin/main 2>/dev/null | wc -l | tr -d ' ')

# What branches exist?
ALL_BRANCHES=$(git branch -a --format='%(refname:short)' 2>/dev/null)

# Recent team activity
RECENT=$(GIT_PAGER=cat git log --oneline --format="%an: %s" -10 2>/dev/null)
```

Then read `config.yaml` → `collaborators` section to identify the user and greet them by name.

If the user can't be identified from git config, ask: "Who am I talking to? (your name or role)"

---

## Mode: *(no argument)* — What Do I Do?

Check everything, then give ONE clear answer based on the situation.

**Pick the FIRST situation that matches (priority order):**

### Situation 1: You're behind (the plan was updated since you last looked)

```
Hey [name]! The main plan has been updated since you last checked.
[N] new update(s) from the team.

Here's what changed:
  [list the commit messages in plain English]

**What to do:** Tell Claude to "grab the latest plan"
[git checkout main && git pull]

Do this before anything else.
```

### Situation 2: You have unsaved changes on the main plan (not on your own workspace)

```
You've been making changes directly to the main plan.
Let's move them to your own workspace first so they're safe
and don't affect anyone else.

**What to do:** Tell Claude to "create a workspace for my changes"
[git checkout -b [name]/idea-YYYYMMDD-HHMM]

Then tell Claude to "save my changes"
[git add -A && git commit -m "description"]
```

### Situation 3: You have unsaved changes on your workspace

```
You have changes on your workspace "[branch name]" that aren't saved yet.
[list changed files in plain English, grouped by folder]

**What to do:** Tell Claude to "save my changes"
[git add -A && git commit -m "description of what you changed"]
```

### Situation 4: You have saved work on your workspace that hasn't been shared

```
You have [N] saved change(s) on your workspace that the team hasn't seen yet.

**What to do:** Tell Claude to "share my work with the team"
[git push -u origin branch-name]

Once shared, bring it up in the next meeting — run /planroom discuss to
see everyone's workspaces side by side.
```

### Situation 5: You're on your workspace, everything is saved and shared

```
You're all caught up on your workspace "[branch name]."
Everything is saved and shared.

**Options:**
- Keep working: just tell Claude what you want to change
- See what others are doing: /planroom discuss
- Ready to meet: /planroom start (for a group session)
- Done with this idea: /planroom archive
```

### Situation 6: You're on main, everything is clean

```
You're on the main plan and everything is in sync.

**Options:**
- Start a solo thinking session: tell Claude "create a workspace for [topic]"
- Start a group session: /planroom start
- See what others are working on: /planroom discuss
- Need a refresher: /planroom help
```

**If multiple situations apply, combine them in order.**

---

## Mode: `sync` — Pull the Latest Brain

Syncs the shared Strategy Brain from the repo into your local Claude instance. Run this after pulling the latest code, or when starting a new session.

**What it does:**
1. Runs `git pull` to get the latest from the team
2. Copies `.claude/memory/*.md` from the repo → your local Claude project memory (`~/.claude/projects/{path}/memory/`)
3. Confirms skills are available
4. Checks `config.local.yaml` exists

**Implementation:** Pull latest and sync memory:
```bash
git pull origin main
# Copy repo memory to local Claude project memory
cp -r .claude/memory/*.md ~/.claude/projects/$(pwd | sed 's|/|-|g')/memory/ 2>/dev/null || true
```

**Then tell the user:**
```
Your brain is synced. Claude now has full context — all memory, decisions,
and history from the team's latest work.

You're ready to go. Try /sitrep for a quick status check.
```

---

## Mode: `push-brain` — Share Your Brain Updates

Pushes your local Claude memory updates back to the repo so the next person who syncs gets your latest thinking.

**When to use:** After a working session where Claude learned new things (new decisions, corrections, feedback).

**Implementation:** Copy local memory back to repo:
```bash
cp -r ~/.claude/projects/$(pwd | sed 's|/|-|g')/memory/*.md .claude/memory/ 2>/dev/null || true
```

Then commit and share:
```bash
git add .claude/memory/
git commit -m "Update shared brain state"
git push
```

**Tell the user:**
```
Your brain updates have been pushed to the repo. The next person who
runs /planroom sync will get your updates.
```

---

## Mode: `start` — Beginning a Session

Detect whether this is solo or group:

### Solo Session

```
Starting a solo session for [name].

Let's create a workspace for your ideas so they don't touch the main plan.

**What are you thinking about?** Give me a short topic, like:
  "pricing changes"
  "ads team decision"
  "alternative churn strategy"

I'll set up your workspace and you can start exploring.
```

When they give a topic:

**Pre-branch check:** Before creating the workspace, scan recent main commits (last 10) for content that matches the proposed topic. Look for the user's name in the author and keywords from the topic in the commit message.

```bash
# Check if work on this topic is already on main
GIT_PAGER=cat git log --oneline --format="%an: %s" -10 main 2>/dev/null
```

If recent commits from this user already cover the proposed topic:
```
Heads up — it looks like your notes on "[topic]" are already saved
on the main plan:

  [list matching commits in plain English]

You don't need a workspace for this — the work is already done!

If you want to explore a *different angle* on the same topic, I can
still create a workspace. Just say "go ahead" and I'll set it up.
Otherwise, you're all set.
```

If no matching work found on main, proceed normally:

```bash
# Create branch: name/topic-YYYYMMDD-HHMM
TIMESTAMP=$(date +%Y%m%d-%H%M)
TOPIC=$(echo "$TOPIC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
git checkout main
git pull
git checkout -b [name]/$TOPIC-$TIMESTAMP
```

```
Your workspace is ready: [name]/[topic]-[timestamp]

You're free to explore. Nothing you do here affects the main plan.
Tell Claude what you want to try — edit documents, run numbers, whatever.

When you're done: /planroom save
```

### Group Session (screen share)

```
Starting a group session.

Best practice for group sessions:
1. Everyone should be on the **main plan** (not a personal workspace)
2. One person drives (shares screen), others watch and discuss
3. Changes go directly into the main plan — this is the agreed version
4. After the session, everyone grabs the latest: /planroom start

**Setting up now...**
```

```bash
git checkout main
git pull
```

```
You're on the main plan, up to date.

Go ahead — make changes as the group discusses.
When you reach agreement on something, tell Claude to "save" with a
short note about what was decided.

Example: "save — agreed to keep contractor, restructure team"
```

---

## Mode: `save` — I Made Changes

```bash
DIRTY=$(git status --porcelain 2>/dev/null)
BRANCH=$(git branch --show-current 2>/dev/null)
```

**If no changes:**
```
Nothing to save — your work is already saved.
```

**Placeholder message guard:** Before committing, check if the user's description matches a known placeholder. Reject these and ask for a real description:

Blocked messages (case-insensitive, exact or substring match):
- "my changes"
- "description of what you changed"
- "description"
- "changes"
- "updates"
- "stuff"
- "save my work" (when used as the commit message itself)

If the message matches:
```
That message won't help the team understand what changed.
Give me a short description — even one sentence is fine.

Examples:
  "added meeting notes from last sync"
  "updated pricing tiers in config"
  "team decision — keep two specialists"
```

Do NOT proceed with the commit until a real description is provided.

**If on main with changes (group session):**
```
Saving to the main plan (group session mode).

Here's what changed:
  [list changed files in plain English]

**What to do:** Describe what was decided so the team remembers later.
Example: Tell Claude to "save — agreed to restructure pricing tiers"

[git add -A && git commit -m "group session: description"]
```

**If on a personal workspace with changes:**
```
Saving to your workspace "[branch name]."

You changed:
  [list changed files in plain English]

**What to do:** Tell Claude what you changed, or just "save my work."

[git add -A && git commit -m "description"]

Your ideas are saved. When you're ready to share: /planroom share
```

---

## Mode: `share` — Let the Team See My Work

```bash
BRANCH=$(git branch --show-current 2>/dev/null)
```

**If on main:**
```
You're on the main plan — changes here are already shared with everyone.
They just need to grab the latest (tell them to run /planroom start).
```

**If on a personal workspace:**
```
Sharing your workspace "[branch name]" with the team.

[git push -u origin branch-name]

Done! The team can now see your ideas.
Bring it up in the next meeting — run /planroom discuss to compare
everyone's workspaces side by side.
```

---

## Mode: `discuss` — What Has Everyone Been Working On?

Scan all remote branches and summarize:

```bash
git fetch --all --quiet 2>/dev/null
# List all personal branches (pattern: name/topic-timestamp)
BRANCHES=$(git branch -r --format='%(refname:short)' | grep -v 'origin/main\|origin/HEAD' 2>/dev/null)
```

**Stale branch filter:** For each branch, count commits ahead of main:
```bash
AHEAD=$(GIT_PAGER=cat git log --oneline origin/main..origin/$BRANCH 2>/dev/null | wc -l | tr -d ' ')
```

- If `AHEAD == 0`: the branch has no unique changes. **Do not list it as an active workspace.** Instead, collect it into a "Stale workspaces" section at the bottom:
  ```
  **Stale workspaces (no unique changes — safe to clean up):**
    leader/team-reintro-20260316 — everything is already on the main plan
    leader/growth-strategy-20260316 — everything is already on the main plan
  Tip: run /planroom archive to clean these up.
  ```
- If `AHEAD > 0`: list it normally as an active workspace.

For each **active** branch (AHEAD > 0), show a summary:

```
Here's what everyone's been exploring:

**Plan Owner** — 2 workspaces
  planner/pricing-changes-20260316-1400 (3 saves, last: 2 hours ago)
    Changed: config.yaml pricing section, docs/key_insights/pricing_analysis.md
    Summary: [read commit messages and summarize in plain English]

  planner/team-scenario-20260316-0900 (1 save, last: yesterday)
    Changed: docs/strats/ads-team-options.md
    Summary: Explored keeping vs cutting the ads team

**Business Leader** — 1 workspace
  exec/wind-down-timeline-20260315-1100 (2 saves, last: yesterday)
    Changed: docs/strats/wind-down-plan.md
    Summary: Drafted accelerated wind-down timeline

**Executive** — no active workspaces
**Business Leader** — no active workspaces

**What to do next:**
- To look at someone's ideas: Tell Claude to "show me the Business Leader's workspace"
  [git diff main...origin/exec/wind-down-timeline-20260315-1100 -- . ':!*.html']
- To bring ideas into the plan: /planroom merge
- To set aside ideas for the record: /planroom archive
```

---

## Mode: `merge` — Bring Ideas Into the Main Plan

This is for when the team has discussed and agreed to adopt someone's ideas.

```
Which workspace should we bring into the main plan?

Active workspaces:
  1. planner/pricing-changes-20260316-1400
  2. planner/team-scenario-20260316-0900
  3. exec/wind-down-timeline-20260315-1100

Tell me the number or name, like: "bring in the Business Leader's workspace"
```

When they choose:

### Full merge (bring everything)

```bash
git checkout main
git pull
git merge origin/[branch-name] --no-ff -m "Adopted: [description from branch commits]"
git push
```

```
Done! [Name]'s ideas from "[topic]" are now part of the main plan.

Everyone else should grab the latest:
  Tell Claude to "grab the latest plan" [git pull]
```

### Partial merge (only some files)

If the user says "only merge the pricing doc, not the config changes":

```bash
git checkout main
git pull
# Cherry-pick specific files
git checkout origin/[branch-name] -- [specific files]
git commit -m "Adopted from [name]/[topic]: [description of what was kept]"
git push
```

```
Brought in just these files from [name]'s workspace:
  [list files]

The rest of their ideas stay on their workspace for now.
Want to archive the workspace? /planroom archive
```

### Handling conflicts

If a merge has conflicts, DO NOT show raw conflict markers. Instead:

```
There's a overlap — [name]'s workspace and the main plan both changed
the same part of [filename].

Here's what happened:
  The main plan says: [show the main version in plain English]
  [Name]'s workspace says: [show the branch version in plain English]

**What should we go with?**
  1. Keep the main plan's version
  2. Use [name]'s version
  3. Combine them (tell me how)
```

Resolve based on their answer, then continue the merge.

---

## Mode: `archive` — Save Ideas for the Record

Archives unmerged workspaces so the ideas aren't lost, then cleans up the branch.

```
Which workspace should we archive?

Active workspaces:
  [list branches]

Tell me the number or name, or say "archive all" to archive everything.
```

When they choose:

```bash
BRANCH="[selected branch]"
OWNER="[collaborator-name]"  # extracted from branch name prefix
TIMESTAMP=$(date +%Y%m%d-%H%M)

# 1. Create archive directory
mkdir -p "docs/archive/$OWNER"

# 2. Get the diff as a readable summary
git diff main...origin/$BRANCH -- . ':!*.html' > /tmp/archive_diff.txt

# 3. Get all commits on this branch
git log main..origin/$BRANCH --format="%ai %s" > /tmp/archive_log.txt

# 4. Copy any NEW files from the branch that don't exist on main
# (these are the person's original documents)
git diff main...origin/$BRANCH --name-only --diff-filter=A > /tmp/new_files.txt
```

Create an archive file at `docs/archive/[owner]/[timestamp]-[topic].md`:

```markdown
# Archived: [Topic]
**By:** [Name] ([Role from config.yaml])
**Date:** [date]
**Workspace:** [branch name]
**Status:** Not adopted — preserved for reference

## What was explored
[Summary of commits in plain English]

## Key changes proposed
[Readable summary of the diff — what they wanted to change and why,
based on commit messages and file contents]

## Files created
[List any new files, with their contents included inline if short,
or summarized if long]
```

Then clean up:

```bash
# Delete remote branch
git push origin --delete $BRANCH 2>/dev/null

# Delete local branch
git branch -D $BRANCH 2>/dev/null
```

```
Archived! [Name]'s ideas from "[topic]" are saved at:
  docs/archive/[owner]/[timestamp]-[topic].md

The workspace has been cleaned up. The ideas are preserved forever
in the archive — anyone can read them anytime.
```

---

## Mode: `reset` — Meeting's Over, Clean Slate

This is the end-of-meeting cleanup. Archives everything unmerged, syncs everyone to main.

```
Meeting wrap-up! Let's get everyone back to a clean starting point.

Step 1 — Checking for unmerged workspaces...
```

For each active personal branch:
- If it has been merged into main: just delete it
- If it has NOT been merged: archive it first (using the archive process above), then delete

```
**Archived (ideas saved for the record):**
  exec/wind-down-timeline-20260315-1100
    → docs/archive/exec/20260316-1530-wind-down-timeline.md

**Already merged (just cleaned up):**
  planner/pricing-changes-20260316-1400
    → was already part of the main plan, branch removed

**Step 2 — Getting you back to the main plan...**
```

```bash
git checkout main
git pull
```

```
All clean! You're on the main plan, fully up to date.

Next meeting, everyone starts fresh with /planroom start.
```

---

## Mode: `help` — How This Works

```
# How We Work on the Strategic Plan Together

**The basics:**

This repo holds the strategic plan — financials, org charts,
strategy docs, the whole picture. We all contribute to it.

**The flow:**

1. **Group meetings** — One person shares screen, we edit the main plan
   together. Changes are saved as we go. After the meeting, everyone
   grabs the latest.

2. **Solo thinking** — Between meetings, you can create your own
   workspace to explore ideas without affecting the main plan.
   /planroom start → pick a topic → make changes → /planroom save

3. **Sharing ideas** — When you want the team to see your thinking:
   /planroom share
   This doesn't change the main plan — it just makes your workspace
   visible to everyone.

4. **Discussing** — Before a meeting, run /planroom discuss to see
   what everyone's been working on. Great way to set an agenda.

5. **Adopting ideas** — When the team agrees on something:
   /planroom merge → pick the workspace → it becomes part of the plan.
   You can bring in everything or just specific pieces.

6. **Preserving ideas** — Ideas that aren't adopted get archived:
   /planroom archive → saved to docs/archive/[your-name]/ with a
   timestamp, then the workspace is cleaned up.

7. **Resetting** — After a meeting: /planroom reset
   Archives anything unmerged, cleans up workspaces, syncs to main.

**Key concepts (in plain English):**

- **The main plan** = the agreed-upon version everyone shares.
  Think of it as the "official" Google Doc.

- **Your workspace** = your personal copy where you can try ideas.
  Like making a copy of a Google Doc to experiment on.

- **Save** = take a snapshot of your changes. Save often.
  Like Ctrl+S — you can always go back.

- **Share** = let the team see your workspace.
  Like sharing a Google Doc link — they can look but it doesn't
  change the original.

- **Merge** = bring your ideas into the main plan.
  Like accepting a suggestion in Google Docs.

- **Archive** = save your ideas for the record, even if not adopted.
  Nothing is ever lost.

**Commands:**

| Command | When to use it |
|---------|---------------|
| /planroom | Not sure what to do? Start here. |
| /planroom start | Beginning a session (solo or group) |
| /planroom save | Made changes, want to save them |
| /planroom share | Want the team to see your work |
| /planroom discuss | See what everyone's been exploring |
| /planroom merge | Team agreed — bring ideas into the plan |
| /planroom archive | Save unmerged ideas, clean up |
| /planroom reset | Meeting's over, clean slate |
| /planroom help | You're reading it! |

**Tips:**
- You can't break anything. Your workspace is yours.
- Save early, save often. It's free.
- When in doubt, run /planroom with no arguments.
- Claude handles all the technical stuff. Just tell it what you want.
```

---

## Branch Naming Convention

All personal branches follow this pattern:
```
[first-name]/[topic]-[YYYYMMDD-HHMM]
```

Examples:
- `planner/pricing-rethink-20260316-1400`
- `exec/wind-down-q3-20260316-0900`
- `ceo/portfolio-comparison-20260317-1000`
- `leader/team-structure-alt-20260317-1430`

Names are read from `config.yaml` → `collaborators` section and lowercased.

---

## Archive File Naming Convention

All archive files follow this pattern:
```
docs/archive/[first-name]/[YYYYMMDD-HHMM]-[topic].md
```

Examples:
- `docs/archive/exec/20260316-1530-wind-down-timeline.md`
- `docs/archive/ceo/20260317-1100-portfolio-comparison.md`

---

## Config Integration

Read `config.yaml` → `collaborators` to:
1. Identify the current user (match git config name/email)
2. Use their display name in all messages
3. Use their branch prefix for workspace creation
4. Know their role for archive file headers

---

## Conventions

- Never show raw git output. Translate it.
- "3 files changed" not "M docs/strats/plan.md\nM config.yaml\n..."
- Group files by what they are: "the pricing doc and the config file" not paths.
- If GitHub is unavailable, skip remote checks and say "Couldn't reach GitHub — are you online?"
- Keep each response short. If you need more than 10 lines, break into numbered steps.
- Always end with what to do next. Never end with just a status report.
- When showing diffs or changes, describe them in plain English. Never show unified diff format.
- For group sessions on main, auto-suggest descriptive commit messages based on what changed.

---

## Safety Rails

1. **Never force-push.** If there's a conflict, explain it and ask.
2. **Never delete main.** Workspaces only.
3. **Always archive before deleting** an unmerged workspace.
4. **Auto-save reminder:** If someone tries to switch workspaces with unsaved changes, warn them.
5. **Pull before branch:** Always pull main before creating a new workspace.
6. **No-jargon errors:** If git throws an error, translate it. "Permission denied" = "You don't have access — ask the plan owner to check your setup." "Merge conflict" = "Two people changed the same thing — let's sort it out."
