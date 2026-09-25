---
name: scribe
description: Captain's log agent — enhances /captainslog with search, auto-retrieval during planning, and continuity linking
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: "search [query] | recent | link | index"
---

# /scribe — Captain's Log Agent

Enhances the existing `/captainslog` command with search capability, auto-retrieval during planning phases, and continuity linking between logs.

> "Captain's logs are critical but optional and hard to reference. Scribe makes them searchable and discoverable." — Friction Analysis

## Trigger

User invokes `/scribe [action]` or during planning when historical context is needed.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `search [query]` | Search captain's logs for a topic | `/scribe search "JWT token handling"` |
| `recent` | Show the 5 most recent logs with summaries | `/scribe recent` |
| `link` | Show the continuity chain for current feature | `/scribe link` |
| `index` | Build a searchable index of all logs | `/scribe index` |

---

## Action: `search`

### Step 1: Search All Knowledge Sources

```bash
# Captain's logs
grep -ril "$QUERY" docs/captains_log/ 2>/dev/null

# Solutions
grep -ril "$QUERY" docs/solutions/ 2>/dev/null

# Key findings
grep -ril "$QUERY" docs/key_findings/ 2>/dev/null

# Brainstorms
grep -ril "$QUERY" docs/brainstorms/ 2>/dev/null
```

### Step 2: Rank Results

For each match:
1. Read the file
2. Extract the relevant section (Summary, Decisions Made, Lessons Learned)
3. Score by relevance (exact match > partial > tangential)
4. Sort by score, then by recency

### Step 3: Present Results

```markdown
## Search Results: "[query]"

### 1. caplog-20260404-153500-foundation-bootstrap.txt (Relevance: HIGH)
> "The state file is deceptively simple but its schema design shapes
> everything that follows."
- **Date:** 2026-04-04
- **Bolt:** B-001
- **Context:** Foundation bootstrap decisions

### 2. docs/solutions/2026-03-15-jwt-rotation.md (Relevance: MEDIUM)
> "Use short-lived access tokens (15m) with refresh tokens (7d)."
- **Date:** 2026-03-15
- **Context:** Auth implementation pattern
```

---

## Action: `recent`

Show the last 5 captain's logs with one-line summaries:

```bash
ls -t docs/captains_log/caplog-*.txt 2>/dev/null | head -5
```

For each, read the Summary section and display:

```markdown
## Recent Captain's Logs

| # | Date | Name | Summary |
|---|------|------|---------|
| 1 | 2026-04-04 | gatekeeper-agent | Built Gatekeeper — 57 exit criteria across 7 phases |
| 2 | 2026-04-04 | foundation-bootstrap | Bootstrapped ai-lfg from empty to Phase 0 |
```

---

## Action: `link`

Trace the continuity chain through Previous Log references:

```
caplog-20260404-180000-handoff-foreman-hardener.txt
  └── caplog-20260404-173000-pillar-guardians.txt
       └── caplog-20260404-170000-reqs-speccer.txt
            └── caplog-20260404-163000-tracer-agent.txt
                 └── caplog-20260404-160000-gatekeeper-agent.txt
                      └── caplog-20260404-153500-foundation-bootstrap.txt
                           └── (First Entry)
```

---

## Action: `index`

Build a searchable index from all knowledge sources:

```markdown
## Knowledge Index

**Generated:** YYYY-MM-DD
**Sources:** [count] captain's logs, [count] solutions, [count] key findings

### Topics
| Topic | Sources | Last Referenced |
|-------|---------|-----------------|
| Authentication | caplog-B003, solution-jwt | 2026-04-02 |
| State file schema | caplog-B001, key-finding-panel | 2026-04-04 |
```

Save to `docs/captains_log/INDEX.md`.

---

## Auto-Retrieval Integration

When another agent (Foreman, /bolt-lfg, /pm plan) is in a planning phase, Scribe can be invoked to surface relevant history:

1. Extract the topic from the current bolt goal
2. Run `search` against that topic
3. If results found, present as "Prior Knowledge" section
4. If no results, note "No prior context found for this topic"

This closes the knowledge retrieval loop described in AI-DLC Phase 6.

---

## Integration Points

- **Evolver:** Scribe's logs are Evolver's primary input for pattern extraction
- **Librarian:** Scribe indexes, Librarian retrieves
- **Foreman:** Auto-retrieval during bolt planning
- **/captainslog:** Scribe extends, doesn't replace, the base command
- **/bolt-lfg:** Step 2 knowledge retrieval uses Scribe
