---
name: truck-incentives
description: Research and compare current manufacturer financing deals, rebates, and incentives on new trucks in Canada. Tracks 0% financing offers, cash rebates, trade-in bonuses, and lease deals.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch, AskUserQuestion
argument-hint: [command] [options] — e.g., /truck-incentives check, /truck-incentives compare F-150 vs Sierra, /truck-incentives history
---

# /truck-incentives — New Truck Financing Deal Tracker

Research current manufacturer incentives on new trucks in Canada, compare deals across brands, and track how offers change month to month.

## Trigger

User invokes `/truck-incentives` or asks about new truck financing deals, 0% APR offers, manufacturer rebates, or new vs used truck comparisons.

## Arguments

| Command | Description |
|---------|-------------|
| `check` | Research all current 0% financing and incentive deals (default) |
| `compare <truck1> vs <truck2>` | Side-by-side comparison of two specific trucks |
| `history` | Show how deals have changed over time from saved data |
| `--province <XX>` | Filter for province-specific offers (default: SK) |
| `--makes <list>` | Only check specific makes (e.g., "Ford,RAM,GMC") |
| `--include-midsize` | Include mid-size trucks (Tacoma, Ranger, Canyon, Frontier, etc.) |
| `--save` | Save results to data/incentives/ for tracking over time |

## Process

### Phase 1: Research Current Deals

Use WebSearch to find current offers for each manufacturer. Search queries:

**Full-size trucks (always check):**
1. `"Ford F-150 0% financing Canada [current year] incentives"`
2. `"RAM 1500 0% financing Canada [current year] deals"`
3. `"Chevrolet Silverado 0% financing Canada [current year]"`
4. `"GMC Sierra 0% financing Canada [current year]"`
5. `"Toyota Tundra 0% financing Canada [current year]"`

**Mid-size trucks (if --include-midsize):**
6. `"Ford Ranger 0% financing Canada [current year]"`
7. `"Toyota Tacoma 0% financing Canada [current year]"`
8. `"Chevrolet Colorado GMC Canyon 0% financing Canada [current year]"`
9. `"Nissan Frontier 0% financing Canada [current year]"`
10. `"Honda Ridgeline 0% financing Canada [current year]"`

**General market context:**
11. `"best new truck deals Canada [current month] [current year]"`
12. `"zero percent financing trucks Canada [current month] [current year]" site:caredge.com OR site:finder.com`

Also fetch:
- https://www.ford.ca/offers/ (Ford Canada offers page)
- https://www.ramtruck.ca/en/current-offers/ (RAM Canada)
- https://www.chevrolet.ca/en/current-offers (Chevy Canada)
- https://www.gmccanada.ca/en/current-offers (GMC Canada)

### Phase 2: Extract & Organize

For each truck with a 0% or low-rate offer, extract:

```json
{
  "make": "Ford",
  "model": "F-150",
  "trim": "STX",
  "year": 2026,
  "apr_rate": 0.0,
  "apr_term_months": 72,
  "msrp_starting_cad": 52000,
  "cash_rebate_cad": 6500,
  "effective_price_after_rebate": 45500,
  "trade_in_bonus_cad": 0,
  "other_incentives": ["$1,000 costco member bonus"],
  "offer_expires": "2026-03-31",
  "province_specific": false,
  "notes": "STX trim only. On approved credit via Ford Credit Canada.",
  "source_url": "https://www.ford.ca/offers/"
}
```

### Phase 3: Compare & Analyze

Build a comparison table showing:

| Factor | Truck A | Truck B | Truck C | ... |
|--------|---------|---------|---------|-----|
| MSRP (starting) | | | | |
| 0% APR term | | | | |
| Cash rebate | | | | |
| Effective price | | | | |
| Trade-in bonus | | | | |
| Monthly payment (0% / max term) | | | | |
| Total cost of ownership (5yr) | | | | |

**Monthly payment calculation:** `effective_price / term_months`

**Total cost comparison vs used:** Compare against the user's used truck top picks from `data/top10.json` if it exists. Show the premium for buying new.

### Phase 4: Present Results

Show:
1. **Deal summary table** — all trucks with 0% or sub-2% financing
2. **Best overall deal** — factoring in rebates, term length, and effective price
3. **New vs used comparison** — "For the price of one new F-150 STX at $45.5K, you could buy [X] used trucks from our top 10"
4. **Time sensitivity** — when offers expire, whether to act now or wait
5. **Province-specific notes** — any SK/AB/ON/BC variations

### Phase 5: Save (if --save or auto)

Save to `data/incentives/YYYY-MM-incentives.json`:
```json
{
  "schema_version": 1,
  "date": "YYYY-MM-DD",
  "month": "March 2026",
  "deals": [ ... ],
  "best_deal": { ... },
  "market_context": "Tens of thousands of leftover 2025 models unsold. Average truck price near all-time high at $66K."
}
```

If previous months exist, show trend: "RAM dropped from 3.9% to 0% this month" or "Ford added $2K more rebate vs last month."

## Known Baseline (March 2026)

These are the deals we confirmed as of March 26, 2026. Use as a starting point and update with fresh research:

### Full-Size Trucks with 0% Financing

**Ford F-150 STX (2026)**
- 0% APR for 72 months (best term in market)
- $6,500 manufacturer rebate on top
- Effective price: ~$45,500 on a $52K truck
- Valid Mar 3-31, 2026 (check for April renewal)
- Source: ford.ca/offers

**RAM 1500 Big Horn Crew 4x4 (2026)**
- 0% APR for 60 months
- 90-day payment deferral available
- Offer price: ~$74,604 (Big Horn is mid-trim, pricier than base)
- Valid through Mar 31, 2026
- Source: ramtruck.ca

**GMC Sierra 1500 (2026)**
- 0% APR for 72 months (tied with Ford for longest term)
- $1,500 truck trade-in bonus (if trading a truck)
- Select trims only (Pro, SLE)
- Valid through Mar 31, 2026
- Source: gmccanada.ca

**Chevrolet Silverado 1500 (2026)**
- 0% APR for 60 months (ON) or 72 months (other provinces incl. SK)
- $1,500 truck trade-in bonus (if trading a truck)
- Valid through Mar 31, 2026
- Source: chevrolet.ca

### NO 0% Financing Available (March 2026)

**Toyota Tundra** — 4.49% best rate in Canada (0% available in US only)
**Toyota Tacoma** — 4.19% best rate in Canada
**Nissan Frontier** — No 0% in Canada. Starting MSRP $56,498 (expensive for the segment)
**Honda Ridgeline** — Typically 3.99%+ in Canada
**Ford Ranger** — 3.99% for 72 months (no 0%)

### Key Market Context (March 2026)
- Average new truck transaction price: ~$66,241 CAD
- Tens of thousands of leftover 2025 models remain unsold — creates leverage for negotiation
- Best strategy: look for leftover 2025 models with current 0% offers stacked
- 0% financing typically worth $5,000-$10,000 in interest savings vs 6-7% bank rate on a $50K+ truck
- Offers typically refresh monthly — April offers announced late March

### New vs Used Math

At 0% financing on a new F-150 STX (~$45.5K after rebate):
- Monthly payment: $632/mo for 72 months
- Zero interest cost
- Full warranty, latest safety tech, no unknown history

At 6.99% dealer financing on a used 2017 RAM Laramie ($20,999):
- Monthly payment: $403/mo for 60 months
- Total interest cost: ~$4,189
- True cost: ~$25,188

**The gap:** ~$20K more for new, but you get 5 more model years, full warranty, and $0 interest. For someone who keeps trucks 10+ years, new at 0% can actually be the better long-term play.

## Example Usage

```
/truck-incentives
/truck-incentives check --province SK
/truck-incentives compare "F-150 STX" vs "Sierra 1500 Pro"
/truck-incentives --include-midsize --makes "Ford,Toyota"
/truck-incentives history
```
