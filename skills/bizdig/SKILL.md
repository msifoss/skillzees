---
name: bizdig
description: Deep-dive dossier on a HubSpot company — fans out across every associated contact, pulls all engagements (notes, calls, emails, meetings, tasks) and tickets in a date window, joins in APS billing/member data, and sweeps O365 (Outlook, Teams, Calendar, SharePoint) for related activity. Optional focus lets you spotlight one contact or theme.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, ToolSearch, mcp__hubmcp__hubmcp_get, mcp__hubmcp__hubmcp_query, mcp__hubmcp__hubmcp_timeline, mcp__hubmcp__hubmcp_associations_graph, mcp__hubmcp__hubmcp_workflow_enrollment, mcp__hubmcp__hubmcp_workflow_activity, mcp__claude_ai_HubSpot__search_crm_objects, mcp__claude_ai_HubSpot__get_crm_objects, mcp__claude_ai_HubSpot__query_crm_data, mcp__claude_ai_HubSpot__get_user_details, mcp__claude_ai_Microsoft_365__outlook_email_search, mcp__claude_ai_Microsoft_365__outlook_calendar_search, mcp__claude_ai_Microsoft_365__chat_message_search, mcp__claude_ai_Microsoft_365__sharepoint_search, mcp__claude_ai_Microsoft_365__find_meeting_availability
argument-hint: <hubspot-company-url-or-id> [from YYYY-MM-DD] [to YYYY-MM-DD] [focus: ...]
---

# /bizdig — Company Deep-Dive Dossier

Fan-out dossier for a single HubSpot company across every channel MSI has visibility into: HubSpot contacts + engagements + tickets + workflow enrollments, APS/Lakey billing and member data, and the O365 stack (Outlook, Teams, Calendar, SharePoint). Output is a markdown dossier written to `docs/key_findings/` in the current repo.

> The point isn't to summarize what HubSpot already shows. The point is to surface what HubSpot *doesn't* show — the missing threads, the untracked meetings, the billing signal that hasn't reached the account owner, the internal chatter no one wrote down.

## Trigger

User invokes `/bizdig` with a HubSpot company URL or company id, optionally followed by a date range and a focus clause. Examples:

- `/bizdig for company https://app.hubspot.com/contacts/9221154/record/0-2/53528472149 (Causby Karate Academy) with a focus on communication with Ben Causby, but also deep dive other areas`
- `/bizdig 53528472149 from 2026-01-01 to today`
- `/bizdig <url> --focus "renewal risk and CSAT signal"`

The skill parses these conversationally — no positional slot enforcement. If any input is ambiguous, ask.

---

## Step 0 — Parse and confirm scope

Before running any query:

1. **Extract portal and company id from the URL.** HubSpot company URLs are `https://app.hubspot.com/contacts/<PORTAL_ID>/record/0-2/<COMPANY_ID>`. Portal map used at MSI Group:

   | Portal ID | Slug | Description |
   |---|---|---|
   | 9221154 | `membersolutions` | Member Solutions HubSpot |
   | 7126753 | `display97` | 97 Display HubSpot |

   If only a bare company id is given, **ask** which portal — do not guess. Both portals are hubmcp-registered.

2. **Extract or default the date range.** Default = last 12 months from today. Convert relative dates ("last quarter", "since January") to absolute ISO dates before proceeding.

3. **Extract the focus clause.** If present, capture it verbatim. Focus text drives one dedicated section of the dossier; the rest is a broader account survey.

4. **Read back the scope in one line** before executing:

   > `Digging: <Company Name> (portal <slug>, company id <id>) · <since> → <until> · focus: <focus or "none">`

   Give the user one beat to correct anything, then run.

---

## Step 1 — HubSpot fan-out (parallel where possible)

The HubSpot pull has to be exhaustive — this is what separates /bizdig from a routine account summary.

### 1a. Company core

Pull the company record with every property that carries join value or account context:

- Identity: `name`, `domain`, `website`, `phone`, `city`, `state`, `country`, `industry`
- Lifecycle: `lifecyclestage`, `hs_lead_status`, `hubspot_owner_id`, `createdate`, `hs_lastmodifieddate`
- Cross-system join keys (per hubmcp CLAUDE.md and 97eye MCP instructions):
  - `n97_crm_id__` → APS reference
  - `vendastaid` → Vendasta account ID
  - `chargify_customer_id` → Maxio/Chargify customer id (97 Display side)
- Anything else on the record with obvious signal (e.g. custom churn-risk scores, renewal dates)

### 1b. Associated contacts

Use `hubmcp_associations_graph` or an associations query to enumerate every contact linked to the company. For each contact, pull:

- `email`, `hs_additional_emails`, `firstname`, `lastname`, `phone`, `mobilephone`
- `lifecyclestage`, `hs_lead_status`, `hubspot_owner_id`, `hubspot_owner_assigneddate`
- `hs_email_optout`, `hs_marketable_status`, `hs_last_sales_activity_date`
- `createdate`, `lastmodifieddate`

**Watch for aggregate/merged contact records.** MSI HubSpot has some contacts with 10+ secondary emails in `hs_additional_emails` (see Bill Taylor / Ian Rack precedents). If a contact shows this pattern, flag it — engagements on that record may belong to different people at the same shop.

### 1c. Engagements per contact (all kinds)

For each associated contact, call `hubmcp_timeline` with `kinds=["notes","calls","emails","meetings","tasks"]` and `since=<from date>`.

**Known gotcha:** `hubmcp_timeline` may 403 on emails due to missing `sales-email-read` scope on the hubmcp private-app token. If that happens, fall back to the native HubSpot MCP (`mcp__claude_ai_HubSpot__search_crm_objects` with `objectType=emails` and `associatedWith` filter). The native MCP is bound to one portal at a time — verify via `get_user_details` that its `accountId` matches the portal you're digging in; if not, note the limitation and continue with only hubmcp results (calls/notes/meetings/tasks will still come through).

For emails specifically: capture direction (`hs_email_direction`), from/to, subject, timestamp, and the first ~500 chars of `hs_email_text` when it looks meaningful (replies, service tickets, escalations). Skip drip-sequence marketing blasts beyond a count summary.

### 1d. Tickets + ticket notes

Query `crm.tickets` filtered by `associatedcompanyid = <company_id>` (or the equivalent associations filter). For each ticket in the window:

- Core: subject, `hs_pipeline_stage`, `hs_ticket_priority`, `hs_ticket_category`, `createdate`, `hs_lastmodifieddate`, `hubspot_owner_id`, `content`
- Ticket notes: pull all notes associated to each ticket (associations endpoint or a follow-up search)

Preserve ticket-note chronology — that's where the actual back-and-forth on the account lives.

### 1e. Deals in the window

Any deal touching this company where `createdate`, `closedate`, or `hs_lastmodifieddate` is in the window. Capture pipeline, stage, amount, close date, and owner. If a deal was won or lost in the window, that's headline material.

### 1f. Workflow enrollments (optional but valuable)

If time and scope permit, call `hubmcp_workflow_enrollment` for the primary contact(s) to see which automations are still firing at this account. Especially useful for renewal / at-risk investigations.

---

## Step 2 — APS / Lakey / EFIT join (`../aps`)

APS is the source of truth for billing, member counts, and financial standings. This step gives the dossier its money layer.

### 2a. Resolve the account in APS

Use HubSpot join keys **in this order**:

1. `n97_crm_id__` on the company (the primary APS reference field)
2. `chargify_customer_id` (97 Display side, maps to Maxio → HubSpot bridge)
3. `vendastaid` (Vendasta account → matches APS via a separate join)
4. Domain match against `[APS File]` or `V_APS_Accounts_Complete`
5. Fuzzy name match — last resort, always report which key was used

**Report which join key resolved.** If the record has no APS reference (common for pure prospects), say so explicitly — don't fake it.

### 2b. Pull recent APS signal

APS lives on VPN'd SQL Server. Invoke via the aps CLI:

```bash
cd /Users/msichris/repos/aps && .venv/bin/python -m aps query "<SQL>"
```

Or, when a well-known SQL file exists, run it via the `sql` subcommand. Signal to pull, scoped to the date window where possible:

- **Standing / status changes:** any status flip in `[APS Standings]` during the window
- **Financials:** monthly totals from `[APS Monthly Financials]` for the window months
- **Notes:** `[web_aps_notes]` filtered to this account (this often catches internal ops notes that never made it to HubSpot)
- **Delinquency / holds:** delinquency-flag or hold columns on `[APS File]` / `V_APS_Accounts_Complete`
- **Transactions volume:** month-by-month transaction count and dollar volume from the transaction views (see `docs/MRR-METHODS.md` in the aps repo for the canonical query patterns)

If APS is unreachable (no VPN), report that cleanly and continue with HubSpot + O365. Do not retry silently.

### 2c. Cross-reference APS notes vs HubSpot notes

If APS has notes in the window that don't appear in HubSpot, call that out — it's usually a sign that ops handled something without looping in the account owner. High-value insight.

---

## Step 3 — O365 sweep (`o365 mcp`)

The O365 stack is where the untracked communication lives. For each dimension, scope searches to the date window and to identifiers gathered from HubSpot (company domain + every contact email including `hs_additional_emails` values).

### 3a. Outlook email search

Call `mcp__claude_ai_Microsoft_365__outlook_email_search` once per query strategy:

1. Company name search (subject + body)
2. Domain search — this often catches emails that never got associated to a HubSpot contact
3. Per-contact-email search for the focus contact(s) if a focus clause is present

Aggregate results. For each email, capture: date, subject, from, to, direction, thread id. Deduplicate against the HubSpot email set (by subject + timestamp within ±5 min) — surface only the emails that HubSpot doesn't already have.

### 3b. Teams chat search

Call `mcp__claude_ai_Microsoft_365__chat_message_search` for:

1. Company name mentions
2. Focus contact's name (if applicable)

Teams chatter tends to be internal (MSI staff talking about the account, not to them). Report it under an "Internal chatter on this account" section — it's often the most surprising signal in the dossier.

### 3c. Calendar sweep

Call `mcp__claude_ai_Microsoft_365__outlook_calendar_search` filtered to the date window, then post-filter meetings where any attendee email matches the HubSpot contact set. Report cadence (meeting counts per quarter), who attended, and any explicit no-shows if that's visible.

### 3d. SharePoint search

Call `mcp__claude_ai_Microsoft_365__sharepoint_search` with the company name. Surface any file hits (contracts, proposals, spreadsheets) with the SharePoint URL. Don't try to read file contents — just report they exist and where.

### 3e. O365 auth caveat

If any O365 tool returns an auth or scope error, note it in the "Data quality" section of the dossier and continue. Never let one broken surface abort the whole run.

---

## Step 4 — Compose the dossier

Write the result to `docs/key_findings/YYYYMMDD-HHMM-bizdig-<company-slug>/dossier.md` in the **current repo** (the CWD when the skill was invoked). Filename uses the global timestamp convention (`YYYYMMDD-HHMM-slug.ext`).

### Structure

```
# <Company Name> — Deep-Dive Dossier
Portal: <slug> · Company ID: <id> · Window: <since> → <until> · Prepared: <today>
Focus: <focus clause or "none">

## Executive summary
<3-6 bullets. What matters most from this pull, ranked by impact.>

## Company snapshot
<Identity, lifecycle, owner, join keys resolved, APS status one-line.>

## Focus deep-dive: <focus clause>
<This section only appears if a focus was provided. Every touch involving
the focus contact/topic, chronological, verbatim where useful. Cross-channel:
HubSpot emails/calls/notes/meetings + Outlook + Teams + Calendar.>

## Broader account survey
### Associated contacts (N)
<Table: name, email, role/title if known, owner, last-touched, engagement count in window.>

### HubSpot engagements
- Notes: N in window · <themes>
- Calls: N · <who called whom, cadence>
- Emails: N (direction split) · <themes>
- Meetings: N · <cadence>
- Tasks: N open, N closed · <themes>

### Tickets
<Table: id, subject, category, priority, stage, created, last mod, owner.
Then per-ticket note timelines for anything unresolved or recent.>

### Deals in window
<Table: name, pipeline, stage, amount, close date, owner.>

### APS / billing signal
<Standing changes, financial trajectory, delinquency, ops notes not in HubSpot.>

## O365 findings HubSpot doesn't have
### Outlook (external threads not associated)
### Teams (internal chatter)
### Calendar (meeting cadence)
### SharePoint (documents)

## Data quality caveats
<Which tools 403'd, which portals were unreachable, which join keys were missing,
merged/aggregate contact records that muddied engagement attribution, etc.>

## Recommended next steps
<Concrete actions the reader can take. Each item follows the "action → why → who → by when" pattern.
Group by decisiveness: "Decided (do this)" first, then "Depends on the answer to a question" second.
See Step 4b below for how to build this section.>

## Clarifying questions
<The 2-5 questions that gate the next moves. Each question exposes the choice under it —
what changes if the answer is X vs Y. See Step 4b for the pattern. If the pull surfaced
no real decisions to make, keep this heading and write "None — the recommended next steps
above are unambiguous.">
```

### Style rules

- **Preserve dates and IDs.** Every table row that references a HubSpot object should include its id. Every APS row should reference the account key that resolved.
- **Never hallucinate a signal.** If APS was unreachable, say so. If a contact has no engagement in the window, say "no touches" — not "quiet".
- **Skimmable.** The exec summary is the only guaranteed read. Bury the deep tables below.
- **No filler prose.** Bullets and tables over paragraphs. If a section has nothing to report, keep the heading and write "None in window."

---

## Step 4b — Recommended next steps & clarifying questions

This is the section that makes /bizdig an operational tool rather than a report generator. Skipping it or filling it with generic advice defeats the point. Both subsections come out of the same drafting exercise — do them together.

### Draft the exercise

For every substantive finding in the dossier, ask: **"So what should someone do about this in the next 24–72 hours?"** Write those actions down. Then, for each action, check whether it can proceed on what you already know, or whether it forks on a question no one has asked. That fork is where the clarifying question comes from.

An action that has no fork is a *recommendation*. An action that changes shape depending on the answer is a *question that gates a recommendation*. Both belong in the dossier, in the two sections below.

### The "Recommended next steps" section

Every item follows the shape:

> **N. Action.** *Why it matters (one sentence tying to a specific finding above).* Owner: `<person or team>`. By when: `<date or event>`.

Rules:

- Lead with the verb (Send, Schedule, Reassign, Escalate, Reconcile, Write, Call, Cancel, Log).
- Refer to specific dossier evidence by ID or paragraph so the reader can verify. "Ben's Jun 18 note in ticket 43963256703" beats "Ben's fee concern."
- Owner must be a real person or a specific queue (finance@, product@, the account owner in HubSpot). "Someone" is not an owner.
- By-when should be a real date or a triggering event ("before the Aug 1 cutover"). "ASAP" is not a deadline.
- Group items into two subsections when the mix warrants:
  - **Decided — do these** (no fork; the finding is unambiguous)
  - **Contingent on the answers below** (each item references a question in the next section)
- 3–7 items is the sweet spot. Fewer than 3 usually means the pull didn't dig hard enough. More than 7 usually means the account needs its own project doc, not a bulleted list.

### The "Clarifying questions" section

Every question follows the shape:

> **Q<N>. Question — direct, closed-ended when possible.**
> *What changes if the answer is A vs B.* If A: [next-step change]. If B: [different next-step change].
> Who can answer: `<role or person>`.

Rules:

- **Only include a question if answering it visibly moves the action list.** "How does Ben feel about MSI?" is not a clarifying question because no next step forks on the answer. "Do we honor the verbal 4% + $0.25/txn rate, or is the CSIPay form's fee schedule the corrected terms?" is, because the next email to Ben is completely different in each branch.
- Prefer closed-ended (yes/no, A/B, this-amount/that-amount) over open-ended. Open-ended questions belong in a meeting, not a document.
- 2–5 questions. Zero is legitimate if the pull uncovered no real forks — in that case write "None — the recommended next steps above are unambiguous."
- Order by which one blocks the most downstream action.
- When a question has an obvious default and you want to note it, add a **Recommended default: X** line — but do not skip the question.

### The two sections work as a pair

The recommended-steps list is what a reader could do *right now* on the strength of the pull. The clarifying-questions list is what the reader has to resolve to unlock the *other* actions that are conditional. Together they turn the dossier from a description of the world into a plan.

If both sections come out empty, the /bizdig run didn't earn its keep — go back and look at the findings again for the "so what."

---

## Step 5 — Report back in chat

After the file is written, print in chat:

1. Absolute path to the dossier file
2. The exec-summary bullets, verbatim
3. Any data-quality caveats that shaped the pull (e.g. "hubmcp timeline 403 on emails — native MCP filled in")
4. **The clarifying questions from the dossier, verbatim**, so the user can answer them now if they want to unlock the contingent next steps
5. One-line offer: "Want me to render this as a rocket-style PDF, drill into any section, or work an answer to one of the questions above into a concrete follow-up (draft email, HubSpot note, calendar hold)?"

If the user answers any of the clarifying questions in the same turn, resolve the corresponding contingent next step(s) in your reply — either mark it "confirmed" (if the user gave a decision), draft the artifact it produces (if the user asked you to do it), or update the dossier file's Recommended next steps section to reflect the resolved fork.

---

## Data-quality gotchas to watch for (accumulated tribal knowledge)

- **Merged HubSpot contacts** with many secondary emails → engagements may belong to multiple people. Flag it.
- **`hs_email_from_email` misclassification** — MSI HubSpot has a documented gotcha where inbound emails sometimes have the wrong `hs_email_from_email` value. When email direction and content disagree, trust the content.
- **hubmcp `sales-email-read` scope** may be missing → timeline 403s on emails. Fall back to native HubSpot MCP.
- **Native HubSpot MCP is single-portal.** Confirm the portal it's attached to before relying on it. If the target company is in the other portal, you can only pull emails via hubmcp (and if that 403s, note the gap).
- **APS join key sparsity.** Many companies don't have `n97_crm_id__` set. Domain / fuzzy match is legitimate but always disclose.
- **Marketing drip sequences** dominate email counts. Group them, don't list every send individually.
- **Ticket `content` renders HTML literally** in hubmcp (documented). If a ticket body looks like garbled tags, it's the display, not the data.
- **Timezone drift.** APS timestamps are usually US Eastern, HubSpot is UTC, Outlook depends on the mailbox. When cross-referencing "did the customer email us before we called them," normalize to UTC before comparing.

---

## When to skip sections

- **No focus given** → skip the "Focus deep-dive" section entirely, don't leave an empty heading.
- **Prospect company (no APS record)** → skip the APS billing signal section; note it under Data quality.
- **User explicitly narrows scope** ("just the emails", "just the tickets") → honor it; still write to the dossier file but keep unrun sections out.

---

## Related skills

- `/librarian` — check for prior deep-dives on the same account before starting fresh
- `/am prep <client>` — same source data, different consumer (a briefing for a call rather than an audit)
- `/wrapit` — if the dossier drove a decision, wrap the session so the decision is discoverable next time
