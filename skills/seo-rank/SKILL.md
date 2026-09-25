---
name: seo-rank
description: Run a keyword ranking audit for a fleet site — searches all target keywords × locations and reports where the business appears in Google results
user-invocable: true
allowed-tools: Bash, Read, WebSearch
argument-hint: "<site-slug>"
---

# /seo-rank — Keyword Ranking Audit

Run a full keyword × location ranking audit for a fleet site. Reads site.json to extract business type, programs, and service areas, generates a keyword matrix, runs searches, and reports where the business ranks (position 1–10 or not ranking).

## Trigger

User invokes `/seo-rank <site-slug>` where `<site-slug>` matches a directory under `sites/`.

Example: `/seo-rank platinum-fitness`

---

## Phase 1 — Load Site Data

Read `sites/<slug>/site.json` and extract:

- `name` — business name
- `tagline` — brand tagline
- `locations[0].fullAddress` — primary address (for NAP verification)
- `locations[0].city`, `state`
- `locations[0].serviceAreas` — neighborhood targets
- `serviceAreas` — top-level service areas (fallback)
- `programs[].name` — what they offer
- `config.copy` — any overrides (ctaLabel, programsLabel, etc.)
- Site domain from `site.yaml` (grep `^domain:`)

If `sites/<slug>/site.json` does not exist, report an error and stop.

---

## Phase 2 — Build Keyword Matrix

From the site data, generate three tiers of keywords:

### Tier 1 — Primary (high intent)
- `gym in [city]` / `fitness center [city]` (or business-type equivalent)
- `gym membership [city]`
- `[business type] near [primary area]`

### Tier 2 — Program keywords
For each program in `programs[]`, generate:
- `[program name] [city]`
- `[program name] [primary area]`

Examples based on business type:
- Gym: `group fitness classes`, `personal trainer`, `tanning salon`, `gym with tanning`
- Martial arts: `kids martial arts`, `adult taekwondo`, `self defense classes`
- Fitness studio: `yoga classes`, `HIIT classes`, `pilates`

### Tier 3 — Differentiators
Pull from tagline and about copy to identify what makes them unique:
- `affordable gym [city]`
- `no contract gym [city]`
- `gym with [unique feature] [city]`

### Location modifier matrix
Run Tier 1 + Tier 2 across:
1. **City** (e.g., Pittsburgh PA)
2. **Primary area** (e.g., Greentree Pittsburgh)
3. **Each service area** — run `gym [service area]` minimum; add program keywords for the 2–3 closest ones

---

## Phase 3 — Run Searches

Run WebSearch for all keyword × location combinations. Batch independent searches in parallel (up to 4 at a time).

**For each result**, scan the returned links for:
1. The business's own domain (from `site.yaml` domain field)
2. The business's name appearing in a link title or Yelp/Google listing

Determine position (1 = first organic result, count down). Note:
- Own domain appearing = owned ranking
- Business name in a Yelp/aggregator listing = partial/unowned ranking
- Not in results = not ranking

Also note the top 2–3 competitors appearing above the business for each keyword.

---

## Phase 4 — Compile Report

Output the report in three sections:

### Section 1 — [City] (Broad)

Table with all keywords, position, and top competitor(s) for the city-level searches.

```
| Keyword | Position | Top Competitors |
|---------|----------|-----------------|
| gym in [city] | #X or ❌ | Competitor A, B |
| ...
```

### Section 2 — [Primary Area]

Same table format for the primary area (neighborhood level where the business is physically located).

### Section 3 — Target Neighborhoods

For each service area, one row:

```
| Area | Gym ranking | Notes |
|------|-------------|-------|
| [area] | #X / ❌ / Yelp mention | key competitor or gap |
```

### Section 4 — Key Takeaways

End with 3–5 bullet takeaways:
- **Strengths to protect** — where they already rank top 3
- **Biggest opportunity** — highest-value unranked keyword with realistic path to top 10
- **Notable threats** — competitors ranking above them on their own turf
- **Neighborhood coverage** — which service areas have no ranking at all vs. some signal

---

## Output Format

```
## SEO Ranking Audit — [Business Name]
**Site:** [slug] | **Domain:** [domain] | **Date:** [today]

### [City] — Broad Keywords
[table]

### [Primary Area] — Local Keywords  
[table]

### Target Neighborhoods
[table]

### Key Takeaways
- ...
```

---

## Notes

- Position is approximate — WebSearch results are organic web results, not a logged-in Google SERP with personalization. Treat as directional, not exact.
- Map/Local Pack results (the 3-pack) are separate from organic; this skill measures organic only.
- Re-run quarterly or after major site changes to track movement.
- If the business has no service areas in site.json, ask the user to provide target neighborhoods before running Phase 3.
