---
name: wrapit
description: Wrap up the current session into one durable recap under docs/wrapit/ — fuses the conversation arc, decisions, commits, uncommitted work, docs touched, and external links, then (after confirming) invokes relevant panel skills like /pm and /staff and references their artifacts. Use when the user says "/wrapit", "wrap up this session", "write up what we did", or wants a recap a future session can read to get up to speed.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill
argument-hint: "[optional-slug] — kebab-case label for the recap filename (auto-derived if omitted)"
---

# /wrapit — Session Wrap-Up Recap

Produce a detailed, durable write-up of the current working session so a future session — or a teammate — can
read **one file**, follow its links, and be fully up to speed. The recap fuses the conversation, decisions,
commits, uncommitted work, docs/artifacts touched, and external references. When the session warrants it,
`/wrapit` offers to bring in panel skills (`/pm`, `/staff`, …) and **references** their artifacts rather than
duplicating them.

> Born from the pattern: at the end of a meaty session you want a single recap that captures *everything that
> matters* — not just a diary entry (`scribe`), not just a transcript dump (`snapshot`), not just git stats
> (`changeloggy`). `/wrapit` is the comprehensive "state of play, with pointers to everything" artifact.

## Trigger

- `/wrapit` — wrap the current session; auto-derive the slug.
- `/wrapit <slug>` — wrap with an explicit kebab-case slug (e.g. `/wrapit ads-account-map`).
- Natural language: "wrap up this session", "write up what we did so we can pick it up later".

## Scope of a recap

Default window = **current session + uncommitted work**:
1. **Conversation** — this session's live transcript (the most-recently-modified `.jsonl` in this repo's project dir).
2. **Commits** — commits made during the session (current user, recent; cross-checked against the conversation).
3. **Uncommitted work** — `git status`, staged/unstaged diff summary, untracked files at wrap time.
4. **Docs & artifacts** — files created or modified under the repo's brain (docs/…), with links.
5. **External references** — URLs, dashboards, tickets, named conversations surfaced during the session.
6. **Panel inputs** — optional `/pm`, `/staff`, etc., referenced by link.

## How it is repo-aware

`/wrapit` is **global** but adapts to the repo it runs in:
- Always resolves the repo root and writes to `<repo>/docs/wrapit/`.
- Offers `/pm` **only if** `docs/pm/` exists; offers `/staff` **only if** the skill is available and the session
  has a design/decision worth reviewing.
- In a repo with no brain, it still writes a clean plain recap (no panel offers).

---

## Instructions (model-facing)

Follow these phases in order. Keep the user informed with short status lines; don't dump raw command output.

### Phase 0 — Resolve context

Run one Bash block to gather everything the recap needs. Do **not** paste its full output to the user.

```bash
set -e
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "NOT_A_REPO"; exit 0; }
REPO_NAME=$(basename "$REPO_ROOT")
NOW=$(date +%Y%m%d-%H%M)            # filename stamp (YYYYMMDD-HHMM, 24h — required convention)
NOW_HUMAN=$(date "+%Y-%m-%d %H:%M")
USER_NAME=$(git config user.name)
USER_EMAIL=$(git config user.email)

echo "REPO_ROOT=$REPO_ROOT"
echo "REPO_NAME=$REPO_NAME"
echo "NOW=$NOW"
echo "NOW_HUMAN=$NOW_HUMAN"

# Brain capability detection (drives which panels we offer)
[ -d "$REPO_ROOT/docs/pm" ] && echo "HAS_PM=1" || echo "HAS_PM=0"
[ -f "$REPO_ROOT/docs/STATE.md" ] && echo "HAS_STATE=1" || echo "HAS_STATE=0"

# Live session transcript = most-recently-modified .jsonl in this repo's project dir
SANITIZED=$(echo "$REPO_ROOT" | sed 's#/#-#g')
PROJ_DIR="$HOME/.claude/projects/$SANITIZED"
TRANSCRIPT=$(ls -t "$PROJ_DIR"/*.jsonl 2>/dev/null | head -1)
echo "PROJ_DIR=$PROJ_DIR"
echo "TRANSCRIPT=${TRANSCRIPT:-NONE}"

# Git signals (session window): recent commits by this user + working-tree state
echo "--- RECENT_COMMITS ---"
git -C "$REPO_ROOT" log --author="$USER_EMAIL" --since="16 hours ago" --pretty=format:'%h%x09%ad%x09%s' --date=short 2>/dev/null | head -40
echo
echo "--- GIT_STATUS ---"
git -C "$REPO_ROOT" status --short 2>/dev/null
echo "--- DIFFSTAT_STAGED ---"
git -C "$REPO_ROOT" diff --staged --stat 2>/dev/null | tail -40
echo "--- DIFFSTAT_UNSTAGED ---"
git -C "$REPO_ROOT" diff --stat 2>/dev/null | tail -40

# Prior wrap (for continuity link) + ensure output dir
mkdir -p "$REPO_ROOT/docs/wrapit"
echo "--- PREV_WRAP ---"
ls -t "$REPO_ROOT"/docs/wrapit/*.md 2>/dev/null | grep -v INDEX | head -1
```

- If output is `NOT_A_REPO`, tell the user `/wrapit` must run inside a git repo and stop.
- Note `HAS_PM` / `HAS_STATE` and the available skills list — these gate Phase 3.
- Capture `TRANSCRIPT` for the verbatim copy and for reconstructing the conversation arc.

### Phase 1 — Reconstruct the session

You already hold most of the session in your own context — **use it directly** as the primary source. Supplement
with the transcript only if you need to recover detail from earlier in a long session:

- If the transcript is large, extract the user's asks to trace the arc:
  ```bash
  grep '"type":"user"' "$TRANSCRIPT" 2>/dev/null | tail -60
  ```
- Identify: the goal(s), how they evolved, decisions made (and *why*), what was produced, what's unresolved.
- Cross-reference commits and the working-tree diff against the conversation so the "Work produced" section is
  grounded in fact, not memory.

### Phase 2 — Derive the slug

- If the user passed an argument, use it verbatim (kebab-case it if needed).
- Otherwise auto-derive a short kebab-case slug from the session's dominant theme
  (e.g. `google-ads-account-map-design`, `partner-program-audit`). 3–6 words max.
- Final filename stem: `<NOW>-<slug>` → e.g. `20260604-1642-google-ads-account-map-design`.

### Phase 3 — Offer panel skills (auto-detect, then confirm)

Decide which panel skills would *add value to the recap*, then present a one-line confirmation. Only consider
skills that are actually available and applicable:

- **`/pm`** — offer if `HAS_PM=1` **and** the session shipped/changed work that should update sprint/backlog state.
- **`/staff`** — offer if the session produced a non-trivial design or architectural decision worth a panel review.
- Other repo-relevant skills (e.g. `/exec-review`, `/librarian`) — offer only if clearly relevant.

Present like:
> This session designed a new lake table + build plan. I can fold in:
> • `/pm` — update sprint/backlog with the new work item
> • `/staff` — panel review of the schema before you build
> Run both, pick some, or skip? (I'll **reference** their output in the wrap, not duplicate it.)

On approval, invoke each via the `Skill` tool, let it write its own artifact normally, and capture the **path +
a 2-line summary** of what it produced. If the user skips, proceed with no panel section.

### Phase 4 — Write the recap

Write `<REPO_ROOT>/docs/wrapit/<stem>.md` with this structure. Link files as clickable repo-relative paths.
**Never paste raw customer rows** — link to the source file instead (repo data-hygiene rule).

```markdown
---
date: <NOW_HUMAN>
slug: <slug>
repo: <REPO_NAME>
session_transcript: ./<stem>.jsonl
prev_wrap: <relative link to previous wrap, or "none">
---

# Session Wrap — <Title Case Slug>

> **Prev wrap:** [<prev stem>](<prev link>)   ·   **Transcript:** [verbatim .jsonl](./<stem>.jsonl)

## TL;DR
- <3–5 bullets: what this session was, what changed, where it stands>

## What we set out to do
<the original goal and how it evolved through the session>

## Decisions made
- **<decision>** — <rationale; link any decision record / brainstorm>
- ...

## Work produced
**Commits**
- `<hash>` <subject>
- ...

**Files created / modified**
- `path/to/file` — <one line>
- ...

**Uncommitted at wrap time**
- <git status summary: staged / unstaged / untracked — what they are and why>

## Docs & artifacts
- [<doc title>](<repo-relative path>) — <what it is>
- ...

## Panel inputs
- **/pm** → [<artifact>](<path>) — <2-line summary>      (omit section if none run)
- **/staff** → [<artifact>](<path>) — <2-line summary>

## External references
- <URL / dashboard / ticket / conversation> — <what it is>
- ...

## Open threads / next steps
- [ ] <what's unresolved, what the next session should pick up>
- ...
```

Then **copy the verbatim transcript** next to the recap (same stem), and link is already in the front-matter:

```bash
[ -n "$TRANSCRIPT" ] && [ "$TRANSCRIPT" != "NONE" ] && cp "$TRANSCRIPT" "$REPO_ROOT/docs/wrapit/<stem>.jsonl" && echo "transcript copied"
```

### Phase 5 — Update the index

Maintain `docs/wrapit/INDEX.md` (newest first; create with a header if absent). Prepend one line:

```
- <YYYY-MM-DD HH:MM> — <slug> — [recap](./<stem>.md) · [transcript](./<stem>.jsonl)
```

If `INDEX.md` doesn't exist, create it:
```markdown
# Wrapit Index

Session wrap-ups for this repo, newest first. Each recap is a complete "state of play" with links to commits,
docs, and the verbatim transcript. Read the top entry to get up to speed.

```

### Phase 6 — Report

Tell the user, concisely:
- The recap path (clickable) and the transcript path.
- Which panel skills ran and where their artifacts landed.
- The INDEX entry was added.
- A one-line pointer: "Next session: read this file to get up to speed."

---

## Notes & boundaries

- **Additive, not authoritative.** `/wrapit` does not rewrite `docs/STATE.md` or own the captain's log — it
  **links** the artifacts that `/pm`, `scribe`, etc. produce. Keeps surfaces from fighting.
- **Composes with siblings:** `snapshot` (mid-session transcript), `scribe`/captain's log (narrative diary),
  `changeloggy` (cross-range git report), `repo-activity` (daily weeklyops log). `/wrapit` is the end-of-session
  comprehensive recap that points at all of them.
- **Naming rule (global):** filenames are always `YYYYMMDD-HHMM-slug` — 24h time, never date-only.
- **No clobber:** every run writes a new timestamped file; INDEX prepend is append-only-safe.
