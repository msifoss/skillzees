---
name: repo-activity
description: Summarize today's activity in the current repo (git commits + captain's logs + memory changes + session context) and deposit to weeklyops-prompt workspace with global and per-repo INDEX upkeep. Use when the user says "log today's activity", "/repo-activity", "summarize today's work here", or similar.
---

# /repo-activity — Daily Repo Activity Logger

Summarizes the current user's activity in the current repo for a given day (default: today) and writes it into `~/repos/weeklyops-prompt/workspace/repo-activity/` with dual-index bookkeeping. Re-running on the same day REGENERATES the daily file from scratch (full rebuild — no merge logic, no races).

## Trigger

User invokes `/repo-activity` or asks naturally: "log today's activity", "summarize today's work here", "record what I did in this repo today".

Arguments (optional):
- `YYYY-MM-DD` or `YYYYMMDD` — specify a different day (default: today, local TZ)
- `YYYYMMDD-YYYYMMDD` — range. Each day in the range produces its own daily file.

## Scope (what gets summarized)

v1 captures four signals for the current user, current repo, target day(s):

1. **Git commits** authored by the current user in the repo (local-midnight → 23:59:59 of the target day)
2. **Captain's logs** at `docs/captains_log/*.txt` (or `*.md`) whose filename date prefix matches the target day
3. **Memory changes** — files under `~/.claude/projects/-Users-msichris-repos-{repo}/memory/` with mtime on the target day
4. **Session context** — conversation arc reconstructed from `~/.claude/projects/-Users-msichris-repos-{repo}/*.jsonl` session files modified on the target day. Extract `type:"user"` lines → their `message.content` text → produce a summary of what the user asked for across the day.

All four signals fold into one markdown file per (repo, day).

---

## Phase 1 — Resolve context

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "Not in a git repo. Skill aborts."; exit 1
fi
REPO_NAME=$(basename "$REPO_ROOT")
USER_NAME=$(git config user.name)
USER_EMAIL=$(git config user.email)
TARGET_DAY=${1:-$(date +%Y-%m-%d)}  # normalize input to YYYY-MM-DD
DAY_SLUG=$(echo "$TARGET_DAY" | tr -d '-')    # YYYYMMDD
WEEKLYOPS=~/repos/weeklyops-prompt
ACTIVITY_DIR="$WEEKLYOPS/workspace/repo-activity"
PER_REPO_DIR="$ACTIVITY_DIR/$REPO_NAME"
DAILY_FILE="$PER_REPO_DIR/${DAY_SLUG}-${REPO_NAME}-activity.md"
GLOBAL_INDEX="$ACTIVITY_DIR/INDEX.md"
REPO_INDEX="$PER_REPO_DIR/INDEX.md"
```

If `~/repos/weeklyops-prompt` does not exist, abort with a clear error telling the user to clone it first.

Announce:
```
Logging activity for {REPO_NAME} on {TARGET_DAY}
  → {DAILY_FILE}
```

---

## Phase 2 — Collect signals

### 2a. Git commits

```bash
cd "$REPO_ROOT"
git log --author="$USER_EMAIL" \
    --since="$TARGET_DAY 00:00" \
    --until="$TARGET_DAY 23:59:59" \
    --pretty=format:"%H|%ai|%s" \
    --shortstat \
    > /tmp/repo-activity-commits.txt
```

Also capture total lines added/removed across the day and a files-changed count.

Fall back to `--author="$USER_NAME"` if `--author="$USER_EMAIL"` returns nothing (some repos use just-name commits).

If zero commits today: note that explicitly but don't abort — captain's logs and session context may still have content.

### 2b. Captain's logs

```bash
# Files like docs/captains_log/caplog-YYYYMMDD-HHMM-slug.{txt,md}
find docs/captains_log -maxdepth 2 -type f \
    \( -name "caplog-${DAY_SLUG}*" -o -name "${DAY_SLUG}*caplog*" \) \
    2>/dev/null | sort
```

For each match: extract the filename, the first 3 lines (usually SITREP or summary), and the file size. Do NOT try to read and re-summarize the full log — that's what the captain's log itself is for. Just surface its existence + headline.

### 2c. Memory changes

```bash
MEMORY_DIR=~/.claude/projects/-Users-msichris-repos-${REPO_NAME}/memory
find "$MEMORY_DIR" -maxdepth 2 -type f -name "*.md" \
    -newermt "$TARGET_DAY 00:00" \
    ! -newermt "$TARGET_DAY 23:59:59" \
    2>/dev/null
```

For each: note the file path, what memory type it is (user/feedback/project/reference inferred from filename or frontmatter), and a one-line description from frontmatter `description:` field.

### 2d. Session context

```bash
SESSION_DIR=~/.claude/projects/-Users-msichris-repos-${REPO_NAME}
for jsonl in $(find "$SESSION_DIR" -maxdepth 1 -type f -name "*.jsonl" \
    -newermt "$TARGET_DAY 00:00" \
    ! -newermt "$TARGET_DAY 23:59:59" 2>/dev/null); do

    # Extract user prompts from the JSONL
    python3 - <<PY
import json, sys
for line in open("$jsonl"):
    try:
        d = json.loads(line)
        if d.get("type") == "user":
            msg = d.get("message", {})
            content = msg.get("content", "")
            # content is often a list of blocks; flatten to text
            if isinstance(content, list):
                content = " ".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
            if content and len(content) > 10:
                print(content[:300])
    except Exception:
        continue
PY
done
```

Collect the day's user prompts (one per line, truncated to 300 chars each), dedupe near-duplicates. Feed this bucket into the LLM synthesis step (Phase 3) to produce a "what did I ask Claude to do today?" narrative of 3-8 bullets.

**Size guardrail:** If the total user-prompt volume exceeds ~8000 chars, summarize in chunks rather than one shot. Some days have 200+ prompts.

---

## Phase 3 — Synthesize the daily file

Produce a markdown file with this structure:

```markdown
# {REPO_NAME} — Activity for {TARGET_DAY}

**User:** {USER_NAME} <{USER_EMAIL}>
**Repo:** `{REPO_ROOT}`
**Generated:** {NOW_ISO}

## Headline

{1-2 sentence LLM-synthesized summary of the day. What was the dominant theme? What shipped? What was deferred?}

## Commits ({N})

| Time | SHA | Message | Files | +/- |
|---|---|---|---:|---|
| 02:15 | `1aec76f` | hotfix: bring production up behind Imperva WAF | 12 | +540/-48 |
...

**Totals:** {N} commits, {M} files touched, +{X}/-{Y} lines

### Commit themes

{Grouped by theme if >3 commits. Otherwise flat list of messages.}
- **Production recovery** — {commit shas}
- **Form integration** — {commit shas}
- ...

## Captain's logs ({N})

- `caplog-20260421-2320-production-back-up-imperva-selfsigned-hotfix.txt` — Production recovery hotfix (132 lines)
- `caplog-20260421-2243-...` — ...

## Memory updates ({N})

- `project_production_topology.md` — Imperva → Vultr origin topology with self-signed cert state
- `MEMORY.md` — Updated index

## What I asked Claude today

{LLM-synthesized from user prompts across all sessions open on this day, in rough chronological order. 3-8 bullets. Focus on intent, not tactics — "investigated the Imperva outage and shipped the fix" rather than "ran curl three times".}

- Morning: investigated Imperva Error 8 and restored production via self-signed origin cert
- Midday: wrote robots.txt per-environment deploy logic
- Evening: full HubSpot wiring across 10 forms, including deal creation for checkout

## Sources

- {N} session(s): {list of session file basenames}
- {N} commit(s)
- {N} captain's log(s)
- {N} memory file(s)
```

---

## Phase 4 — Write files + indexes

### 4a. Write daily file

```bash
mkdir -p "$PER_REPO_DIR"
# ALWAYS overwrite — full regenerate per /staff panel Option B
cat > "$DAILY_FILE" <<EOF
{content from Phase 3}
EOF
```

### 4b. Update global INDEX.md

`~/repos/weeklyops-prompt/workspace/repo-activity/INDEX.md` structure:

```markdown
# Repo Activity Index — All Repos

**Last updated:** {NOW_ISO}

Newest first. One row per (date, repo) pair.

| Date | Repo | Commits | Files | Themes | Path |
|---|---|---:|---:|---|---|
| 2026-04-23 | msi-web | 7 | 24 | Bolt 17 redirects, OnMat cleanup, Ahrefs analysis | `msi-web/20260423-msi-web-activity.md` |
| 2026-04-22 | msi-web | 5 | 13 | HubSpot forms bolt, prune outage fix | `msi-web/20260422-msi-web-activity.md` |
...
```

**Update algorithm:**
1. If INDEX.md doesn't exist, create with header + empty table.
2. Parse the table rows. Find any row where (Date, Repo) == (TARGET_DAY, REPO_NAME).
3. If found: replace that row with the regenerated data.
4. If not found: insert a new row in date-DESC order (newest first).
5. Update the "Last updated" line.
6. Rewrite the file.

### 4c. Update per-repo INDEX.md

Same logic, scoped to `$PER_REPO_DIR/INDEX.md`. Only rows for this repo. Columns identical minus the `Repo` column (redundant).

### 4d. Register in manifest.yaml (weeklyops-prompt convention)

Per the target repo's CLAUDE.md rule #2: working files must be tracked in `workspace/manifest.yaml`.

```bash
MANIFEST="$WEEKLYOPS/workspace/manifest.yaml"
# Add an entry for this file if not already present:
# - path: repo-activity/{repo}/{slug}.md
#   type: repo-activity
#   repo: {repo}
#   date: {TARGET_DAY}
#   generated: {ISO}
```

Idempotent: find existing entry by `path`, update `generated` timestamp, or append new. Do not duplicate.

---

## Phase 5 — Output

Print to the user:

```
✓ Wrote /Users/msichris/repos/weeklyops-prompt/workspace/repo-activity/msi-web/20260423-msi-web-activity.md

Today in msi-web:
  7 commits · 24 files · +540/-183 lines
  2 captain's logs · 3 memory updates · 1 session

Indexes updated:
  workspace/repo-activity/INDEX.md
  workspace/repo-activity/msi-web/INDEX.md
```

---

## Behavior rules

### Regenerate, never merge

Every invocation is a full rebuild of the target day's file. Re-running at 3pm overwrites the 10am version. This is intentional — no merge conflicts, no staleness, no concurrency bugs. The commit log + captain's logs + memory + session data are all the source of truth; the file is the derived artifact.

### Idempotent indexes

The INDEX.md updates must be idempotent. Running the skill twice on the same day for the same repo produces the same final index state — one row for that (date, repo), not two.

### Scope to current user

Git commits filtered to `user.email`. Do NOT include commits by other team members in team repos.

### Abort conditions

- Not in a git repo → abort with clear message
- `~/repos/weeklyops-prompt` doesn't exist → abort, tell user to clone
- Target day is in the future → abort (no activity to summarize yet)

### Multi-day ranges

If the user passes `YYYYMMDD-YYYYMMDD`, iterate each day independently:
- Loop through each day
- Generate one daily file per day
- Update indexes once at the end with all touched (date, repo) rows

Do not produce a single combined range file. Range mode is convenience, not a new output format.

### Quiet days

If the day has zero commits AND zero captain's logs AND zero memory changes AND zero session activity, write a minimal file saying "No tracked activity" — don't skip it. Skipping would create gaps in INDEX.md that look like missing data.

---

## Output file naming

- Daily file: `workspace/repo-activity/{repo}/{YYYYMMDD}-{repo}-activity.md`
- Global index: `workspace/repo-activity/INDEX.md`
- Per-repo index: `workspace/repo-activity/{repo}/INDEX.md`

No HHMM suffix on daily files — the skill is day-scoped, not moment-scoped.

---

## What this skill is NOT

- Not an MCP-integrated skill. Writes local filesystem only. No `save_document` calls.
- Not a replacement for `weekly-update` — that skill synthesizes across multiple sources for the week; this one is a single-repo single-day snapshot.
- Not a full session transcript. Summarizes user intent, not assistant responses.
- Not a commit audit tool. Doesn't verify commit quality, just records what happened.
