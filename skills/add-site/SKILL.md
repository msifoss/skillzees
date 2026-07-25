---
name: add-site
description: Add a new site to Anny's site registry by walking the user through GA4 and Search Console access grants, then live-verifying via `python -m anny.cli.sites verify` before appending the entry with `python -m anny.cli.sites add`. Use when user says "add a new site to Anny", "/add-site", "hook anny up to example.com", or similar.
---

# /add-site — Register a New Site with Anny

Conversational walkthrough that adds a new GA4 + Search Console site to Anny's registry. Handles the Google-side grants, verifies they took effect, and writes the entry via the CLI.

## Trigger

User invokes `/add-site [domain]` or asks:
- "Add a new site to Anny"
- "Hook Anny up to example.com"
- "Add example.com to the registry"

---

## How It Works

This skill is CONVERSATIONAL. It walks the user step-by-step, waiting for confirmation between steps. The user does Google-side grants in their browser; the skill verifies + writes the registry entry via the CLI.

### Step 1 — Gather the details

Ask the user (or extract from the trigger):
- **Site URL** (e.g. `https://example.com`)
- **Slug** (URL-safe, lowercase, hyphens; propose one based on the domain)
- **Friendly name** (human-readable)
- **Tags** (optional — common ones in the registry: `callhero`, `customer`, `fitness`, `bjj`, `production`)

### Step 2 — Show the service account email

Read it once with:

```bash
grep client_email /Users/msichris/repos/Anny/anny-service-account.json
```

Display:

> **Robot email to grant access to:**
> `anny-reader@anny-analytics.iam.gserviceaccount.com`

Tell them to copy it.

### Step 3 — User grants GA4 access (browser)

Tell the user to do this in their browser:
1. https://analytics.google.com
2. Top-left dropdown → pick the property for their domain
3. Admin (⚙️ bottom-left) → Property column → **Property access management**
4. Click **+** → **Add users**
5. Paste `anny-reader@anny-analytics.iam.gserviceaccount.com`
6. **Uncheck** "Notify new users by email"
7. Role: **Viewer**
8. Click Add

Wait for "done".

### Step 4 — User grants Search Console access (browser)

1. https://search.google.com/search-console
2. Top-left dropdown → pick the property
   - **Domain property** (`sc-domain:example.com`) covers all subdomains and protocols — prefer this if available
   - **URL-prefix property** (`https://example.com/`) is per-prefix
3. Settings (⚙️ left nav) → **Users and permissions**
4. **Add user** → paste the robot email
5. Permission: **Full**
6. Click Add

Ask them: did you pick the Domain or URL-prefix property? Remember the answer — it determines the `sc_site_url` value.

Wait for "done".

### Step 5 — Get the GA4 Property ID

From the user: Admin → Property → **Property details** → top-right shows a 9-digit number. Just the number. No "properties/" prefix.

### Step 6 — Live-verify both grants

Run the CLI with a temporary slug verification flow. Best approach: do the add (provisionally) then verify, or verify standalone using a Python script.

The cleanest path is:

```bash
cd /Users/msichris/repos/Anny
source .venv/bin/activate && PYTHONPATH=src python -c "
from anny.core.services import google_verifier
import json
sc = google_verifier.verify_sc_access('<exact sc_site_url from Step 4>')
ga = google_verifier.verify_ga4_access('<ga4 property id from Step 5>')
print(json.dumps({'sc': sc, 'ga4': ga}, indent=2))
"
```

If `sc.ok` is false, the SC grant didn't take. Most common cause: added to the wrong property type. Have them retry Step 4 with the other property type, or wait 60 seconds (Search Console grants sometimes lag).

If `ga.ok` is false, the GA4 grant didn't take or the property ID is wrong. Have them double-check Step 3 and Step 5.

Show the user the verification result (e.g. "GA4 returned 47 sessions in the last 7 days — looks good").

### Step 7 — Append to the registry

Once both verifications pass, run:

```bash
cd /Users/msichris/repos/Anny
source .venv/bin/activate && PYTHONPATH=src python -m anny.cli.sites add \
  --slug "<slug>" \
  --friendly-name "<Friendly Name>" \
  --ga4-property-id "<numeric ID>" \
  --sc-site-url "<exact siteUrl from Step 5 verification>" \
  --tags "<tag1,tag2>" \
  --notes "<optional one-liner>" \
  --json
```

Verify `ok: true` in the JSON response.

If the slug already exists, the CLI returns `ok: false`. Ask the user if they want to update the existing entry instead (use `--slug other-slug` to add a second entry, or skip and use `anny sites verify <existing-slug>` to update verification date).

### Step 8 — Summarize

```
✓ Added <slug> to the registry

  friendly_name: <name>
  ga4_property_id: <NNNNNNNNN>
  sc_site_url:    <url>
  tags:           <tags>
  status:         active
  last_verified:  <today>

Live verification:
  SC:  <permission_level> on <url>
  GA4: <sessions_7d> sessions in the last 7 days

To query this site:
  /switch-site <slug>     # swap local Anny
  /list-sites <slug>      # see full config
```

---

## Edge cases

- **Slug already exists** → CLI errors. Ask if they want to update the existing entry (different command: `python -c "from anny.core.services import sites_service; sites_service.update_site('<slug>', updates={...})"` — explain the manual update path or guide them through it).
- **Service account already has access** (user did grants earlier) → that's fine. Skip Step 3/4 prompts, jump to verification.
- **Domain has TWO GA4 properties** (old + new, like global1bjj.com) → add them as two separate entries with different slugs (`<base>-new` and `<base>-old`) but possibly the same `sc_site_url`. Tell the user this upfront.
- **GA4 Property ID has "properties/" prefix** → the CLI strips it automatically. Trust it.
- **No tags suggested** → default to `customer`. Always add at least one tag.

---

## What this skill does NOT do

- **Does not switch local Anny** to the new site. After adding, use `/switch-site <slug>` if they want to query it.
- **Does not touch production.**
- **Does not enroll the site in any monitoring or alerting.**

---

## See also

- `/list-sites` — see what's currently registered
- `/switch-site` — flip local Anny to a registered site
- `/remove-site` — archive a registered site
- `docs/manuals/SITE-SWITCHING.md` — the full manual procedure
- CLI directly: `python -m anny.cli.sites add --help` and `python -m anny.cli.sites verify --help`
