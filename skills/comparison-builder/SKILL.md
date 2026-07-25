# /comparison-builder — Build the Best Comparison Page in the Universe (repeatable)

Rewrites-safe, positioning-compliant, schema-heavy comparison pages that convert. Optimized for **LLMs** (ChatGPT/Perplexity/Claude/Gemini), **humans** (Sabri/Ogilvy conversion mechanics), and **Google/Bing** (E-E-A-T + 5-schema stack).

## Trigger

`/comparison-builder <mode> <competitor-slug>` where mode is one of `plan|draft|review|ship|check` and slug is a row in `data/competitors.json`.

Examples:
- `/comparison-builder plan mindbody`
- `/comparison-builder draft mindbody`
- `/comparison-builder review mindbody`
- `/comparison-builder ship mindbody`
- `/comparison-builder check mindbody` (28 days post-launch)

## Preflight — always

Before ANY mode runs:

1. Confirm the competitor slug exists in `data/competitors.json`. If not, halt and ask the user to add the row.
2. Confirm no other comparison page for that competitor already exists in `src/content/blog/member-solutions-vs-<slug>*.mdx`. If it does, halt — this is a `review` or `check` situation, not a fresh build.
3. Read `docs/brand/POSITIONING.md`, `docs/brand/VOICE.md`, `docs/brand/PROOF.md`, `data/reviews.json`. These are the source of truth for tone, phrasing, and testimonial pool.

## Mode: `plan`

Purpose: pre-flight risk check. Prevents cannibalization of existing pages and confirms Ahrefs viability. Writes a plan doc; **does not touch content files**.

### Steps

1. Load competitor row from `data/competitors.json`. Extract `primary_query`, `vertical_focus`, `positioning`, pricing, strengths, weaknesses.
2. **Cannibalization scan.** Use `mcp__anny-cloud__search_console_query` with `dimensions=query,page` and `date_range=last_28_days`. Filter for pages that already rank on the target primary query AND its close variants. Print a table: `query | ranking page | position | clicks`. If the primary query is already earning >10 clicks/28d on a different URL, RED FLAG — the new page will cannibalize. Otherwise GREEN.
3. **Ahrefs difficulty check.** If Ahrefs MCP is available, pull KD + volume for the primary query. KD ≤ 15 with volume ≥ 50 = GREEN. KD > 30 = RED (multi-quarter effort with no expected payoff). Otherwise YELLOW.
4. **Testimonial pool check.** Filter `data/reviews.json` for entries whose `vertical` field intersects the competitor's `vertical_focus`. If fewer than 3 relevant testimonials exist, YELLOW — the page can still ship using generic reviews, but note it.
5. **Positioning-rule dry run.** Skim the drafted title, description, and section 5 opening lines against `docs/brand/POSITIONING.md`. Any language that leads with "billing team, not software" or "we're not just an app" is a fail. Rewrite before proceeding.
6. **Freshness of competitor row.** Check `data/competitors.json[competitor].last_verified`. If >90 days old, YELLOW — refresh the competitor row first via a quick WebFetch of their homepage and pricing.

### Output

Write to `docs/sprints/comparison-2026Q3/<slug>-plan.md`:

```markdown
# Comparison Plan — Member Solutions vs <Competitor Name>

**Slug:** vs-<slug>
**Plan created:** YYYY-MM-DD
**Target primary query:** <query>

## Green/yellow/red flags

- [ ] GREEN: cannibalization scan — no existing page ranks for target query
- [ ] GREEN: Ahrefs KD ≤ 15, volume ≥ 50
- [ ] GREEN: testimonial pool ≥ 3 relevant reviews
- [ ] GREEN: positioning-rule dry run clean
- [ ] GREEN: competitor data last verified within 90 days

## Cannibalization scan
<paste table>

## Recommended testimonials
<3-5 reviews from data/reviews.json>

## Positioning statement for this page
"Member Solutions is membership management software with a real billing team behind it. Unlike <Competitor>, whose <thing>, our software comes with humans who <thing>."

## Ready to draft
<yes | no | address flags first>
```

Halt after writing the plan doc. Await user confirmation to proceed to `draft`.

## Mode: `draft`

Purpose: generate the `.mdx` file end-to-end from the template using parallel sub-agents. Ships as `draft: true` — does NOT deploy.

### Preflight for draft

- Read `docs/sprints/comparison-2026Q3/<slug>-plan.md`. Halt if it doesn't exist or has unresolved RED flags.

### Sub-agent fan-out

Launch these three sub-agents **in parallel** (single message, three Agent tool calls). Every sub-agent MUST return JSON conforming exactly to the schema below — no prose wrapper, no markdown fencing, just the raw JSON object. Parse with `JSON.parse`; if any parse fails, halt and re-run that single sub-agent (do NOT synthesize partial results). Contract enforcement is the whole point of the parallelism.

**Agent 1 — Competitor product research.** subagent_type=`general-purpose`. Prompt:

```
Research <competitor name>. Fetch <homepage URL>, their pricing page, product tour, and top 3 Capterra/G2 reviews (if publicly accessible). Use only publicly available info. Do not editorialize.

Return EXACTLY this JSON shape — no prose, no markdown fencing, just the object. All fields REQUIRED. Categories keys MUST match this fixed set exactly.

{
  "overview_paragraph_1": "string, 140-160 words, one paragraph, no markdown. Company + positioning + history.",
  "overview_paragraph_2": "string, 140-160 words, one paragraph, no markdown. Their software/platform depth.",
  "known_for_line": "string, one sentence under 30 words. What third parties consistently praise.",
  "strengths_by_category": {
    "Membership Management & Billing": "string, 30-60 words, honest, third-party sourced",
    "Failed Payment Recovery": "string, 30-60 words",
    "Scheduling & Member Experience": "string, 30-60 words",
    "Reporting & Dashboards": "string, 30-60 words",
    "Onboarding & Migration": "string, 30-60 words",
    "Support Model": "string, 30-60 words",
    "Contract Terms & Cancellation": "string, 30-60 words"
  },
  "limitations_by_category": {
    "Membership Management & Billing": "string, 30-60 words, honest gap or trade-off",
    "Failed Payment Recovery": "string, 30-60 words",
    "Scheduling & Member Experience": "string, 30-60 words",
    "Reporting & Dashboards": "string, 30-60 words",
    "Onboarding & Migration": "string, 30-60 words",
    "Support Model": "string, 30-60 words",
    "Contract Terms & Cancellation": "string, 30-60 words"
  },
  "sources": ["array of URLs actually fetched"]
}
```

**Agent 2 — Positioning + SERP snippet forensics.** subagent_type=`general-purpose`. Prompt:

```
Fetch the current top 5 SERP results for '<primary_query>' AND for '<competitor> alternatives'. Also fetch the competitor's own 'why choose us' / 'compare' / 'vs' page if it exists (search their site for /compare/ or /vs/ or /alternatives/ paths).

Return EXACTLY this JSON shape — no prose, no markdown fencing.

{
  "serp_snapshot": [
    {
      "query": "string — the search query used",
      "rank": "number 1-10",
      "url": "string",
      "title": "string — <title> tag as rendered",
      "meta_description": "string — up to 160 chars",
      "published_date": "string YYYY-MM-DD or null if not detectable",
      "unique_angle": "string, one sentence — what makes this result different"
    }
  ],
  "competitor_self_positioning": "string, 90-110 words. How the competitor pitches themselves on THEIR site (not third-party). Direct paraphrase of their homepage hero + value prop.",
  "differentiators_worth_naming": [
    "string, one sentence — a specific gap or angle competitors in the SERP are NOT covering that our page could",
    "…3 to 5 items total"
  ],
  "sources": ["array of URLs actually fetched"]
}
```

**Agent 3 — Testimonial curator.** subagent_type=`general-purpose`. Prompt:

```
Read /Users/msichris/repos/msi-web/data/reviews.json. Filter for reviews whose `vertical` field matches ANY vertical in the competitor's vertical_focus (from data/competitors.json[<slug>].vertical_focus). If fewer than 3 vertical matches exist, expand to all 5-star reviews.

Prefer reviews that address time-savings, revenue recovery, or delegation themes (matches the MSI positioning wedge).

Return EXACTLY this JSON shape — no prose, no markdown fencing. All three testimonial objects REQUIRED. Do NOT invent quotes. Every field must come verbatim from data/reviews.json.

{
  "testimonials": [
    {
      "id": "string — the id field from reviews.json (e.g. rev-005)",
      "author": "string — verbatim from reviews.json",
      "business": "string — verbatim",
      "quote": "string — verbatim quote text, no rewording",
      "rating": "number 1-5",
      "date": "string YYYY-MM-DD",
      "vertical": "string",
      "why_this_one": "string, one sentence — why this testimonial matches this specific competitor comparison"
    },
    { "…same shape, second testimonial" },
    { "…same shape, third testimonial" }
  ]
}
```

### After sub-agents complete

7. Read `src/content/blog/_templates/vs-competitor-template.mdx.txt`.
8. Replace every `__PLACEHOLDER__` using sub-agent outputs + competitor row from `data/competitors.json` + positioning rules from `docs/brand/POSITIONING.md`. Fill:
   - Frontmatter: title, description (≤160 chars), pubDate=today, updatedDate=today, image path, competitor bestFor lines
   - The "our bias" section (voice-compliant, per VOICE.md)
   - The "who this comparison is for" bullets (adapt to competitor's vertical)
   - The VerdictCard props (from Agent 1 + Agent 2 synthesis)
   - The 7 head-to-head comparison table sections (use Agent 1's strengths_by_category / limitations_by_category maps)
   - Pricing table (from `data/competitors.json[slug].pricing`)
   - "The real difference" paragraph (must reflect the single decisive philosophical difference — see POSITIONING.md pillar 1)
   - Testimonial cards (from Agent 3)
   - BestForCards MSI + competitor arrays
   - "Who this isn't for" paragraphs (both sides, honest)
   - FAQ block (8 questions — use the FAQ template list, populate with competitor-specific answers)
9. Write to `src/content/blog/member-solutions-vs-<slug>.mdx`. Ensure `draft: true` in frontmatter.
10. Run `npm run build` — must pass. Fix build failures before proceeding.
11. Run positioning-rule verifier explicitly: `node scripts/verify-positioning-rule.mjs`.
12. Report file path + word count + built pages back to user. Halt.

## Mode: `review`

Purpose: dispatch design + marketing panel review, then flip `draft: false`.

1. Read the drafted `.mdx`.
2. Invoke `/marketing-team` panel with prompt: "Review member-solutions-vs-<slug>.mdx against POSITIONING.md, VOICE.md, and Sabri/Ogilvy conversion mechanics baked into the template. Return: (a) positioning-rule compliance yes/no, (b) voice compliance yes/no, (c) any section where the copy feels weak or off-brand with specific line-level rewrites, (d) any missing conversion element."
3. Invoke `/design-panel` on the built page URL (`http://localhost:4321/blog/member-solutions-vs-<slug>/` after `npm run dev`). Ask: visual hierarchy, scanability, mobile UX on the VerdictCard/ComparisonTable/FAQBlock components.
4. Apply the specific rewrites suggested by the panels — but ONLY the ones that don't require re-running the sub-agents. Bigger structural changes require re-running `draft`.
5. Flip `draft: false`. Set `updatedDate` to today.
6. Run `npm run build` again. Report completion.

## Mode: `ship`

Purpose: commit + push + open PR. Does NOT deploy.

1. Run `npm run build` one final time.
2. `git add src/content/blog/member-solutions-vs-<slug>.mdx docs/sprints/comparison-2026Q3/<slug>-plan.md`.
3. Commit with the template message (competitor name, target query, plan doc reference).
4. Push branch to origin.
5. Open a PR via `gh pr create` with title `feat(seo): comparison page — Member Solutions vs <Competitor>` and body summarizing the plan doc findings.
6. Report PR URL. Halt. User decides when to merge + deploy.

## Mode: `check`

Purpose: 28-day post-launch checkpoint. Verifies (a) new page is performing, (b) no cannibalization of existing pages.

1. Compute today - launch date. If < 21 days, warn: too early for reliable SC data, ask user to confirm.
2. Pull SC data for the new URL — 28 days ending today. Compare to the plan's Ahrefs KD/volume expectations.
3. Pull SC data for BOTH decay-recovery pages (`/blog/best-personal-training-software-for-trainers/` and `/blog/best-membership-management-software/`). Compare current 28d clicks/CTR/position to the day-of-launch baseline stored in the plan doc.
4. If either decay-recovery page has lost >20% clicks in the same window the new comparison page shipped in, RED FLAG cannibalization suspected.
5. Write findings to `docs/sprints/comparison-2026Q3/<slug>-check-<YYYYMMDD>.md`.

## Cadence rules — DO NOT VIOLATE

1. **One comparison page per 3-week cycle.** Week 1 plan+draft, week 2 review+ship, week 3 quiet index-window, then next competitor starts. Rush = snippet churn = decay.
2. **Never re-edit an existing comparison page's title or meta description within 28 days of that page's launch or last edit.** Snippet churn is worst when the same page's snippet keeps changing. If a page is underperforming, wait for the 28-day window to close before rewriting.
3. **Never write two comparison pages targeting overlapping primary queries in-flight simultaneously.** The `plan` step's cannibalization scan enforces this — if it flags RED, halt.
4. **Testimonials must come from `data/reviews.json`.** Do not invent quotes. Do not paraphrase real ones. The `TestimonialCard.astro` component emits `Review` schema and Google will penalize fabricated reviews.
5. **`data/competitors.json` is the single source of truth for competitor facts.** If the page needs a fact not in the row, add it to the row first, then reference it. `last_verified` gets bumped whenever you refresh the row.

## Build gates that MUST pass

- `scripts/verify-positioning-rule.mjs` — no "not just an app" phrasing, software leads
- `scripts/verify-roundup-schema.mjs` — roundup frontmatter valid
- `scripts/verify-schema.mjs` — Article schema valid
- `scripts/verify-schema-coverage.mjs` — Article + Roundup schemas present on all posts
- `scripts/verify-comparison-schema-coverage.mjs` (NEW, if present) — FAQ + Review + BestFor schemas present on comparison pages

If any fail, the ship mode halts. Fix at the source, not by silencing the gate.

## Related files

- Template: `src/content/blog/_templates/vs-competitor-template.mdx.txt`
- Components: `src/components/comparison/*.astro`
- Data: `data/competitors.json`, `data/reviews.json`
- Brand docs: `docs/brand/POSITIONING.md`, `VOICE.md`, `PROOF.md`, `BUYER.md`
- Launch tracker: `docs/sprints/comparison-2026Q3/README.md`
- Freshness audit: `scripts/audit-comparison-freshness.mjs`
- GHA workflow: `.github/workflows/comparison-freshness.yml`
