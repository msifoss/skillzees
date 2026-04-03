---
name: ai-effort
description: Scan all msifoss GitHub repos for weekly commit activity, produce file-level AI time-savings estimates, write JSON ledger, and generate markdown summaries
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch
argument-hint: "[YYYY-MM-DD YYYY-MM-DD] [--summary] [--query \"question\"]"
---

# /ai-effort — AI Effort & Time Savings Tracker

Scan all GitHub repos under a user account for commits in a date range. For each file touched, classify the work, estimate complexity, and calculate how much time AI saved compared to manual development. Results are stored in a cumulative JSON ledger and can be queried over time.

## Trigger

User invokes `/ai-effort` with optional arguments.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| *(none)* | Scan current ISO week (Monday–Sunday) | Current week |
| `YYYY-MM-DD YYYY-MM-DD` | Explicit start and end dates (inclusive) | — |
| `YYYYMMDD-DD` | Folder-style date range (e.g., `20260322-28`) | — |
| `--summary` | Regenerate markdown from existing ledger (no GitHub scan) | Off |
| `--query "question"` | Query the ledger conversationally | — |

---

## Phase 1: Resolve Identity and Date Range

### Step 1a: Resolve GitHub Username

1. Try `mcp__weeklyops__whoami` — if it returns a name, map to GitHub username
2. Fall back: `git config user.name`
3. If neither resolves, ask: "What is your GitHub username?"

**Known mapping:**
- Chris → `msifoss`

Store the resolved username for all subsequent API calls.

### Step 1b: Parse Date Range

Parse the invocation arguments into `start_date` and `end_date` (ISO 8601, inclusive):

**No arguments → current week:**
```bash
# Get Monday of current week and Sunday
start_date=$(date -v-$(( ($(date +%u) - 1) ))d +%Y-%m-%d)
end_date=$(date -v+$(( 7 - $(date +%u) ))d +%Y-%m-%d)
```

**Two ISO dates (e.g., `2026-03-22 2026-03-28`):**
Use as-is.

**Folder-style (e.g., `20260322-28`):**
```python
arg = "{argument}"
year, month, day_from = arg[:4], arg[4:6], arg[6:8]
end_part = arg.split("-")[1]
if len(end_part) == 2:  # same month
    start_date = f"{year}-{month}-{day_from}"
    end_date = f"{year}-{month}-{end_part}"
elif len(end_part) == 4:  # cross-month
    start_date = f"{year}-{month}-{day_from}"
    end_date = f"{year}-{end_part[:2]}-{end_part[2:]}"
```

**For GitHub API:** Convert to ISO 8601 with time:
- `since` = `{start_date}T00:00:00Z`
- `until` = `{end_date + 1 day}T00:00:00Z` (GitHub `until` is exclusive — use the day after)

**IMPORTANT:** Also use `while IFS= read -r` loops (not `for x in $(...)`) when iterating over shell command output to avoid word-splitting issues with repo names and SHAs.

Report: "Scanning commits for **{username}** from **{start_date}** to **{end_date}**"

### Step 1c: Route by Mode

- If `--summary` flag: skip to Phase 6 (regenerate markdown from ledger)
- If `--query` flag: skip to Phase 7 (query mode)
- Otherwise: continue to Phase 2

---

## Phase 2: Discover Active Repos

### Step 2a: List all repos

**IMPORTANT:** Use the authenticated `/user/repos` endpoint (not `/users/{username}/repos`) to include private repos:

```bash
gh api "/user/repos?per_page=100&sort=pushed&direction=desc&affiliation=owner" --jq '.[].name'
```

If more than 100 repos, paginate:
```bash
gh api "/user/repos?per_page=100&sort=pushed&direction=desc&affiliation=owner&page=2" --jq '.[].name'
```

### Step 2b: Filter to repos with commits in range

For each repo, check for commits:

```bash
gh api "/repos/{username}/{repo}/commits?author={username}&since={since_iso}&until={until_iso}&per_page=1" --jq 'length' 2>/dev/null
```

- If the result is `1` (or more), the repo is **active** — include it.
- If the result is `0` or the call errors (empty repo, no commits), **skip** it.
- If you get a 409 (empty repo) or 404, skip silently.

**Rate limit awareness:** This uses N+1 API calls (1 for repo list + 1 per repo). For ~25 repos this is ~26 requests. If you hit a 403 or 429 response, wait 60 seconds and retry. Report progress: "Checking {repo}... {N}/{total}"

### Step 2c: Report discovery results

Report:
```
Found {N} active repos (out of {total} total):
- repo1 (✓ commits found)
- repo2 (✓ commits found)
- repo3 (— no commits, skipping)
...
```

Store the list of active repo names for Phase 3.

---

## Phase 3: Collect File-Level Diffs

For each active repo, gather commit details and file-level stats.

### Step 3a: Fetch commits for each active repo

```bash
gh api "/repos/{username}/{repo}/commits?author={username}&since={since_iso}&until={until_iso}&per_page=100" \
  --jq '.[] | {sha: .sha, message: .commit.message, date: .commit.author.date}'
```

Store the list of commit SHAs and their messages per repo.

### Step 3b: Fetch file-level diffs per commit

For each commit SHA:

```bash
gh api "/repos/{username}/{repo}/commits/{sha}" \
  --jq '{sha: .sha, message: .commit.message, files: [.files[] | {path: .filename, additions: .additions, deletions: .deletions, status: .status}]}'
```

This returns the list of files with additions, deletions, and status (added/modified/removed/renamed).

**Optimization:** If a repo has many commits (>20), batch the API calls. Report progress: "Fetching diffs for {repo}: {n}/{total} commits"

### Step 3c: Aggregate at file level

For each file that appears across commits in a repo, aggregate:

| Field | Aggregation |
|-------|-------------|
| `path` | File path (unique key) |
| `lines_added` | Sum of `additions` across all commits touching this file |
| `lines_removed` | Sum of `deletions` across all commits touching this file |
| `net_lines` | `lines_added - lines_removed` |
| `commits_touching` | Count of commits that modified this file |
| `status` | `"added"` if the first commit's status is "added"; `"removed"` if the last commit's status is "removed"; otherwise `"modified"` |
| `commit_messages` | List of first-line commit messages for commits touching this file |

### Step 3d: Generate file descriptions

For each file:
- If 1 commit touched it: use that commit message's first line (truncate to 80 chars)
- If 2+ commits touched it: `"{N} changes: {first_msg}, {last_msg}"` (truncate to 80 chars)

### Step 3e: Get repo description for "purpose" field

```bash
gh api "/repos/{username}/{repo}" --jq '.description // "No description"'
```

Store as the repo's `purpose` field.

---

## Phase 4: Classify and Estimate

For each file in each repo, classify the category, estimate complexity, and calculate time saved.

### Step 4a: Classify file category

Classify by file path and extension — no content analysis needed:

| Category | Match Rules |
|----------|-------------|
| `test` | Path contains `tests/` or `test_` or `__tests__` or file matches `*.test.*` or `*.spec.*` |
| `config` | Extension is `.yaml`, `.yml`, `.json`, `.toml`, `.ini`, `.cfg`, or filename is `Dockerfile`, `docker-compose.*`, `.env*`, `Makefile`, `pyproject.toml`, `package.json`, `requirements*.txt` |
| `docs` | Extension is `.md`, `.rst`, `.txt` and path contains `docs/` or filename is `README*`, `CHANGELOG*`, `LICENSE*` |
| `infra` | Path contains `.github/`, `deploy/`, `scripts/`, or filename matches `nginx*`, `*provision*`, `Makefile` (when in deploy/ or scripts/) |
| `style` | Extension is `.css`, `.scss`, `.sass`, `.less`, or path contains `styles/`, `design-tokens` |
| `ui` | Extension is `.astro`, `.tsx`, `.jsx`, `.svelte`, `.vue`, `.html` (but NOT in tests/) |
| `data` | Extension is `.sql`, or path contains `migrations/`, `fixtures/`, `seeds/`, or file is a `.json` in a `data/` directory |
| `skill` | Path contains `skills/` or filename is `SKILL.md` |
| `feature` | Everything else (business logic, services, API routes, models, utilities) |

Apply rules top-to-bottom — first match wins. `test` and `config` checks come first because they overlap with other categories.

### Step 4b: Estimate complexity

For each file, assign `low`, `medium`, or `high`:

| Complexity | Rule |
|------------|------|
| `low` | Category is `config`, `docs`, `style`, `data`, or `skill`. OR `abs(net_lines)` < 30. |
| `high` | `abs(net_lines)` > 150 AND category is `feature` or `infra`. OR file path contains `auth`, `crypto`, `security`, `lock`, `permission`, `concurrency`. |
| `medium` | Everything else. |

### Step 4c: Determine AI speed factor

Default: `ai_speed_factor = 0.3` (AI-assisted work takes ~30% of manual time)

Override for specific patterns:

| Pattern | Factor | Reason |
|---------|--------|--------|
| Category is `test` | 0.15 | AI excels at generating tests from existing code |
| Category is `docs` or `skill` | 0.20 | AI excels at documentation |
| Category is `config` AND complexity is `low` | 0.10 | Boilerplate/scaffold |
| File path contains `auth`, `crypto`, `security`, `permission` | 0.50 | AI helps less with security-sensitive code |
| `abs(net_lines)` > 500 AND status is `added` | 0.10 | New file scaffold — AI's sweet spot |
| Category is `feature` AND complexity is `high` | 0.50 | Novel business logic needs human judgment |

Apply overrides top-to-bottom — first match wins.

### Step 4d: Calculate time saved per file

**Base rates** (hours per net line, by category and complexity):

| Category | Low | Medium | High |
|----------|-----|--------|------|
| `feature` | 0.02 | 0.04 | 0.08 |
| `test` | 0.015 | 0.025 | 0.05 |
| `config` | 0.01 | 0.02 | 0.04 |
| `docs` | 0.008 | 0.015 | 0.03 |
| `infra` | 0.015 | 0.03 | 0.06 |
| `style` | 0.01 | 0.02 | 0.04 |
| `ui` | 0.015 | 0.03 | 0.06 |
| `data` | 0.01 | 0.02 | 0.04 |
| `skill` | 0.01 | 0.02 | 0.04 |

**Formula:**
```
time_without_ai = abs(net_lines) * base_rate[category][complexity]
time_without_ai = max(0.25, min(40.0, time_without_ai))   # floor 15min, cap 40hrs
time_with_ai = time_without_ai * ai_speed_factor
time_saved = time_without_ai - time_with_ai
```

Round all time values to 2 decimal places.

**Flag large files:** If `abs(net_lines)` > 5000, add a note: "Likely generated code — estimate capped".

### Step 4e: Aggregate repo totals

For each repo, sum across all files:
- `files_changed`: count of files
- `lines_added`: sum
- `lines_removed`: sum
- `net_lines`: sum
- `time_without_ai_hours`: sum
- `time_with_ai_hours`: sum
- `time_saved_hours`: sum

### Step 4f: Prompt for non-repo work

Ask the user:

> "Any significant AI-assisted work this week that isn't in a git repo? (documentation, analysis, email drafts, meeting prep — type 'none' to skip)"

For each item the user provides, record:
- `activity`: description
- `time_saved_hours`: user-provided estimate, or default 1.0

### Step 4g: Calculate grand total

Sum across all repos + non-repo work:
- `repos_active`: count of repos
- `total_commits`: sum of commits across repos
- `total_files_changed`: sum of files_changed across repos
- `lines_added`: sum
- `lines_removed`: sum
- `net_lines`: sum
- `time_without_ai_hours`: sum across repos (non-repo doesn't have this)
- `time_with_ai_hours`: sum across repos
- `time_saved_hours`: sum across repos + non-repo

---

## Phase 5: Write Ledger Entry

### Ledger Location

**Primary:** `weeklyops-data` repo (`msifoss/weeklyops-data`) at path `team/chris/ai-effort/ai-effort-ledger.json`

**Fallback:** If weeklyops-data is not accessible via GitHub API, write to the local weeklyops repo at `docs/data/ai-effort-ledger.json` and warn: "Could not write to weeklyops-data. Ledger saved locally — push manually."

### Step 5a: Read existing ledger (or initialize)

**Try GitHub API first:**
```bash
gh api "/repos/msifoss/weeklyops-data/contents/team/chris/ai-effort/ai-effort-ledger.json" \
  --jq '.content' | base64 -d
```

If the file doesn't exist (404), initialize with:
```json
{"schema_version": 1, "weeks": []}
```

If the API call fails for other reasons, try reading from a local clone of weeklyops-data if available. If neither works, initialize fresh and note the fallback.

**Store the file's SHA** (needed for updates via GitHub API):
```bash
gh api "/repos/msifoss/weeklyops-data/contents/team/chris/ai-effort/ai-effort-ledger.json" \
  --jq '.sha'
```

### Step 5b: Build the week entry

Construct the JSON entry from Phase 4 results following this schema:

```json
{
  "week_start": "{start_date}",
  "week_end": "{end_date}",
  "generated_at": "{ISO 8601 timestamp with timezone}",
  "github_username": "{username}",
  "repos": [
    {
      "name": "{repo_name}",
      "purpose": "{repo description from GitHub}",
      "url": "https://github.com/{username}/{repo_name}",
      "commits": "{commit_count}",
      "files": [
        {
          "path": "{file_path}",
          "category": "{category}",
          "complexity": "{low|medium|high}",
          "lines_added": "{n}",
          "lines_removed": "{n}",
          "net_lines": "{n}",
          "commits_touching": "{n}",
          "time_without_ai_hours": "{n.nn}",
          "time_with_ai_hours": "{n.nn}",
          "time_saved_hours": "{n.nn}",
          "ai_speed_factor": "{n.nn}",
          "description": "{commit-derived description}"
        }
      ],
      "totals": {
        "files_changed": "{n}",
        "lines_added": "{n}",
        "lines_removed": "{n}",
        "net_lines": "{n}",
        "time_without_ai_hours": "{n.nn}",
        "time_with_ai_hours": "{n.nn}",
        "time_saved_hours": "{n.nn}"
      }
    }
  ],
  "non_repo": [
    {
      "activity": "{description}",
      "time_saved_hours": "{n.n}"
    }
  ],
  "grand_total": {
    "repos_active": "{n}",
    "total_commits": "{n}",
    "total_files_changed": "{n}",
    "lines_added": "{n}",
    "lines_removed": "{n}",
    "net_lines": "{n}",
    "time_without_ai_hours": "{n.nn}",
    "time_with_ai_hours": "{n.nn}",
    "time_saved_hours": "{n.nn}"
  }
}
```

Sort repos by `time_saved_hours` descending (biggest impact first). Sort files within each repo by `time_saved_hours` descending.

All numeric fields are actual numbers (not strings). The template placeholders above are for illustration only.

### Step 5c: Upsert into ledger

**Idempotency:** If a week entry with the same `week_start` AND `week_end` already exists, replace it. Otherwise, append.

Insert the new entry into the `weeks` array. Sort `weeks` by `week_start` ascending (chronological).

### Step 5d: Write ledger to weeklyops-data

**Via GitHub API:**
```bash
# Encode the JSON content
content_base64=$(echo '{ledger_json}' | base64)

# Create or update the file
gh api -X PUT "/repos/msifoss/weeklyops-data/contents/team/chris/ai-effort/ai-effort-ledger.json" \
  -f message="ai-effort: update ledger for {start_date} to {end_date}" \
  -f content="$content_base64" \
  -f sha="$existing_sha"   # omit this field if creating new file
```

**Via local fallback:**
Write the JSON to `docs/data/ai-effort-ledger.json` in the weeklyops repo.

Report: "Ledger updated: {weeklyops-data or local path}"

---

## Phase 6: Generate Markdown Summary

Generate a human-readable markdown report from the ledger entry. This is also the entry point for `--summary` mode (which skips Phases 2–5 and reads the ledger directly).

### Step 6a: Determine output path

**Output location:** `docs/team/chris/ai-effort/` in the weeklyops repo (local).

**Filename:** `{YYYYMMDD}-{HHMM}-ai-effort-{week_start}-to-{week_end}.md`

Example: `20260401-1430-ai-effort-2026-03-22-to-2026-03-28.md`

Create the directory if it doesn't exist:
```bash
mkdir -p docs/team/chris/ai-effort/
```

### Step 6b: Generate the report

Write the markdown file with this structure:

```markdown
# AI Effort Report: {week_start} to {week_end}

**Generated:** {YYYY-MM-DD HH:MM}
**GitHub user:** {username}
**Repos active:** {repos_active}
**Total commits:** {total_commits}
**Total net lines:** +{net_lines}
**Total time saved:** ~{time_saved_hours} hrs (estimated {time_without_ai_hours} hrs manual → {time_with_ai_hours} hrs AI-assisted)

---

## Repo Summary

| Repo | Purpose | Commits | Net Lines | Time Saved |
|------|---------|---------|-----------|------------|
| {name} | {purpose} | {commits} | +{net_lines} | ~{time_saved_hours} hrs |
| ... | ... | ... | ... | ... |
| **TOTAL** | | **{total_commits}** | **+{net_lines}** | **~{time_saved_hours} hrs** |

## Non-Repo Work

| Activity | Time Saved |
|----------|------------|
| {activity} | ~{time_saved_hours} hrs |

---

## File-Level Detail

{For each repo, sorted by time_saved descending:}

### {repo_name} (+{net_lines} lines, ~{time_saved_hours} hrs saved)

| File | Category | Complexity | Net Lines | AI Factor | Time Saved |
|------|----------|------------|-----------|-----------|------------|
| {path} | {category} | {complexity} | +{net_lines} | {ai_speed_factor} | ~{time_saved_hours} hrs |

#### Category Breakdown

| Category | Files | Net Lines | Time Saved | % of Repo |
|----------|-------|-----------|------------|-----------|
| {category} | {count} | +{net_lines} | ~{time_saved_hours} hrs | {pct}% |

---

## Overall Category Breakdown

| Category | Files | Net Lines | Time Saved | % of Total |
|----------|-------|-----------|------------|------------|
| {category} | {count} | +{net_lines} | ~{time_saved_hours} hrs | {pct}% |
```

### Step 6c: Report completion

Report:
```
AI Effort Report written to: docs/team/chris/ai-effort/{filename}.md
Ledger updated at: weeklyops-data/team/chris/ai-effort/ai-effort-ledger.json

Summary:
  {repos_active} repos | {total_commits} commits | +{net_lines} lines | ~{time_saved_hours} hrs saved
```

---

## Phase 7: Query Mode

Entry point when invoked with `--query "question"`. Loads the full ledger and answers questions conversationally.

### Step 7a: Load the ledger

Fetch the ledger from weeklyops-data:
```bash
gh api "/repos/msifoss/weeklyops-data/contents/team/chris/ai-effort/ai-effort-ledger.json" \
  --jq '.content' | base64 -d
```

If not available, try local path: `docs/data/ai-effort-ledger.json`

If neither exists: "No ledger found. Run `/ai-effort` first to generate data."

### Step 7b: Answer the query

Read the full JSON ledger into context. Answer the user's question by analyzing the data.

**Example queries and how to handle them:**

| Query | Approach |
|-------|----------|
| "Total time saved this quarter" | Filter weeks where `week_start` falls in the quarter, sum `grand_total.time_saved_hours` |
| "Which category saves the most time?" | Flatten all files across all weeks, group by `category`, sum `time_saved_hours` |
| "Most active repos over Q1" | Filter weeks in Q1, group by repo name, sum `net_lines` or `time_saved_hours` |
| "Week-over-week trend" | List each week's `grand_total.time_saved_hours` in chronological order |
| "Where does AI help least?" | Find files/categories with highest `ai_speed_factor` (closest to 0.5) |
| "Show me all high-complexity work" | Filter files where `complexity == "high"`, list with context |

Present results in tables or narrative form, whichever is clearer for the question.

---

## Edge Cases

- **No commits in range:** Report "No commits found for {username} between {start_date} and {end_date}. Nothing to report." and stop.
- **Private repos:** `gh` CLI with authenticated token sees private repos. If a repo returns 403, note it: "Skipped {repo} (insufficient permissions)" and continue.
- **Forked repos:** Included only if the user has commits in the date range. The commit author filter handles this naturally.
- **Very large diffs (>5,000 net lines per file):** Flag as "Likely generated code" and cap time estimate at 40 hours.
- **Re-run same week:** Overwrites the existing ledger entry (idempotent by week_start + week_end).
- **GitHub rate limiting (403/429):** Pause for 60 seconds, report progress so far, then retry. If still limited, report partial results and offer to resume later.
- **Ledger doesn't exist:** Initialize with `{"schema_version": 1, "weeks": []}`.
- **weeklyops-data not accessible:** Fall back to local `docs/data/ai-effort-ledger.json`. Warn user.
- **Empty repo (409 from commits endpoint):** Skip silently.

## Integration with /weekly-update

The `/weekly-update` skill can read from the ledger to add an "AI Efforts & Time Savings" section:

1. Check if `team/chris/ai-effort/ai-effort-ledger.json` in weeklyops-data has an entry matching the review week
2. If yes: read the entry and format the repo-level summary table + a one-paragraph summary
3. If no: note "Run `/ai-effort {dates}` to generate AI effort data for this week"

This is a **read-only** integration — `/weekly-update` never writes to the ledger.

## What This Skill Does NOT Do

- Does not track time spent (only time saved)
- Does not require manual time logging
- Does not modify any source code
- Does not push to remote (writes locally or via GitHub API to weeklyops-data only)
- Does not run on a schedule (manual invocation only)
