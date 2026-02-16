# Ticky — Azure DevOps Work Item Submission

Usage: `/ticky [path-to-ticket.yaml] [--assign "Name"]`

**Arguments:** $ARGUMENTS

---

## Purpose

Submit work items (tickets) to Azure DevOps using the ticky CLI. Creates issues, tasks, bugs, or feature requests for the DevOps board with proper formatting and optional assignment.

---

## Instructions for Claude

### 0. Parse Arguments

Extract file path and optional `--assign` flag from: `$ARGUMENTS`

**If a YAML file path is provided:**

1. Validate the file exists and has required fields (`title`, `description`)
2. Optionally dry-run first: `python3 /Users/msichris/repos/ticky/ticky.py validate <file>`
3. Submit: `python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"`
4. If `--assign "Name"` is specified, PATCH the created work item to assign it
5. Report the ticket number and URL

**If no file is provided (just a description of the ticket):**

1. Create the ticket YAML file in `docs/tickets/` following the naming convention:
   - YAML: `ticky-<short-name>.yaml`
   - MD: `YYYYMMDD-ticket-<short-name>.md`
2. Use the standard YAML format (see Template below)
3. Submit via ticky CLI as above
4. Update `docs/tickets/CHANGELOG.md` with the new ticket

---

## Authentication

- PAT stored at: `/Users/msichris/repos/ticky/tickypat.txt`
- Pass via: `--pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"`
- Default org/project configured in `~/.ticky.conf`: `membersolutionsinc/DevOps`

---

## Assigning Work Items

After creation, assign via ADO REST API PATCH:

```bash
python3 -c "
import base64, json, urllib.request
pat = open('/Users/msichris/repos/ticky/tickypat.txt').read().strip()
auth = base64.b64encode(f':{pat}'.encode()).decode()
patches = json.dumps([{'op': 'add', 'path': '/fields/System.AssignedTo', 'value': 'ASSIGNEE_NAME'}]).encode()
req = urllib.request.Request('https://dev.azure.com/membersolutionsinc/DevOps/_apis/wit/workitems/TICKET_ID?api-version=7.0', data=patches, method='PATCH')
req.add_header('Content-Type', 'application/json-patch+json')
req.add_header('Authorization', f'Basic {auth}')
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read().decode())
    print(f'Assigned to: {result[\"fields\"][\"System.AssignedTo\"][\"displayName\"]}')
"
```

Replace `ASSIGNEE_NAME` and `TICKET_ID` with actual values.

---

## Ticket YAML Template

```yaml
title: "Project: <Short description>"
type: Issue
priority: 2
tags: "Project; relevant-tags"
description: |
  <h2>Description</h2>
  <p>What needs to happen and why.</p>

  <h2>What's Needed</h2>
  <p><strong>Specific action required.</strong></p>

  <h2>Steps to Complete</h2>
  <table border="1" cellpadding="6" cellspacing="0">
  <tr style="background-color:#1B3A5C;color:#FFFFFF;"><th>Step</th><th>Action</th></tr>
  <tr><td>1</td><td>First step</td></tr>
  <tr style="background-color:#F2F6FA;"><td>2</td><td>Second step</td></tr>
  </table>

  <h2>Reference</h2>
  <table border="1" cellpadding="6" cellspacing="0">
  <tr style="background-color:#1B3A5C;color:#FFFFFF;"><th>Item</th><th>Value</th></tr>
  <tr><td>Account</td><td>Account ID</td></tr>
  <tr style="background-color:#F2F6FA;"><td>Repo</td><td>Repo URL</td></tr>
  </table>

  <h2>Impact if Not Resolved</h2>
  <p>What happens if this isn't done.</p>

  <h2>Estimated Time</h2>
  <p><strong>X minutes</strong></p>

  <h2>Contact</h2>
  <p><strong>Requestor:</strong> name<br/>
  <strong>Email:</strong> email@example.com<br/>
  Available for questions or a quick call if needed.</p>
```

---

## Ticky CLI Reference

```bash
# Validate without submitting
python3 /Users/msichris/repos/ticky/ticky.py validate <file>

# Dry run (show payload)
python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)" --dry-run

# Submit for real
python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)"

# With verbose logging
python3 /Users/msichris/repos/ticky/ticky.py create <file> --pat "$(cat /Users/msichris/repos/ticky/tickypat.txt)" -v
```

---

## After Submission

1. Note the ticket number from ticky output (e.g., `#5272`)
2. Assign to the right person (if requested)
3. Update `docs/tickets/CHANGELOG.md` — add to Outstanding table and Ticket Details section
4. The YAML and MD files in `docs/tickets/` serve as the git-tracked record
