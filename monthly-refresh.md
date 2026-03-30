---
name: monthly-refresh
description: Monthly datalake refresh — pull active members and billing volume from APS, update Lakey core_data snapshots, sync to HubSpot
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, mcp__claude_ai_HubSpot__search_crm_objects, mcp__claude_ai_HubSpot__manage_crm_objects, mcp__claude_ai_HubSpot__search_properties, AskUserQuestion
argument-hint: [YYYY-MM] — month to refresh (default: previous month)
---

# /monthly-refresh — Datalake Monthly Data Refresh

Pull active members and billing volume from APS (SQL Server), update Lakey datalake (PostgreSQL) snapshots, and sync key fields to HubSpot.

> Replaces the manual process documented in "Updating Monthly Billing Volume and Active Members in DataLake.pdf". Runs against the previous completed billing cycle.

## Trigger

User invokes `/monthly-refresh` or `/monthly-refresh 2026-02` to refresh a specific month.

## Arguments

| Argument | Description |
|----------|-------------|
| `YYYY-MM` | Target month (optional, defaults to previous completed cycle) |
| `--dry-run` | Show what would change without writing to Lakey or HubSpot |
| `--skip-hubspot` | Skip the HubSpot sync step |

If no argument is provided, auto-detect the most recent completed cycle from APS.

---

## Prerequisites

- VPN connection to MSI network (for APS SQL Server access)
- `.env` in project root with APS and Lakey credentials
- HubSpot MCP server connected (for HubSpot sync)

---

## Instructions for Claude

### Step 0: Setup & Cycle Detection

Parse arguments from user input. Then detect the target cycle:

```python
from aps.db import query as aps_query

# Find the most recent COMPLETED cycle (status = 0)
# Status 0 = closed, 1 or 2 = active/in-progress
cycles = aps_query("""
    SELECT TOP 3 cycle_id, cycle_end, cycle_status
    FROM [Bank cycle]
    WHERE [bank#] = 1
    ORDER BY cycle_id DESC
""")
```

If user specified a `YYYY-MM`, find the matching cycle. Otherwise use the most recent completed cycle (status = 0).

Also check Lakey for the latest existing snapshot:

```python
from aps.lakey_db import query as lakey_query

latest = lakey_query("""
    SELECT MAX(snapshot_date)::date AS latest
    FROM live_core_data
    WHERE monthly_billing_volume IS NOT NULL
""")
```

Present to user:
```
Target cycle: {cycle_id} ending {cycle_end}
Snapshot date: {last day of target month}
Latest Lakey snapshot with billing data: {latest}
Months to backfill: {list of missing months if any}
```

GATE: STOP. Confirm the target month(s) with the user before proceeding. If multiple months need backfilling, confirm the user wants to process all of them.

---

### Step 1: Pull Data from APS

Run the combined query against APS for each target cycle. This query gets billing volume, active members, and gross monthly revenue in one pass:

```python
# For each target cycle_id:
data = aps_query("""
    DECLARE @cycleId INT = {cycle_id};
    DECLARE @CycleEnd AS smalldatetime = (
        SELECT cycle_end FROM [Bank cycle] WHERE cycle_id = @cycleId
    );

    WITH ActiveMembers AS (
        SELECT
            d.[dealer#],
            COUNT(p.person_id) AS MemberCount
        FROM dbo.Dealer d
        INNER JOIN dbo.[Key] k ON d.[dealer#] = k.[dealer#]
        INNER JOIN dbo.Person p ON k.person_id = p.person_id
        INNER JOIN dbo.[Accounts basic] ab ON k.[customer#] = ab.[customer#]
        WHERE ab.active_setting = 1
        GROUP BY d.[dealer#]
    )

    SELECT
        a.[dealer#] AS client_id,
        d.dealer_name,
        a.[date] AS snapshot_date,
        a.total_paid AS monthly_billing_volume,
        ISNULL(am.MemberCount, 0) AS active_members
    FROM [dbo].[Dealer summary] a WITH (NOLOCK)
    INNER JOIN [dbo].[Dealer] d WITH (NOLOCK) ON a.[dealer#] = d.[dealer#]
    LEFT JOIN ActiveMembers am ON a.[dealer#] = am.[dealer#]
    WHERE a.cycle_id = @cycleId
      AND d.[dealer status] = 'Active'
    ORDER BY a.total_paid DESC
""")
```

Present summary:
```
Pulled {N} active dealers from APS cycle {cycle_id} ({cycle_end})
Top 5 by billing volume: ...
Total billing volume: ${sum}
Total active members: {sum}
```

GATE: STOP. Verify numbers look reasonable by comparing to the previous month's Lakey data. If any dealer's billing volume changed by more than 50%, flag it for review. Do NOT proceed until user confirms.

---

### Step 1b: Pull Data from EFIT (Oracle)

For each target month, pull MRR and billing volume from `FAS.CLUB_DATA_1` + `FAS.CLUB_DATA_2`:

```python
from aps.efit_db import query as efit_query

# month_name = 'January', 'February', etc.  year = 2026
efit_data = efit_query(f"""
    WITH base AS (
        SELECT
            cd1.club_id AS client_id,
            REPLACE(cd1.name, ',', '') AS name,
            ROUND(
                NVL(cd2.access_fees, 0) + NVL(cd2.wires, 0) + NVL(cd2.cc_fees, 0)
                + NVL(cd2.payfac_cc_fees, 0) + NVL(cd2.ach_fees, 0) + NVL(cd2.pif_tracking, 0)
                + NVL(cd2.statement_fees, 0) + NVL(cd2.marketing, 0) + NVL(cd2.cards, 0)
                + NVL(cd2.card_postage, 0) + NVL(cd2.brivo_fees, 0) + NVL(cd2.custom, 0)
                + NVL(cd2.misc, 0) + NVL(cd2.member_late_fees, 0)
                + NVL(cd2.payfac_member_late_fees, 0) + NVL(cd2.member_return_fees, 0)
                + NVL(cd2.payfac_member_return_fees, 0) + NVL(cd2.data_security_fees, 0)
                + NVL(cd2.file_management_fees, 0) - NVL(cd2.club_cancellation, 0)
            , 2) AS mrr
        FROM fas.club_data_1 cd1
        JOIN fas.club_data_2 cd2
            ON cd1.club_id = cd2.club_id AND cd1.month = cd2.month AND cd1.year = cd2.year
        WHERE cd1.month = '{month_name}' AND cd1.year = {year}
            AND cd1.club_id NOT IN ('1', '2', '1000', '5000', '1150')
    )
    SELECT client_id, name, mrr, ROUND(mrr / 0.06, 2) AS monthly_billing_volume
    FROM base ORDER BY mrr DESC
""")
```

Also pull active members from `CMS.MEMBER`:

```python
efit_members = efit_query("""
    SELECT m.club_id AS client_id, COUNT(*) AS active_members
    FROM CMS.MEMBER m
    WHERE m.status = 'Active'
    GROUP BY m.club_id
""")
```

**Key details:**
- MRR = sum of all fee columns from `FAS.CLUB_DATA_2` minus `club_cancellation`
- Monthly billing volume = `MRR / 0.06` (6% fee rate)
- Exclude test clubs: `1, 2, 1000, 5000, 1150`
- Active clubs are further filtered by `CORE.APPLICATION_PARAMETER_VALUES` (parameter_id = '71') for club info queries
- Active members come from `CMS.MEMBER WHERE status = 'Active'`

Present summary:
```
EFIT {month_name} {year}: {N} clubs
Total billing: ${sum}  Total MRR: ${sum}
Active members across {N} clubs: {sum}
```

---

### Step 2: Detect New Clients

Compare APS dealer IDs and EFIT club IDs against `live_clients` in Lakey:

```python
lakey_clients = lakey_query("SELECT client_id, brand FROM live_clients")
lakey_ids = {r['client_id'].upper() for r in lakey_clients}

# New MB clients (from APS)
new_mb = [r for r in aps_data if r['client_id'].upper() not in lakey_ids]

# New EFIT clients (from Oracle)
new_efit = [r for r in efit_data if str(r['client_id']) not in {str(c['client_id']) for c in lakey_clients}]
```

If new dealers/clubs found:
1. **MB:** Pull full dealer info from APS `Dealer` + `Address` tables
2. **EFIT:** Pull club info from `CMS.CLUB` (filtered by parameter_id 71)
3. Search HubSpot for matching company records
4. Present new clients to user with proposed field mappings

```
New clients to add to Lakey:
| ID | Name | Brand | Members | Billing | HubSpot Match |
```

GATE: STOP. Confirm new client additions with user. Some may be test accounts or duplicates.

---

### Step 3: Update Lakey

Execute updates in this order:

#### 3a. Insert new clients into `live_clients` (if any)

Map APS Dealer fields to Lakey columns:

| APS Source | Lakey Column |
|-----------|-------------|
| `dealer#` | `client_id` |
| `dealer_name` | `school_name` |
| `contact` | `primary_contact` |
| `primary_email` | `primary_email` |
| `phone1` | `phone` |
| Address table `city` | `city` |
| Address table `state` | `state` |
| Address table `zip` | `zipcode` |
| Address table `country` | `country` |
| Address table `streetl1` | `street` |
| `industry` | `industry` |
| `dealer status` | `status` |
| HubSpot record ID | `hubspot_recordid` |
| Always `'MB'` for APS | `brand` |

#### 3b. Update `live_clients` with current values

```python
# MB: Update active_members and monthly_billing_volume from APS
for row in aps_data:
    cur.execute("""
        UPDATE live_clients
        SET active_members = %s, monthly_billing_volume = %s
        WHERE UPPER(client_id) = UPPER(%s)
    """, (row['active_members'], row['monthly_billing_volume'], row['client_id']))

# EFIT: Update monthly_billing_volume, mrr, and active_members from Oracle
for row in efit_data:
    cur.execute("""
        UPDATE live_clients
        SET monthly_billing_volume = %s, mrr = %s
        WHERE client_id::text = %s
    """, (int(row['monthly_billing_volume']), int(row['mrr']), str(row['client_id'])))

for row in efit_members:
    cur.execute("""
        UPDATE live_clients
        SET active_members = %s
        WHERE client_id::text = %s AND brand = 'EFIT'
    """, (row['active_members'], str(row['client_id'])))
```

#### 3c. Create snapshot rows in `live_core_data`

For each target snapshot date:

```python
# Check if rows already exist
existing = lakey_query(
    "SELECT COUNT(*) as cnt FROM live_core_data WHERE snapshot_date = %s::timestamp",
    (snapshot_date,)
)

if existing[0]['cnt'] == 0:
    # Create rows for ALL clients (MB + EFIT) based on previous month
    cur.execute("""
        INSERT INTO live_core_data (client_id, snapshot_date, brand)
        SELECT client_id, %s::timestamp, brand
        FROM live_core_data
        WHERE snapshot_date = %s::timestamp
    """, (snapshot_date, previous_snapshot_date))

    # Also add rows for any new clients not in previous snapshot
    # (handle separately)
```

#### 3d. Update snapshot fields

**MB data** (from APS — cycle-specific values, not from live_clients):
```python
# For each APS row, update core_data directly with cycle-specific values
for row in aps_data:
    cur.execute("""
        UPDATE live_core_data
        SET monthly_billing_volume = %s, active_members_mm = %s
        WHERE UPPER(client_id) = UPPER(%s)
          AND snapshot_date = %s::timestamp
    """, (int(row['monthly_billing_volume']), row['active_members'],
          row['client_id'], snapshot_date))

# Copy mrr from live_clients for MB
cur.execute("""
    UPDATE live_core_data SET mrr = c.mrr
    FROM live_clients c
    WHERE live_core_data.client_id = c.client_id
      AND live_core_data.snapshot_date = %s::timestamp
      AND c.brand = 'MB' AND c.mrr IS NOT NULL
""", (snapshot_date,))
```

**EFIT data** (from Oracle — month-specific values):
```python
# Update billing, mrr from EFIT query results (per month)
for row in efit_data:
    cur.execute("""
        UPDATE live_core_data
        SET monthly_billing_volume = %s, mrr = %s
        WHERE client_id::text = %s
          AND snapshot_date = %s::timestamp
    """, (int(row['monthly_billing_volume']), int(row['mrr']),
          str(row['client_id']), snapshot_date))

# Update active members for EFIT (current count, same for all months)
for row in efit_members:
    cur.execute("""
        UPDATE live_core_data
        SET active_members_mb = %s
        WHERE client_id::text = %s
          AND snapshot_date = %s::timestamp
    """, (row['active_members'], str(row['client_id']), snapshot_date))
```

Present results:
```
Lakey updates for {snapshot_date}:
- New clients added: {N}
- live_clients updated: {N} rows
- core_data rows created: {N}
- billing volume populated: {N} rows
- active members populated: {N} rows
```

GATE: STOP. Show a spot-check comparing 5 random dealers between APS source data and what's now in Lakey. Confirm values match before proceeding to HubSpot.

---

### Step 4: Sync to HubSpot

Skip this step if `--skip-hubspot` was passed.

#### 4a. Find HubSpot records

For all clients (MB + EFIT) with updated data, search HubSpot by company name for any that don't already have a `hubspot_recordid` in `live_clients`.

#### 4b. Batch update HubSpot

Process **both brands** — MB and EFIT clients that have `hubspot_recordid` values.

Update these custom properties on each company record:

| Lakey Field | HubSpot Property |
|------------|-----------------|
| `client_id` | `client_id` |
| `active_members` | `active_members` |
| `monthly_billing_volume` | `monthly_billing_volume` |
| `mrr` | `monthly_recurring_revenue` |

**Important:** HubSpot MCP limits updates to 10 objects per request. Batch accordingly.

Present proposed changes table and get user confirmation per the HubSpot MCP requirements:

```
Proposed HubSpot Updates:
| Company | client_id | active_members | billing_volume |
```

GATE: STOP. Get explicit user approval before writing to HubSpot. Offer to skip confirmations for the session if this is a routine run.

---

### Step 5: Summary Report

Generate a summary and save to `output/monthly-refresh-{YYYY-MM}.md`:

```markdown
# Monthly Refresh: {Month Year}

**Cycle:** {cycle_id} ending {cycle_end}
**Run date:** {today}

## Data Pulled from APS
- Active dealers: {N}
- Total billing volume: ${sum}
- Total active members: {sum}

## Lakey Updates
- New clients added: {N} ({list names})
- Snapshot rows created: {N}
- Billing volume updated: {N} dealers
- Active members updated: {N} dealers

## HubSpot Sync
- Records updated: {N}
- Records not found: {N} ({list names})

## Anomalies
- {Any flagged items from Step 1 gates}

## Missing Data
- Clients without HubSpot records: {list}
- EFIT clients (no active member data): {N}
```

---

## Field Reference

### APS Source Tables (MB brand — SQL Server)

| Table | Key Fields | Used For |
|-------|-----------|---------|
| `[Dealer summary]` | `total_paid`, `cycle_id` | Monthly billing volume |
| `[Dealer]` | `dealer#`, `dealer_name`, `dealer status` | Client info, filtering active |
| `[Key]` + `[Person]` + `[Accounts basic]` | `active_setting = 1` | Active member count |
| `[Bank cycle]` | `cycle_id`, `cycle_end`, `cycle_status` | Cycle detection |
| `[Address]` | `city`, `state`, `zip`, `country` | New client address |

### EFIT Source Tables (EFIT brand — Oracle)

| Table | Key Fields | Used For |
|-------|-----------|---------|
| `FAS.CLUB_DATA_1` | `club_id`, `month`, `year`, `name` | Club identity, period |
| `FAS.CLUB_DATA_2` | All fee columns, `club_cancellation` | MRR calculation (sum fees - cancellations) |
| `CMS.MEMBER` | `club_id`, `status = 'Active'` | Active member count |
| `CMS.CLUB` | `club_id`, `club_name`, `status`, address fields | Club info for new clients |
| `CORE.APPLICATION_PARAMETER_VALUES` | `parameter_id = '71'` | Filter out internal/test clubs |

**EFIT MRR formula:** Sum of `access_fees`, `wires`, `cc_fees`, `payfac_cc_fees`, `ach_fees`, `pif_tracking`, `statement_fees`, `marketing`, `cards`, `card_postage`, `brivo_fees`, `custom`, `misc`, `member_late_fees`, `payfac_member_late_fees`, `member_return_fees`, `payfac_member_return_fees`, `data_security_fees`, `file_management_fees` minus `club_cancellation`.

**EFIT billing volume:** `MRR / 0.06` (6% fee rate).

**EFIT excluded club IDs:** `1, 2, 1000, 5000, 1150` (test/internal clubs).

### Lakey Target Tables

| Table | Key Fields | Updated By |
|-------|-----------|-----------|
| `live_clients` | `active_members`, `monthly_billing_volume`, `hubspot_recordid` | Steps 3a, 3b |
| `live_core_data` | `monthly_billing_volume`, `active_members_mm`, `snapshot_date` | Steps 3c, 3d |

### HubSpot Properties

| Property | Type | Source |
|----------|------|--------|
| `client_id` | Text | APS dealer# |
| `active_members` | Number | APS active member count |
| `monthly_billing_volume` | Number | APS Dealer summary.total_paid |
| `monthly_recurring_revenue` | Number | Lakey live_clients.mrr |

---

## Cycle ID Reference

Cycles use odd numbers, incrementing by 2. Bank# = 1 for the primary billing bank.

| Status | Meaning |
|--------|---------|
| 0 | Closed / completed |
| 1 | Active (current) |
| 2 | In progress |

---

## Troubleshooting

- **"No completed cycles found"**: The current cycle hasn't closed yet. Wait until after month-end processing.
- **Large billing volume swings**: Check if the dealer had a contract change, cancellation wave, or seasonal pattern. Compare 3-month trend before accepting.
- **New dealer not in HubSpot**: May need to be created manually in HubSpot first, or flag for sales team.
- **EFIT clients missing active members**: Expected — active member tracking is only for APS/MB clients per current process.
