---
name: discuss-jenmatrix
description: jenmatrix-project variant of /discuss — voice-friendly contributor communications for docs/discussions/. File threads (addressed to a contributor) or journals (running notes), reply to existing threads, list/show entries, and regenerate INDEX.md. Contributor identities are hard-wired to the jenmatrix project (msifoss, jennifer97-display).
---

# /discuss — Contributor Communications

Files contributor messages into `docs/discussions/<github-id>/` and keeps `INDEX.md` regenerated. Designed for **voice dictation** — the user speaks, Claude infers structure, files the entry, and confirms with one short sentence.

## Author identity (jenmatrix project)

- The dictator is **`msifoss`**. All entries authored in this session go under `docs/discussions/msifoss/`.
- Known contributors: `msifoss`, `jennifer97-display`. New GitHub IDs are accepted without confirmation — Claude creates the folder if missing.

## Single discussion surface

jenmatrix has **one** discussions root: `docs/discussions/`. There is **no `--project` flag** and no per-project namespace. Scoping is done with tags. If a future user asks for `/discuss --project webengine`, decline and point them at the tag-based pattern below — that decision came from the 2026-05-21 staff panel ([`docs/key_findings/20260521-0800-brain-system-Staff-Engineer-Panel.md`](../../../docs/key_findings/20260521-0800-brain-system-Staff-Engineer-Panel.md)).

## Canonical tag vocabulary

Use these tags to scope discussions. Pick the narrowest that fits; combine when an entry crosses categories.

**Project scope tags (pick one):**
- `strategy` — portfolio-level / cross-project strategy. No specific project.
- `cross-project` — affects 2+ implementation projects.
- `webengine` — primarily about `../webengine`.
- `agent1` — primarily about `../agent1`.
- `97ddata` — primarily about `../97ddata` (future repo).

**Topical tags (add 0–2):**
- `coordination`, `handoff`, `decision`, `blocker`, `onboarding`, `runbook`, `architecture`, `customer-migrate`, `crm`, `agents`, `eval`

Add new tags only when none of the above fits. The frontmatter `tags:` array is the source of truth — `INDEX.md` surfaces them in the table.

## Subactions

| Trigger | Action |
|---|---|
| `/discuss file <freeform>` or unprefixed dictation that fits | Create a new entry |
| `/discuss reply <freeform>` or "reply to <id> ..." | Continue an existing thread |
| `/discuss regenerate` or "regenerate the index" | Run the regenerator |
| `/discuss list [filter]` or "what's open / what has X said / what's recent" | Render filtered view of INDEX |
| `/discuss show <github-id or path>` | Open and summarize a specific entry |

Default action when ambiguous: **file**.

## Type inference (the voice-friendly part)

When the user dictates, decide between `thread` and `journal` from the content:

- **thread** — the dictation addresses a person ("tell jennifer97-display", "ask jen", "message jen about ...", "to jennifer97-display:"), OR mentions a contributor's GitHub ID as the recipient.
- **journal** — the dictation is in first person without an addressee ("today I figured out", "note to self", "running notes on ...").
- **Ambiguous?** Pick `thread` if a GitHub ID appears anywhere; otherwise `journal`. Do NOT ask the user to confirm type — voice flow stays smooth. If you're truly unsure (e.g. "thoughts on the matrix" with no addressee and no first-person framing), default to `journal` and mention "filed as journal" in the confirmation so the user can correct in the next breath.

## Filing flow

### 1. Parse the dictation

Extract:
- **Addressee** (if any) — first GitHub-ID-like token referenced as a recipient. Map common heard-forms to canonical IDs (e.g. "jen" → `jennifer97-display`).
- **Topic** — derive a kebab-case slug (3–5 words) from the first sentence
- **Tags** — pick 1–3 from the canonical vocabulary above (project scope: `strategy`, `cross-project`, `webengine`, `agent1`, `97ddata`; topical: `coordination`, `handoff`, `decision`, `blocker`, `onboarding`, `runbook`, `architecture`, `customer-migrate`, `crm`, `agents`, `eval`). Every entry should carry exactly one project-scope tag. Add new topical tags only when none fit.
- **Status** — `open` by default for threads (expects reply), `fyi` for journals (no response expected). Use `answered` or `resolved` only when explicitly stated.
- **Summary** — one specific sentence. Write it yourself from the dictation; do NOT echo the user's first line verbatim if you can compress it.

### 2. Compute the filename

```
docs/discussions/msifoss/<YYYYMMDD>-<HHMM>-<slug>.md
```

- Date/time = current local time, formatted UTC in frontmatter
- Slug = kebab-case, 3–5 words, alphanumeric + hyphens only
- If a file with that exact name already exists, append `-2`, `-3`, etc.

### 3. Write the file with frontmatter

```yaml
---
author: msifoss
date: <ISO 8601 UTC>
type: thread            # or journal
status: open            # or fyi / answered / resolved
summary: <one specific sentence>
tags: [<1-3 tags>]      # omit field if none
participants: [msifoss, <addressee>]   # threads only
---

<body — the user's dictated content, lightly cleaned for punctuation and obvious transcription errors but NOT paraphrased>
```

**Body rules:**
- Preserve the user's voice. Light cleanup (capitalization, punctuation, paragraph breaks) only.
- Do NOT add headers, summaries, or "context" the user didn't dictate.
- If the dictation includes an obvious greeting ("hey jen,") keep it.
- If the dictation includes voice artifacts ("um", "you know"), remove them.

### 4. Regenerate INDEX.md automatically

Run `python3 scripts/regen_discussions_index.py` after every `file` or `reply`. If it exits non-zero, surface the error to the user — do not claim success.

### 5. Confirm in one sentence

```
Filed thread to jennifer97-display at docs/discussions/msifoss/20260521-1430-handoff-question.md and regenerated the index.
```

Or for a journal:

```
Filed journal at docs/discussions/msifoss/20260521-1500-implementation-notes.md.
```

If type was ambiguous and you defaulted:

```
Filed as journal (no addressee detected) at <path>. Say "make that a thread to <id>" if you want it re-filed.
```

## Reply flow

When the user says "reply to jennifer97-display" or "respond to <id> about <topic>":

1. Locate the most recent matching thread:
   - Most recent entry in `docs/discussions/<id>/` with `type: thread` and `status: open` or `answered`
   - If multiple match, pick the one whose tags/summary best match the topic in the dictation
   - If still ambiguous, ask: "Reply to which? [show 2–3 candidates with date + summary]"
2. File the reply as a new entry under `docs/discussions/msifoss/`:
   - `type: thread`
   - `replies-to: <id>/<filename>`
   - `participants: [msifoss, <id>]`
   - `tags:` — inherit from parent thread unless the dictation introduces new ones
3. Update the parent thread's `status` from `open` to `answered` (write the file back with the updated frontmatter).
4. Regenerate INDEX.

## List flow

When the user says "what's open" / "what's recent" / "what has jen said":

- For "what's open" — filter INDEX by `status: open`, render the rows
- For "what's recent" — show the top 10 rows of INDEX
- For "what has <id> said" — `ls docs/discussions/<id>/` and read frontmatter summaries
- For "what's been said about <topic>" — grep tags or summaries for the topic

Do NOT open every file. Trust the summary column. Open a specific file only if the user follows up with "show me that one."

## Regenerate-only flow

When the user says "regenerate the index" or "/discuss regenerate":

```bash
python3 scripts/regen_discussions_index.py
```

Surface the output ("wrote docs/discussions/INDEX.md (N entries)") and any errors. This is the explicit form for after manual edits.

## Voice-mode rules

- **One short confirmation sentence** after filing. The user is dictating — long confirmations interrupt flow.
- **No clarifying questions** unless ambiguity is real (e.g. multiple matching reply threads). Type inference, slug, tags, status: decide and move on.
- **Don't read entries back** unless asked. The user knows what they dictated.
- **GitHub IDs are case-sensitive** in folder paths but the user may say them differently ("jen" → `jennifer97-display`). Map heard-form to the canonical folder name silently.

## Failure modes to avoid

| Don't | Do |
|---|---|
| Ask "thread or journal?" every time | Infer from the dictation |
| Paraphrase the body | Light cleanup only |
| Hand-edit INDEX.md | Edit frontmatter, then regenerate |
| File under jen's folder because the message is *to* jen | File under msifoss/ — author owns the folder |
| Skip regeneration "because the user will run it later" | Run it every time, automatically |
| Write a "summary of the discussion" as the body | Body is the dictated content; summary lives in frontmatter |

## Example: dictated → filed

**User says (voice):**
> "Tell jen I'm going to start on the customer migration runbook tonight and need her to confirm the registrar list by tomorrow. Tag this coordination and runbook."

**Claude does:**

Writes `docs/discussions/msifoss/20260521-1430-customer-migration-runbook-start.md`:

```yaml
---
author: msifoss
date: 2026-05-21T14:30:00Z
type: thread
status: open
summary: Telling jen I'm starting the customer migration runbook tonight and need the registrar list confirmed by tomorrow.
tags: [coordination, runbook]
participants: [msifoss, jennifer97-display]
---

Hey jen — I'm going to start on the customer migration runbook tonight and need you to confirm the registrar list by tomorrow.
```

Runs the regenerator. Confirms: "Filed thread to jennifer97-display at docs/discussions/msifoss/20260521-1430-customer-migration-runbook-start.md and regenerated the index."
