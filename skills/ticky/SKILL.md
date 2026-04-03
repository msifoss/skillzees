---
name: ticky
description: Full lifecycle ticket management — draft, submit, sync, and clean Azure DevOps work items across repos.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: <mode> [args...] — modes: draft, submit, clean, update, get, create
---

# Ticky — Full Lifecycle Ticket Management

Manage Azure DevOps work items through their full lifecycle: draft locally, submit to ADO, sync status, and clean up cross-repo tickets.

**CLI:** `${TICKY_HOME:-$HOME/repos/ticky}/ticky.py`
**PAT:** `${TICKY_HOME:-$HOME/repos/ticky}/tickypat.txt`

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

1. Parse `$ARGUMENTS` for the description text and optional flags (`--priority N`, `--tags "X; Y"`, `--type Bug|Task|Issue`, `--dry-run`)
2. Generate a slug from the description (see Slug Generation Rules)
3. Generate timestamp: `YYYYMMDD-HHMMSS`
4. Create the ticket file at `docs/tickets/YYYYMMDD-HHMMSS-slug-draft.md` using the **Ticket .md Format** below
5. Use the ticket-prompt template at `${TICKY_HOME:-$HOME/repos/ticky}/templates/ticket-prompt.md` to generate the HTML body sections (TL;DR, Description, What's Needed, Steps, Reference, Impact, Time, Contact)
6. Register the ticket in `docs/tickets/tickets.json` (create the file if it doesn't exist) — see **tickets.json Schema** below
7. If `--dry-run` was passed, show what would be created (filename, slug, frontmatter) without creating any files, then stop.
8. Report the file path and tell the user to review before submitting

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
<p><strong>Requestor:</strong> <!-- Read from ~/.ticky.conf or git config user.name --><br/>
<strong>Email:</strong> <!-- Read from ~/.ticky.conf or git config user.email --><br/>
Available for questions or a quick call if needed.</p>
```

---

## Mode 2: Submit

**Trigger:** `/ticky submit <path-to-draft.md>` or `/ticky submit <path> --assign "Name"`

Submits a draft ticket to ADO, updates the local file and `tickets.json`.

### Steps

1. Load the PAT into an environment variable (do this once per session):
   ```bash
   TICKY_PAT="$(cat ${TICKY_HOME:-$HOME/repos/ticky}/tickypat.txt)"
   ```
2. Read the draft `.md` file and validate it has frontmatter with `status: draft`
3. Dry-run first to verify payload:
   ```bash
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py create <file> --pat "$TICKY_PAT" --dry-run
   ```
3. Submit for real:
   ```bash
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py create <file> --pat "$TICKY_PAT"
   ```
4. Capture the ADO work item ID and URL from output
5. If `--assign "Name"` was specified, assign via:
   ```bash
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py update <ado_id> --assign "Name" --pat "$TICKY_PAT"
   ```
6. **Verify ADO response** — confirm the response contains a valid ADO work item ID before proceeding. If the API returned an error, stop and report the error without updating local state.
7. Update the `.md` frontmatter:
   - Set `status: submitted`
   - Set `ado_id: <id>`
   - Set `assigned_to: <name>` (if assigned)
   - Set `submitted: <ISO timestamp>`
8. Write the updated content to the new filename (`-submitted.md`) first, then remove the old draft file. This ensures no data loss if the process is interrupted.
9. Update `docs/tickets/tickets.json` with the new state, ADO ID, URL, and filename
10. Report the ticket number and URL

---

## Mode 3: Clean

**Trigger:** `/ticky clean` or `/ticky clean --dry-run`

Normalizes tickets in the current repo to the new naming/format. Creates `tickets.json`. Use `--all-repos` to scan all repos under `~/repos/`.

**IMPORTANT:** Always run `--dry-run` first and show the user what will change before doing anything.

### Existing Naming Patterns to Handle

| Pattern | Example | How to Handle |
|---------|---------|---------------|
| `ticky-<name>.yaml` | `ticky-graph-explorer.yaml` | Use file mtime for timestamp |
| `YYYYMMDD-ticket-<name>.md` | `20260212-ticket-ses-config.md` | Extract date from filename, normalize to `YYYYMMDD-HHMMSS-slug-status.md` (use `120000` if time unknown) |
| `NNN-<name>.yaml` | `001-enable-eventbridge.yaml` | Use file mtime for timestamp |
| `YYYYMMDD-<name>.md` | `20250628-tinygo-wasm-support.md` | Extract date, merge existing frontmatter |
| `NNNN-<name>.yaml` | `5139-secretsmanager-write.yaml` | Extract ADO ID from prefix |
| `YYYY-MM-DD-<name>.yaml` | `2025-02-25-initial-setup.yaml` | Reformat date |

### Steps

1. Scan current repo's `docs/tickets/` for ticket files (`.yaml`, `.yml`, `.md`). To scan all repos, user must pass `--all-repos` flag explicitly.
2. **Idempotency check:** If `tickets.json` already exists, read it first. Skip any ticket files that already have an entry in `tickets.json` with matching slug and status.
3. For each repo with tickets:
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
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py get <ado_id> --json --pat "$TICKY_PAT"
   ```
   - Update local frontmatter `assigned_to` from ADO `System.AssignedTo`
   - Update `tickets.json` field `ado_state` from ADO `System.State`
   - Update `last_synced` timestamp
4. **Push to ADO** (if local content fields differ):
   - Compare local title/description/priority/tags to ADO values
   - If different, push via:
     ```bash
     python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py update <ado_id> --title "X" --priority N --tags "X" --pat "$TICKY_PAT"
     ```
   - Description push: use the full body from the `.md` file
5. Report what changed in each direction

### Update --all

When `/ticky update --all` is used:
1. Read `docs/tickets/tickets.json` in the current repo
2. For each ticket with an `ado_id`, run the sync steps above. Process in batches of 10 with a 2-second pause between batches to respect ADO's rate limit (200 requests/minute).
3. Report summary: N tickets synced, M had changes

---

## Legacy Mode: Create (Backward Compat)

**Trigger:** `/ticky create <path-to-file>` or `/ticky <path-to-yaml>`

Direct submission without the draft/submit lifecycle. Works exactly as before.

### Steps

1. Parse `$ARGUMENTS` for file path and optional `--assign "Name"` flag
2. Validate:
   ```bash
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py validate <file>
   ```
3. Submit:
   ```bash
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py create <file> --pat "$TICKY_PAT"
   ```
4. If `--assign "Name"`, run:
   ```bash
   python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py update <ado_id> --assign "Name" --pat "$TICKY_PAT"
   ```
5. Report the ticket number and URL

---

## Legacy Mode: Get

**Trigger:** `/ticky get <ado-id>`

Fetch and display a work item from ADO.

```bash
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py get <id> --pat "$TICKY_PAT"
```

For raw JSON: add `--json` flag.

---

## tickets.json Schema

Per-repo database at `docs/tickets/tickets.json`:

```json
{
  "schema_version": 1,
  "last_sync": "2026-03-02T15:00:00",
  "tickets": {
    "20260302-143000-m365-admin-approval": {
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

- **Key** is the full timestamp prefix + slug (e.g., `20260302-143000-m365-admin-approval`), matching the file naming convention. If two tickets collide on slug, append `-2`, `-3`, etc.
- Create the file if it doesn't exist (empty: `{"schema_version": 1, "last_sync": null, "tickets": {}}`)
- Always update `last_sync` when any operation touches the file
- `status` values: `draft`, `submitted`, `closed`
- `ado_state` mirrors the ADO board state: `New`, `Active`, `Resolved`, `Closed`
- **Status sync rule:** When `ado_state` changes to `Closed` or `Resolved`, automatically set local `status` to `closed` and rename the file suffix from `-submitted.md` to `-closed.md`

---

## Naming Convention

All ticket files follow: `YYYYMMDD-HHMMSS-slug-status.md`

| Part | Example | Notes |
|------|---------|-------|
| Date | `20260302` | Creation date |
| Time | `143000` | Creation time (HHMMSS) |
| Slug | `m365-admin-approval` | See Slug Generation Rules below |
| Status | `draft` or `submitted` | Current lifecycle status |
| Extension | `.md` | Always markdown with YAML frontmatter |

### Slug Generation Rules

1. Convert to lowercase
2. Replace spaces and underscores with hyphens
3. Remove all characters except `a-z`, `0-9`, and `-`
4. Collapse consecutive hyphens into one
5. Remove leading/trailing hyphens
6. Truncate to 50 characters at a word boundary (don't split mid-word)
7. **Collision handling:** If a ticket with the same timestamp+slug already exists in `tickets.json`, append `-2`, `-3`, etc.

Examples:
- `20260302-143000-m365-admin-approval-draft.md`
- `20260302-143000-m365-admin-approval-submitted.md`

---

## Authentication

- PAT stored at: `${TICKY_HOME:-$HOME/repos/ticky}/tickypat.txt`
- **Pass via environment variable** (not CLI argument — CLI args are visible in `ps` output):
  ```bash
  TICKY_PAT="$(cat ${TICKY_HOME:-$HOME/repos/ticky}/tickypat.txt)"
  ```
  Then use `--pat "$TICKY_PAT"` in commands, or export it so ticky.py reads from env.
- Ensure PAT file permissions: `chmod 600 ${TICKY_HOME:-$HOME/repos/ticky}/tickypat.txt`
- Default org/project configured in `~/.ticky.conf`: `membersolutionsinc/DevOps`

---

## Ticky CLI Reference

```bash
# Load PAT once per session (NEVER pass PAT as a bare CLI argument — use env var)
TICKY_PAT="$(cat ${TICKY_HOME:-$HOME/repos/ticky}/tickypat.txt)"

# Validate (YAML, JSON, or MD)
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py validate <file>

# Create (submit to ADO)
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py create <file> --pat "$TICKY_PAT"

# Dry run
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py create <file> --pat "$TICKY_PAT" --dry-run

# Get work item by ID
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py get <id> --pat "$TICKY_PAT"

# Get as raw JSON
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py get <id> --json --pat "$TICKY_PAT"

# Update work item fields
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py update <id> --state Active --pat "$TICKY_PAT"
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py update <id> --assign "Name" --priority 1 --tags "Tag1; Tag2" --pat "$TICKY_PAT"

# Dry-run update
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py update <id> --tags "test" --dry-run --pat "$TICKY_PAT"

# Verbose logging
python3 ${TICKY_HOME:-$HOME/repos/ticky}/ticky.py create <file> --pat "$TICKY_PAT" -v
```

---

## Rollback

If a ticket was submitted in error:

1. **In ADO:** Close or delete the work item manually (ADO does not support API deletion of work items — set state to "Removed")
2. **Locally:** Update the `.md` frontmatter: set `status: draft`, clear `ado_id` and `submitted`
3. **Rename file:** Change `-submitted.md` back to `-draft.md`
4. **Update tickets.json:** Set the entry's `status` to `draft`, clear `ado_id`, `ado_url`, `submitted`

There is no automated retract command — this is intentional to prevent accidental mass-retraction. The steps above are manual and auditable.

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
| Quoted text (no mode keyword) | If text matches an existing file path → Legacy create mode; otherwise → Draft mode (treat as description) |
