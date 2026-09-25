---
name: switch-site
description: Switch local Anny to query a different registered site by running `python -m anny.cli.sites switch <slug> --json`. The CLI handles backup, .env edit, and reports the change. Skill then reminds the user to restart Anny if it's running. LOCAL ONLY — does not touch production. Use when user says "switch to ageless", "/switch-site bjj", "point anny at membersolutions", or similar.
---

# /switch-site — Local Anny Site Swap

Change which site Anny queries locally. The CLI backs up `.env`, swaps the two env vars, and reports what changed. Production is never touched — that requires manual SSH per `docs/manuals/SITE-SWITCHING.md`.

## Trigger

User invokes `/switch-site <slug>` or asks:
- "Switch to ageless"
- "Point Anny at global1bjj-new"
- "Use Member Solutions"

## Arguments

| Argument | Required? | What it does |
|----------|-----------|-------------|
| `<slug>` | Yes | The slug from `config/sites.yaml` (e.g. `ageless`, `membersolutions`, `global1bjj-new`) |

If the user passes something that doesn't match a slug exactly, first run `/list-sites <their-string>` to find candidates. If exactly one matches, confirm with the user before running the switch. If multiple match, list them and ask which.

---

## How It Works

### Step 1 — Confirm

Before running the switch, show the user:
1. **Current local slug** (run `python -m anny.cli.sites list --no-prod --json` and look at `active_local`)
2. **Target slug** with a one-line summary from the registry
3. The plan: "I'll back up .env, edit GA4_PROPERTY_ID and SEARCH_CONSOLE_SITE_URL, then you'll need to restart Anny if it's running."

Wait for explicit "yes" / "proceed" — this is a destructive change. (Reversible via the backup, but still.)

### Step 2 — Run the CLI

```bash
source .venv/bin/activate && PYTHONPATH=src python -m anny.cli.sites switch <slug> --json
```

JSON output:

```json
{
  "ok": true,
  "from_slug": "membersolutions",
  "to_slug": "ageless",
  "backup_path": ".env.20260516-1530-membersolutions.bak",
  "new_env": {
    "GA4_PROPERTY_ID": "528368259",
    "SEARCH_CONSOLE_SITE_URL": "https://agelessfitnessencinitas.com/"
  },
  "note": "Local .env updated. Restart Anny (make run) for the change to take effect. Production is unchanged."
}
```

If `ok: false`, show the error to the user and stop. Common failures: slug doesn't exist, target site has incomplete config (missing GA4 or SC).

If `no_op: true`, the user tried to switch to the already-active site. Tell them, don't restart.

### Step 3 — Restart Anny (only if the `make run` REST server is up)

**Note (Bolt 15 #138):** in the default laptop-only setup, Claude Code talks to Anny over **stdio** — it spawns a fresh `python -m anny.cli.mcp_stdio` process per session, which reads `.env` at startup. That means an MCP-only user picks up the new site automatically on the **next** Claude Code session; there's nothing to restart. Use `lsof -ti :8000` to detect the *optional* `make run` REST server (only present if someone started it for `curl` / Swagger use).

If the REST server is running (`lsof -ti :8000` returns a PID):
1. Kill it: `lsof -ti :8000 | xargs kill` (this catches uvicorn's reloader child too, which a bare Ctrl+C in the launching terminal would miss).
2. Start fresh in background: `source .venv/bin/activate && PYTHONPATH=src uvicorn anny.main:app --host 127.0.0.1 --port 8000 > /tmp/anny.log 2>&1 &` (use `run_in_background: true` on the Bash tool)
3. Poll `http://127.0.0.1:8000/health` until 200 OK.

If the REST server is NOT running, tell the user: "Anny's REST server isn't running — the `.env` change is saved. If you query via Claude Code (stdio MCP), it takes effect on your next Claude Code session. If you want the REST API, start it with `make run`."

### Step 4 — Smoke test (if Anny is running)

Pull a quick SC summary to confirm the new config is live:

```bash
KEY=$(grep '^ANNY_API_KEY=' .env | cut -d= -f2)
curl -s "http://127.0.0.1:8000/api/search-console/summary?days=7" -H "X-API-Key: $KEY"
```

Show the clicks/impressions/CTR/position numbers. The user can sanity-check they match the expected site magnitude.

### Output

```
✓ Switched local Anny: <from_slug> → <to_slug>
  GA4: <new_ga4>
  SC:  <new_sc>
  Backup: <basename of backup_path>

Smoke test (last 7 days):
  clicks: <N>  impressions: <M>  CTR: <X>%  position: <P>

Production (anny.membies.com) is unchanged.
```

---

## What this skill does NOT do

- **Does not touch production.** Prod swaps require SSH + `docker compose up -d --force-recreate` (NOT `restart`). Use the manual procedure in `docs/manuals/SITE-SWITCHING.md`.
- **Does not delete old backup files.** They accumulate in the repo root as `.env.YYYYMMDD-HHMM-<slug>.bak` — your undo history. Clean by hand if they get out of hand.
- **Does not register new sites.** Use `/add-site` first if the slug isn't in the registry.

---

## Edge cases

- **Slug doesn't exist** → CLI returns `ok: false` with a helpful error. Tell user; suggest `/list-sites <substring>`.
- **Target has incomplete config** (no GA4 or no SC) → CLI returns `ok: false`. Likely a `partial` status site like `ccansam`. Tell user and ask if they want to fix the registry first.
- **Already on target** → CLI returns `no_op: true`. Tell user, don't restart.

---

## See also

- `/list-sites` — see what's available
- `/add-site` — register a new site
- `docs/manuals/SITE-SWITCHING.md` — the full manual procedure (includes prod swap)
- CLI directly: `python -m anny.cli.sites switch --help`
