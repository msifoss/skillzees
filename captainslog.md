# Captain's Log Command

Usage: `/captainslog [action] [name]`

**Actions:**
- `new [name]` — Create a new log entry
- `update` — Append to the most recent log
- `list` — Show all existing logs
- `read [name]` — Display a specific log (partial name match supported)

**Arguments:** $ARGUMENTS

---

## Purpose

Captain's Logs solve the problem of AI context loss between sessions. They serve as:
- **Handoff documents** for resuming work with Claude
- **Decision records** explaining *why* things were built a certain way
- **Mistake journals** to avoid repeating past errors
- **Progress tracking** across work sessions

---

## Instructions for Claude

### 0. Ensure Directory Exists
Before any action, check if `docs/captains_log/` exists. If not, create it:
```bash
mkdir -p docs/captains_log
```

### 1. Parse Arguments
Extract `action` and optional `name` from: `$ARGUMENTS`

**Validation rules:**
- If no arguments provided, show usage help and ask what they'd like to do
- `action` must be one of: `new`, `update`, `list`, `read`
- For `new`: `name` is required, should be kebab-case (e.g., `feature-name`)
- For `update`: `name` is optional (defaults to most recent log)
- For `list`: no additional arguments needed
- For `read`: `name` is required (can be partial match)

**Name validation:**
- Convert spaces to hyphens
- Convert to lowercase
- Remove special characters except hyphens
- Warn if name exceeds 50 characters

### 2. Find Existing Logs
```bash
ls -1 docs/captains_log/caplog-*.txt 2>/dev/null | sort
```
- Sort by filename (timestamp prefix ensures chronological order)
- Identify the most recent log for `update` action and `Previous Log` reference

---

## Action: `list`

Display all existing logs in chronological order:
```
📋 Captain's Logs:
1. caplog-20251128-091500-initial-setup.txt
2. caplog-20251129-131041-botpress-theming.txt
   └── Last modified: 2025-11-29 13:10:41
```
Show total count and offer to read any specific log.

---

## Action: `read [name]`

1. Search for logs matching the name (partial match, case-insensitive)
2. If multiple matches, list them and ask user to be more specific
3. If single match, display the full contents
4. Offer to update the log if it's the most recent one

---

## Action: `new [name]`

### Step 1: Gather Context
Before writing, collect information:
```bash
# Recent commits (last 15)
git log --oneline -15

# Current branch
git branch --show-current

# Uncommitted changes
git status --short

# Files changed with stats
git diff --stat HEAD~5 2>/dev/null || git diff --stat

# Remote status
git log --oneline origin/main..HEAD 2>/dev/null || echo "No remote tracking"
```

### Step 2: Generate File
- **Timestamp format:** `YYYYMMDD-HHMMSS`
- **Filename:** `docs/captains_log/caplog-[timestamp]-[name].txt`
- **Example:** `docs/captains_log/caplog-20251129-143022-auth-refactor.txt`

### Step 3: Read Previous Log
If a previous log exists, read it to:
- Reference it in the "Previous Log" field
- Understand prior context and decisions
- Check if any "Next Steps" are being addressed
- Maintain continuity of narrative

### Step 4: Write the Log
Use the template below. Fill in ALL sections, even if brief. If a section has nothing to report, write "None this session."

### Step 5: Confirm Creation
```
✅ Created: docs/captains_log/caplog-20251129-143022-auth-refactor.txt

📝 Summary: [First line of summary]

Commit this log? (y/n)
```

---

## Action: `update`

### Step 1: Find Target Log
- Default: most recent log
- If `name` provided: find matching log

### Step 2: Gather New Context
Same git commands as `new` action, but focus on changes since the log was created.

### Step 3: Append Update Block
Add to the end of the file, before `END OF LOG`:
```
--- UPDATE: [YYYY-MM-DD HH:MM:SS] ---

## Session Summary
[What was accomplished in this session]

## New Work Completed
- [New accomplishments]

## Additional Commits
- [commit_hash]: [message]

## Issues Encountered
- [Any new issues]

## Decisions Made
- [Any new decisions]

## Lessons Learned
- [New insights]

## Updated Next Steps
- [Revised priorities]

--- END UPDATE ---
```

### Step 4: Confirm Update
Show what was appended and offer to commit.

---

## Log Template

```
================================================================================
CAPTAIN'S LOG: [name]
Date: [YYYY-MM-DD HH:MM:SS]
Previous Log: [filename or "None - First Entry"]
================================================================================

## Summary
[Brief 2-3 sentence overview of what this log covers]

## Current State
[Where the project/feature stands right now]

## Work Completed
- [List of accomplishments]
- [Files changed]
- [Features implemented]

## Decisions Made
- [Why certain approaches were chosen]
- [Trade-offs considered]

## Issues Encountered
- [Bugs found]
- [Errors hit]
- [Blockers and how they were resolved]

## Commits Made
- [commit_hash]: [commit message]

## Mistakes & Lessons
- [What went wrong]
- [What we learned]

## Next Steps
- [What needs to happen next]
- [Open questions]

================================================================================
END OF LOG
================================================================================
```

### After Creating/Updating
- Confirm to the user what was done
- Show the filename created/updated
- Offer to commit the log if desired
