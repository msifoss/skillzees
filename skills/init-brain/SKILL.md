---
name: init-brain
description: Retrofit a knowledge management brain into any existing repo — memory index, state snapshot, strategy docs, key findings, insights, meetings, and notes
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: ""
---

# /init-brain — Retrofit Knowledge Brain into Existing Repo

Add a structured knowledge management system to any existing repo. Interactive — walks through questions to build a tailored brain rather than stamping a generic template.

Modeled after the 97plan brain system: hierarchical documentation, timestamped findings with supersession tracking, leadership decision logs, and a single-page state snapshot.

## Trigger

User invokes `/init-brain` with no arguments. Must be run from within a git repo.

---

## Phase 1: Detect Existing Structure

Scan the repo for existing brain-like structures. Check for:

```
.claude/memory/MEMORY.md    — brain index
docs/STATE.md               — project state snapshot
docs/strats/                — strategy documents
docs/key_findings/          — timestamped panel outputs / findings
docs/key_findings/INDEX.md  — findings index with supersession tracking
docs/key_insights/          — durable analysis and reference docs
docs/meetings/              — meeting notes archive
docs/todo/                  — task tracking (general, not sprint-specific)
docs/pm/                    — sprint/bolt system
notes.txt                   — scratch pad
CLAUDE.md                   — project operating manual
```

Also detect existing task management systems:
- `docs/pm/CURRENT-SPRINT.md` or similar sprint files
- Any `*todo*` or `*task*` files
- `docs/tickets/` or issue tracking

### Report to user:

```
Brain Scan Results:
  .claude/memory/MEMORY.md .... MISSING (will create)
  docs/STATE.md ............... MISSING (will create)
  docs/strats/ ................ MISSING (will create)
  docs/key_findings/ .......... EXISTS (9 files)
  docs/key_findings/INDEX.md .. MISSING (will create)
  docs/key_insights/ .......... MISSING (will create)
  docs/meetings/ .............. MISSING (will create)
  notes.txt ................... MISSING (will create)

  Existing task system: docs/pm/ (Bolt sprint system) — will not create docs/todo/
```

Wait for user confirmation: "Ready to build? (yes / skip any of the above)"

---

## Phase 2: Interactive STATE.md Builder

Walk through these questions one at a time. Assemble STATE.md from the answers.

1. "What does this project do in one sentence?"
2. "What's the current version or status?" (check CLAUDE.md, package.json, pyproject.toml, Cargo.toml for hints — offer what you find)
3. "Who are the key people and their roles? (one per line: Name — Role)"
4. "What are the active risks or blockers? (one per line, or 'none')"
5. "Any upcoming gates, milestones, or deadlines? (one per line, or 'none')"
6. "What key metrics matter for this project? (test count, uptime, users, revenue — whatever applies)"

### STATE.md Template

```markdown
# {Project Name} — State of Play

**Last updated:** {today's date}
**Updated by:** {user name}

## Scoreboard
{assembled from version/status answers + auto-detected metrics}

## Team
{from people answer}

## Active Risks
{from risks answer, numbered}

## Gates & Milestones
{from gates answer}

## Key Metrics
{from metrics answer}
```

---

## Phase 3: Interactive MEMORY.md Builder

Walk through these questions. Build .claude/memory/MEMORY.md from answers + auto-detection.

1. Auto-detect critical files:
   - CLAUDE.md, config.yaml, config.json, package.json, pyproject.toml, Makefile, docker-compose.yml
   - Any existing docs/STATE.md, docs/pm/*.md, docs/strats/*.md
   - Report what was found

2. "Who are the key people? (same list from STATE.md, or adjust)"
   - Use the list from Phase 2 if already provided

3. "Any dashboards, reports, or external tools to track? (URL — description, one per line, or 'none')"

4. "Any key decisions already made that should be recorded? (one per line, or 'none')"

### MEMORY.md Template

```markdown
# {Project Name} Brain

## People
{from people list}

## Current State
- [STATE.md](../../docs/STATE.md) — project snapshot
{auto-detected sprint/task/backlog links}

## Strategy & Decisions
{from decisions list, or placeholder}

## Key References
{auto-detected critical files with relative paths}

## Dashboard / Report Registry
{from dashboards list, or "(populated as reports are created)"}

## Key Decisions
{from decisions list, or "(recorded as decisions are made)"}
```

---

## Phase 4: Leadership Question Log

Ask: "Is there a key decision-maker who needs a question log? (name, or 'skip')"

If a name is provided:
- Create `docs/strats/questions4{name_lowercase}.md`
- Populate with header and empty table:

```markdown
# Questions for {Name}

Leadership decisions that need {role} input. Each question gets an ID, status, and answer when resolved.

| ID | Question | Status | Asked | Answered | Answer |
|----|----------|--------|-------|----------|--------|
```

If skipped, still create `docs/strats/` directory.

---

## Phase 5: Key Findings Index

If `docs/key_findings/` exists but `docs/key_findings/INDEX.md` does not:
- Scan existing files in key_findings/
- Build an INDEX.md with current vs superseded sections:

```markdown
# Key Findings Index

## Current (use these)

| Date | File | Topic |
|------|------|-------|
{list of existing files, parsed from filenames}

## Superseded (kept for historical reference)

(none yet)
```

If `docs/key_findings/` doesn't exist, create it with INDEX.md containing empty tables.

---

## Phase 6: Scaffold Remaining

Create any remaining missing pieces with minimal content:

- `docs/key_insights/.gitkeep` — if directory missing
- `docs/meetings/.gitkeep` — if directory missing
- `notes.txt` — if missing, create with:
  ```
  Scratch pad — ad-hoc research, questions, clipboard content.

  ---

  ```
- `docs/todo/teamtodo.md` — ONLY if no existing task system was detected. Template:
  ```markdown
  # Team Todo

  | ID | Task | Owner | Status | Priority | Due |
  |----|------|-------|--------|----------|-----|
  ```

---

## Phase 7: Report

Summarize everything created:

```
Brain initialized:

  Created:
    .claude/memory/MEMORY.md
    docs/STATE.md
    docs/strats/questions4bryant.md
    docs/key_findings/INDEX.md
    docs/key_insights/
    docs/meetings/
    notes.txt

  Preserved (already existed):
    docs/key_findings/ (9 files)
    docs/pm/ (sprint system)

  Skipped:
    docs/todo/ (existing sprint system detected)
```

Ask: "Want to commit these files? (yes / no)"

If yes, stage and commit with message: "init-brain: add knowledge management brain"

---

## Edge Cases

- **No docs/ directory:** Create it
- **Partial brain:** Only create missing pieces, never overwrite existing files
- **No CLAUDE.md:** Note it — suggest running `/init-project` first, but continue
- **Monorepo:** Brain goes at repo root
- **Empty repo:** Works fine — full structure created
- **.claude/memory/ has existing files:** Preserve them, only add MEMORY.md if missing
- **User skips a question:** Use sensible defaults or leave section empty with placeholder
- **Not in a git repo:** Warn and offer to continue anyway (files still useful without git)
