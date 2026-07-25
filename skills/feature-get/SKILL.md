# /feature-get — Pull Platform Enhancement Ideas

Fetch feature requests submitted by weeklyops-prompt users, group by theme, and present to developers for triage. Runs in the weeklyops repo.

## Trigger

Developer invokes `/feature-get` or `/feature-get --all`.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--all` | Show all requests including implemented/declined | Show only pending/planned |

## Instructions

### Step 1: Fetch Feature Requests

Call `mcp__weeklyops__list_documents(category="feature-requests")` to get the list of feature request files.

If no documents found, report: "No feature requests in the queue." and stop.

For each file listed, read its content. The files are in weeklyops-data at `docs/feature-requests/`.

### Step 2: Parse and Filter

Each feature request has this structure in the content:

```
# {Title}

**Status:** {pending | planned | implemented | declined}
**Frequency:** {one-off | recurring | systemic}
**Source Skill:** {skill name}
**Affected Tools:** {tool list}

---

## Problem
{description}

## Proposed Solution
{description}

## Effort Hint
{small | medium | large}
```

Parse the frontmatter fields from each file. By default, filter to `status: pending` and `status: planned` only. With `--all`, show everything.

### Step 3: Group and Sort

**Primary grouping:** By `Affected Tools` — requests touching the same tools are likely related.

**Secondary grouping:** By `Source Skill` — shows which skills generate the most friction.

**Sort within groups:**
1. `systemic` > `recurring` > `one-off` (frequency)
2. Oldest first (by date)

### Step 4: Present

Display as a grouped table:

```
## Feature Requests — {N} pending, {N} planned

### Affecting: {tool_name}

| # | Title | Frequency | Source | Effort | Status | Date |
|---|-------|-----------|--------|--------|--------|------|
| 1 | {title} | systemic | /weekly-update | medium | pending | 2026-04-06 |
| 2 | {title} | recurring | /email-ingest | small | pending | 2026-04-07 |

**Problem:** {1-line summary of #1}
**Solution:** {1-line summary of #1}

---

### Affecting: {other_tool}
...

### Ungrouped (no specific tool)
...
```

After the table, suggest:
> "To update status, say: 'mark #N as planned' or 'decline #N: {reason}'"

### Step 5: Handle Status Updates

If the developer says "mark #N as planned" or "decline #N: reason":

1. Read the original file from weeklyops-data
2. Update the `**Status:**` line to the new value
3. For declines, append `**Decline Reason:** {reason}` after the Status line
4. Write the updated file back via the GitHub client (the weeklyops repo has direct GitHub API access through `get_github_client()`)

Confirm: "Updated #{N} '{title}' → {new_status}"

### Step 6: Summary

After triage is complete:

```
## Triage Summary
- Reviewed: {N} requests
- Marked planned: {N}
- Declined: {N}
- Still pending: {N}
```

If any `planned` requests exist, suggest: "Consider creating backlog items for the planned requests."

## Notes

- This skill runs in the weeklyops repo where developers work on the MCP server
- Feature requests come from weeklyops-prompt users via /prompt-feature-assess
- No conversation content appears in requests — only patterns and gaps
- The skill uses MCP tools for reading and the GitHub client for writing updates
- Frequency signal is the best priority indicator: "systemic" means multiple skills/sessions are affected
