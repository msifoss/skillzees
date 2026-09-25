---
name: discuss
description: Voice-friendly contributor discussions logged to docs/discussions/<contributor>/. Reads project name and contributor roster from the target repo's config.yaml.
---

# /discuss — Contributor Communications

Files contributor messages into `docs/discussions/<github-id>/` and keeps `INDEX.md` regenerated. Designed for **voice dictation** — the user speaks, Claude infers structure, files the entry, and confirms with one short sentence.

## Configuration (required)

Before doing anything, read `config.yaml` at the target repo root. All project-specific identity comes from that file — this skill contains **no** hardcoded project names, contributor IDs, or tag lists.

### Expected schema

```yaml
project:
  # Short project name, used only in confirmation messages and error surfaces.
  name: my-project

  # The dictator (the human running this session). Their entries land under
  # docs/discussions/<author>/. If omitted, fall back to the git user's login.
  author: msifoss

  # Known contributors. GitHub IDs are the canonical folder names.
  # `aliases` lets voice heard-forms map cleanly ("jen" → jennifer97-display).
  contributors:
    - github_id: msifoss
      display_name: Chris Fossenier
      aliases: [chris, cf]
    - github_id: cgeorge-ms
      display_name: Cliff George
      aliases: [cliff, see-george-ms, cgeorge]

  # Tag vocabulary. Two flavors are supported — pick whichever the project uses:
  #
  # (a) Flat list — a single pool of allowed tags:
  #
  #     tag_vocabulary:
  #       - tbac
  #       - isolation
  #       - mcp
  #       - architecture
  #       - onboarding
  #       - runbook
  #
  # (b) Structured — a required project-scope tag plus optional topical tags:
  #
  #     tag_vocabulary:
  #       project_scope:        # exactly one required per entry
  #         - strategy
  #         - cross-project
  #         - webengine
  #         - agent1
  #       topical:              # 0–2 additional
  #         - coordination
  #         - handoff
  #         - decision
  #         - blocker
  #         - runbook
  #         - architecture
  tag_vocabulary:
    - example-tag-1
    - example-tag-2
```

New GitHub IDs (not in `contributors`) are accepted without confirmation — Claude creates the folder if missing. New tags are accepted only when nothing in `tag_vocabulary` fits.

If `config.yaml` is missing or lacks a `project.author`, ask the user once for the author's GitHub ID and proceed; do not invent one.

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

- **thread** — the dictation addresses a person ("tell <id>", "ask <alias>", "message <id> about ...", "to <id>:"), OR mentions a contributor's GitHub ID as the recipient.
- **journal** — the dictation is in first person without an addressee ("today I figured out", "note to self", "running notes on ...").
- **Ambiguous?** Pick `thread` if a GitHub ID or alias appears anywhere; otherwise `journal`. Do NOT ask the user to confirm type — voice flow stays smooth. If you're truly unsure (no addressee, no first-person framing), default to `journal` and mention "filed as journal" in the confirmation so the user can correct in the next breath.

## Filing flow

### 1. Parse the dictation

Extract:
- **Addressee** (if any) — first GitHub-ID-like token or configured `alias` referenced as a recipient. Map heard-forms to the canonical `github_id` from `config.yaml`.
- **Topic** — derive a kebab-case slug (3–5 words) from the first sentence.
- **Tags** — pick 1–3 from `project.tag_vocabulary` in `config.yaml`. If the vocabulary is structured (`project_scope` + `topical`), every entry must carry exactly one `project_scope` tag plus 0–2 `topical` tags. Add new tags only when none of the configured tags fit.
- **Status** — `open` by default for threads (expects reply), `fyi` for journals (no response expected). Use `answered` or `resolved` only when explicitly stated.
- **Summary** — one specific sentence. Write it yourself from the dictation; do NOT echo the user's first line verbatim if you can compress it.

### 2. Compute the filename

```
docs/discussions/<author>/<YYYYMMDD>-<HHMM>-<slug>.md
```

- `<author>` = `project.author` from `config.yaml`.
- Date/time = current local time, formatted UTC in frontmatter.
- Slug = kebab-case, 3–5 words, alphanumeric + hyphens only.
- If a file with that exact name already exists, append `-2`, `-3`, etc.

### 3. Write the file with frontmatter

```yaml
---
author: <project.author>
date: <ISO 8601 UTC>
type: thread            # or journal
status: open            # or fyi / answered / resolved
summary: <one specific sentence>
tags: [<1-3 tags>]      # omit field if none
participants: [<author>, <addressee>]   # threads only
---

<body — the user's dictated content, lightly cleaned for punctuation and obvious transcription errors but NOT paraphrased>
```

**Body rules:**
- Preserve the user's voice. Light cleanup (capitalization, punctuation, paragraph breaks) only.
- Do NOT add headers, summaries, or "context" the user didn't dictate.
- If the dictation includes an obvious greeting ("hey <alias>,") keep it.
- If the dictation includes voice artifacts ("um", "you know"), remove them.

### 4. Regenerate INDEX.md automatically

Run `python3 scripts/regen_discussions_index.py` after every `file` or `reply`. If it exits non-zero, surface the error to the user — do not claim success. If the script does not exist in the target repo, tell the user once and skip regeneration for the rest of the session.

### 5. Confirm in one sentence

```
Filed thread to <addressee> at docs/discussions/<author>/<file>.md and regenerated the index.
```

Or for a journal:

```
Filed journal at docs/discussions/<author>/<file>.md.
```

If type was ambiguous and you defaulted:

```
Filed as journal (no addressee detected) at <path>. Say "make that a thread to <id>" if you want it re-filed.
```

## Reply flow

When the user says "reply to <id>" or "respond to <id> about <topic>":

1. Locate the most recent matching thread:
   - Most recent entry in `docs/discussions/<id>/` with `type: thread` and `status: open` or `answered`.
   - If multiple match, pick the one whose tags/summary best match the topic in the dictation.
   - If still ambiguous, ask: "Reply to which? [show 2–3 candidates with date + summary]".
2. File the reply as a new entry under `docs/discussions/<author>/`:
   - `type: thread`
   - `replies-to: <id>/<filename>`
   - `participants: [<author>, <id>]`
   - `tags:` — inherit from parent thread unless the dictation introduces new ones.
3. Update the parent thread's `status` from `open` to `answered` (write the file back with the updated frontmatter).
4. Regenerate INDEX.

## List flow

When the user says "what's open" / "what's recent" / "what has <id> said":

- For "what's open" — filter INDEX by `status: open`, render the rows.
- For "what's recent" — show the top 10 rows of INDEX.
- For "what has <id> said" — `ls docs/discussions/<id>/` and read frontmatter summaries.
- For "what's been said about <topic>" — grep tags or summaries for the topic.

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
- **GitHub IDs are case-sensitive** in folder paths but the user may say them differently. Use the `aliases` list in `config.yaml` to map heard-forms to canonical folder names silently.

## Failure modes to avoid

| Don't | Do |
|---|---|
| Ask "thread or journal?" every time | Infer from the dictation |
| Paraphrase the body | Light cleanup only |
| Hand-edit INDEX.md | Edit frontmatter, then regenerate |
| File under the addressee's folder because the message is *to* them | File under `<author>/` — author owns the folder |
| Skip regeneration "because the user will run it later" | Run it every time, automatically |
| Write a "summary of the discussion" as the body | Body is the dictated content; summary lives in frontmatter |
| Hardcode project name, contributors, or tags in this skill | Everything project-specific lives in `config.yaml` |

## Example: dictated → filed

Assume a `config.yaml` with `project.author: msifoss`, a contributor `cgeorge-ms` (aliases: `cliff`), and `tag_vocabulary` including `tbac`, `isolation`, `lake-formation`.

**User says (voice):**
> "Tell cliff I'm thinking about whether LF tag inheritance covers row-level filters or if we need a separate mechanism. Tag this TBAC and isolation."

**Claude does:**

Writes `docs/discussions/msifoss/20260520-1430-lf-tag-inheritance-row-filters.md`:

```yaml
---
author: msifoss
date: 2026-05-20T14:30:00Z
type: thread
status: open
summary: Asking cgeorge-ms whether LF-Tag inheritance covers row-level filters or if a separate mechanism is needed.
tags: [tbac, isolation, lake-formation]
participants: [msifoss, cgeorge-ms]
---

Hey cliff — I'm thinking about whether LF-Tag inheritance covers row-level filters, or if we need a separate mechanism. Want your read on this.
```

Runs the regenerator. Confirms: "Filed thread to cgeorge-ms at docs/discussions/msifoss/20260520-1430-lf-tag-inheritance-row-filters.md and regenerated the index."
