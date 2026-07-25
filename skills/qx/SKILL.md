---
name: qx
description: Log a question for any leader (Bryant, Miranda, Arpit, Stefano, Maria, Joanne, Matt, Mario, Lisa, Chad). Takes a first name as the arg, routes to docs/strats/questions/questions4<lastname>.md, and creates a Q<prefix>-NNN row in docs/todo/teamtodo.md so the leader sees the task.
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
argument-hint: "<firstname> [question text]"
reads:
  - config.yaml#team
  - docs/strats/questions/
  - docs/todo/teamtodo.md
---

# /qx — Question for a Leader

Log, route, and track questions for any leader on the EZFacility growth-plan team. Generalizes the old single-leader pattern to the full 10-person exec roster.

## Trigger

User invokes `/qx <firstname>` with optional question text:

- `/qx miranda What's the ETA on the Q3 pricing-tier rewrite?`
- `/qx arpit` — prompts the user for the question, then logs it
- `/qx bryant` — same flow, routes to questions4strozinsky.md
- `/qx` (no args) — print the first-name → file table and exit

## Process

### Step 1 — Parse the first name and look up the leader

Map the first name (lowercase) to the leader using this table (also in `config.yaml` → `team`):

| First | Last | Q-prefix | File |
|---|---|---|---|
| bryant | strozinsky | QB | `docs/strats/questions/questions4strozinsky.md` |
| miranda | pruitt | QMP | `docs/strats/questions/questions4pruitt.md` |
| arpit | madan | QA | `docs/strats/questions/questions4madan.md` |
| stefano | tromba | QS | `docs/strats/questions/questions4tromba.md` |
| maria | conlin | QC | `docs/strats/questions/questions4conlin.md` |
| joanne | lloyd | QJ | `docs/strats/questions/questions4lloyd.md` |
| matt | likuski | QML | `docs/strats/questions/questions4likuski.md` |
| mario | maravolo | QM | `docs/strats/questions/questions4maravolo.md` |
| lisa | cannon | QL | `docs/strats/questions/questions4cannon.md` |
| chad | townsend | QCT | `docs/strats/questions/questions4townsend.md` |

If the first name isn't in the table, print: "Unknown leader. Roster: bryant, miranda, arpit, stefano, maria, joanne, matt, mario, lisa, chad."

### Step 2 — Identify the asker

Read `git config user.email` and match against `config.yaml` → `team[].email` to determine the asker's full name. Fall back to `git config user.name`. If still unknown, prompt: "Who's asking? (your first name)".

### Step 3 — Get the question text

If the user passed question text on the command line, use it. Otherwise prompt: "What's the question for <firstname>?"

Keep questions to **one line** in the file. If the user gives multi-paragraph context, ask them to compress it to a single decision-oriented sentence (1 question per row); save the context inline as part of the same line if needed.

### Step 4 — Find the next sequence number

Read the target `questions4<lastname>.md` file. Count existing data rows (skip the header). The next number is `(count + 1)`, zero-padded to 3 digits. Combined with the Q-prefix this becomes the task ID, e.g., `QMP-007`.

### Step 5 — Append to the questions file

Append one row to the questions file in this format:

```
| YYYY-MM-DD | <asker first name> | <question> | _pending_ | OPEN |
```

Columns: `date_asked | asker | question | answer | status`. Preserve the existing table header. Don't reformat the file.

### Step 6 — Create the teamtodo row

Append a row to `docs/todo/teamtodo.md`:

```
| Q<prefix>-NNN | Answer: "<short title of question>" | <leader full name> | YYYY-MM-DD (today + 7 days) | P1 | OPEN | Q | Asked by <asker>. See docs/strats/questions/questions4<lastname>.md row #NNN. |
```

Columns (per spec §4.2): `id | title | owner | due_date | priority | status | type | notes`. Type is `Q` (question). Default priority is `P1`; promote to `P0` only if the asker says it blocks a decision.

### Step 7 — Confirm

Tell the asker: "Logged as `Q<prefix>-NNN` in `docs/strats/questions/questions4<lastname>.md` and added to `docs/todo/teamtodo.md`. <firstname> sees this in `/mytodo <firstname>`."

## Examples

- `/qx miranda What's our Q3 hiring plan for support?` → appends to `questions4pruitt.md`, creates `QMP-NNN` in teamtodo.
- `/qx arpit Can we pilot enterprise with 3 customers this quarter?` → `questions4madan.md` + `QA-NNN`.
- `/qx bryant` (then user types the question at prompt) → `questions4strozinsky.md` + `QB-NNN`.

## Quality standards

- **One question per row.** Multi-part questions get split into multiple `/qx` invocations or noted as sub-questions in the same row.
- **Frame for the leader, not for Claude.** Decision-oriented, time-bound, with enough context that the leader doesn't have to ping the asker.
- **Don't re-ask answered questions.** Before appending, grep the target file for similar wording. If a near-match exists with status `ANSWERED` or `DECIDED`, surface it to the asker first.
- **Asker accountability.** The asker's first name is always recorded so follow-ups have someone to ping.

## Why the generalization

The earlier single-leader question pattern was hard-coded to one recipient. bigify has 10 leaders and questions flow in both directions (Bryant → directs, directs → Bryant, peer → peer). `/qx <firstname>` covers all 10 routes with the same UX.
