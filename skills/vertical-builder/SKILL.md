---
name: vertical-builder
description: Build out martial arts and fitness vertical pages with buyer-relevant content, scenarios, proof, and industry-specific language
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, mcp__anny__ga4_top_pages, mcp__anny__search_console_top_pages
argument-hint: "[martial-arts | fitness | about | audit]"
---

# /vertical-builder — Martial Arts & Fitness Page Enhancement

Builds out vertical-specific pages with buyer-relevant content — scenarios they recognize, proof from owners like them, and language that says "we know your world."

> "When a school owner lands from a friend's recommendation, they should find themselves in under 5 seconds." — Jill

## Trigger

User invokes `/vertical-builder` with an optional argument.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Audit all vertical pages and show what needs work |
| `audit` | Full audit of current vertical page content and gaps |
| `martial-arts` | Build out martial arts vertical pages |
| `fitness` | Build out fitness vertical pages |
| `about` | Refresh the About Us page with founding story |

---

## Coordination

**Execution order:** This skill edits vertical .astro pages (martial-arts, fitness, about-us) — NOT blog posts. It is safe to run at any time.

**Safe to run in parallel with:** ALL other skills. This skill only edits pages in `src/pages/membership-billing-services/`, `src/pages/martial-arts.astro`, `src/pages/fitness-centers.astro`, and `src/pages/about-us.astro`.

---

## MCP Fallback

If Anny MCP tools (GA4, Search Console) are unavailable:
1. Check for `docs/data/latest-traffic-snapshot.json` — use if <7 days old
2. If no snapshot, use the traffic data in `docs/key_findings/20260312-website-structure-vs-traffic-audit-marketing-team.md`
3. If neither available, proceed with the buildout anyway — traffic data informs priority but isn't required for page content creation

---

## Phase 0 — Load Context

1. **Read brand docs:**
   - `docs/brand/POSITIONING.md` — three pillars, competitive alternative
   - `docs/brand/VOICE.md` — tone and language
   - `docs/brand/BUYER.md` — buyer persona, pain points, journey
   - `docs/brand/PROOF.md` — available testimonials, stats, proof inventory
2. **Read current vertical pages:**
   - `src/pages/martial-arts.astro` — MA hero page
   - `src/pages/membership-billing-services/martial-arts.astro` — MA service page
   - `src/pages/fitness-centers.astro` — Fitness hero page
   - `src/pages/membership-billing-services/fitness.astro` — Fitness service page
   - `src/pages/about-us.astro` — About page
3. **Read the main services hub** for structure reference:
   - `src/pages/membership-billing-services/index.astro`
4. **Read the homepage** for narrative arc reference:
   - `src/pages/index.astro`
5. **Pull traffic data** for these pages:
   - `mcp__anny__ga4_top_pages` (last_28_days)
   - `mcp__anny__search_console_top_pages` (last_28_days)
6. **Read the reviews page** for vertical-specific testimonials:
   - `src/pages/reviews.astro` or `data/reviews.*`

---

## Phase 1 — Audit

For each vertical page, assess:

```
| Page | Current State | Traffic (GA4) | Organic (SC) | Gaps |
|------|---------------|---------------|-------------|------|
| /martial-arts/ | [Brief description] | X sessions | Y clicks | [List] |
| /membership-billing-services/martial-arts/ | ... | ... | ... | ... |
| /fitness-centers/ | ... | ... | ... | ... |
| /membership-billing-services/fitness/ | ... | ... | ... | ... |
| /about-us/ | ... | ... | ... | ... |
```

### What to assess per page:

1. **Content depth:** Is this a full page or a thin placeholder?
2. **Buyer recognition:** Does a MA school owner / fitness studio operator immediately see themselves?
3. **Industry-specific scenarios:** Are there billing scenarios specific to this vertical?
4. **Proof:** Are there testimonials or stats from this vertical?
5. **CTA:** Does it link to /free-billing-assessment/?
6. **Internal links:** Does it connect to relevant service pages and blog posts?
7. **SEO:** Is the title/meta optimized for vertical-specific queries?

### Page architecture note:

Each vertical has two pages (e.g., `/martial-arts/` and `/membership-billing-services/martial-arts/`). This skill does NOT make page consolidation decisions — that's a strategic decision for `/marketing-team`.

**If consolidation is needed:** Run `/marketing-team` first to decide which URL should be canonical, then come back to this skill to build the surviving page.

**Default behavior:** Build out BOTH pages with distinct roles:
- Hero page (`/martial-arts/`) — short, emotional, referral-focused landing page
- Service page (`/membership-billing-services/martial-arts/`) — detailed service content, scenarios, proof

**GATE:** Present the audit findings. Get user approval before building.

---

## Phase 2 — Build Martial Arts Pages (if `martial-arts`)

### Content Structure for MA Vertical Page

The page should feel like it was written BY a martial arts billing specialist FOR martial arts school owners. Not generic fitness content with "martial arts" substituted in.

#### Section 1: Hero
- Headline: Address the MA school owner directly
- Subhead: The core promise (billing handled, you teach)
- Proof stat: "X,000+ martial arts schools trust us" (pull from PROOF.md)
- CTA: Get a Free Billing Assessment

#### Section 2: "We Know Your World"
Demonstrate deep MA industry understanding:
- **Types of schools we serve:** Taekwondo, BJJ, MMA, Karate, Kung Fu, Kickboxing, Judo, Krav Maga, Hapkido
- **Billing scenarios we handle every day:**
  - Summer camp / vacation holds (students leave for 2 months — pause, don't cancel)
  - Family plans (3 kids, different belt levels, one credit card)
  - Belt test fees (one-time charges on top of recurring billing)
  - Seasonal enrollment spikes (September back-to-school, January resolution)
  - Student upgrades (kids class → adult class, different pricing)

#### Section 3: "What Happens When a Payment Fails"
The revenue recovery story — MA-specific:
- A student's card expires → our team contacts the bank, not you
- A parent disputes a charge → we handle the chargeback, not you
- A family goes on vacation → we set up the hold and reactivation, not you

#### Section 4: Proof
- MA-specific testimonials (filter from reviews)
- Stats: recovery rates, schools served, years in martial arts billing
- If no MA-specific testimonials available: use general testimonials with MA-relevant framing

#### Section 5: "How It Works"
Simple 3-step process:
1. We audit your current billing (free assessment)
2. We migrate your members (seamless, no disruption)
3. We handle billing, you teach classes

#### Section 6: CTA
- "See What Your Billing Is Costing You"
- Link to /free-billing-assessment/
- Secondary: "Or call us — we'll walk you through it in 15 minutes"

### Implementation

- Edit the existing page file(s) — don't create new pages
- Follow existing component patterns from the homepage and services hub
- Use existing Astro components where possible
- If new sections need components, create them in `src/components/` following existing patterns

---

## Phase 3 — Build Fitness Pages (if `fitness`)

Same structure as martial arts, adapted for fitness:

#### Fitness-specific scenarios:
- Class package billing (10-class packs, unlimited monthly, drop-in)
- Personal training add-ons (recurring PT sessions billed separately)
- Seasonal membership freezes (snowbirds, students home for summer)
- Corporate wellness programs (company-paid memberships, different billing)
- Family and couples memberships
- Cancellation requests during contract periods

#### Fitness-specific proof:
- Filter reviews/testimonials for fitness studio references
- Stats relevant to fitness: average delinquency rate, recovery rates

#### Fitness-specific language:
- "Members" not "students"
- "Studio" or "gym" not "school" or "dojo"
- "Classes" and "sessions" not "training" and "belts"
- Different pain points: class no-shows, personal training billing complexity, seasonal churn

---

## Phase 4 — About Us Refresh (if `about`)

The About page should tell the 35-year story. Not a corporate "our mission" page.

### Content Structure:

#### Section 1: The Story
- Founded in 1991 — the story of how/why
- What the fitness/martial arts billing world looked like 35 years ago
- How the company evolved through every economic cycle
- "We've seen every billing scenario, every type of school, every payment failure"

#### Section 2: What We Do
- Not features — the philosophy
- "We believe billing should be handled by people who are good at it, not by the school owner between classes"
- The team model vs. the software model

#### Section 3: The Numbers
- 35 years
- 11,000+ schools
- [Any other stats from PROOF.md]

#### Section 4: Why No Photos
Address the elephant: "You may notice we don't plaster our team's faces on the site. Our team works behind the scenes in revenue recovery and collections — roles where discretion matters. What you will see: the results of their work."

#### Section 5: CTA
Link to /free-billing-assessment/

### Important notes:
- Do NOT fabricate founding story details — use what's available in brand docs
- If the founding story isn't documented, write the section in a way that references the 35-year history without inventing specifics. Flag this as a gap to fill with real information.
- Tone: warm, experienced, humble — not boastful. "We've been doing this a long time. We're good at it."

---

## Phase 5 — Build Validation

After all changes, run:
```bash
npm run build 2>&1 | head -50
```
If the build fails, read the error and fix before reporting. Do NOT skip this step.

---

## Phase 6 — Report

Save findings and changes to `docs/key_findings/YYYYMMDD-HHmm-vertical-pages-buildout-vertical-builder.md` (use current date and 24h time):

```markdown
# Vertical Pages Buildout

## Pages Updated
| Page | Before | After | Key Changes |
|------|--------|-------|-------------|

## Consolidation Decisions
[Which pages were consolidated and why]

## Content Added
[Summary of new sections per page]

## Proof Gaps
[Testimonials or data points that are needed but not available]

## Measurement Plan
- Track vertical page traffic via GA4
- Monitor organic impressions for vertical-specific queries
- Check referral path: blog → vertical page → /free-billing-assessment/
```

---

## The /lp/ Landing Page Pattern

- Each vertical page may need an `/lp/` variant (e.g., `/lp/martial-arts/`) for paid campaigns targeting that vertical. LP pages use `LandingLayout.astro` (no nav, no footer, `noindex`).
- On-page CTAs on vertical pages should link to `/free-billing-assessment/` (the nav version), never to `/lp/`.
- When building a vertical page, flag whether an `/lp/` variant is warranted for paid traffic (e.g., Google Ads campaigns targeting "martial arts billing").
- First LP created: `/lp/free-billing-assessment/`. Future LP candidates include vertical-specific landing pages and lead magnets.

---

## Quality Standards

- **Industry authenticity.** Every scenario should be one the buyer has actually experienced. If you're unsure about a MA or fitness billing scenario, flag it rather than inventing.
- **Proof over promises.** Testimonials and stats > marketing claims. If proof isn't available, note the gap.
- **Buyer language.** Use the words the buyer uses. "Students" for MA, "members" for fitness. "School" or "dojo" for MA, "studio" or "gym" for fitness.
- **Don't duplicate the homepage.** Vertical pages go deeper into the specific buyer's world. The homepage tells the broad story. Vertical pages say "yes, specifically for YOUR type of business."
- **CTA consistency.** Every page ends with "Get a Free Billing Assessment" → /free-billing-assessment/
- **Component reuse.** Use existing Astro components. Don't build new components unless the existing ones can't handle the content structure.
