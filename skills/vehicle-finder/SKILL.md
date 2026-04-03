---
name: vehicle-finder
description: Search dealerships in any area for vehicles matching specific criteria (type, price, features, KMs). Scrapes dealer sites and aggregators in parallel, deduplicates, scores deals, and outputs structured JSON/MD.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
argument-hint: [location] [vehicle-type] [options] — e.g., /vehicle-finder Saskatoon trucks --max-price 25000 --features "heated seats" --max-km 200000
---

# /vehicle-finder — Multi-Dealership Vehicle Search & Deal Analyzer

Scrape dozens of dealerships and aggregators in a target area, filter by your criteria, score each vehicle against market value, and output a ranked deal list.

## Trigger

User invokes `/vehicle-finder` with search parameters, or asks to find vehicles for sale in an area.

## Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `location` | Yes | — | City/region to search (e.g., "Saskatoon", "Regina", "Calgary") |
| `vehicle-type` | No | `truck` | Vehicle type: `truck`, `suv`, `sedan`, `van`, `any` |
| `--max-price` | No | `25000` | Maximum price in CAD |
| `--min-price` | No | `0` | Minimum price in CAD |
| `--max-km` | No | `none` | Maximum kilometers (no limit if omitted) |
| `--features` | No | `none` | Comma-separated required features (e.g., "heated seats,backup camera,4WD") |
| `--radius` | No | `200` | Search radius in km from location center |
| `--output` | No | `json` | Output format: `json`, `md`, or `both` |
| `--output-path` | No | `./` | Directory to write results |
| `--min-year` | No | `none` | Minimum model year |
| `--makes` | No | `any` | Comma-separated makes to include (e.g., "Ford,RAM,Chevrolet") |
| `--history` | No | — | Show search history from manifest (no new search) |
| `--top10` | No | — | Show current top 10 leaderboard (no new search) |
| `--insights` | No | — | Show accumulated insights (no new search) |

If no arguments provided, ask the user for location and what they're looking for.

### Quick Commands (no search)

These flags skip the search and just read from history:
- `/vehicle-finder --history` — Show all past searches with dates, locations, and top picks
- `/vehicle-finder --top10` — Show the rolling top 10 leaderboard with status (active/likely sold)
- `/vehicle-finder --insights` — Show accumulated market insights and observations

Read from `data/manifest.json`, `data/top10.json`, or `data/insights.md` respectively. If the files don't exist yet, tell the user to run a search first.

## Process

### Phase 1: Discover Dealerships

**First, check for existing dealer registry:** Read `data/dealers.json` if it exists. For any dealers already known for this location:
- Use scrapeable dealers directly (skip re-discovery)
- Skip known-blocked dealers unless `last_checked` is older than 30 days (they may have changed)
- Only search for NEW dealers not already in the registry

If no registry exists or this is a new location, do full discovery:

1. **Search for dealerships** in the target area using WebSearch:
   - `"used car dealerships [location] [province]"`
   - `"car dealerships [nearby towns] [province]"`
   - `"used [vehicle-type] dealerships [location]"`
   - `"independent used car lots [location]"`
   - `"[location] auto dealer site:yellowpages.ca"`
   - Check for well-known franchise dealers (Toyota, Honda, Ford, Chrysler, GM, Hyundai, Kia, etc.)

2. **Build dealership list** — aim for 30-60 dealerships. Include:
   - Franchise dealers (new car dealers with used inventory)
   - Independent used car lots
   - Nearby town dealers (within radius)
   - Aggregator sites (AutoTrader, Kijiji, CarGurus, Facebook Marketplace dealer listings)

3. **Create task list** to track progress.

### Phase 2: Scrape Inventory (Parallel)

Split dealerships into batches of 5-7 and dispatch **parallel Agent workers**. Each agent gets:

**Agent prompt template:**
```
You are scraping used vehicle inventory from dealerships in [LOCATION].
For each dealership, fetch their inventory page and find ALL [VEHICLE_TYPE]s that match:
- Price: $[MIN_PRICE] - $[MAX_PRICE] CAD
- [MAX_KM constraint if set]
- [MIN_YEAR constraint if set]
- [MAKES constraint if set]
Note kilometers and whether these features are present: [FEATURES]

For each matching vehicle, extract: year, make, model, trim, price, kilometers,
key features (especially [FEATURES]), and the listing URL.

Scrape these dealerships:
[DEALER_LIST with URLs and inventory page hints]

Return a JSON array of objects with this structure:
{
  "dealership": "Name",
  "dealership_url": "url",
  "year": 2020,
  "make": "Ford",
  "model": "F-150",
  "trim": "XLT",
  "price": 24995,
  "kilometers": 85000,
  "heated_seats": true/false,
  "drivetrain": "4WD",
  "engine": "5.3L V8",
  "features": ["feature1", "feature2"],
  "listing_url": "url",
  "accidents": "none/unknown/yes"
}

If a dealership has no qualifying vehicles or is inaccessible, note why.
Only include vehicles matching ALL criteria. Return the complete JSON array.
```

**Tips learned from experience:**
- Many dealer sites use JS-heavy platforms (Autobunny, Convertus, DealerCity) that return empty on static fetch. Note these as "JS-only" and move on.
- Cloudflare/Incapsula blocks are common on franchise dealers. Note and skip.
- AutoTrader blocks WebFetch (Incapsula). Kijiji and CarGurus usually work.
- Try common inventory URL patterns: `/inventory`, `/used-vehicles`, `/vehicles`, `/search`, `/used/type/Trucks.html`
- FFUN group shares inventory across their network — one scrape covers multiple dealers.
- Aggregator sites (Kijiji, CarGurus) are the richest data sources — always include them.
- Some dealers list prices as "+ PST/GST" — note this as it changes the all-in cost.
- Private sales on Kijiji can be great deals (no GST, often negotiable).
- Smaller independent lots may not have websites — note for the user to check in person.

### Phase 3: Compile & Deduplicate

1. **Collect all agent results** — wait for all to complete.
2. **Deduplicate** — same vehicle may appear on multiple sites (dealer site + Kijiji + CarGurus). Match by:
   - Year + Make + Model + KMs (within 500km tolerance)
   - Price (within $500 tolerance)
   - Dealership name similarity
   Keep the listing with the most detail. Note alternative listing URLs.

3. **Market value assessment** for each vehicle using Claude's knowledge:
   - Estimate typical market range for that year/make/model/trim/KMs in the region
   - Rate as: `BELOW MARKET`, `AT MARKET`, `AT MARKET (low end)`, `ABOVE MARKET`
   - Explain reasoning

4. **Score and rank** vehicles that meet ALL criteria:
   - Primary: has all required features
   - Secondary: below market price
   - Tertiary: lower KMs preferred
   - Quaternary: newer model year preferred

### Phase 4: Output & History

All search data is persisted in a `data/` directory within the project root. Create it if it doesn't exist.

#### 4a. Save Search File (always — before asking)

Save the full search results to `data/searches/YYYY-MM-DD-HHMMSS-[location]-[type].json`:
```json
{
  "schema_version": 1,
  "search_id": "2026-03-26-143022-saskatoon-truck",
  "search_metadata": {
    "date": "YYYY-MM-DD",
    "timestamp": "YYYY-MM-DDTHH:MM:SS",
    "criteria": {
      "location": "Saskatoon",
      "vehicle_type": "truck",
      "max_price": 25000,
      "features": ["heated seats"],
      "max_km": null,
      "min_year": null,
      "makes": "any"
    },
    "dealerships_searched": N,
    "dealerships_with_results": N,
    "dealerships_blocked_or_no_inventory": [...]
  },
  "vehicles": [ ... sorted by composite_score ... ],
  "summary": {
    "total_found": N,
    "matching_all_criteria": N,
    "below_market": N,
    "top_picks": [ ... top 5-7 with reasoning ... ]
  }
}
```

#### 4b. Composite Scoring

Score each vehicle that meets ALL required features using this formula:

```
composite_score = (market_discount_pct * 0.4) + (feature_match_pct * 0.3) + (low_km_score * 0.3)
```

Where:
- `market_discount_pct`: How far below estimated market value (0-100). E.g., $5K below on a $25K truck = 20%.
- `feature_match_pct`: What % of desired features are confirmed present (0-100).
- `low_km_score`: Normalized score based on KMs. 0-100K = 100, 100-150K = 80, 150-200K = 60, 200-250K = 40, 250K+ = 20.

Add `composite_score` to each vehicle object. Rank by this score descending.

#### 4c. Update Top 10 (`data/top10.json`)

Maintain a rolling leaderboard of the 10 best finds across ALL searches:
```json
{
  "schema_version": 1,
  "last_updated": "YYYY-MM-DD",
  "vehicles": [
    {
      "rank": 1,
      "composite_score": 78.5,
      "year": 2014,
      "make": "Chevrolet",
      "model": "Silverado 1500",
      "trim": "LT Z71",
      "price": 24500,
      "kilometers": 108000,
      "dealership": "Private Sale (Rosthern)",
      "listing_url": "...",
      "source_search_id": "2026-03-26-143022-saskatoon-truck",
      "first_seen_date": "2026-03-26",
      "last_seen_date": "2026-03-26",
      "status": "active",
      "why": "Lowest KMs, no GST, garaged, $3-5K below market"
    }
  ]
}
```

Rules:
- Merge new finds into existing top 10 by composite score. Keep top 10 only.
- If a vehicle already exists (matched by year+make+model+KMs within 500km tolerance), update `last_seen_date` and `status`. If price changed, note the change.
- If a previously-seen vehicle is NOT found in a new search of the same location, set `status: "likely_sold"`.
- `first_seen_date` and `last_seen_date` enable tracking — a truck on the list for 6+ weeks is negotiable; a truck that appeared today and is below market will sell fast.

#### 4d. Update Manifest (`data/manifest.json`)

Append a one-liner entry for the search:
```json
{
  "schema_version": 1,
  "searches": [
    {
      "search_id": "2026-03-26-143022-saskatoon-truck",
      "date": "2026-03-26",
      "location": "Saskatoon",
      "vehicle_type": "truck",
      "criteria_summary": "trucks <$25K, heated seats",
      "total_found": 30,
      "below_market": 7,
      "top_pick": "2014 Silverado LT Z71 — $24,500 — 108K km",
      "file": "data/searches/2026-03-26-143022-saskatoon-truck.json",
      "kept": true
    }
  ]
}
```

#### 4e. Update Dealer Registry (`data/dealers.json`)

Accumulate dealer info across searches. On repeat searches for the same location, load this first to skip Phase 1 discovery (only search for NEW dealers):
```json
{
  "schema_version": 1,
  "dealers": [
    {
      "name": "FFUN Cars",
      "url": "https://www.ffuncars.com/",
      "location": "Saskatoon",
      "type": "franchise",
      "inventory_url": "https://www.ffuncars.com/used/type/Trucks.html",
      "scrapeable": true,
      "platform": "DealerCity",
      "last_checked": "2026-03-26",
      "notes": "Part of FFUN network — shares inventory across sites"
    },
    {
      "name": "Carget Auto",
      "url": "https://www.carget.ca/",
      "location": "Saskatoon",
      "type": "independent",
      "scrapeable": false,
      "platform": "Cloudflare blocked",
      "last_checked": "2026-03-26",
      "notes": "Blocked by Cloudflare"
    }
  ]
}
```

On repeat searches:
1. Load `data/dealers.json` for the target location
2. Use known scrapeable dealers directly (skip discovery for them)
3. Search for NEW dealers only
4. Update `last_checked` dates and `scrapeable` status

#### 4f. Append Insights (`data/insights.md`)

After each search, auto-append observations. Format:

```markdown
## 2026-03-26 — Saskatoon trucks <$25K

- **Market trend:** RAM 1500 dominates the under-$25K segment (60% of finds). Ford F-150 Lariats are the best-equipped deals.
- **Dealer note:** Prairie West Automotive has the most inventory in this price range. FFUN network lists same trucks across 4+ sites.
- **Scraping note:** AutoTrader blocked (Incapsula). Kijiji and CarGurus are the best aggregator sources.
- **Price insight:** 2017 RAM Laramies are underpriced relative to their trim level — luxury truck at mid-trim prices.
- **Top find:** 2014 Silverado LT Z71 private sale — 108K km, garaged, no GST. Unicorn.
```

The user can also manually add notes to this file at any time.

#### 4g. Ask to Keep

After presenting results and updating all files, ask:

> "Search saved to `data/searches/[filename]`. Want to keep it in your history? [Y/n]"

- Default: **Yes** (just pressing enter keeps it)
- If **No**: delete the search file from `data/searches/`, remove the manifest entry, revert top10 changes. Keep dealer registry updates (those are always useful).

### Phase 5: Present Results

Show the user:
1. **Top picks** — ranked by composite score with reasoning
2. **Quick stats** — total found, how many match all criteria, how many below market
3. **Caveats** — which dealers couldn't be scraped, which prices are + tax, etc.
4. **History context** (if repeat search): "Compared to your last [location] search on [date]: X new vehicles, Y no longer listed (likely sold), Z price changes"
5. **Ask to keep** — per Phase 4g

## Key Principles

- **Cast a wide net** — more dealerships searched = better chance of finding deals
- **Parallelize aggressively** — 6-8 agents running simultaneously
- **Don't guess features** — only mark features as present if explicitly listed. If a Laramie trim "should" have heated seats but the listing doesn't say, mark as `false` with a note.
- **Note all caveats** — as-is sales, + tax pricing, accident history, etc.
- **Private sales can be gold** — no GST, often below dealer prices, more negotiable
- **Franchise dealers add confidence** — note when a vehicle is at a franchise vs independent lot
- **Diesel holds value differently** — EcoDiesel Ram 1500s and Powerstroke F-series command premiums
- **2WD in prairie provinces is a hard sell** — flag 2WD vehicles as limited appeal

## Example Usage

```
/vehicle-finder Saskatoon trucks --max-price 25000 --features "heated seats" --max-km 200000
/vehicle-finder Regina suv --max-price 30000 --features "AWD,third row" --min-year 2018
/vehicle-finder Calgary any --max-price 15000 --max-km 150000 --output both
/vehicle-finder "Prince Albert" truck --max-price 35000 --makes "Toyota,Ford" --features "4WD"
```
