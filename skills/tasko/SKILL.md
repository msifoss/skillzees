---
name: tasko
description: Prioritized snapshot of one HubSpot owner's open work — every open task and every open ticket assigned to them, sorted overdue→due-soon→HIGH→rest, with per-item status lines, a state-derived sentiment, and clickable URLs. Follow-up modes (on request): "Critical Few" (3–5 must-do items with reasoning) and "Teams Post" (colored-ball 🔴🟡 bullets for chat). Delta mode (--delta flag): before→after comparison against the most recent stored snapshot, showing what got closed, moved, or newly landed since. Every run auto-writes a snapshot for next time. Use when the user asks "what's on <name>'s plate", "/tasko chris", "critical few for today", "Teams post", "what changed since this morning", "before/after", or wants to see someone's HubSpot workload.
user-invocable: true
allowed-tools: Bash, Read, Write, AskUserQuestion, ToolSearch, mcp__hubmcp__hubmcp_portals_list, mcp__hubmcp__hubmcp_query, mcp__hubmcp__hubmcp_get, mcp__claude_ai_HubSpot__search_owners, mcp__claude_ai_HubSpot__get_user_details
argument-hint: <name-or-email> [portal-id-or-slug] [--delta]
---

# /tasko — HubSpot Owner Work Snapshot

One-shot answer to "what's on their plate right now?" — pulls every open task and every open ticket assigned to a HubSpot owner, sorts them by urgency, prints one status line each with a full URL, and closes with a state-derived sentiment read.

## Trigger

User invokes `/tasko <person> [portal] [--delta]`. Examples:

- `/tasko chris`
- `/tasko chris membersolutions`
- `/tasko Todd Blyth 9221154`
- `/tasko cfossenier@membersolutions.com display97`
- `/tasko chris --delta` (see Step 10 — before/after against the most recent snapshot)

The person argument can be a first name, full name, username, or email. The portal argument (optional) can be either a portal slug (`membersolutions`, `display97`) or a numeric portal id (`9221154`, `7126753`). The `--delta` flag (optional, position-independent) appends a before→after section — see **Step 10**.

**Common follow-up asks** (the report is rarely the last output — the user typically asks for one of these next). Anticipate them but do NOT auto-produce them; wait for the ask:

- *"the critical few"* / *"top items for today"* / *"priority TODO"* → **Step 9a: Critical Few**
- *"Teams post"* / *"short bullets"* / *"colored balls"* / *"in the same format as yesterday"* → **Step 9b: Teams Post**
- *"what changed"* / *"before and after"* / *"take a look at where things are at"* / *"what did I complete"* → **Step 10: Delta**
- *"I already did X and Y"* → drop those items and re-render whichever view is active

---

## Step 0 — Resolve portal

Portal argument accepts either form. Resolve by calling `hubmcp_portals_list` once and matching the argument against `slug` OR `id` (or a `friendly_name` substring). Known map at MSI Group, from memory:

| Portal ID | Slug | Description |
|---|---|---|
| 9221154 | `membersolutions` | Member Solutions HubSpot |
| 7126753 | `display97` | 97 Display HubSpot |

If the portal argument is omitted, **default to `membersolutions`** and say so in the header (`portal: membersolutions (default)`).

If the argument is ambiguous or matches nothing, print the list of registered portals and ask which one.

---

## Step 1 — Resolve person to owner_id

The person argument names a HubSpot **owner** (a user in the portal), not a contact. Use `mcp__claude_ai_HubSpot__search_owners` — it's the fastest path.

1. Call `search_owners` with the argument as the query. Pass the portal id/slug through if the tool accepts it; otherwise search the currently-attached portal and note that in the output.
2. If exactly one owner matches → capture `owner_id`, `email`, `firstName lastName`.
3. If multiple owners match → print a short numbered list (name · email · id), ask the user to pick, then continue.
4. If zero owners match → try a broader search (last name only, or email local-part) before giving up. If still nothing, print "No HubSpot owner matched `<arg>` in portal `<slug>`" and stop.

Read back the resolved scope in one line before doing any query:

> `Tasko: <First Last> (owner <id>, <email>) · portal <slug> (<portal_id>)`

---

## Step 2 — Pull open tasks

Query `crm.objects.tasks` via `hubmcp_query`. Filter:

- `hubspot_owner_id = <owner_id>`
- `hs_task_status IN (NOT_STARTED, IN_PROGRESS, WAITING)` — anything except `COMPLETED` / `DELETED`

Properties to request (all of these get used downstream, ask for them explicitly so hubmcp caches the right shape):

```
hs_task_subject, hs_task_body, hs_task_status, hs_task_priority,
hs_task_type, hs_timestamp, hs_createdate, hs_lastmodifieddate,
hubspot_owner_id, hs_object_id, hs_queue_membership_ids
```

`hs_timestamp` is the due date (unix ms). Do not confuse with `hs_createdate`.

Do not cap results — the user asked for the full list. Pass `limit=null` to `hubmcp_query`.

## Step 3 — Pull open tickets

Query `crm.tickets` via `hubmcp_query`. Filter:

- `hubspot_owner_id = <owner_id>`
- `hs_pipeline_stage` is NOT a closed stage (per-pipeline the closed-stage ids vary; the simplest robust filter is `hs_ticket_pipeline_stage != <closed_id>` for the relevant pipeline, but easier is to filter on `hs_pipeline_stage HAS_PROPERTY` and post-filter in code by looking up the pipeline's `isClosed` on each stage — or, most practical, use the pre-existing convention: `hs_pipeline_stage NOT IN (<known closed stage ids>)`).

For the Member Solutions Support pipeline, closed stages are typically `4` (Closed) — verify the current stage map via `hubmcp_get` on the pipelines endpoint if unsure. If the person owns tickets in multiple pipelines, keep it simple: request all tickets for that owner and drop ones whose stage's `isClosed=true` after fetch.

Properties to request:

```
subject, content, hs_pipeline, hs_pipeline_stage, hs_ticket_priority,
hs_ticket_category, hs_lastmodifieddate, hs_createdate,
time_to_close, hubspot_owner_id, hs_object_id
```

Do not cap. `limit=null`.

---

## Step 4 — Sort and classify

Sort composite key (all items — tasks and tickets — sorted into ONE list):

1. **Overdue first**, most-overdue on top. An item is overdue if it has a due date (`hs_timestamp` for tasks; tickets don't have a native due date, so a ticket counts as overdue if `hs_lastmodifieddate` is older than 14 days AND it's still open — treat that as a stale-ticket signal).
2. **Due within 7 days**, soonest first.
3. **HIGH priority undated**, in `hs_lastmodifieddate` descending (most-recently-touched first).
4. **Everything else**, by `hs_lastmodifieddate` descending.

Compute per-item:

- `urgency_bucket` — one of `OVERDUE`, `DUE_SOON`, `HIGH`, `NORMAL`
- `age_days` — days since `hs_createdate`
- `stale_days` — days since `hs_lastmodifieddate`

---

## Step 5 — Build URLs

Full-record URLs are portal-scoped and object-scoped:

- Task: `https://app.hubspot.com/contacts/<PORTAL_ID>/tasks/list/view/all/task/<TASK_ID>`
- Ticket: `https://app.hubspot.com/contacts/<PORTAL_ID>/record/0-5/<TICKET_ID>`

The task URL above opens the task in the side panel from the all-tasks view (the most reliable deep-link form for tasks). Ticket object-type-id is `0-5`.

Every item in the output MUST have a clickable URL.

---

## Step 6 — Derive sentiment (state-based, no LLM read)

Compute from counts only — do not editorialize on the content of individual tasks. Bucket the whole picture into ONE of the following, printed as the closing line:

| Sentiment | Trigger |
|---|---|
| **Underwater** | ≥ 10 overdue OR overdue > 40% of open items |
| **Behind** | 3–9 overdue OR overdue 20–40% of open |
| **Healthy** | < 3 overdue AND < 20% overdue AND ≥ 3 open items |
| **Light** | Fewer than 3 open items total |
| **Empty** | Zero open items |

Also emit the raw counts alongside the label so the reader can sanity-check the classification.

---

## Step 7 — Output format

Markdown to stdout. **Do not** write a file. Structure:

```markdown
# Tasko — <First Last>

**Portal:** <slug> (<portal_id>) · **Owner:** <owner_id> · **Email:** <email>
**Open items:** <N_tasks> tasks · <N_tickets> tickets · **Overdue:** <N_overdue>
**Sentiment:** <label> — <one short justifying phrase>

---

## Overdue

- **[<age>d overdue]** [<subject>](<url>) — priority <P>, status <S>, last touched <D> ago
- ...

## Due within 7 days

- **[due <YYYY-MM-DD>]** [<subject>](<url>) — priority <P>, status <S>
- ...

## HIGH priority (undated)

- [<subject>](<url>) — status <S>, last touched <D> ago
- ...

## Open tickets

- **[<pipeline> / <stage>]** [<subject>](<url>) — priority <P>, opened <D> ago, last touched <D> ago
- ...

## Everything else

- [<subject>](<url>) — status <S>, last touched <D> ago
- ...
```

Rules for the item lines:

- Every line has a full URL.
- Every line fits in ~120 chars — if the subject is longer, truncate with `…`.
- Skip any section that has zero items (don't print an empty heading).
- Tasks and tickets are visually separated by section, EXCEPT overdue/due-soon where they interleave (a stale open ticket sits next to an overdue task, sorted by how bad it is).
- If a task has `hs_task_body` and it's short and informative, append it as a second line (indented `> …`). Skip if empty, boilerplate, or > 200 chars.

---

## Step 8 — Sanity checks before printing

- If the raw pull returned zero items in both tasks and tickets → print the header + "No open items." + sentiment (`Empty`). Do not print empty section headings.
- If the tasks pull errored but tickets succeeded (or vice versa), print what you got and add a warning line: `⚠ Tasks pull failed: <one-line reason>` — do NOT invent counts.
- Cross-check `hubspot_owner_id` on every returned record. If any record's owner doesn't match the resolved owner_id, drop it and note the mismatch in a footer (indicates a filter bug — see `[[feedback_filter_bug_diagnosis]]`).

---

## Step 9 — Follow-up views (on request only)

The full report from Steps 1–8 is the *input*. The user almost always wants one of two condensed views next. Only produce these when asked; the request phrasing is listed in the Trigger section.

### 9a — Critical Few

The "what should I do TODAY" cut. Rules:

- **Cap at 3–5 items.** More than 5 is not a critical few; it's the whole list.
- **Rank by real deadline pressure, not HubSpot priority alone.** A HIGH ticket with no movement in 15 days beats a task marked HIGH that was just created and isn't blocking anything. Think: "if I only do 3 things today, which 3 change outcomes?"
- **Include tickets AND tasks together in one ranking**, not two separate lists.
- **The Emyr/ATT-Wellington-style "self-imposed deadline lands today" pattern trumps everything** — those are the ONE thing.
- **Every item has a URL.** No exceptions.
- **Group by tier**:
  - **The ONE thing** — the single most-urgent item (self-imposed deadline today, or in-flight commitment that stalls without you)
  - **Also today** — 2–3 HIGH-signal items with real movement pressure
  - **Defer to Monday / later this week** — batch the low-signal task-follow-ups here; explicitly name them so the user knows they're being consciously deferred, not forgotten
- Add a one-line **Bottom line** at the end summarizing the 3 moves in one sentence (e.g. "Emyr letter → Ali chargebacks → Silver Fox nudge. Three moves.").
- **Honor "already did X" corrections.** If the user says "I already emailed Sean and Mike," drop those items from the critical few before ranking. Don't ask; just drop.

### 9b — Teams Post

The super-short colored-ball Teams-friendly bullets. Rules:

- **First line = header** in the form `**<Name> — Today (<Day> MM-DD)**`. Bold. One line.
- **Bullets use colored-ball emoji as the priority marker:**
  - 🔴 = today's critical moves (max 3–4)
  - 🟡 = defer / batch later
  - 🟢 = done / info-only (rarely used — omit unless the user explicitly wants a "here's what I finished" flavor)
- **Every bullet has a URL** (HubSpot task or ticket link).
- **Each bullet is one line, ~100 chars max.** No sub-bullets. No indented `>` quote lines. This is meant to be pasted into a Teams chat.
- **Group the defer items on ONE 🟡 bullet with inline links**, not one bullet per deferred task. Example:
  `🟡 Defer to Monday: [Merced](url), [Kalista](url), [BFS](url), [NKI](url), [Mike Franzen](url)`
- Do NOT add explanation prose after the bullets. The bullets ARE the post.
- If the user has posted this format before ("in the same format as yesterday"), match the exact ordering and grouping they used, not what looks "cleanest" in isolation.

### The relationship between 9a and 9b

9a explains the reasoning; 9b is the artifact that gets shipped. They're the same 3–4 items, expressed twice. Any item in 9b came from 9a's ranking — never pick different items for the Teams post than the ones you just called "critical."

---

## Step 10 — Delta mode + auto-snapshot

Every /tasko run auto-writes a snapshot to disk so future runs can compare. The `--delta` flag (or a natural-language ask like "what changed", "before/after", "take a look at where things are at now") appends a before→after section to the normal report.

### 10a — Snapshot on every run (silent side effect)

After you have the raw tasks + tickets pulled (end of Step 3), write a JSON snapshot to disk **before** rendering the report. This runs on every invocation, not just delta mode.

**Path:** `~/.claude/skills/tasko/snapshots/<owner_id>-YYYYMMDD-HHMM.json`

**Directory:** create with `mkdir -p ~/.claude/skills/tasko/snapshots/` if missing.

**Filename:** always includes HHMM (per the user's global rule about timestamped files). Never overwrite; each run gets a fresh timestamped file.

**Schema:**

```json
{
  "captured_at": "2026-07-24T20:00:00Z",
  "owner": {
    "id": "1690863663",
    "name": "Chris Fossenier",
    "email": "cfossenier@membersolutions.com"
  },
  "portal": {
    "slug": "membersolutions",
    "id": "9221154"
  },
  "tasks": [
    {
      "id": "113317718836",
      "subject": "Follow up with Emyr on cancellation",
      "status": "NOT_STARTED",
      "priority": "NONE",
      "due": "2026-07-24T14:00:00Z",
      "created": "2026-07-20T18:16:07Z",
      "modified": "2026-07-24T14:00:39Z",
      "url": "https://app.hubspot.com/tasks/9221154/view/all/task/113317718836"
    }
  ],
  "tickets": [
    {
      "id": "47096415556",
      "subject": "Large number of chargebacks on June statement",
      "pipeline": "771382917",
      "stage": "1125985693",
      "stage_label": "Client Support / New",
      "priority": "HIGH",
      "created": "2026-07-22T20:22:48Z",
      "modified": "2026-07-22T20:23:20Z",
      "url": "https://app.hubspot.com/contacts/9221154/record/0-5/47096415556",
      "is_closed_stage": false
    }
  ],
  "counts": {
    "open_tasks": 17,
    "open_tickets": 5,
    "overdue": 0,
    "due_today": 8
  },
  "sentiment": "Healthy"
}
```

Snapshot writing MUST NOT block or fail the main report. If the write errors, log a single warning line at the end of the report (`⚠ Snapshot write failed: <reason>`) and continue.

### 10b — Delta mode (--delta flag OR natural-language ask)

When invoked with `--delta` OR when the user asks "what changed since [reference point]" / "before and after" / "take a look at where things are at" / "what did I complete":

1. **Find the reference snapshot.** Default = the most recent snapshot file for this owner_id *before this run*. If the user names a reference ("since this morning", "since yesterday's snapshot"), pick the closest snapshot to that time.

2. **If no prior snapshot exists** → this run establishes the baseline. Print the normal report + append a one-line footer: `📸 Baseline snapshot established. Run /tasko chris --delta later to see what changed.`

3. **Otherwise, compute the diff** across three axes:

**Task diff:**
- **Closed** — IDs in prior snapshot but not in current (COMPLETED, DELETED, or archived)
- **New** — IDs in current but not in prior
- **Rescheduled** — same ID in both, but `due` shifted
- **Retitled** — same ID in both, but `subject` changed
- **Priority changed** — same ID in both, but `priority` changed

**Ticket diff:**
- **New** — IDs in current but not in prior
- **Stage moved** — same ID in both, but `stage` changed (name the from→to labels)
- **Priority changed** — same ID in both, but `priority` changed
- **Closed** — was open, now in a closed stage (per Step 3's closed-stage list)

**Count diff:** delta in `open_tasks`, `open_tickets`, `overdue`, `due_today`. Show the arrow direction (↓ good for open items and overdue, ↑ good for closed).

4. **Render the delta section** appended after the standard report. Suggested layout:

```markdown
---

# Before → After

**Reference snapshot:** <path> (captured YYYY-MM-DD HH:MM, N hours ago)

## Counts

| Metric | Before | After | Δ |
|---|---|---|---|
| Open tasks | 17 | 12 | −5 |
| Open tickets | 5 | 6 | +1 |
| Due today | 8 | 0 | −8 ✅ |
| Overdue | 0 | 0 | 0 |

## What you completed

- ✅ [Task subject](url) — closed
- ✅ [Task subject](url) — closed
- 🔀 [Ticket subject](url) — stage moved from "Client Support / New" → "Client Support / Waiting on contact"
- ✅ [Ticket subject](url) — closed

## Newly landed

- 📥 [Task/ticket subject](url) — priority, created HH:MM today

## Rescheduled (deferred, not forgotten)

- ⏭ [Task subject](url) — was due YYYY-MM-DD, now due YYYY-MM-DD

## Retitled / re-scoped

- 🔄 [Old subject] → [new subject](url)

## Summary

<One-paragraph read on whether the day/window went well. Reference the biggest priorities from the prior snapshot's Critical Few if you can identify them — did they land or did they slip? Close with a sentiment shift call: "Healthy → Trending better" or "Healthy → Slipping" etc.>
```

### 10c — Rules for the delta

- **Never invent movement.** If a task ID appears in both snapshots identically, it did NOT change. Don't claim progress that isn't in the data.
- **Closed tickets need stage verification.** A ticket that disappears from the current query MIGHT be closed OR MIGHT have been reassigned. Check: if it's still in HubSpot but now owned by someone else, say "reassigned" not "closed." If it can't be found, say "closed or archived."
- **Same-day snapshots count.** If the reference snapshot is from the same day (e.g. morning → evening), that's a valid before/after — no minimum time gap.
- **Multi-snapshot support.** If the user asks "since Wednesday morning", walk the snapshots directory in descending timestamp order and pick the newest one that predates the requested reference. Explicitly cite which snapshot you used.
- **Snapshot storage is local-only.** These files may contain customer names and subjects; treat them like memory files. Not for sharing.

### 10d — Handoff to Critical Few / Teams Post from delta

After a delta, the user often asks "so what's left to do today?" — that's a Step 9a Critical Few call over the CURRENT state, informed by what the delta showed already got done. Don't re-ask; just produce it. The delta's "What you completed" list is a natural handoff into "what should you do next" without re-rendering the whole report.

---

## Notes / gotchas

- **Owners vs users vs contacts.** A HubSpot "owner" is a user who can be assigned records. Tasks/tickets have `hubspot_owner_id`, which is the owner id, NOT the user id and NOT the contact id. `search_owners` returns owner records with both `id` (owner_id) and `userId` — use `id`.
- **Portal argument accepts id or slug.** Both `9221154` and `membersolutions` resolve to the same portal via `hubmcp_portals_list`. Numeric argument → match on `id`. Alpha argument → match on `slug` or `friendly_name`.
- **Default portal is `membersolutions`.** Say so in the header so the user notices if they meant the other one.
- **hs_timestamp is unix ms.** Convert to a date for display and for the overdue calculation. Anything before `now()` and status ≠ `COMPLETED` is overdue.
- **Ticket "due date" doesn't exist natively.** Treat 14+ days without modification as the stale-signal for the overdue bucket. Say "stale <N>d" instead of "overdue <N>d" on those items so the reader knows the difference.
- **Do not summarize task content with an LLM.** Sentiment is state-derived (counts). Don't invent qualitative reads from titles — that's a different skill.
- **Full list, no truncation.** The user chose "all open items" over top-N. If the count is huge (> 100), still print them all, but consider grouping the "Everything else" section by status.
