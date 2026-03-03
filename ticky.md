---
name: ticky
description: Full lifecycle ticket management — draft, submit, sync, and clean Azure DevOps work items across repos.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: <mode> [args...] — modes: draft, submit, clean, update, get, create
---

# Ticky — Full Lifecycle Ticket Management

Manage Azure DevOps work items through their full lifecycle: draft locally, submit to ADO, sync status, and clean up cross-repo tickets.

**CLI:** `/Users/msichris/repos/ticky/ticky.py`
**PAT:** `/Users/msichris/repos/ticky/tickypat.txt`

## Usage

```
/ticky draft "Short description of what's needed"
/ticky draft "Short description" --priority 1 --tags "Tag1; Tag2" --type Bug
/ticky submit docs/tickets/20260302-143000-my-ticket-draft.md
/ticky submit docs/tickets/20260302-143000-my-ticket-draft.md --assign "Muhammad Usman"
/ticky clean [--dry-run]
/ticky update <slug-or-ado-id> [--pull] [--push]
/ticky get <ado-id> [--json]
/ticky create docs/tickets/my-ticket.yaml
/ticky create docs/tickets/my-ticket.yaml --assign "Name"
```

**Arguments:** $ARGUMENTS

---

## Mode 1: Draft

**Trigger:** `/ticky draft "description"` or `/ticky "description of ticket needed"`

Creates a local `.md` ticket file and registers it in `tickets.json`. No ADO API call.

### Steps

1. Parse `$ARGUMENTS` for the description text and optional flags (`--priority N`, `--tags "X; Y"`, `--type Bug|Task|Issue`)
2. Generate a slug from the description (lowercase, hyphens, max 50 chars)
3. Generate timestamp: `YYYYMMDD-HHMMSS`
4. Create the ticket file at `docs/tickets/YYYYMMDD-HHMMSS-slug-draft.md` using the **Ticket .md Format** below
5. Use the ticket-prompt template at `/Users/msichris/repos/ticky/templates/ticket-prompt.md` to generate the HTML body sections (TL;DR, Description, What's Needed, Steps, Reference, Impact, Time, Contact)
6. Register the ticket in `docs/tickets/tickets.json` (create the file if it doesn't exist) — see **tickets.json Schema** below
7. Report the file path and tell the user to review before submitting

### Ticket .md Format

```markdown
---
title: "Short title"
type: Issue
priority: 2
tags: "Tag1; Tag2"
status: draft
ado_id: null
assigned_to: null
created: 2026-03-02T14:30:00
submitted: null
---

<h2>TL;DR</h2>
<p>...</p>

<h2>Description</h2>
<p>...</p>

<h2>What's Needed</h2>
<p><strong>...</strong></p>

<h2>Steps to Complete</h2>
<table border="1" cellpadding="6" cellspacing="0">
<tr style="background-color:#1B3A5C;color:#FFFFFF;"><th>Step</th><th>Action</th></tr>
<tr><td>1</td><td>...</td></tr>
</table>

<h2>Reference</h2>
<table border="1" cellpadding="6" cellspacing="0">
<tr style="background-color:#1B3A5C;color:#FFFFFF;"><th>Item</th><th>Value</th></tr>
<tr><td>Repo</td><td>...</td></tr>
</table>

<h2>Impact if Not Resolved</h2>
<p>...</p>

<h2>Estimated Time</h2>
<p><strong>X minutes</strong></p>

<h2>Contact</h2>
<p><strong>Requestor:</strong> cfossenier<br/>
<strong>Email:</strong> cfossenier@membersolutions.com<br/>
Available for questions or a quick call if needed.</p>
```

---

## Mode 2: Submit

**Trigger:** `/ticky submit <path-to-draft.md>` or `/ticky submit <path> --assign "Name"`

Submits a draft ticket to ADO, updates the local file and `tickets.json`.

### Steps

1. Read the draft `.md` file and validate it has frontmatter with `status: draft`
2. Dry-run first to verify payload:
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)" --dry-run
   ```
3. Submit for real:
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
   ```
4. Capture the ADO work item ID and URL from output
5. If `--assign "Name"` was specified, assign via:
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py update <ado_id> --assign "Name" --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
   ```
6. Update the `.md` frontmatter:
   - Set `status: submitted`
   - Set `ado_id: <id>`
   - Set `assigned_to: <name>` (if assigned)
   - Set `submitted: <ISO timestamp>`
7. Rename the file: replace `-draft.md` with `-submitted.md`
8. Update `docs/tickets/tickets.json` with the new state, ADO ID, URL, and filename
9. Report the ticket number and URL

---

## Mode 3: Clean

**Trigger:** `/ticky clean` or `/ticky clean --dry-run`

Scans all repos under `~/repos/` and normalizes tickets to the new naming/format. Creates `tickets.json` per repo.

**IMPORTANT:** Always run `--dry-run` first and show the user what will change before doing anything.

### Existing Naming Patterns to Handle

| Pattern | Example | How to Handle |
|---------|---------|---------------|
| `ticky-<name>.yaml` | `ticky-graph-explorer.yaml` | Use file mtime for timestamp |
| `YYYYMMDD-ticket-<name>.md` | `20260212-ticket-ses-config.md` | Extract date from filename |
| `NNN-<name>.yaml` | `001-enable-eventbridge.yaml` | Use file mtime for timestamp |
| `YYYYMMDD-<name>.md` | `20250628-tinygo-wasm-support.md` | Extract date, merge existing frontmatter |
| `NNNN-<name>.yaml` | `5139-secretsmanager-write.yaml` | Extract ADO ID from prefix |
| `YYYY-MM-DD-<name>.yaml` | `2025-02-25-initial-setup.yaml` | Reformat date |

### Steps

1. Scan `~/repos/*/docs/tickets/` for ticket files (`.yaml`, `.yml`, `.md`)
2. For each repo with tickets:
   a. Parse each ticket file to extract: title, type, priority, tags, description, ADO ID (if embedded in filename or content)
   b. Check `CHANGELOG.md` in the tickets dir for ADO IDs and states
   c. Determine the canonical name: `YYYYMMDD-HHMMSS-slug-status.md`
   d. Handle duplicate `.yaml` + `.md` pairs by merging (YAML has structured data, MD may have richer body)
   e. Generate the new `.md` file with proper frontmatter
   f. Build the `tickets.json` database
3. In `--dry-run` mode: print what would be created/renamed/merged, but change nothing
4. In live mode: create new files, build `tickets.json`, but **do not delete old files** — leave them for user to clean up after verifying

### CHANGELOG Parsing

For repos like callhero that track ADO IDs in `CHANGELOG.md`:
- Look for patterns like `#5139`, `ADO-5139`, or `ID: 5139` to extract ADO work item IDs
- Look for state labels like `[Closed]`, `[Active]`, `[Resolved]` next to ticket entries
- Map these back to the corresponding ticket files

---

## Mode 4: Update (Two-Way Sync)

**Trigger:** `/ticky update <slug-or-ado-id>` or `/ticky update --all`

Syncs state between local ticket files and ADO.

### Conflict Resolution

| Field | Who Wins | Rationale |
|-------|----------|-----------|
| State, AssignedTo | ADO wins | Workflow fields managed in ADO board |
| Title, Description, Priority, Tags | Local wins | Content fields managed by author |

### Steps

1. Locate the ticket — by slug (lookup in `tickets.json`) or by ADO ID
2. Read the local `.md` file and `tickets.json` entry
3. **Pull from ADO** (always):
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py get <ado_id> --json --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
   ```
   - Update local frontmatter `assigned_to` from ADO `System.AssignedTo`
   - Update `tickets.json` field `ado_state` from ADO `System.State`
   - Update `last_synced` timestamp
4. **Push to ADO** (if local content fields differ):
   - Compare local title/description/priority/tags to ADO values
   - If different, push via:
     ```bash
     python3 /Users/msichris/repos/ticky/ticky.py update <ado_id> --title "X" --priority N --tags "X" --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
     ```
   - Description push: use the full body from the `.md` file
5. Report what changed in each direction

### Update --all

When `/ticky update --all` is used:
1. Read `docs/tickets/tickets.json` in the current repo
2. For each ticket with an `ado_id`, run the sync steps above
3. Report summary: N tickets synced, M had changes

---

## Legacy Mode: Create (Backward Compat)

**Trigger:** `/ticky create <path-to-file>` or `/ticky <path-to-yaml>`

Direct submission without the draft/submit lifecycle. Works exactly as before.

### Steps

1. Parse `$ARGUMENTS` for file path and optional `--assign "Name"` flag
2. Validate:
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py validate <file>
   ```
3. Submit:
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
   ```
4. If `--assign "Name"`, run:
   ```bash
   python3 /Users/msichris/repos/ticky/ticky.py update <ado_id> --assign "Name" --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
   ```
5. Report the ticket number and URL

---

## Legacy Mode: Get

**Trigger:** `/ticky get <ado-id>`

Fetch and display a work item from ADO.

```bash
python3 /Users/msichris/repos/ticky/ticky.py get <id> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
```

For raw JSON: add `--json` flag.

---

## tickets.json Schema

Per-repo database at `docs/tickets/tickets.json`:

```json
{
  "last_sync": "2026-03-02T15:00:00",
  "tickets": {
    "20260302-m365-admin-approval": {
      "file": "20260302-143000-m365-admin-approval-submitted.md",
      "ado_id": 5542,
      "ado_url": "https://dev.azure.com/membersolutionsinc/DevOps/_workitems/edit/5542",
      "status": "submitted",
      "assigned_to": "Christopher Griffith",
      "priority": 2,
      "created": "2026-03-02T14:30:00",
      "submitted": "2026-03-02T14:35:00",
      "last_synced": "2026-03-02T15:00:00",
      "ado_state": "New"
    }
  }
}
```

### tickets.json Rules

- **Key** is the slug (date prefix + descriptive name, no timestamp seconds)
- Create the file if it doesn't exist (empty: `{"last_sync": null, "tickets": {}}`)
- Always update `last_sync` when any operation touches the file
- `status` values: `draft`, `submitted`, `closed`
- `ado_state` mirrors the ADO board state: `New`, `Active`, `Resolved`, `Closed`

---

## Naming Convention

All ticket files follow: `YYYYMMDD-HHMMSS-slug-status.md`

| Part | Example | Notes |
|------|---------|-------|
| Date | `20260302` | Creation date |
| Time | `143000` | Creation time (HHMMSS) |
| Slug | `m365-admin-approval` | Lowercase, hyphens, max 50 chars |
| Status | `draft` or `submitted` | Current lifecycle status |
| Extension | `.md` | Always markdown with YAML frontmatter |

Examples:
- `20260302-143000-m365-admin-approval-draft.md`
- `20260302-143000-m365-admin-approval-submitted.md`

---

## Authentication

- PAT stored at: `/Users/msichris/repos/ticky/tickypat.txt`
- Pass via: `--pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"`
- Default org/project configured in `~/.ticky.conf`: `membersolutionsinc/DevOps`

---

## Ticky CLI Reference

```bash
# Validate (YAML, JSON, or MD)
python3 /Users/msichris/repos/ticky/ticky.py validate <file>

# Create (submit to ADO)
python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"

# Dry run
python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)" --dry-run

# Get work item by ID
python3 /Users/msichris/repos/ticky/ticky.py get <id> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"

# Get as raw JSON
python3 /Users/msichris/repos/ticky/ticky.py get <id> --json --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"

# Update work item fields
python3 /Users/msichris/repos/ticky/ticky.py update <id> --state Active --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"
python3 /Users/msichris/repos/ticky/ticky.py update <id> --assign "Name" --priority 1 --tags "Tag1; Tag2" --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"

# Dry-run update
python3 /Users/msichris/repos/ticky/ticky.py update <id> --tags "test" --dry-run --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"

# Verbose logging
python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)" -v
```

---

## Mode Detection

Parse `$ARGUMENTS` to determine the mode:

| First Arg | Mode |
|-----------|------|
| `draft` | Draft mode |
| `submit` | Submit mode |
| `clean` | Clean mode |
| `update` | Update mode |
| `get` | Get mode (pass-through to CLI) |
| `create` or path to `.yaml`/`.yml` | Legacy create mode |
| Quoted text (no mode keyword) | Draft mode (treat as description) |
