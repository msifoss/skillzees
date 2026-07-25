---
name: pci-sync
description: Monthly PCI compliance sync from Mega/Planit Visa Level 4 report into Lakey live_clients and HubSpot. Audits matches via mega_id-first lookup with fuzzy fallback, applies Lakey writes, generates HubSpot import CSV, and reconciles against the CSI billing run for non-compliance fee gaps.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, mcp__claude_ai_HubSpot__search_crm_objects, mcp__claude_ai_HubSpot__manage_crm_objects, mcp__claude_ai_HubSpot__search_properties
argument-hint: <path-to-Report.xls|.xlsx> [--csi <path-to-csi-fees.xlsx>] [--apply] [--auto-push-hubspot]
---

# /pci-sync — Mega → Lakey → HubSpot PCI Compliance Sync

Reconcile Lakey `live_clients.pci` and `live_clients.pci_renewal` with the latest Mega/Planit Visa Level 4 PCI compliance report, produce a HubSpot import CSV, and (optionally) cross-check against the CSI billing run to find Not-Compliant clients who aren't being charged the $84.99 non-compliance fee.

> Mega is canonical. Lakey writes happen during this skill; HubSpot writes happen when the user uploads the generated CSV (or when `--auto-push-hubspot` is set).

## Trigger

User invokes `/pci-sync <path-to-Report.xls>` (Mega report path is required). Optionally pass `--csi <path-to-csi-fees.xlsx>` for billing-gap reconciliation.

## Arguments

| Argument | Description |
|----------|-------------|
| `<path>` | **Required.** Path to the Mega Visa Level 4 `.xls` or `.xlsx` report. |
| `--csi <path>` | **Optional.** Path to the CSI billing run xlsx. If provided, produces a `csi-billing-gaps.xlsx` report listing Not-Compliant clients who are NOT in the CSI billing run (= not being charged the $84.99 non-compliance fee). Tab 1 is Active-only (priority); Tab 2 is the full list. |
| `--apply` | Actually write changes to Lakey. Without this flag, the skill runs in audit-only mode (no DB writes). |
| `--auto-push-hubspot` | After producing the HubSpot import CSV, push the changes via the HubSpot MCP tool. Confirmation prompt before pushing. CSV is always created either way. |

## Authoritative rules

These are locked in — do not re-derive each run:

- **Mega is canonical.** Its values overwrite Lakey and HubSpot.
- **PCI mapping:** Mega `Overall Status = Compliant` → `Yes`. Anything else (`Not Compliant`, `Not Started`) → `No`.
- **Renewal date:** Mega `SAQ Due Date` → Lakey `pci_renewal` and HubSpot `pci_expirationrenewal_date`.
- **Casing:** Lakey `pci` is `Yes` / `No` (capitalized). HubSpot enum is the same.
- **Date formats:** Lakey `pci_renewal` is a DATE (`YYYY-MM-DD`). HubSpot import wants `MM/DD/YYYY`.
- **Multi-MID dedup (auto):** when one Lakey `client_id` maps to multiple Mega MIDs, pick the row with the **most recent SAQ Due Date**. Tie-breaker: `Compliant` over `Not Compliant`.
- **Lakey scope:** sync any Lakey row that has BOTH `hubspot_recordid` AND `mega_id` populated, regardless of `status`. Rows missing one of those get logged for review.
- **Skip noise rows in Mega:** `Merchant ID = 12345678900` (MSITest), `4445043969054` (YouBill / Member Solutions itself).
- **Ignore these Mega columns entirely:** `Scan Status`, `Last Scan Date`, `Next Scan Date`. (We use SAQ Due Date for the renewal field.)
- **Stage 6 exclusions** (applied in this exact order):
  1. **Overrides file** — any `client_id` with `action = EXCLUDE` in `config/pci-visa-overrides.csv` (e.g. EP0024 Traditional Karate America, EM1508 SCIFI Inc. — exempt by agreement).
  2. **Canadian clients** — `live_clients.country` ∈ {`Canada`, `CANADA`, `canada`, `CAN`}. Canadian clients are not subject to the US Visa Level 4 program or the $84.99 non-compliance fee.
  3. **SSB clients** — `client_id` starts with `p1_mer_` (case-insensitive). SSB uses CSIPay, not the Visa Level 4 program.
  4. **eFit clients** — `client_id` matches `^[1-9]\d*$` (purely numeric **with no leading zero**). APS pads its client IDs to 6 digits (e.g. `000047`), so the no-leading-zero requirement is what distinguishes eFit's `392`/`676` from APS's `000063`. Do NOT use `^\d+$` — it will incorrectly drop real APS clients.
- **Stage 10 inactive-status set:** `INACTIVE_STATUSES = {"Inactive", "Cancelled", "", "CAN", "Closed", "Junk"}`. Anything not in this set counts as Active for the billing-gap split.
- **CSI client_id case:** the CSI billing file mixes `04038B` and `04038b`. Always uppercase both sides of the lookup.

## Output layout

All artifacts go into a single rolling folder, timestamped per run:

```
output/pci-sync/
  <YYYYMMDD-HHMM>-mega-input.csv               # raw Mega data parsed (audit trail)
  <YYYYMMDD-HHMM>-membership.csv               # 3-way membership: Mega ↔ Lakey ↔ HubSpot
  <YYYYMMDD-HHMM>-needs-hubspot-recordid.csv   # Mega rows whose Lakey row lacks hubspot_recordid
  <YYYYMMDD-HHMM>-missing-from-lakey.csv       # Mega rows that didn't fuzzy-match any Lakey row
  <YYYYMMDD-HHMM>-orphan-lakey-rows.csv        # live_clients rows missing client_id/hubspot_recordid/mega_id (any of the three)
  <YYYYMMDD-HHMM>-lakey-backup.csv             # snapshot of all touched Lakey rows BEFORE update
  <YYYYMMDD-HHMM>-multi-mid-deduped.csv        # multi-MID clients after auto-dedup (for audit)
  <YYYYMMDD-HHMM>-hubspot-import.csv           # FINAL HubSpot import file
  <YYYYMMDD-HHMM>-csi-billing-gaps.xlsx        # NC clients not in CSI billing run (only when --csi is provided)
  <YYYYMMDD-HHMM>-pci-sync-summary.txt         # quick stage-by-stage counts
```

Plus a Markdown run log at:
```
docs/key_findings/<YYYYMMDD-HHMM>-pci-sync.md
```

---

## Stages

### Stage 1 — Validate environment

1. Confirm the Mega report path exists. Fail fast with a clear message if not.
2. Confirm Lakey is reachable: `.venv/bin/python -m aps lakey query "SELECT 1"`. If it fails, prompt user to check VPN.
3. Verify the Mega `.xls` parses: load sheet `Visa Level 4`, confirm the header row is at row 8 (zero-indexed: `header=8`). Required columns: `Merchant ID`, `DBA Name`, `Legal Name`, `Date Account Setup`, `Overall Status`, `SAQ Due Date`.
4. Create the output folder `output/pci-sync/` if missing.
5. Generate the run timestamp (`YYYYMMDD-HHMM`) — use it as the prefix for every artifact.

### Stage 2 — Pre-flight Lakey integrity check

Find `live_clients` rows missing **any** of `client_id`, `hubspot_recordid`, `mega_id`. Save to `<ts>-orphan-lakey-rows.csv`. Use AskUserQuestion to prompt:

> "Found N live_clients rows missing one or more of (client_id, hubspot_recordid, mega_id). See `<path-to-orphan-csv>`. Proceed with PCI sync anyway?"

If user says no, exit. If yes, continue.

### Stage 3 — Load Mega report

1. Read sheet `Visa Level 4` with `header=8`.
2. Drop empty rows (`dropna(how='all')`).
3. Cast `Merchant ID` to string (avoids float coercion).
4. Drop noise rows: `12345678900`, `4445043969054`.
5. Save full parsed input to `<ts>-mega-input.csv` for audit trail.
6. Print: `Loaded N Mega merchants (excluding internals)`.

### Stage 4 — Match Mega → Lakey (two-pass)

For each Mega merchant, attempt matches in two passes:

1. **Pass 1 — Exact `mega_id` lookup.** If `live_clients.mega_id` equals the Mega merchant ID, that's the match (`match_score = 100`, `match_src = mega_id_exact`). This is unambiguous and cannot produce false positives. Most clients land here once Lakey is backfilled.
2. **Pass 2 — Fuzzy fallback.** For Mega merchants whose ID is not yet linked in Lakey, normalize DBA Name and Legal Name (lowercase, strip punctuation, drop common suffixes: `llc`, `inc`, `ltd`, `corp`, `corporation`, `co`) and fuzzy-match (`rapidfuzz.fuzz.token_set_ratio`, score cutoff = 80) against `live_clients.school_name`. Among matched candidates, prefer rows with status priority `Active > Collection > Inactive > Cancelled > others`. Take the best score across DBA and Legal Name.

Output `<ts>-membership.csv` with columns:
- `merchant_id`, `mega_dba`, `mega_legal`, `mega_overall`, `mega_saq_due`
- `client_id`, `lakey_school_name`, `lakey_status`, `lakey_hubspot_recordid`, `lakey_mega_id`
- `match_score`, `match_src` (`mega_id_exact` | `fuzzy_dba_name` | `fuzzy_legal_name`), `in_lakey` (bool)

Print counts: pass-1 hits, pass-2 hits, unmatched.

### Stage 5 — Identify gaps

1. **Missing from Lakey** — any Mega merchant with no Lakey match. Save to `<ts>-missing-from-lakey.csv`. Print the list.
2. **Mega merchants whose matched Lakey row lacks `hubspot_recordid`** — save to `<ts>-needs-hubspot-recordid.csv` with columns: `client_id`, `school_name`, `lakey_status`, `merchant_id`, `mega_overall`, `mega_saq_due`.
3. Both files are flagged for human follow-up. They do NOT block the sync.

### Stage 6 — Filter to syncable rows + auto-dedup

1. Drop rows with no Lakey match (already saved above).
2. **Apply exclusion filters in order:**
   1. Overrides file `EXCLUDE` entries (`config/pci-visa-overrides.csv`).
   2. Canadian clients (`country` matches Canada/CAN — see Authoritative rules above).
   3. SSB clients (`client_id` starts with `p1_mer_`, case-insensitive).
   4. eFit clients (`client_id` matches `^[1-9]\d*$`).
3. Drop rows where the matched Lakey row's `hubspot_recordid` is null/blank — those will only update Lakey, not HubSpot. (Save the count for the run log.)
4. **Multi-MID auto-dedup:** group by `client_id`. For groups with >1 row, keep the row with the most recent `SAQ Due Date`. Ties: prefer `Compliant`.
5. Save the dedup'd multi-MID rows to `<ts>-multi-mid-deduped.csv` for the audit trail.
6. The result: one row per `client_id`, ready to apply.

### Stage 7 — Backup Lakey state

For every `client_id` about to be touched, snapshot `client_id, school_name, pci, pci_renewal, hubspot_recordid` to `<ts>-lakey-backup.csv`. This is the rollback source AND the "previous-state diff" file (replaces detection-of-hand-edits — we just dump the current state and proceed).

### Stage 8 — Apply Lakey updates (only if `--apply`)

1. If `--apply` was NOT passed, print "DRY RUN — no Lakey writes" and skip to Stage 9.
2. For each row, run:
   ```sql
   UPDATE live_clients SET pci = %s, pci_renewal = %s WHERE client_id = %s
   ```
   Values: `pci_compliant_yes_no`, `saq_due_yyyy_mm_dd`, `client_id`.
3. Track row counts. Each UPDATE should affect exactly 1 row.
4. **Verify:** re-read all touched rows, compare to expected. Print "All N rows match expected" or list mismatches. Mismatches are a hard failure — abort and surface to the user.

### Stage 9 — Generate HubSpot import CSV (always)

1. Cross-reference: for each row in the syncable set, confirm `hubspot_recordid` exists in Lakey AND is non-blank. Drop rows that fail.
2. Build the import file at `<ts>-hubspot-import.csv` with columns:
   ```
   Record ID, PCI Compliant, PCI Expiration/Renewal Date
   ```
3. Date format: `MM/DD/YYYY` (zero-padded).
4. Print: `HubSpot import CSV ready: N rows.`

### Stage 10 — CSI billing reconciliation (only if `--csi <path>`)

Cross-reference Mega compliance state against the CSI billing run to surface billing errors in **both** directions: NC clients who aren't being charged AND inactive clients who *are* being charged.

1. Skip if `--csi` was not provided.
2. Load the CSI xlsx (sheet 0). Match on `CustomerNumber` (= Lakey `client_id`). Filter to PCI-fee rows via the `Notes` column regex `pci.*non.*compliance`. Charge amount lives in `OriginalDocumentAmount`.
3. **Uppercase both sides** of the client_id lookup — the CSI file mixes `04038B` and `04038b`, and case-sensitive lookups silently miss those clients.
4. Build the NC set from the **post-exclusion syncable rows** (not raw membership). This way Canadian/SSB/eFit/override clients aren't counted as billing gaps.
5. Use `INACTIVE_STATUSES` (see Authoritative rules) to split active vs. inactive — not a bare `lakey_status = "Active"` check.
6. Produce a 3-tab xlsx, with tab colors:
   - **Tab 1 "Active NC Not Billed"** (red, `FF0000`): priority — Active NC clients not in the CSI billing run.
   - **Tab 2 "All NC Not Billed"** (yellow, `FFFF00`): full list including inactive.
   - **Tab 3 "Inactive Still Charged"** (orange, `FFA500`): clients whose Lakey status is in `INACTIVE_STATUSES` but who appear in the CSI run with `OriginalDocumentAmount > 0`. This is a billing error in the opposite direction from Tab 1.
7. Save to `<ts>-csi-billing-gaps.xlsx`.

Print the headline gap counts (including Tab 3) to stdout and include them in the run log.

### Stage 11 — Push to HubSpot (only if `--auto-push-hubspot`)

1. Use AskUserQuestion to confirm: "About to update N HubSpot company records. Proceed?"
2. If confirmed, call `mcp__claude_ai_HubSpot__manage_crm_objects` in batches.
3. Track success/failure per batch. Log to the run log.

If `--auto-push-hubspot` is NOT set: print clear instructions for the manual import:
> "HubSpot import CSV is at `<path>`. Upload via HubSpot UI: Companies → Import → choose file → map columns: Record ID → Record ID, PCI Compliant → PCI Compliant, PCI Expiration/Renewal Date → PCI Expiration/Renewal Date."

### Stage 12 — Run log

Write `docs/key_findings/<ts>-pci-sync.md` with these sections:

```markdown
# PCI Sync — <date> <time>

## Inputs
- Mega report: <path>
- Mode: <audit-only | apply | apply + auto-push>

## Stage Counts
- Mega merchants loaded: N (after dropping noise)
- Matched to Lakey:        N
- Missing from Lakey:      N (see <missing-csv>)
- Multi-MID clients:       N (auto-deduped)
- Lakey rows updated:      N
- HubSpot import rows:     N
- Lakey rows missing hubspot_recordid (logged for review): N (see <needs-hubspot-csv>)

## Lakey Pre-flight
- Orphan rows in live_clients: N (see <orphan-csv>)
- User confirmed proceed: <yes|no>

## Hand-edit / Drift Note
Pre-update Lakey state captured in <backup-csv>. Compare to prior run's backup
to spot manual edits between runs.

## Applied Changes
- Total Lakey UPDATEs: N (verified N matches expected)
- Lakey-only updates (no HubSpot record): N — flag if non-zero
- HubSpot CSV / push: N rows

## Flagged for Manual Follow-up
- Mega merchants missing from Lakey: <count, top 5 names>
- Mega merchants with no HubSpot recordid in Lakey: <count, top 5 names>

## Files Produced
- <ts>-mega-input.csv
- <ts>-membership.csv
- ...

## Next Steps
- Manually research the N "missing from Lakey" rows.
- Backfill hubspot_recordid for the N "needs HubSpot recordid" rows.
- Upload <ts>-hubspot-import.csv to HubSpot if --auto-push-hubspot was not used.
```

---

## Implementation notes

- **Single Python script:** `scripts/pci_sync.py` does all the work. The skill calls it via `.venv/bin/python scripts/pci_sync.py <path> [flags]`.
- **No transactional wrapping** of the Lakey UPDATE — the Lakey connection runs in autocommit mode (per `aps/lakey_db.py`). If an UPDATE fails mid-batch, the run log will show partial progress; user can re-run safely (UPDATEs are idempotent).
- **`rapidfuzz` is the matching library** — already in the venv from this session. If it's not available, the skill should print a clear install command rather than crash.
- **HubSpot push:** when `--auto-push-hubspot` is set, batch in chunks of 100 to respect HubSpot rate limits. Confirm before first batch.
- **Re-runs are safe** — the skill is idempotent. Running it twice on the same Mega report produces no Lakey changes the second time (UPDATEs are write-same-value).

## Common pitfalls

- **Header row in Mega xls.** The "Visa Level 4" sheet has 8 rows of preamble; pandas needs `header=8`. If Mega changes the layout, the skill should fail with a clear message ("expected 'Merchant ID' header on row 9 of sheet 'Visa Level 4', found '<actual>'").
- **Mega `Merchant ID` is numeric in xls but a string identifier conceptually.** Cast to `int64` then `str` to avoid scientific notation / float artifacts.
- **`live_clients.pci_renewal` is a DATE column, not text.** Pass strings in `YYYY-MM-DD` form to psycopg2.
- **Auto-dedup edge case:** if all MIDs for a client tie on SAQ Due Date AND tie on compliant status, the script picks deterministically (first by sorted MID).
- **eFit filter must require no leading zero.** APS pads its client IDs to 6 digits (`000047`, `000063`). A `^\d+$` regex would catch them as "eFit" and silently drop real APS clients from the sync. The correct pattern is `^[1-9]\d*$`.
- **CSI client_id case-sensitivity.** The CSI billing file mixes `04038B` and `04038b`. Without uppercasing the lookup keys, those clients silently appear as "Not in CSI billing run" — Tab 1 false positives.

## Inputs and overrides

| File | Required | Purpose |
|------|----------|---------|
| Mega Visa Level 4 report | Yes | Source of truth for compliance status. Provided per run. |
| `--csi <xlsx>` | Optional | CSI billing run; enables Stage 10 reconciliation (Tabs 1/2/3). |
| `config/pci-visa-overrides.csv` | Optional, persistent | Permanent EXCLUDE list — clients exempt from PCI sync by agreement. Add a row to extend; no script changes needed. Schema: `client_id,action,reason,added_date,added_by`. Only `action=EXCLUDE` is read today. |

## Future enhancements (not in v1)

- Compare current Lakey state to the previous run's backup to flag hand-edits explicitly (today: just dump current state and proceed).
- Direct HubSpot search to backfill recordids for the "needs HubSpot recordid" set.
- Email/Slack notification when run completes.
- Schedule as a recurring agent.
