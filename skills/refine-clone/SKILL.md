---
name: refine-clone
description: Full-cycle refinement of a cloned Astro site — marketing review, design audit, page-by-page rebuild, and quality validation. Built for migration at scale.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch
argument-hint: "<site-name> [page-slug | 'all' | 'audit']"
---

# /refine-clone — Cloned Site Refinement Pipeline

Takes a WebEngine-cloned Astro site through structured refinement: audit what the clone got wrong, review each page's marketing effectiveness, polish design, fix issues, and validate. Built to be run repeatedly — each iteration improves the skill and agents for mass migration.

> Purpose: Answer the question "What does it actually cost to take a cloned site from 97% pixel-fidelity to production-ready?" — and then reduce that cost to near-zero through iteration.

## Trigger

User invokes `/refine-clone <site-name> [mode]`

## Arguments

| Argument | Description |
|----------|-------------|
| `<site-name>` | WebEngine site directory name (e.g., `test97-site`). Must exist in `sites/<name>/`. |
| `audit` | Run Phase 1 only — produce a full site audit without making changes. |
| `<page-slug>` | Refine a single page (e.g., `index`, `contact`, `classes`). |
| `all` | Refine all pages sequentially. |
| `compare` | Side-by-side comparison of source vs. clone for visual fidelity audit. |

Examples:
- `/refine-clone test97-site audit` — Full audit, no changes
- `/refine-clone test97-site index` — Refine homepage only
- `/refine-clone test97-site all` — Refine every page
- `/refine-clone test97-site compare` — Visual fidelity comparison

---

## The Process (Overview)

```
Phase 1 — Site Audit (automated)
        ↓
Phase 2 — Marketing Review (per page)
        ↓ (user approves)
Phase 3 — Design & Fidelity Fixes (per page)
        ↓ (user approves)
Phase 4 — Technical Validation
        ↓ (build passes)
Phase 5 — Report & Cost Tracking
```

---

## Phase 0 — Load Context

### 1. Read the site structure
```
sites/<site-name>/site.yaml          — domain, wp_url (source site)
sites/<site-name>/src/pages/          — all .astro page files
sites/<site-name>/public/             — assets (images, fonts, CSS)
sites/<site-name>/.csp/               — original scraped data (source of truth)
sites/<site-name>/build_report.json   — clone quality report (if exists)
```

### 2. Identify the source site
Read `wp_url` from `site.yaml` — this is the original site the clone was made from. The source is the reference point for fidelity comparison.

### 3. Inventory all pages
List all `.astro` files in `src/pages/`. For each page, note:
- File path and slug
- Approximate content (read first 20 lines)
- Whether it has a corresponding source page (check `.csp/` artifacts)

### 4. Check clone quality report
If `build_report.json` exists, read it for:
- Quality tier (full/partial)
- Completeness score
- Warnings (theme issues, content gaps, broken elements)
- Files generated count

### 5. Produce a Site Brief
```
Site: [name] ([domain])
Source: [wp_url]
Pages: [count] pages cloned
Clone quality: [tier] ([completeness]%)
Known issues from clone: [list warnings]
```

---

## Phase 1 — Site Audit

For each page, assess:

### A. Content Fidelity (vs. source)
- Does the page have all the text content from the source?
- Are images present and loading?
- Are navigation links correct?
- Are forms present with correct fields?
- Is the page structure (sections, headings) preserved?

### B. Visual Quality
- Does the CSS load and apply correctly?
- Are fonts loading (check `/public/fonts/`)?
- Is the layout responsive (check for viewport meta, flexible widths)?
- Are there obvious layout breaks (overlapping elements, missing backgrounds)?

### C. Functional Elements
- Forms: Do they have `action` attributes? Do they submit somewhere valid?
- Phone numbers: Are they `tel:` links?
- Maps: Are embedded maps present?
- Social links: Present and pointing to correct URLs?
- Navigation: All internal links work?

### D. SEO Baseline
- Does each page have a `<title>` tag?
- Does each page have a `<meta name="description">`?
- Is there a canonical URL?
- Is the favicon present?
- Is `robots.txt` present?

### E. Performance Indicators
- Total page weight (HTML + CSS + images)
- Number of images per page
- CSS file size
- Any render-blocking resources?

### Audit Output
Produce a markdown table per page:

```
| Page | Content | Visual | Functional | SEO | Issues |
|------|---------|--------|-----------|-----|--------|
| index | 95% | 90% | 80% | 70% | Missing form action, no meta desc |
| contact | 100% | 85% | 90% | 60% | Map not loading, no canonical |
```

Plus a prioritized issue list:
```
1. [CRITICAL] Form on /contact has no action — leads are lost
2. [HIGH] No meta descriptions on any page — SEO impact
3. [MEDIUM] Hero background image not loading on /classes
4. [LOW] Social media icons using outdated URLs
```

**If mode is `audit`, stop here and present findings. Otherwise continue.**

---

## Phase 2 — Marketing Review (per page)

For each page (or the specified page), convene a focused marketing review.

### The Review Team (adapted for fitness/martial arts studio sites)

**Reviewers assess independently:**

1. **Conversion Analyst** — Is this page doing its job? What's the call-to-action? Is it clear, compelling, and findable? Is there a phone number prominently displayed (studio owners' customers call, they don't fill forms)?

2. **Local Business Expert** — Does this page serve a local business well? Is the address visible? Are class schedules easy to find? Does it answer the question "should I bring my kid here?"

3. **Content Reviewer** — Is the copy clear, authentic, and free of jargon? Does it speak to parents/adults looking for martial arts or fitness? Are testimonials present and credible?

4. **Mobile Reviewer** — Does this page work on a phone? (Most martial arts inquiries come from mobile.) Is the phone number tappable? Is the form thumb-friendly?

### Review Output (per page)
```
### [Page Name] — Marketing Review

**Page Job:** [what this page should accomplish]
**Current CTA:** [what exists]
**Phone Number:** [visible/hidden/missing]

**Working:**
- [what the page does well]

**Broken:**
- [what needs fixing — specific, actionable]

**Recommended Changes:**
1. [Change] — [Why] — [Effort: S/M/L]
2. ...

**Priority:** [Critical / High / Medium / Low]
```

**GATE 1:** Present review findings to user. Wait for approval before implementing.

---

## Phase 3 — Design & Fidelity Fixes (per page)

Apply approved fixes. Work in this order:

### Implementation Order
1. **Critical fixes** — Broken forms, missing phone numbers, dead links
2. **Content fixes** — Missing text, wrong headings, broken images
3. **SEO fixes** — Title tags, meta descriptions, canonical URLs, structured data
4. **Layout/visual fixes** — CSS issues, responsive problems, spacing
5. **Enhancement** — Better CTA placement, testimonial positioning, trust signals

### Rules
- **Preserve the source site's design language.** This is a clone, not a redesign. The goal is fidelity + fixes, not a new look.
- **Fix the clone's mistakes, don't redesign.** If the source site has a red hero, the clone should have a red hero. Don't impose a different design system.
- **Every form must have a working action.** If the original form posted to the CMS, the clone form needs a new endpoint (or a mailto: fallback, or a redirect to a contact page).
- **Phone numbers must be `tel:` links.** Martial arts studios live and die by phone calls.
- **Addresses must be visible.** Local business = local presence.
- **Images that fail to load get a fallback.** Better to show a solid color background than a broken image icon.

### Build Check
After each page's fixes:
```bash
cd sites/<site-name> && npm run build 2>&1 | tail -5
```
Must pass before moving to next page.

**GATE 2:** Show user what changed. Approve before proceeding.

---

## Phase 4 — Technical Validation

After all pages are refined:

### Automated Checks
```bash
# Build passes
cd sites/<site-name> && npm run build

# All pages generate HTML
ls dist/ | wc -l

# No broken internal links (check all href values in generated HTML)
# No missing images (check all src values)
# robots.txt exists
# 404 page exists
```

### Manual Spot-Check (user)
- View homepage in browser
- Check one interior page on mobile
- Test the contact form
- Verify phone number is tappable

---

## Phase 5 — Report & Cost Tracking

This phase is critical for answering the migration cost question.

### Per-Site Refinement Report
Save to `sites/<site-name>/refinement_report.md`:

```markdown
# Refinement Report — [site-name]

**Source:** [wp_url]
**Domain:** [domain]
**Date:** [timestamp]
**Pages refined:** [count]

## Time Tracking
| Phase | Duration | Notes |
|-------|----------|-------|
| Audit | Xm | Automated |
| Marketing review | Xm | Per-page review |
| Implementation | Xm | Fixes applied |
| Validation | Xm | Build + checks |
| **Total** | **Xm** | |

## Issues Found & Fixed
| # | Page | Issue | Severity | Fix | Time |
|---|------|-------|----------|-----|------|
| 1 | index | Missing form action | Critical | Added mailto: fallback | 2m |
| 2 | all | No meta descriptions | High | Generated from page content | 5m |
| ... |

## Issues Deferred
| # | Page | Issue | Why Deferred |
|---|------|-------|-------------|
| 1 | contact | Google Map embed | Needs API key from client |

## Cost Summary
| Item | Cost |
|------|------|
| AI API (if any) | $X.XX |
| Labor (estimated at Xm × $30/hr) | $X.XX |
| **Total refinement cost** | **$X.XX** |

## Lessons Learned (for pipeline improvement)
- [Pattern that should be automated next time]
- [Common issue that clone converter should handle]
- [Process improvement for the next site]
```

### Append to Migration Worklog
If running in the context of 97 Display migration planning, append key findings to the worklog at `../97plan/docs/worklog/20260313-migration-qa.md` — specifically updating M2 (clean-up process) and M7 (touch-up work details).

---

## Iteration Mode

The power of this skill is iteration. After refining N sites:

1. **Common issues become automated** — If every site needs meta descriptions generated, add that to the clone converter
2. **Review templates get faster** — The marketing review learns what matters for martial arts/fitness studio sites
3. **Fix patterns get reusable** — CSS fixes, form patterns, and SEO templates become copy-paste

### After 5 sites: Review and update this skill
### After 10 sites: The audit should be 90% automated
### After 25 sites: The full refinement should take <30 minutes/site
### After 50 sites: Target is <15 minutes/site (mass migration ready)

---

## Quality Standards

### What makes a good refinement
1. **Source fidelity first** — The clone should look like the source site, not like a different site
2. **Fix, don't redesign** — Address defects, don't impose opinions
3. **Phone numbers always visible** — #1 conversion path for studio businesses
4. **Forms must work** — A form that submits to nowhere is worse than no form
5. **Every change tracked** — Time, cost, and lessons feed back into the pipeline
6. **Build passes** — Non-negotiable

### What makes a bad refinement
- Redesigning the site instead of fixing the clone
- Skipping the audit and going straight to "improvements"
- Not tracking time and issues (we need the data for M2/M7)
- Breaking the build
- Adding features the source site didn't have (scope creep)
