---
name: conversion-plumber
description: Audit CTA links site-wide, consolidate conversion paths to /free-billing-assessment/, and fix broken conversion plumbing
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, mcp__anny__ga4_top_pages, mcp__anny__ga4_report
argument-hint: "[audit | fix | report]"
---

# /conversion-plumber — CTA Audit & Conversion Path Fixer

Finds every CTA, form link, and conversion endpoint across the site. Consolidates them to a single path. Fixes the plumbing so conversions flow to one measurable funnel.

> "Three conversion endpoints splitting traffic means you can't measure your funnel. One CTA, one path, one form." — Peep

## Trigger

User invokes `/conversion-plumber` with an optional argument.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Full audit + recommendations |
| `audit` | Scan all pages for CTA links and report findings |
| `fix` | Apply recommended fixes (after audit approval) |
| `report` | Generate a conversion path status report |

---

## Coordination

**Execution order:** This skill MUST run FIRST among the blog-editing skills. It fixes CTA link targets — the foundation everything else depends on.

Run order for blog-editing skills:
1. **conversion-plumber** — FIRST (this skill — fixes CTA link targets)
2. **seo-meta-agent** — SECOND (fixes titles/metas)
3. **internal-link-builder** — THIRD (adds internal links + bridge sentences)

**Safe to run in parallel with:** moat-content-writer, vertical-builder (they touch different files).

**NOT safe to run in parallel with:** seo-meta-agent, internal-link-builder (all three edit the same blog posts).

---

## MCP Fallback

If Anny MCP tools (GA4) are unavailable:
1. Check for `docs/data/latest-traffic-snapshot.json` — use if <7 days old
2. If no snapshot, use the page traffic data in `docs/key_findings/20260312-website-structure-vs-traffic-audit-marketing-team.md`
3. If neither available, STOP and ask the user for guidance

---

## Phase 0 — Load Context

1. **Read config.yaml** — check `cta.primary.text`, `cta.primary.url`, and any secondary CTA settings
2. **Read brand docs:**
   - `docs/brand/PAGES.md` — page roles and conversion funnel
   - `docs/brand/POSITIONING.md` — positioning statement for CTA copy
3. **Pull GA4 data** — page views for conversion endpoints:
   - `/free-billing-assessment/`
   - `/get-in-touch/`
   - `/request-info/`
   - `/start-growing-now/`
   - `/thank-you/`

---

## Phase 1 — CTA Inventory

Scan the entire site for every link, button, or form that points to a conversion endpoint.

### What to scan:

1. **Components** — `src/components/**/*.astro`
   - Navigation.astro (header CTA button)
   - Footer.astro (footer CTA)
   - Any CTA component (CTABanner, CTABox, HeroCTA, etc.)
2. **Layouts** — `src/layouts/**/*.astro`
3. **Pages** — `src/pages/**/*.astro` (all 27 real pages)
4. **Blog posts** — `src/content/blog/**/*.md` (CTA sections in markdown)
5. **Config** — `config.yaml` (CTA URL settings)

### What to look for:

Search for these patterns:
- `free-billing-assessment`
- `get-in-touch`
- `request-info`
- `start-growing-now`
- `contact`
- `href.*form`
- `href.*#form`
- `mailto:`
- Any `<form>` elements
- HubSpot form embeds
- Calendly or scheduling tool embeds

### Output format:

```
| File | Line | Link Target | CTA Text | Type |
|------|------|-------------|----------|------|
| src/components/Navigation.astro | 42 | /free-billing-assessment | Get a Free Billing Assessment | Button |
```

Categorize each finding:
- **PRIMARY** — Points to /free-billing-assessment/ (correct)
- **LEAK** — Points to /get-in-touch/, /request-info/, or other endpoint (needs fix)
- **LEGACY** — Points to /start-growing-now/ (should be redirected)
- **EXTERNAL** — mailto:, phone, or third-party tool

**GATE:** Present the full CTA inventory and wait for user approval before making changes.

---

## Phase 2 — Diagnose

Answer these questions from the audit:

1. **Why does /free-billing-assessment/ get almost no traffic?**
   - Is the CTA text pointing elsewhere?
   - Is the URL misspelled or misconfigured?
   - Is the page broken?
   - Do CTAs actually render on mobile?

2. **What role should /get-in-touch/ play?**
   - If it's a general contact page (support, press, partnerships) → keep it, but it's not a conversion endpoint
   - If it's duplicating the CTA → redirect to /free-billing-assessment/

3. **What role should /request-info/ play?**
   - Same analysis as above
   - Check if any external sources (ads, email campaigns) link to this URL

4. **Are blog post CTAs consistent?**
   - Do all 114 posts have a CTA section?
   - What URL do they point to?
   - Is the CTA text consistent?

5. **Is the form on /free-billing-assessment/ working?**
   - Read the page
   - Check for form action, API endpoint, or embedded form
   - Verify it matches the contact.php API

---

## Phase 3 — Fix (if `fix` argument or user approves)

Apply changes in this order:

1. **Config first** — Ensure config.yaml CTA settings are correct
2. **Components** — Fix shared CTA components (biggest blast radius)
3. **Pages** — Fix individual page CTAs
4. **Blog posts** — Fix blog CTA sections (bulk operation)
5. **Redirects** — Ensure /start-growing-now/ redirects properly

### Rules for fixes:

- `/free-billing-assessment/` is the ONE conversion endpoint for prospects
- `/get-in-touch/` should be a contact page (support, general inquiries) — NOT the primary CTA destination
- `/request-info/` should redirect to `/free-billing-assessment/` unless it serves a distinct purpose
- Every blog post should have a CTA that links to `/free-billing-assessment/`
- CTA text should follow brand voice: "Get a Free Billing Assessment" (primary) or contextual variants like "See What Your Billing Is Costing You"
- Do NOT change the form itself — only the links/buttons that route to it

---

## Phase 4 — Verify & Build

### Post-fix verification
After all changes, grep the entire codebase to confirm zero remaining LEAK or LEGACY links:
```bash
grep -r "get-in-touch\|request-info\|start-growing-now" src/ --include="*.astro" --include="*.md" -l
```
Any remaining matches should be investigated — they're either intentional (contact page linking to itself) or missed fixes.

### Build validation
```bash
npm run build 2>&1 | head -50
```
If the build fails, read the error and fix before reporting. Do NOT skip this step.

---

## Phase 5 — Report

Save findings and changes to `docs/key_findings/YYYYMMDD-HHmm-conversion-path-audit-conversion-plumber.md` (use current date and 24h time):

```markdown
# Conversion Path Audit

## Before
- X CTAs pointing to /free-billing-assessment/
- Y CTAs pointing to /get-in-touch/ (leaks)
- Z CTAs pointing to /request-info/ (leaks)
- W CTAs pointing to /start-growing-now/ (legacy)

## After
- All CTAs consolidated to /free-billing-assessment/
- /get-in-touch/ retained as general contact (not conversion)
- /request-info/ [redirected | retained for specific purpose]

## Changes Made
[List of files changed]

## Measurement Plan
- Track /thank-you/ pageviews as conversion proxy
- Check GA4 in 2 weeks for conversion path clarity
```

---

## The /lp/ Landing Page Pattern

- `/lp/[page-name]` pages use `LandingLayout.astro` (no nav, no footer, logo-only header) — for paid traffic, email campaigns, ads. Always `noindex, nofollow`.
- The main page (e.g., `/free-billing-assessment/`) uses regular `Layout.astro` with full nav — for on-site visitors.
- **Internal CTAs must always point to `/free-billing-assessment/`, never to `/lp/free-billing-assessment/`.** LP URLs are for external traffic sources only.
- LP forms include `<input type="hidden" name="source" value="lp" />` to track conversion source.
- When auditing, categorize `/lp/` links found in internal CTAs as **LEAK** — they bypass site navigation and skew source tracking.

---

## Quality Standards

- **Don't break existing forms.** Only change links/buttons that route TO forms, not the forms themselves.
- **Preserve /get-in-touch/ for non-sales contact.** Not every contact is a lead. Support, partnerships, press — these need a contact page.
- **Mobile-first CTA check.** If a CTA isn't visible on mobile without scrolling, flag it.
- **Don't change blog content.** Only the CTA link targets and text within CTA components/sections.
- **Track what you change.** Every file modified goes in the report for rollback if needed.
