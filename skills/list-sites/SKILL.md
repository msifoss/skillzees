---
name: list-sites
description: List the sites Anny can query (GA4 + Search Console) by running `python -m anny.cli.sites list --json` and rendering the results. Supports a substring filter that matches against slug, friendly name, SC URL, GA4 property ID, or any tag. Also shows what's currently active in both local .env and production. Use when user asks "what sites can Anny see?", "list anny sites", "/list-sites", or similar.
---

# /list-sites — Anny Site Registry Viewer

Show every site Anny can query, with all config fields, and indicate which one is currently active locally and on production.

## Trigger

User invokes `/list-sites [filter]` or asks any equivalent question.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Show all sites in the registry |
| `<filter>` | Substring filter (case-insensitive) — matches against slug, friendly_name, sc_site_url, ga4_property_id, OR tags |

Examples: `/list-sites`, `/list-sites bjj`, `/list-sites 468`, `/list-sites customer`.

---

## How It Works

This skill is a thin wrapper around the Anny CLI. The agent runs the CLI with `--json` and renders a rich table from the structured output.

### Step 1 — Run the CLI

```bash
cd /Users/msichris/repos/Anny
source .venv/bin/activate && PYTHONPATH=src python -m anny.cli.sites list [filter] --json
```

(Omit `[filter]` if none was provided.) The CLI also checks production state via SSH by default — that adds ~2 seconds. If the user adds `--no-prod` to their request, pass `--no-prod` to the CLI.

If for any reason the user explicitly asks to also include archived/removed entries, pass `--include-removed`.

### Step 2 — Parse the JSON

The JSON shape:

```json
{
  "total_in_registry": 5,
  "filter": "bjj",
  "active_local": "membersolutions",
  "active_prod": "membersolutions",
  "prod_error": null,
  "sites": [
    {
      "slug": "...",
      "friendly_name": "...",
      "ga4_property_id": "...",
      "sc_site_url": "...",
      "tags": ["..."],
      "status": "active",
      "last_verified": "2026-05-15",
      "notes": "..."
    }
  ]
}
```

### Step 3 — Render a table

Columns: marker (`[L+P]` / `[L]` / `[P]` / blank) · slug · friendly_name · ga4_prop · sc_site (truncated to ~35 chars) · tags (truncated to ~30 chars) · status.

Below the table, print:
```
Currently active — local: <active_local>  ·  prod: <active_prod or prod_error>
To switch local: /switch-site <slug>
To add a new site: /add-site
```

If `prod_error` is non-null, show it as a parenthetical instead of a slug, e.g. `(unknown — ssh failed: timeout)`.

### Output format

```
N sites in registry · M match filter '<filter>'

       slug              friendly_name                       ga4_prop     sc_site                              tags                            status
       ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
[L+P]  membersolutions   Member Solutions                    468449912    https://membersolutions.com/         callhero, default, production   active
       ageless           Ageless Fitness Encinitas           528368259    https://agelessfitnessencinitas.co…  fitness, customer               active
       ...

Currently active — local: membersolutions  ·  prod: membersolutions
To switch local: /switch-site <slug>
To add a new site: /add-site
```

### Edge cases

- **CLI fails:** show stderr to user, suggest checking `config/sites.yaml` exists and is valid YAML.
- **Empty registry:** the CLI handles it ("Registry is empty. Run `anny sites add`..."). Just show that.
- **No matches for filter:** the CLI handles it. Just show that.
- **prod_error is non-null:** show it but don't fail the listing.

---

## What this skill does NOT do

- Does not modify anything (read-only)
- Does not live-verify Google access (that's `--verify` on the CLI, or use `/list-sites --verify` if the user explicitly asks)

---

## See also

- `/switch-site` — change which site local Anny queries
- `/add-site` — register a new site
- `/remove-site` — archive a site
- `config/sites.yaml` — the registry file (source of truth)
- CLI directly: `python -m anny.cli.sites list --help`
