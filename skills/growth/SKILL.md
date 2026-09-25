---
name: growth
description: EFIT club price increase impact analysis — monthly revenue trends, fee uptake, payment distribution, and revenue lift for a given club and date range
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep
argument-hint: <club_id> [from YYYY-MM] [to YYYY-MM] — e.g. /growth 429 2025-11 2026-03
---

# /growth — EFIT Price Increase Impact Analysis

Analyze the revenue impact of membership fee increases for a specific EFIT club. Produces a monthly revenue trend, fee uptake snapshot, increase distribution, and payment percentiles — then summarizes the total revenue lift.

## Trigger

User invokes `/growth <club_id>` or `/growth <club_id> <from> <to>`.

## Arguments

| Argument | Description |
|----------|-------------|
| `club_id` | **Required.** EFIT club ID (e.g. `429`) |
| `from` | Start month as `YYYY-MM` (optional, defaults to 6 months ago) |
| `to` | End month as `YYYY-MM` (optional, defaults to last complete month) |

Examples:
- `/growth 429` — last 6 months
- `/growth 429 2025-11` — from Nov 2025 to now
- `/growth 429 2025-11 2026-03` — Nov 2025 through Mar 2026

---

## Prerequisites

- VPN connection to MSI network (for EFIT Oracle access)
- `.env` in project root with EFIT credentials

---

## Instructions for Claude

### Step 0: Parse Arguments & Validate

Parse club_id, from, and to from user input. Apply defaults:
- `from`: if omitted, use `ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -6)` (6 months ago)
- `to`: if omitted, use `TRUNC(SYSDATE, 'MM')` (start of current month, i.e. last complete month)

Validate the club exists:

```bash
.venv/bin/python -m aps efit query "
SELECT CLUB_ID, CLUB_NAME, STATUS
FROM CMS.CLUB
WHERE CLUB_ID = {club_id}
"
```

GATE: STOP if club not found. Tell the user and offer to search by name:
```sql
SELECT CLUB_ID, CLUB_NAME FROM CMS.CLUB WHERE UPPER(CLUB_NAME) LIKE '%KEYWORD%'
```

---

### Step 1: Monthly Revenue & Avg Payment Trend

Run this query to get the month-over-month revenue picture. Splits large payments (>= $200, likely annual fees) from regular recurring payments to avoid distorting averages.

```bash
.venv/bin/python -m aps efit query "
SELECT
    TO_CHAR(mpt.TRANSACTION_DATE, 'YYYY-MM') AS month,
    COUNT(*) AS payments,
    ROUND(SUM(mpt.PAY_AMOUNT), 2) AS total_paid,
    ROUND(AVG(mpt.PAY_AMOUNT), 2) AS avg_payment,
    COUNT(DISTINCT mpt.ACCT_NO) AS unique_members,
    SUM(CASE WHEN mpt.PAY_AMOUNT >= 200 THEN 1 ELSE 0 END) AS large_payments,
    ROUND(SUM(CASE WHEN mpt.PAY_AMOUNT >= 200 THEN mpt.PAY_AMOUNT ELSE 0 END), 2) AS large_total,
    SUM(CASE WHEN mpt.PAY_AMOUNT < 200 THEN 1 ELSE 0 END) AS regular_payments,
    ROUND(SUM(CASE WHEN mpt.PAY_AMOUNT < 200 THEN mpt.PAY_AMOUNT ELSE 0 END), 2) AS regular_total,
    ROUND(AVG(CASE WHEN mpt.PAY_AMOUNT < 200 THEN mpt.PAY_AMOUNT END), 2) AS avg_regular_payment
FROM FAS.MEMBER_PAYMENT_TRANSACTIONS mpt
WHERE mpt.STATUS = 'C'
AND mpt.PAY_AMOUNT > 0
AND mpt.CLUB_ID = {club_id}
AND mpt.TRANSACTION_DATE >= TO_DATE('{from}-01', 'YYYY-MM-DD')
AND mpt.TRANSACTION_DATE < TO_DATE('{to_plus_one}-01', 'YYYY-MM-DD')
GROUP BY TO_CHAR(mpt.TRANSACTION_DATE, 'YYYY-MM')
ORDER BY TO_CHAR(mpt.TRANSACTION_DATE, 'YYYY-MM')
"
```

Where `{to_plus_one}` is the month after `{to}` (e.g. if to=2026-03, use 2026-04).

**What to look for:**
- A step-change in `avg_regular_payment` — this is the inflection point where the price increase activated
- Flat or growing `unique_members` = no churn from the increase
- Declining `unique_members` = possible churn signal

Present results as a table and note the inflection month.

---

### Step 2: Fee Increase Uptake Snapshot

Shows how many currently active members are paying above their base rate.

```bash
.venv/bin/python -m aps efit query "
SELECT
    c.CLUB_NAME,
    ma.CLUB_ID,
    COUNT(*) AS active_paying,
    SUM(CASE WHEN mps.NEXT_PAY_DUE_AMT > mps.BASE_RECURRING_PAYMENT THEN 1 ELSE 0 END) AS increased,
    SUM(CASE WHEN mps.NEXT_PAY_DUE_AMT = mps.BASE_RECURRING_PAYMENT THEN 1 ELSE 0 END) AS at_base,
    SUM(CASE WHEN mps.NEXT_PAY_DUE_AMT < mps.BASE_RECURRING_PAYMENT THEN 1 ELSE 0 END) AS below_base,
    ROUND(SUM(CASE WHEN mps.NEXT_PAY_DUE_AMT > mps.BASE_RECURRING_PAYMENT THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS increase_uptake_pct,
    ROUND(AVG(mps.BASE_RECURRING_PAYMENT), 2) AS avg_base_rate,
    ROUND(AVG(mps.NEXT_PAY_DUE_AMT), 2) AS avg_current_rate,
    ROUND(SUM(mps.NEXT_PAY_DUE_AMT - mps.BASE_RECURRING_PAYMENT), 2) AS total_monthly_lift
FROM CMS.MEMBER_AGREEMENT ma
JOIN FAS.MEMBER_PAYMENT_SUMMARY mps ON ma.ACCT_NO = mps.ACCT_NO AND ma.CLUB_ID = mps.CLUB_ID
JOIN CMS.CLUB c ON ma.CLUB_ID = c.CLUB_ID
WHERE ma.STATUS = 'Active'
AND mps.BASE_RECURRING_PAYMENT > 0
AND ma.CLUB_ID = {club_id}
GROUP BY c.CLUB_NAME, ma.CLUB_ID
"
```

**Key metrics to call out:**
- `increase_uptake_pct` — what % of members got the increase
- `total_monthly_lift` — the dollar value of the increase per month
- `avg_base_rate` vs `avg_current_rate` — the average increase per member

---

### Step 3: Increase Amount Distribution

Shows how the increase was applied across different plan tiers.

```bash
.venv/bin/python -m aps efit query "
SELECT
    ROUND(mps.NEXT_PAY_DUE_AMT - mps.BASE_RECURRING_PAYMENT, 2) AS increase_amount,
    COUNT(*) AS members,
    ROUND(AVG(mps.BASE_RECURRING_PAYMENT), 2) AS avg_base,
    ROUND(AVG(mps.NEXT_PAY_DUE_AMT), 2) AS avg_new_rate
FROM CMS.MEMBER_AGREEMENT ma
JOIN FAS.MEMBER_PAYMENT_SUMMARY mps ON ma.ACCT_NO = mps.ACCT_NO AND ma.CLUB_ID = mps.CLUB_ID
WHERE ma.STATUS = 'Active'
AND mps.BASE_RECURRING_PAYMENT > 0
AND ma.CLUB_ID = {club_id}
GROUP BY ROUND(mps.NEXT_PAY_DUE_AMT - mps.BASE_RECURRING_PAYMENT, 2)
ORDER BY increase_amount
"
```

**What to look for:**
- The largest member buckets show the most common plan tiers and their increases
- Negative values = anomalies (grandfathered rates, data issues, members with $0 or $5 next-pay)
- Outliers at the top (>$100 increase) are likely annual plan conversions or data issues — flag them

---

### Step 4: Payment Distribution Percentiles

Confirms whether the increase hit all tiers or just specific plan levels.

```bash
.venv/bin/python -m aps efit query "
SELECT
    TO_CHAR(mpt.TRANSACTION_DATE, 'YYYY-MM') AS month,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY mpt.PAY_AMOUNT), 2) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY mpt.PAY_AMOUNT), 2) AS median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY mpt.PAY_AMOUNT), 2) AS p75,
    ROUND(MIN(mpt.PAY_AMOUNT), 2) AS min_pay,
    ROUND(MAX(mpt.PAY_AMOUNT), 2) AS max_pay
FROM FAS.MEMBER_PAYMENT_TRANSACTIONS mpt
WHERE mpt.STATUS = 'C'
AND mpt.PAY_AMOUNT > 0
AND mpt.CLUB_ID = {club_id}
AND mpt.TRANSACTION_DATE >= TO_DATE('{from}-01', 'YYYY-MM-DD')
AND mpt.TRANSACTION_DATE < TO_DATE('{to_plus_one}-01', 'YYYY-MM-DD')
GROUP BY TO_CHAR(mpt.TRANSACTION_DATE, 'YYYY-MM')
ORDER BY TO_CHAR(mpt.TRANSACTION_DATE, 'YYYY-MM')
"
```

**What to look for:**
- P25 jumping = even the lowest-paying members got increased (broad rollout)
- Only P75 jumping = increase targeted premium tiers only

---

### Step 5: Analysis & Revenue Calculation

Using the data from Steps 1–4, produce the analysis:

#### 5a. Identify the inflection month
The month where `avg_regular_payment` (from Step 1) jumped the most. This is when the price increase activated.

#### 5b. Calculate revenue lift
Two measures:

1. **Pure rate lift** = `total_monthly_lift` from Step 2 × number of complete months since activation
   - This is the clean measure of the price increase alone

2. **Total revenue delta** = avg post-increase `regular_total` minus avg pre-increase `regular_total`, times months post-increase
   - This captures the full picture including member count changes

3. **Annualized lift** = `total_monthly_lift` × 12

#### 5c. Assess churn impact
Compare `unique_members` pre vs post increase from Step 1. Flag if:
- Dropped by >3% = possible churn from increase
- Flat or growing = no detectable churn (success)

---

### Step 6: Output

Present results in this format:

```
## {Club Name} (Club {club_id}) — Price Increase Impact

### The Increase
- **Uptake:** {pct}% ({increased} / {active_paying} active members)
- **Avg base rate:** ${base} → **Avg current rate:** ${current} (+${diff}/member)
- **Monthly recurring lift:** ${lift}/month
- **Annualized lift:** ~${lift * 12}/year

### Inflection Point: {Month Year}

| Month | Avg Regular Payment | Regular Revenue | Unique Members |
|-------|-------------------|-----------------|----------------|
{table rows from Step 1, highlight the inflection month}

### Revenue Generated from Price Increase
- Pure rate lift: ${monthly_lift} × {N} months = **${total_lift}**
- Revenue delta (pre vs post): **${delta_total}**
- Annualized: ~**${annual}**/year

### Member Retention
{Churn assessment from Step 5c}

### Distribution
- Top increase buckets: {top 3-5 from Step 3}
- Anomalies: {count of negative/outlier entries}
```

Also save the output to `docs/key_findings/{date}-{club_name_slug}-price-increase-impact.md` using the YYYYMMDD-HHMM format.

---

## Reference

### Key Tables

| Table | Purpose |
|-------|---------|
| `FAS.MEMBER_PAYMENT_TRANSACTIONS` | Payment history (STATUS='C' for completed, PAY_AMOUNT > 0) |
| `FAS.MEMBER_PAYMENT_SUMMARY` | Current rates: BASE_RECURRING_PAYMENT vs NEXT_PAY_DUE_AMT |
| `CMS.MEMBER_AGREEMENT` | Member status (Active/Cancelled/Frozen/Inactive) |
| `CMS.CLUB` | Club name and info |

### Excluded Club IDs
Always exclude test clubs: `1, 2, 1000, 5000, 1150`

### Large Payment Threshold
Payments >= $200 are classified as annual/large fees and excluded from avg payment calculations to avoid distortion.

### Portfolio-Wide Analysis
To run this across all clubs at once (no club_id filter), use the existing queries:
- `queries/efit-fee-increase-uptake.sql` — uptake snapshot for all clubs
- `queries/efit-fee-increase-trend.sql` — trend analysis with inflection detection
- `queries/efit-club-inflection-points.sql` — biggest jump month per club
