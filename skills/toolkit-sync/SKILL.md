---
name: toolkit-sync
description: Monthly MSI Toolkit (CSIPay/Pyxis) sync — load merchant-month processing data into Lakey live_toolkit_merchant_month. Filters to merchants Active in APS or Lakey, joins APS [Dealer summary] for monthly_mrr, derives brand (MB/EFIT/MM) and service_tier (FSB/SSB), enforces Net=CP+CSI identity, and is idempotent on (year, month, entity_id).
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <path-to-MSI-Toolkit-Data.xlsx> [--apply]
---

# /toolkit-sync — MSI Toolkit → Lakey Sync

Load monthly MSI Toolkit (CSIPay/Pyxis) merchant-month financial data into the
Lakey datalake. Surfaces processing residual revenue ($3.81M/yr) that's
otherwise invisible to APS reporting.

> Toolkit is canonical for processing financials. APS `[Dealer summary]` is canonical for member-dues MRR. Both are joined onto each row at load time so a single SELECT answers per-dealer P&L.

## Trigger

User invokes `/toolkit-sync <path-to-MSI-Toolkit-Data.xlsx>`. The Toolkit file is delivered monthly by CSI as an .xlsx (cumulative, including prior months for restatement).

## Arguments

| Argument | Description |
|---|---|
| `<path>` | **Required.** Path to the `MSI Toolkit Data.xlsx` file (any local path). |
| `--apply` | Actually write to Lakey. Without it, the script is dry-run only — produces audit CSVs but no DB writes. |

## Authoritative rules

These are locked in — do not re-derive each run:

- **Eligibility filter:** keep merchants where `Channel Partner ID` is **Active in APS `[Dealer]`** (`dealer status = 'Active'`) OR **Active in Lakey `live_clients`** (`status = 'Active'` AND `brand IS NOT NULL`). Excludes ~26% of Toolkit rows; preserves $3.54M of $4.81M total CP revenue.
- **Brand mapping** (Toolkit `Channel Partner` → Lakey `brand`):
  - `MEMBER SOLUTIONS` / `MEMBER SOLUTIONS DIRECT` (any case) → `MB`
  - `EFIT` → `EFIT`
  - else NULL (logged as warning)
- **Service tier:**
  - Channel Partner contains `DIRECT` → `SSB` (self-service / direct)
  - else `FSB` (full-service billing)
- **Identity invariant:** `Net = Channel Partner Revenue + CSIPay Revenue`. Hard-aborts the load if any row violates by ≥ $0.01.
- **PK:** `(year, month, entity_id)`. Idempotent — re-running the same xlsx is a no-op.
- **Restatement:** months present in the file are **DELETE+INSERT** (atomic per transaction). Months absent from the file are left untouched.
- **APS join** for `aps_mrr_dealer` and `aps_members_billed`: aggregate `[Dealer summary]` over `(YEAR(date), MONTH(date), dealer#)`, sum `total_paid + returned + refunded` (so MRR is net of returns/refunds, matching the dealer's actual collected dues).

## Output layout

```
output/toolkit-sync/<YYYYMMDD-HHMM>/
  load-summary.csv                 # per-month rows / merchants / sums
  merchants-in-file.csv            # one row per unique entity_id seen
  excluded-rows.csv                # rows filtered out by eligibility
  identity-failures.csv            # only present if Net ≠ CP + CSI
  backup-live_toolkit_merchant_month.csv  # snapshot pre-load (--apply only)
```

Plus the run log at:
```
docs/key_findings/<YYYYMMDD-HHMM>-toolkit-sync.md
```

## Stages

### Stage 1 — Validate environment

1. File exists. Fail fast if not.
2. APS reachable: `.venv/bin/python -m aps query "SELECT 1"`. If it fails, prompt user to check VPN.
3. Lakey reachable: `.venv/bin/python -m aps lakey query "SELECT 1"`.
4. Sheet `Sheet1` parses with 71 expected columns. New columns warn but proceed (drop with `WARN: unexpected new columns`).

### Stage 2 — Filter to eligible merchants

1. Read xlsx into DataFrame.
2. Drop rows with placeholder `Channel Partner ID` (`'0'`, NaN).
3. Pull APS Active dealer set: `SELECT [dealer#] FROM [Dealer] WHERE [dealer status]='Active'`.
4. Pull Lakey Active client set: `SELECT client_id FROM live_clients WHERE status='Active' AND brand IS NOT NULL`.
5. Filter to merchants where `UPPER(channel_partner_id)` is in **either** set.
6. Save excluded rows to `excluded-rows.csv` for visibility.

### Stage 3 — Derive brand + service_tier

Apply the mapping rules above. Cross-validate against Lakey `live_clients.brand` for any merchant present in both — if Toolkit-derived brand differs from Lakey brand for the same merchant, log the mismatch (currently zero mismatches expected).

### Stage 4 — Join APS [Dealer summary]

For each unique `(year, month, channel_partner_id)` in the eligible set:

```sql
SELECT YEAR([date]) AS y, MONTH([date]) AS m,
       UPPER(LTRIM(RTRIM([dealer#]))) AS dealer_upper,
       SUM(total_paid + returned + refunded) AS mrr_net,
       SUM(no_payments)                      AS members
FROM [Dealer summary]
WHERE YEAR([date]) IN (...)
  AND [dealer#] IN (...)
GROUP BY YEAR([date]), MONTH([date]), UPPER(LTRIM(RTRIM([dealer#])))
```

Populate `aps_mrr_dealer` and `aps_members_billed` per row. Some merchants
won't have an APS match (EFIT clubs, brand-new boards) — those land NULL.

### Stage 5 — Identity check (HARD GATE)

For every eligible row, compute `abs(net - (channel_partner_revenue + csipay_revenue))`. If any row > 0.01, write `identity-failures.csv` and **abort** the run with non-zero exit. The `live_toolkit_merchant_month.ck_net_identity` CHECK constraint also enforces this at insert time as a defence in depth.

### Stage 6 — Build xref entries

For each unique `entity_id`, emit xref rows:
- If `is_aps_active`: `(entity_id, 'aps_dealer', UPPER(channel_partner_id), 100)`
- If `is_lakey_active`: `(entity_id, 'lakey_client', UPPER(channel_partner_id), 100)`

Upsert via `ON CONFLICT (entity_id, source, source_id) DO NOTHING` — never updates existing entries.

### Stage 7 — Audit summary (DRY-RUN STOPS HERE)

Write `load-summary.csv` with per-month rollups. If `--apply` is not set, exit 0 — no DB writes. Operator reviews artifacts and re-runs with `--apply`.

### Stage 8 — Apply (only when `--apply`)

1. **Backup:** `COPY live_toolkit_merchant_month TO STDOUT WITH CSV HEADER` → `backup-live_toolkit_merchant_month.csv`.
2. **Transactional write** (single transaction):
   - For each `(year, month)` in the file: `DELETE FROM live_toolkit_merchant_month WHERE year=? AND month=?`.
   - Bulk INSERT all eligible rows.
   - Bulk UPSERT xref rows.
   - COMMIT.
3. **Post-load verification:**
   - Final row count.
   - Re-run identity check on stored data.
4. **Run log:** write `docs/key_findings/<ts>-toolkit-sync.md`.

## Schema reference

Tables created by `queries/migrations/20260501-1900-toolkit-tables.sql`:

| Table | Purpose | Cols | Indexes |
|---|---|---|---|
| `live_toolkit_merchant_month` | Wide fact table, 1:1 with xlsx + Lakey-aligned classifications + APS join + audit | 62 | PK `(year, month, entity_id)`; B-tree on `(channel_partner_id, year, month)`, `(channel_partner, year, month)`, `(brand, year, month)`, `date_boarded`, `month_date` |
| `merchant_id_xref` | entity_id → APS dealer# / Lakey client_id / EFIT CLUB_ID | 6 | PK `(entity_id, source, source_id)`; reverse on `(source, source_id)` |

Convenience views:

| View | Purpose |
|---|---|
| `v_dealer_pnl_monthly` | Per-dealer monthly with all four MRR concepts named clearly + Lakey enrichment (school_name, health_score, contract_type, etc.) |
| `v_toolkit_channel_partner` | Channel-partner / brand / service_tier monthly rollup |

## The four MRR/Billing concepts

This is the most important conceptual distinction in the schema:

| Concept | Column | Source | Meaning |
|---|---|---|---|
| **Total Monthly Billing** | `sales_volume` | Toolkit | Total $ CSIPay processed (recurring + one-time + retail) |
| **Monthly MRR** | `aps_mrr_dealer` | APS `[Dealer summary]` | Recurring member dues — the dealer's predictable base |
| **MSI Gross MRR** | `gross_revenue` | Toolkit | What CSI billed the dealer (fees) |
| **MSI Net MRR** | `channel_partner_revenue` | Toolkit | What MSI keeps after COGS — the headline |

## Error handling

| Failure | Detection | Recovery |
|---|---|---|
| New/renamed column in xlsx | Stage 1 column check | Update `COL_RENAME` in `scripts/toolkit_sync.py`, re-run |
| Identity mismatch (Net ≠ CP+CSI) | Stage 5 + DB CHECK constraint | Investigate bad row in source; fix in xlsx and re-run |
| APS unreachable | Stage 1 | Reconnect VPN and re-run |
| Lakey unreachable mid-write | Transaction rolls back | Reconnect and re-run; idempotent |
| Wrong file applied | Backup CSV in run dir | `\copy live_toolkit_merchant_month FROM '<backup>' WITH CSV HEADER` then re-run with the right file |

## Cadence

Monthly. CSI delivers the new xlsx ~5–10 days after month-end. Operator runs:

```bash
# Dry-run first — produces audit, no DB writes
.venv/bin/python scripts/toolkit_sync.py ~/Downloads/MSI\ Toolkit\ Data.xlsx

# Review output/toolkit-sync/<ts>/load-summary.csv
# Re-run with --apply
.venv/bin/python scripts/toolkit_sync.py ~/Downloads/MSI\ Toolkit\ Data.xlsx --apply
```

Total operator time: ~5 minutes/month.

## Pitfalls

- **The xlsx contains restated prior months.** Don't truncate the table before loading. The script's per-`(year, month)` DELETE+INSERT handles restatement correctly — restating Jan 2025 just replaces those 359 rows.
- **`Channel Partner ID` formats vary** (e.g. `02684A`, `P00333`, `EF1217`, `1163EF`, `1134-1821`). Always compare upper-case and trimmed.
- **EFIT merchants don't appear in APS `[Dealer]`.** Their `aps_mrr_dealer` will be NULL — that's expected. Use `is_lakey_active` to confirm they're in the EFIT-branded slice of `live_clients`.
- **`PCI Non-Compliance ` has a trailing space** in the xlsx header. Already handled in `COL_RENAME`.
- **`Date Boarded` arrives as `'05-20-2024'` strings.** Parsed to `date` at load. Don't store as text.
- **The first run on an empty table reports `Current rows in Lakey: 0` correctly.** Subsequent runs report the live count. The DELETE+INSERT pattern is idempotent regardless.

## Reference files

- DDL: `queries/migrations/20260501-1900-toolkit-tables.sql`
- Load script: `scripts/toolkit_sync.py`
- DBA panel rationale: `docs/key_findings/20260501-1700-toolkit-to-lakey-DBA-Panel.md`
- Staff panel rationale: `docs/key_findings/20260501-1700-toolkit-to-lakey-Staff-Engineer-Panel.md`
- Reconciliation context: `docs/key_findings/20260501-1330-msi-toolkit-revenue-reconciliation.md`
- Sample dealer P&L: `docs/key_findings/20260501-1635-p00333-mrr-breakdown-2025.md`
