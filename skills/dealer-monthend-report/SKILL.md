---
name: dealer-monthend-report
description: Generate a rocket-styled multi-cycle month-end financial trend report for any APS dealer. Reproduces dbo.usp_MonthEndStatement per cycle (which ReadOnlyUser cannot EXEC) and pivots N cycles into a wide trend PDF with plain-English summary, auto-observations, and matching Excel + CSV.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <dealer#> <cycle_ids | lastN> — e.g. 00414A 1409,1411,1413,1415,1417,1419 · or · 00414A last6
---

# /dealer-monthend-report — Multi-Cycle Statement Trend Report

Answers: **"Show me the full month-end financial statement for this dealer across N cycles, with an owner-readable narrative and PDF."**

Produces:
- `output/dealer-monthend-trend/<dealer>-<startMon>-<endMon>-<year>.pdf` — rocket-styled multi-page PDF
- `output/dealer-monthend-trend/<dealer>-<startMon>-<endMon>-<year>.xlsx` — matching Excel with per-section sheets
- `output/dealer-monthend-trend/<dealer>-<startMon>-<endMon>-<year>.csv` — long-form (line_item × month)

Verified line-by-line against BFS Boxing (00414A) Jan–Jun 2026 statements (cycles 1409, 1411, 1413, 1415, 1417, 1419) — every line matches the source PDFs to the penny.

## Trigger

User invokes `/dealer-monthend-report <dealer#> <cycles>` — e.g.:
- `/dealer-monthend-report 00414A 1409,1411,1413,1415,1417,1419`
- `/dealer-monthend-report 00414A last6`

## Arguments

| Argument | Required | Description |
|---|---|---|
| `<dealer#>` | Yes | The APS dealer number (5-6 chars, usually ending in A/B). Case-sensitive — try both cases if unsure. |
| `<cycles>` | Yes | Either an explicit comma-separated list of cycle_ids (`1409,1411,1413,...`), or `lastN` to pull the N most recent cycles from bank 1 (`last6`, `last12`, etc.). Cycles are ordered oldest → newest in the report. |

## Prerequisites

- VPN connection to MSI network (APS SQL Server access)
- `.venv/bin/python` available in project root
- `queries/dealer-monthend-statement.sql` present (installed with this skill)
- `scripts/build_dealer_monthend_trend.py` present (installed with this skill)
- Python deps in `.venv`: `weasyprint`, `openpyxl` (already installed 2026-07-23)

---

## Data model — what the report reproduces

The report reproduces `dbo.usp_MonthEndStatement(@deal_id, @cycle_id)` — a ~1000-line proc that returns the dealer's monthly financial statement (Gross Revenue, Deductions & Credits, Net Revenue, plus CC/ACH summary panels).

**ReadOnlyUser cannot EXEC the proc**, so we reconstruct via SELECT on its underlying tables.

### Data sources (all SELECT-only)

| Table | What we read |
|---|---|
| `[Dealer summary]` | Cycle-level rollups (many raw fields flow to PDF directly) |
| `Payment` | Per-payment ledger — grouped by `method_of_payment` × `payment_location` |
| `[Dealer transaction]` | Funding activity, past-due entries, refund fee attribution |
| `[Dealer Rates]` | For `@baserate` (payment_source=3 Basic) and CC brand-rate labels |
| `PayfacDisbursement` + `PayfacDisbursementDetails` + `[Dealer Advances]` | Reserves held/released |
| `Dealer` | Dealer name for header |
| `[Bank cycle]` | Cycle end date, month name |

### Non-obvious derivations (all verified against PDFs)

Four line items don't derive naturally from column names. If ever debugging a mismatch, check these first:

1. **Direct Payment Processing Fees = `ds.Direct_commission`** — NOT `SUM(Payment.processing_fee) WHERE payment_location = 2`. That column is per-transaction decline fees (always ~0 for direct payments).

2. **ACH Billing (gross) = `SUM(Payment.amount) WHERE method=3 AND loc=1`** — NOT `ds.EFT_paid`. EFT_paid is principal-only; the PDF's "ACH Billing" includes late_fee and return_fee bundled with the principal.

3. **Late Fees Collected = `SUM(late_fee) WHERE payment_location IN (1, 3)`** — proc source suggests `loc=1` only; actual PDF includes `loc=3` (returns, which negatively offset collections).

4. **Late Fee Revenue Shared = `LF_paid − Total_LF_cost`** (= `LF_paid × lf_paid_%`) — dealer's negotiated share of late fees, a credit that REDUCES total deductions.

### Sign convention

`Payment` stores refunds/returns as **negative** amounts (money coming back). PDF displays deductions as **positive** amounts (money leaving the dealer). Reconstruction `abs()`s refund/return amounts before summing. Late Fee Revenue Shared stays negative (genuine dealer credit).

### Cycle-version branch

The proc uses `[DealerRates_0226]` when `cycle_id < 1413`, `[Dealer Rates]` otherwise. Current query uses `[Dealer Rates]` only. This is fine for cycles ≥ 1413 (March 2026 onward), and also passes for older cycles IF the dealer's rates didn't change across the boundary. For a dealer whose rates DID change pre-Mar-2026, add a `CASE WHEN @cycle_id < 1413 THEN ...` branch.

### Payment enum reminders

- `method_of_payment`: 3=EFT/ACH, 4=Visa, 5=Mastercard, 6=Discover, 7=Amex
- `payment_location`: 1=regular payment, 2=direct, 3=return, 10=refund

---

## Instructions for Claude

### Step 1 — Validate the dealer#

```bash
.venv/bin/python -m aps query "SELECT [dealer#], [dealer_name], [dealer status], [service begins] FROM [Dealer] WHERE [dealer#] = '<DEALER#>'"
```

If zero rows, try the opposite case (dealers are usually uppercase, e.g. `00414A` not `00414a`). If still zero, stop and ask the user.

### Step 2 — Resolve cycles (if user passed lastN or an ambiguous spec)

If the user passed `lastN`, the renderer resolves it automatically. If they passed a specific list, no lookup needed.

To help the user pick, you can list recent cycles:

```bash
.venv/bin/python -m aps query "SELECT TOP 12 ds.cycle_id, bc.cycle_end, ds.total_paid, ds.Total_Paid_to_dealer, ds.wire_date FROM [Dealer summary] ds LEFT JOIN [Bank cycle] bc ON bc.cycle_id = ds.cycle_id AND bc.[bank#] = ds.[bank#] WHERE ds.[dealer#] = '<DEALER#>' AND ds.[bank#] = 1 ORDER BY ds.cycle_id DESC"
```

### Step 3 — Run the report

```bash
.venv/bin/python scripts/build_dealer_monthend_trend.py <DEALER#> <CYCLE_SPEC>
```

Examples:
```bash
.venv/bin/python scripts/build_dealer_monthend_trend.py 00414A 1409,1411,1413,1415,1417,1419
.venv/bin/python scripts/build_dealer_monthend_trend.py 00414A last6
```

Output goes to `output/dealer-monthend-trend/`. Filenames auto-derive from period (e.g. `00414A-jan-jun-2026.{pdf,xlsx,csv}`).

### Step 4 — Verify totals (optional but recommended for first run on a new dealer)

Grep the totals from the CSV and eyeball for reasonableness:

```bash
grep -E 'Total Gross Revenue|Total Deductions|Net Revenue|ACH Billing|Total Amount Due' output/dealer-monthend-trend/<slug>.csv
```

**Common sanity check:** `Total Deductions` should track roughly 15–25% of `Total Gross Revenue` for a healthy MB dealer. If it's dramatically outside that band, there's likely a data quality issue on that specific cycle worth flagging in the summary.

If the user has actual PDF statements for cross-check, diff them line-by-line — see the "Cross-check against source PDFs" section below.

### Step 5 — Open the PDF for the user

```bash
open -a "Google Chrome" output/dealer-monthend-trend/<slug>.pdf
```

Or `open <path>` for their default PDF viewer.

### Step 6 — Report back to user

Print:
- Location of the PDF, XLSX, and CSV
- Total Gross Revenue and Net Revenue for the whole period
- Payments Collected % (Net / Gross across period)
- Any anomalies the auto-observations flagged (returns spike, refund spike, PCI non-compliance, etc.)

Do NOT re-summarize what's in the PDF — the plain-English summary at the top of page 1 already does that for the owner.

---

## Cross-check against source PDFs (verification workflow)

If the user provides source PDFs from apsfinancial.com (typically saved as `202601-<dealer>.pdf` etc.), diff line-by-line:

1. Read each PDF (single Read call per file — extract the whole thing).
2. Compare against the same month's column in `output/dealer-monthend-trend/<slug>.csv`.
3. Any mismatch is a bug in either the SQL or the Python renderer. Investigate immediately — do not paper over.

The four derivations documented above cover every known bug class. If you hit a NEW mismatch, first check whether the PDF value equals a raw `ds.*` column (proc bypasses the derivation) OR is derived from `Payment.*` sums that our query doesn't yet compute. Add the missing formula to `queries/dealer-monthend-statement.sql` and re-verify.

---

## Edge cases

- **VPN offline** — `.venv/bin/python scripts/build_dealer_monthend_trend.py` will fail on `pymssql.connect`. Have user reconnect VPN and retry.
- **Single cycle requested** — Renderer still works but observation engine will be terse (nothing to compare to). Better minimum is 3+ cycles.
- **Very old cycles (< 1413)** — SQL uses `[Dealer Rates]` for brand-rate labels. If the dealer had different rates in `DealerRates_0226`, the "3.50 %" labels may be off. Deduction totals unaffected (those come from live comm_rate on each Payment row).
- **Dealer with no `Dealer Rates.payment_source=3` row** — `@baserate` will be NULL. Skill should catch this and either default `@baserate = 0` or fail loudly.
- **Bank ≠ 1** — Currently hard-coded to bank 1 for `lastN` resolution. Explicit cycle lists work for any bank.

---

## Appendices

The trend PDF ends with two auto-generated appendices. Each is silent when there's no data to show (no fetch, no page).

### Appendix A — ACH Returns Detail
Fires when any cycle has `ach_returns_count > 0`. Per-member breakdown of every ACH return in the period, grouped by month. Columns: Date, Type (always ACH), Account Holder, Student, Status, Amount, Reason (from `[Reason for Return]`).

- Source query: `queries/dealer-chargebacks-detail.sql`
- Trigger: any cycle with ACH returns
- Fetch function: `fetch_chargebacks()` / renderer: `_render_chargebacks_appendix()`

### Appendix B — Credit Card Deductions Detail
Fires when any cycle has CC gross revenue OR CC decline fees OR CC chargebacks OR CC refunds. Per-member breakdown of every CC transaction that generated a deduction. Columns: Date, Card, Event, Account Holder, Student, Status, Principal, Brand Fee, MBS Fee, Late Fee, Decline Fee, Total Ded., Reason.

Formulas:
- `Brand Fee = principal × (comm_rate − baserate)` (Visa/MC 3.50%, Amex 5.50%)
- `MBS Fee = principal × baserate` (Managed Billing Service, typically 4.75%)
- `Total Ded. = principal × comm_rate + late_fee + decline_fee` (all CC fees combined)

Reason populates when `return_reason` is set: 22=Chargeback, 23=Declined, 24=Expired, 25=Invalid Account No.

- Source query: `queries/dealer-cc-declines-detail.sql`
- Trigger: any cycle with CC activity
- Fetch function: `fetch_cc_declines()` / renderer: `_render_cc_declines_appendix()`

### Account model (both appendices)
`Payment.customer#` → `[Key].person_id` → account_holder (payer/cardholder).
`view_APSAccount.MemberName` joined on `(CustomerID, SubID)` → student (the actual member). For parent-child accounts these differ; the renderer marks the student column with " (student)". See Saraceno key finding `20260619-1545-saraceno-phantom-charge-causby-03402A.md` for the full account/sub/student model.

---

## Related

- `docs/APS-DB-BRAIN.md` — general APS schema reference
- `docs/MRR-METHODS.md` — MRR calculation catalog
- `queries/dealer-monthend-statement.sql` — the single-cycle SQL this skill drives
- `queries/dealer-chargebacks-detail.sql` — ACH returns appendix source
- `queries/dealer-cc-declines-detail.sql` — CC deductions appendix source
- `scripts/build_dealer_monthend_trend.py` — the Python renderer
- `docs/key_findings/20260724-1145-monthend-statement-recreation-and-trend-report.md` — original reverse-engineering writeup
- `docs/key_findings/20260619-1545-saraceno-phantom-charge-causby-03402A.md` — account/sub/student model
- Memory: `reference_monthend_statement.md` — condensed reference for future sessions
