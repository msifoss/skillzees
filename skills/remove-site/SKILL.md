---
name: remove-site
description: Mark a site as removed (soft delete) in Anny's site registry by running `python -m anny.cli.sites remove <slug> --json`. Pass --hard for full deletion. Does NOT revoke Google access — reminds the user to do that manually in the Google UI. Use when user says "remove a site", "/remove-site <slug>", "archive ageless", or similar.
---

# /remove-site — Archive a Site from the Registry

Soft-delete a site from `config/sites.yaml` — set its `status` to `removed`, preserving history. Or hard-delete with `--hard`. **Does NOT revoke the service account's Google-side access** — that's a manual step the user does in the Google UI.

## Trigger

User invokes `/remove-site <slug>` or asks:
- "Remove ageless from Anny"
- "Archive global1bjj-old"
- "Take CCANSAM off the registry"

## Arguments

| Argument | Required? | What it does |
|----------|-----------|-------------|
| `<slug>` | Yes | The slug to remove |
| `--hard` | Optional | Permanently delete the entry instead of soft-removing |
| `--reason "<text>"` | Optional | Free-form reason appended to the site's notes |

If user passes something that doesn't match a slug, do fuzzy match against slug + friendly_name. If exactly one match, ask for confirmation. If multiple, list them and ask which.

---

## How It Works

### Step 1 — Show the entry being removed

Pull the current state from the registry so the user can verify they have the right slug:

```bash
cd /Users/msichris/repos/Anny
source .venv/bin/activate && PYTHONPATH=src python -m anny.cli.sites list <slug> --no-prod --json
```

Show the full entry to the user.

### Step 2 — Warn about Google access

Before running the removal, tell the user:

> ⚠️ This will remove the site from Anny's registry, but the service account `anny-reader@anny-analytics.iam.gserviceaccount.com` still has access in Google. To fully cut access, you'll need to manually revoke it in:
>
> - GA4: https://analytics.google.com → Admin → Property access management
> - Search Console: https://search.google.com/search-console → Settings → Users and permissions

Ask: "Are you also revoking Google access, or just hiding it from the registry?"

### Step 3 — Check if it's the active site

Compare the slug to the local `active_local` from `python -m anny.cli.sites list --no-prod --json`. If they're removing the currently-active site:

> ⚠️ This slug is currently active in your local .env. After removing, queries will keep working (the values in .env stay) but `/list-sites` will report the local config as "unregistered". Want to `/switch-site` to another slug first?

### Step 4 — Confirm and run

Wait for explicit confirmation. Then:

```bash
cd /Users/msichris/repos/Anny
source .venv/bin/activate && PYTHONPATH=src python -m anny.cli.sites remove <slug> [--hard] [--reason "<text>"] --json
```

JSON response:

```json
{
  "ok": true,
  "slug": "ageless",
  "hard": false,
  "was": { ... the entry's prior state ... }
}
```

### Step 5 — Summarize

```
✓ <Hard-deleted | Marked as removed>: <slug>

Prior state preserved in <config/sites.yaml | DELETED>.
<If soft-removed:> The entry stays in the file with status: removed and a removal note.

⚠ Google access NOT revoked.
   Manually revoke in:
     https://analytics.google.com → Admin → Property access management
     https://search.google.com/search-console → Settings → Users and permissions
   Remove anny-reader@anny-analytics.iam.gserviceaccount.com from each.
```

---

## Edge cases

- **Slug doesn't exist** → CLI returns `ok: false`. Tell user; suggest `/list-sites`.
- **Already removed** → CLI succeeds but the site stays in `removed` state. If user wants full deletion now, run again with `--hard`.
- **Removing the currently-active local site** → warn first (Step 3).

---

## What this skill does NOT do

- **Does not revoke Google access** (manual — see warning).
- **Does not delete backup `.env.*.bak` files** that reference the site. Those persist as undo history.
- **Does not touch `docs/manuals/SITE-SWITCHING.md`** — leave the doc; it's reference history.
- **Does not touch production** — no Anny restart, no prod swap.

---

## See also

- `/list-sites` — see registered sites (use `/list-sites <slug>` to find what you want to remove)
- `/list-sites --include-removed` (run CLI with `--include-removed`) — see soft-removed entries
- `/switch-site` — flip to a different site before removing the active one
- CLI directly: `python -m anny.cli.sites remove --help`
