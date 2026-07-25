---
name: dealer-rate-hike
description: Detect and explain wholesale rate changes (MSI-to-dealer take rates) for any APS dealer, using the [Changes_History] audit trail plus derived blended-rate confirmation from [Dealer summary]
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <dealer#> — e.g. 03665A, 02478A
---

# /dealer-rate-hike — Wholesale Rate-Change History for a Dealer

Answers: **"When were rate changes made to this dealer, by whom, and what effect did they have on actual billing?"**

Produces a timestamped Markdown key finding under `docs/key_findings/` plus raw CSVs in `output/`.

## Trigger

User invokes `/dealer-rate-hike <dealer#>` — e.g. `/dealer-rate-hike 03665A`.

## Arguments

| Argument | Required | Description |
|---|---|---|
| `<dealer#>` | Yes | The APS dealer number (5-6 chars, usually ending in A/B). Case-sensitive — try both cases if unsure. |

## Prerequisites

- VPN connection to MSI network (APS SQL Server access)
- `.venv/bin/python` available in project root
- `queries/dealer-rate-hike-*.sql` files present (installed with this skill)

---

## Data model — what's available, what isn't

Two rate concepts. Different data availability:

| Rate concept | Meaning | Audit-logged? | Where |
|---|---|---|---|
| **Wholesale rate** | MSI's commission % per payment source (CC, EFT, coupon, etc.) | **YES** | `[Changes_History]` where `Table_Name = '[Dealer Rates]'`, joined to `[Dealer Rates]` by `ReferenceId = Dealer Rates.ID`. Full history back to 2005. |
| **Retail rate** | What the dealer charges each member (member's monthly dues) | **NO direct log** | `AccountRateLog` table exists but is dead (~20 rows total, all from 2005). Retail changes can only be *derived* from cycle-over-cycle diffs of `[Accounts basic].cycle_payment`. Not in scope for this skill. |

**Payment source codes** (in `[Dealer Rates].payment_source`):
| Code | Label |
|---|---|
| 1 | Coupon |
| 2 | Statement |
| 3 | EFT |
| 4 | Credit Card |
| 5 | Direct |
| 6 | Collection |
| 7 | Late Fee |
| 10 | Advance |

---

## Instructions for Claude

### Step 1 — Validate the dealer#

```bash
.venv/bin/python -m aps query "SELECT [dealer#], [dealer_name], [dealer status], [service begins], [date_cancelled], [primary_email] FROM [Dealer] WHERE [dealer#] = '<DEALER#>'"
```

If zero rows, try the opposite case (dealers are usually stored uppercase, e.g. `03665A` not `03665a`). If still zero, stop and ask the user.

### Step 2 — Pull the three source queries

Run each with `--params '{"dealer": "<DEALER#>"}'`. All three are idempotent read-only queries.

```bash
.venv/bin/python -m aps run queries/dealer-rate-hike-wholesale.sql --params '{"dealer": "<DEALER#>"}'
.venv/bin/python -m aps run queries/dealer-rate-hike-current-rates.sql --params '{"dealer": "<DEALER#>"}'
.venv/bin/python -m aps run queries/dealer-rate-hike-effective-by-cycle.sql --params '{"dealer": "<DEALER#>"}'
```

Outputs land in:
- `output/dealer-rate-hike-wholesale.csv` — every logged rate change (date, old, new, delta_bps, user)
- `output/dealer-rate-hike-current-rates.csv` — current rate card, one row per payment_source
- `output/dealer-rate-hike-effective-by-cycle.csv` — every cycle's total_paid, commission, and blended rate

**Rename the CSVs** to include the dealer# so multiple runs don't overwrite each other:
```bash
for f in output/dealer-rate-hike-{wholesale,current-rates,effective-by-cycle}.csv; do
  mv "$f" "${f/.csv/-<DEALER#>.csv}"
done
```

### Step 3 — Compute the blended-rate-by-year rollup

The per-cycle CSV is too granular for the report. Roll up to year:

```python
python3 <<'PY'
import csv
from collections import defaultdict
rows = list(csv.DictReader(open('output/dealer-rate-hike-effective-by-cycle-<DEALER#>.csv')))
def f(x):
    try: return float(x)
    except: return None
b = defaultdict(lambda: {'paid':0,'comm':0,'n':0})
for r in rows:
    y = r['cycle_end'][:4]
    b[y]['paid'] += f(r['total_paid']) or 0
    b[y]['comm'] += f(r['Total_Commission']) or 0
    b[y]['n']    += 1
print(f'{"Year":<6}{"Cycles":>8}{"Paid":>15}{"Commission":>15}{"Blended":>10}')
for y in sorted(b):
    v = b[y]
    r = v['comm']/v['paid'] if v['paid'] else 0
    print(f'{y:<6}{v["n"]:>8}{v["paid"]:>15,.0f}{v["comm"]:>15,.0f}{r:>10.2%}')
PY
```

### Step 4 — Interpret the change log

For each date in `dealer-rate-hike-wholesale-<DEALER#>.csv`, group by `change_at` bucketed to the same day. Each cluster typically represents ONE rate event by one user (e.g. "amendez lowered all sources on 2013-07-03").

Flag the following as **notable**:

- **Onboarding event** — cluster of `delta < 0` changes near `service_begins`. Usually the initial rate card being set below defaults.
- **Rate hike** — cluster of `delta > 0` changes, especially any `delta >= 0.005` (50 bps) or larger. These are the events the skill is named for.
- **Payment-source-specific bumps** — a change hitting only 1-2 sources (e.g. EFT-only) suggests a rate normalization, not a broad hike.
- **User initials** — `APS-DOM\<initials>` — worth mentioning in the writeup so reviewers know who owns the decision (e.g. `sfernando` = Shehani Fernando).

### Step 5 — Write the key finding

Create `docs/key_findings/<YYYYMMDD-HHMM>-dealer-<DEALER#>-rate-hike.md` following this template. Use current date/time in the filename (see the global YYYYMMDD-HHMM convention).

````markdown
# Rate-Change History — Dealer <DEALER#> (<Dealer Name>)

- **Dealer status:** <Active / Cancelled>
- **Service began:** <date>
- **Cancelled:** <date or —>
- **Report generated:** <YYYY-MM-DD HH:MM>

## Executive summary

<2-3 sentences: number of rate events in dealer's life, direction, most recent hike, current blended rate, whether audit log and derived rate agree>

## Wholesale rate change log

<Markdown table of every row in dealer-rate-hike-wholesale-<DEALER#>.csv, sorted by change_at. Columns: Date | Payment source | Old | New | Δ bps | Changed by>

**Distinct rate events:**
1. <Date> — <one-line description, e.g. "onboarding: amendez set opening card">
2. <Date> — <e.g. "first bump: +100 bps on CC/Direct/Collection">
3. <Date> — <e.g. "second bump: +100 bps across the board incl. EFT">

## Current rate card

<Markdown table from dealer-rate-hike-current-rates-<DEALER#>.csv: payment_source_label | rate | billing_volume | payment_term>

## Effective take rate — derived from billing

<Markdown table of the year-rollup from step 3: Year | Cycles | Total Paid | Commission | Blended Rate>

Independent confirmation from `[Dealer summary]`: <verify the blended rate movements line up with the audit-log events. Call out any divergence.>

## Bottom line

<1-2 sentences: what did MSI's take rate do over this dealer's life, and where does it sit now>

## Source files

- `output/dealer-rate-hike-wholesale-<DEALER#>.csv`
- `output/dealer-rate-hike-current-rates-<DEALER#>.csv`
- `output/dealer-rate-hike-effective-by-cycle-<DEALER#>.csv`
````

### Step 6 — Report back to user

Print:
- Location of the key finding
- Total number of rate change events
- Number of distinct rate events (deduplicated by day)
- Most recent hike date and size
- Current blended take rate (latest year's rollup)

Do NOT open the file automatically — the user can `cat` or open it themselves.

---

## Edge cases

- **Zero rows in wholesale log** — Dealer either predates the audit trail (rare, pre-2005) or has never had a rate change. Report "no logged wholesale rate changes" and still include the current rate card + effective-by-cycle so the user has context.
- **Dealer summary shows big blended-rate shifts NOT reflected in the audit log** — This can happen if payment mix shifted dramatically (e.g. dealer moved everyone from Coupon to EFT). Call it out explicitly in the writeup rather than misattributing it to a rate change.
- **`bank#` NULL in old Dealer summary rows** — Normal for pre-2021 cycles due to a schema transition. Include them; don't filter to `bank# = 1` only.
- **Multiple `rate_type` values** — Most dealers only have `Basic`. If a dealer has `Basic` + `Bank` + others, report each separately in the change log so you can see which rate card was modified.

## Related

- `docs/APS-DB-BRAIN.md` — general APS schema reference
- `docs/MRR-METHODS.md` — MRR calculation catalog (rate changes affect MSI's take, not the dealer's MRR)
- `queries/dealer-rate-hike-*.sql` — the three source queries this skill runs
