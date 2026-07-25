# /partner-pull — Partner Deep-Dive Data Pull

Pulls every HubSpot artifact tied to a 97 Display referral partner — contact + company + all engagement object types + property history — and produces five analyst-grade markdown deliverables under `docs/partner_program/clients/<slug>/`.

> Built for the 97 Display partner program. Mirrors the depth Dharmesh Shah would recommend for understanding a partner relationship: surface engagement signals, lifecycle transitions, ownership history, marketing-permission state, form-submission provenance — not just the obvious contact-and-emails dump.

## Trigger

User invokes `/partner-pull <contact-id> [<company-id>]`.

## Arguments

| Argument | Required | Description |
|---|---|---|
| `<contact-id>` | yes | HubSpot contact id for the partner's primary human (e.g. `5635101` for Timothy Lyons) |
| `<company-id>` | no | HubSpot company id for the partner entity. If omitted, the skill walks contact → primary company association and uses that. |

Examples:
- `/partner-pull 5635101 5972568503` — Tim Lyons / ProFit
- `/partner-pull 6049204 8370614536` — Jeff Nodelman / GTMA
- `/partner-pull 5635101` — same as first example; company auto-resolved

## Repository assumptions

The skill expects to run in the **97data** repo with:

- HubSpot Private App token in macOS keychain as slot `hubspot_display97_token` (read via `data97.secrets_cmd.get`)
- `uv run python` available for HTTP calls
- Existing folder convention at `docs/partner_program/` (see `docs/partner_program/README.md`)

If running from a different repo, the skill should be invoked from a working directory containing the partner_program folder.

---

## Phase 0 — Preflight + identity resolution

### 0a. Verify inputs

```python
# Pseudocode
contact_id = arg1
company_id = arg2 or None

# Pull contact and confirm it's a real, non-archived record
contact = hs_get(f'/crm/v3/objects/contacts/{contact_id}?properties=firstname,lastname,email,company,associatedcompanyid,hubspot_owner_id,hs_merged_object_ids')
if not contact: STOP — surface to user

if not company_id:
    # Walk to primary associated company
    assoc = hs_get(f'/crm/v3/objects/contacts/{contact_id}/associations/companies')
    if assoc.results:
        company_id = assoc.results[0].id  # use first; surface if multiple
    else:
        company_id = None  # acceptable; some partners are individuals
```

### 0b. Compute the partner slug

```python
# Take {firstname}-{lastname}, lowercase, kebab-case
slug = f"{contact.firstname}-{contact.lastname}".lower().replace(' ', '-').replace('.', '')
# Examples: "tim-lyons", "jeff-nodelman", "travis-barnes"
```

### 0c. Folder bootstrap (idempotent)

```bash
mkdir -p docs/partner_program/clients/<slug>/{findings,captains_log,raw,extracted}
```

If the folder already exists: **do not** clobber existing files; append-or-update only. Existing partner-profile.md gets a new "Updated: <today>" stamp at the top and the body merged.

### 0d. Confirm before pulling at scale

Before running the full pull, surface to the user:

> "About to pull all HubSpot data for **{name}** (contact `{id}`, company `{id}`). Estimated engagements: {N tasks + M emails + K calls + ...}. Proceed?"

Wait for explicit OK if the total > 1,000 engagements (per the Rhythm Dance Studios lesson — bulk pulls take 5+ minutes and the user should know).

---

## Phase 1 — Raw pull (Dharmesh checklist)

Pulls go to `/tmp/partner-pull-<slug>/` (NOT committed per user decision 2026-05-22).

### 1a. Contact core dump

For the contact, fetch ALL properties + property history on the key fields:

```python
# Get ALL property names first
prop_meta = hs_get('/crm/v3/properties/contacts')
all_props = [p['name'] for p in prop_meta['results']]

# Properties to grab history on (the Dharmesh checklist)
history_props = [
    'hubspot_owner_id',
    'lifecyclestage',
    'hs_lead_status',
    'hs_marketable_status',
    'hs_legal_basis',
    'firstname',
    'lastname',
    'email',
    'company',
    'jobtitle',
    'record_type',        # Paula's canonical partner/client/internal flag
    'is_active_partner',  # mirror of record_type=Partner
    'hs_pipeline_stage',  # contact-side lifecycle pipeline stage
]

# Chunk all_props into ≤150-property GETs (URL length cap)
contact_full = chunk_property_dump('contacts', contact_id, all_props, history_props)
save_to('/tmp/partner-pull-<slug>/raw/contact.json', contact_full)
```

**Why all_props instead of a curated list:** future-Dharmesh-checklist additions (new partner-program custom fields) shouldn't require a skill update.

### 1b. Company core dump (same pattern)

```python
all_props = [p['name'] for p in hs_get('/crm/v3/properties/companies')['results']]
history_props = [
    'hubspot_owner_id',
    'lifecyclestage',
    'name',
    'domain',
    'website',
    'chargify_customer_id',
    'chargify_customer_reference',
    'mrr_total',
    'active_97_client_',
    'record_type',
    'is_active_partner',
    'vendastaid',
]
company_full = chunk_property_dump('companies', company_id, all_props, history_props)
save_to('/tmp/partner-pull-<slug>/raw/company.json', company_full)
```

### 1c. Merged-IDs chain

If `contact_full.properties.hs_merged_object_ids` is populated, fetch each merged-from contact too:

```python
merged_ids = (contact_full.properties.hs_merged_object_ids or '').split(';')
for mid in merged_ids:
    try:
        merged = hs_get(f'/crm/v3/objects/contacts/{mid}?archived=true&properties=...')
        save_to(f'/tmp/.../raw/contact-merged-{mid}.json', merged)
    except: pass  # may be unrecoverable
```

### 1d. Associations inventory

For BOTH contact and company, walk every standard engagement type:

```python
ASSOC_TYPES = ['companies', 'contacts', 'deals', 'tickets', 'tasks', 'notes',
               'calls', 'emails', 'meetings', 'communications', 'quotes',
               'conversations', 'line_items']

associations = {}
for at in ASSOC_TYPES:
    for parent in [('contacts', contact_id), ('companies', company_id)]:
        try:
            ids = []
            after = None
            while True:
                url = f'/crm/v3/objects/{parent[0]}/{parent[1]}/associations/{at}?limit=500'
                if after: url += f'&after={after}'
                r = hs_get(url)
                ids += [x['id'] for x in r.get('results', [])]
                after = r.get('paging',{}).get('next',{}).get('after')
                if not after: break
            associations.setdefault(at, {})[parent[0]] = ids
        except HTTPError as e:
            if e.code == 404: continue  # association type not supported
            raise

save_to('/tmp/.../raw/associations.json', associations)
```

### 1e. Conversation threads (separate from emails)

Conversations are a distinct object class — chats, form fills, live messages.

```python
# From the associations result
thread_ids = associations.get('conversations', {}).get('contacts', [])
threads = []
for tid in thread_ids:
    try:
        thread = hs_get(f'/conversations/v3/conversations/threads/{tid}')
        messages = hs_get(f'/conversations/v3/conversations/threads/{tid}/messages')
        threads.append({'thread': thread, 'messages': messages.get('results', [])})
    except HTTPError as e:
        # Some thread IDs returned by associations are stale; tolerate 404
        if e.code != 404: raise
save_to('/tmp/.../raw/conversations.json', threads)
```

### 1f. Batch-fetch engagement objects

For each engagement type, batch-read in chunks of 100:

| Object type | Properties to grab |
|---|---|
| `deals` | dealname, dealstage, pipeline, amount, closedate, createdate, dealtype, description, hs_priority, hubspot_owner_id, hs_v2_date_entered_current_stage |
| `tickets` | subject, content, hs_pipeline, hs_pipeline_stage, hs_ticket_priority, createdate, hs_lastmodifieddate, hubspot_owner_id, source_type |
| `tasks` | hs_task_subject, hs_task_body, hs_task_status, hs_task_priority, hs_task_completion_date, hs_timestamp, hubspot_owner_id |
| `notes` | hs_note_body, hs_timestamp, hubspot_owner_id |
| `calls` | hs_call_title, hs_call_body, hs_call_disposition, hs_call_duration, hs_call_direction, hs_timestamp, hubspot_owner_id |
| `meetings` | hs_meeting_title, hs_meeting_body, hs_meeting_outcome, hs_meeting_start_time, hs_meeting_end_time, hubspot_owner_id |
| `emails` | hs_email_subject, hs_email_text, hs_email_from_email, hs_email_to_email, hs_email_cc_email, hs_email_direction, hs_email_status, hs_timestamp |
| `communications` | hs_communication_channel_type, hs_communication_body, hs_communication_logged_from, hs_timestamp |
| `quotes` | hs_title, hs_status, hs_expiration_date, hs_quote_amount, hs_createdate |
| `line_items` | name, quantity, price, amount, description, hs_product_id |

Save each as `raw/<type>.json` with the full results array.

### 1g. Workflow enrollment trail (best effort)

Workflow-name resolution doesn't work via public API (per the 2026-05-21 finding), but we CAN extract enrollment IDs from property history sources:

```python
# Walk contact_full.propertiesWithHistory; for each entry where sourceType=AUTOMATION_PLATFORM,
# the sourceId looks like "enrollmentId:NNNNN;actionExecutionIndex:N"
# Record these for the workflow-trail section of the brief
automation_trail = []
for prop, entries in contact_full.get('propertiesWithHistory', {}).items():
    for e in entries:
        if e.get('sourceType') == 'AUTOMATION_PLATFORM':
            automation_trail.append({
                'property': prop,
                'timestamp': e.get('timestamp'),
                'new_value': e.get('value'),
                'source_id': e.get('sourceId'),
            })
save_to('/tmp/.../raw/automation-trail.json', automation_trail)
```

### 1h. Internal mentions of the contact

A note may mention this contact without being directly associated. Search notes by content:

```python
search_terms = [contact.firstname + ' ' + contact.lastname, contact.email]
# (skip if email is shared like info@ — too noisy)
notes_with_mention = []
for term in search_terms:
    body = {
        "filterGroups":[{"filters":[
            {"propertyName":"hs_note_body","operator":"CONTAINS_TOKEN","value":term}
        ]}],
        "properties":["hs_note_body","hs_timestamp","hubspot_owner_id"],
        "limit": 100
    }
    r = hs_post('/crm/v3/objects/notes/search', body)
    notes_with_mention += r.get('results', [])
# Dedupe against notes already in associations
save_to('/tmp/.../raw/notes-mentioning.json', notes_with_mention)
```

---

## Phase 2 — Signal extraction (analyst layer)

Run an analyst pass over the raw data, producing `extracted/*.md` files. The skill should NOT just transcribe; it should classify, cluster, and cite.

### 2a. Engagement signal summary — `extracted/engagement-signals.md`

**Goal:** turn the firehose of emails/calls/meetings into themes a human reads in 10 minutes.

Cluster engagements into these themes (skip themes with zero matches):

1. **Commission / Money** — references to commission, payout, rate, percentage, MRR, invoice, payment, check, $-amount language
2. **Referrals introduced** — emails introducing a prospect; meetings about a pending lead; tasks "follow up on X referral"
3. **Operational handoffs** — "client needs help", "can you connect them with…", escalations from referred customers
4. **Cadence / Relationship maintenance** — quarterly check-ins, "how are things", scheduled syncs, marketing collateral, partner-program updates
5. **Disputes / Concerns** — complaints, "you said you'd pay", "the rate is wrong", "I haven't been paid", churn / unhappy signals
6. **Strategic** — partner-program structure changes, contract renegotiations, scope discussions
7. **Background noise** — newsletters, mass emails, "thanks", "got it", etc.

Per theme: bullet list of 3-7 most-load-bearing engagements with format:
> **[YYYY-MM-DD]** {one-line summary in user's voice} *(via {direction} {type}, id `{eng_id}`)*

Each engagement cited exactly once. End each theme with a 1-sentence assessment ("Tim has been increasingly vocal about commission timing since Q2 2025").

### 2b. Property history — `extracted/property-history.md`

Read property-history JSON; produce a table per significant property:

| Property | Timestamp | Old value | New value | Source |
|---|---|---|---|---|
| hubspot_owner_id | 2024-06-12 | (none) | Sophia Squif (77070293) | MIGRATION |
| lifecyclestage | 2024-06-12 | lead | customer | AUTOMATION enrollmentId:N |

Surface anomalies above the table: "Reassigned 3 times in 2025"; "Lifecycle bounced lead→customer→lead→customer between Jan and Mar 2024."

### 2c. Workflow trail — `extracted/workflow-trail.md`

From the automation-trail extract: group enrollments by source_id to identify distinct workflows, even though we can't name them. For each:
- Which properties did it touch?
- When did it fire?
- Side-effect summary ("This workflow set lifecyclestage=customer at the same timestamp as owner assignment — likely the 'new-partner-onboarded' workflow")

### 2d. Relationship-health snapshot — `extracted/health-snapshot.md`

A scorecard table:

| Signal | Value | Direction |
|---|---|---|
| Days since last contact | 12 | ↑ recent |
| Days since last meeting | 47 | → fine |
| Last email open | 2026-05-18 | ↑ engaged |
| Email reply rate (90d) | 23% | ↓ low |
| Open tickets | 0 | ✓ clean |
| Active deals | 0 | — |
| Cumulative MRR he's earned for us | $X (from Maxio on referrals) | — |
| Cumulative paid to him (from Corcentrix when available) | $Y | — |
| Net to 97D | $(X-Y) | — |
| Last commission payment date | 2026-03-05 | recent |
| Days since last payment | 78 | ↑ overdue? |

---

## Phase 3 — Deliverables (the 5 markdown files)

All go to `docs/partner_program/clients/<slug>/`.

### 3a. `partner-profile.md` (or update existing)

**Schema:**
```markdown
# {Display Name} — Partner Profile

**Slug:** `<slug>`
**Status:** active | inactive | pending | terminated (from contracts + recency)
**Last refresh:** {YYYY-MM-DD HH:MM} via /partner-pull

## Identity
- HubSpot contact: `<id>` ({URL})
- HubSpot company: `<id>` ({URL})
- Other associated companies: ...
- Maxio billing customer(s): ... (if any)
- Maxio ACH customer(s): ... (if any)
- Corcentrix vendor strings: ... (from vendor-alias map if known)

## Contract summary
{From docs/data/partner-program/Partner Agreements/{slug}/ if present}

## Engagement footprint
{counts table — # tickets, deals, emails, calls, etc.}

## Ownership
- Company owner: {name} (id)
- Contact owner: {name} (id)
- Match? ✓ / ✗

## Files in this folder
{links to the other 4 deliverables}
```

### 3b. `findings/{YYYYMMDD}-{HHMM}-{slug}-partnership-state.md`

The headline analyst brief. Follows the docs/key_findings/ schema:

```markdown
# {Name} — Partnership State Brief

**Date:** YYYY-MM-DD
**Trigger:** /partner-pull deep-dive
**Source:** Live HubSpot pull + property history + engagement extraction

## Executive summary
{3-5 sentences: relationship status, financial state, risk flags, recommended action}

## Identity & ownership
{condensed from partner-profile}

## Financial picture
{MRR generated · payouts made · net · variance flags}

## Engagement signal summary
{paste extracted/engagement-signals.md or summarize themes}

## Property history highlights
{anomalies from extracted/property-history.md}

## Workflow trail
{condensed from extracted/workflow-trail.md}

## Open questions for ops
{numbered list of follow-ups}

## Files referenced
{table — raw and extracted}
```

### 3c. `captains_log/{YYYYMMDD}-{HHMM}-{slug}-pull.md`

A short narrative diary entry:
- What was pulled
- What surprised us
- What's next

### 3d. `extracted/engagement-signals.md`

Already produced in Phase 2a — copy from /tmp.

### 3e. `extracted/property-history.md` + `workflow-trail.md` + `health-snapshot.md`

Already produced in Phase 2 — copy from /tmp.

---

## Phase 4 — Cross-references

The skill should also:

1. **Update `docs/partner_program/README.md`** under "Active threads" if the pull surfaces new threads (escalations, disputes, ownership gaps not already captured).
2. **Add backlog items to `docs/partner_program/BACKLOG.md`** (as `PP-NNN` items) for any concrete actions the brief recommends.
3. **Cross-link** from the new findings doc to any related existing findings (e.g. if the contact appears in the cross-system mapping doc, link it).

---

## What this skill explicitly does NOT do

- Does NOT write back to HubSpot. Read-only.
- Does NOT commit raw JSON to git (per user decision 2026-05-22). Raw stays in /tmp.
- Does NOT pull engagements on REFERRED customers' records (out of scope per user decision; if needed, use a separate /referral-pull skill).
- Does NOT contact Maxio or Vendasta — the partner-profile cross-references those, but identity-resolution to Maxio/Vendasta is the analyst's job using existing mapping artifacts.

## Idempotency contract

Running `/partner-pull <id>` twice on the same partner:
- Bootstrap step is a no-op if folder exists
- Raw pulls overwrite /tmp staging
- Markdown findings get a new dated entry (don't overwrite the prior one — each pull is a snapshot in time)
- partner-profile.md gets updated in place with a "Last refresh" stamp

## Performance expectations

A partner with 5+ years of history (Tim Lyons, GTMA): 500-2,000 engagements. Pull takes 3-7 minutes. The signal-extraction phase takes another 2-3 minutes. Don't run more than 2 partners in parallel; HubSpot rate-limits will start biting at 3+.

## Output quality standards

A good /partner-pull run:
1. **Cites engagement IDs** for every claim in the brief — analyst can click through
2. **Surfaces anomalies, not just facts** — "owner reassigned 3x" beats "owner is currently Sophia"
3. **Quantifies relationship health** — recency metrics, reply rates, ticket counts
4. **Names the missing data** — "we don't have Maxio activity for this partner; investigate"
5. **Ends with concrete follow-ups** — not "interesting findings" but "do these 3 things"

A bad run:
- Pastes 400 raw emails into a markdown file
- Reports counts without context
- Lists every engagement chronologically without thematic clustering
- Doesn't quote the actual content of load-bearing messages
- Skips the property history (where 80% of the "wait, what?" findings live)
