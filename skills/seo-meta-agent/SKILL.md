---
name: seo-meta-agent
description: Rewrite title tags and meta descriptions for top organic pages using Search Console data and brand voice guidelines
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, mcp__anny__search_console_top_pages, mcp__anny__search_console_top_queries, mcp__anny__search_console_summary, mcp__anny__ga4_top_pages
argument-hint: "[page-slug | audit | all]"
---

# /seo-meta-agent — Title Tag & Meta Description Optimizer

Rewrites title tags and meta descriptions for top organic pages using actual Search Console data and brand voice guidelines. Turns impressions into clicks.

> "You have pages on page 1 of Google getting almost zero clicks. Fix titles first." — Rand

## Trigger

User invokes `/seo-meta-agent` with an optional page slug, `audit` to scan all pages, or `all` to rewrite the full priority list.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Show the priority list with current vs. recommended titles |
| `audit` | Pull fresh Search Console data and rank pages by opportunity (impressions × CTR gap) |
| `all` | Rewrite titles/metas for the full top-20 priority list |
| `[page-slug]` | Rewrite title/meta for a specific page (e.g., `best-membership-management-software`) |

---

## Coordination

**Execution order:** This skill edits blog post frontmatter (title/description). Three skills touch blog posts:
1. **conversion-plumber** — runs FIRST (fixes CTA link targets)
2. **seo-meta-agent** — runs SECOND (this skill — fixes titles/metas)
3. **internal-link-builder** — runs THIRD (adds internal links + bridge sentences)

**Safe to run in parallel with:** moat-content-writer, vertical-builder (they touch different files).

**NOT safe to run in parallel with:** conversion-plumber, internal-link-builder (all three edit the same top-20 blog posts — later writes can clobber earlier ones).

---

## MCP Fallback

If Anny MCP tools (Search Console, GA4) are unavailable:
1. Check for `docs/data/latest-traffic-snapshot.json` — use if <7 days old
2. If no snapshot, use the hardcoded priority list in `docs/key_findings/20260312-website-structure-vs-traffic-audit-marketing-team.md` (the "High-impression, low-CTR pages" table)
3. If neither available, STOP and ask the user for guidance — do not hallucinate priority lists

---

## Phase 0 — Load Context

Before any work:

1. **Read brand voice docs:**
   - `docs/brand/POSITIONING.md` — positioning statement, three pillars, competitive alternative
   - `docs/brand/VOICE.md` — tone, word choices, headline patterns
2. **Pull Search Console data:**
   - Use `mcp__anny__search_console_top_pages` (last_28_days, limit 50)
   - Use `mcp__anny__search_console_top_queries` (last_28_days, limit 50)
3. **Identify the priority list** — rank pages by `impressions × (benchmark_CTR - actual_CTR)` where benchmark CTR by position is:
   - Position 1-3: 5-10% CTR
   - Position 4-7: 2-5% CTR
   - Position 8-10: 1-2% CTR
   - Position 11-20: 0.5-1% CTR
   Pages significantly below benchmark for their position are the biggest opportunities.

---

## Phase 1 — Audit (if `audit` or no argument)

Present a table:

```
| Page | Impressions | Clicks | CTR | Position | Expected CTR | CTR Gap | Opportunity Score |
```

Sort by opportunity score descending. Highlight the top 20.

For each page, note:
- Current title tag (read from the .astro or .md file)
- Current meta description
- Primary query driving impressions (from Search Console query data)
- Whether the page is a blog post (.md in src/content/blog/) or an .astro page

**GATE:** Present the audit table and get user confirmation before proceeding to rewrites.

---

## Phase 2 — Rewrite (if `all` or specific page)

For each page to rewrite:

1. **Read the current page file** — understand the content
2. **Identify the primary search query** — what are people searching when they see this page?
3. **Write a new title tag** following these rules:
   - Under 60 characters (Google truncates at ~60)
   - Include the primary keyword naturally
   - Add brand voice flavor — not keyword-stuffed SEO, but a title a gym owner would click
   - End with `| Member Solutions` only if space allows and it adds trust
   - Examples of good titles:
     - "Payment Reminder Emails That Don't Alienate Your Members"
     - "What Gym Profit Margins Actually Look Like (Real Numbers)"
     - "BJJ Gym Startup Guide: Costs, Setup & What Nobody Tells You"
4. **Write a new meta description** following these rules:
   - 150-160 characters
   - Include the primary keyword in the first sentence
   - Add a hook that differentiates from competing results
   - Reference MS's authority when relevant ("From 35 years of billing data...")
   - End with a soft CTA or curiosity hook
5. **Apply the changes** — edit the frontmatter (for blog posts) or the `<title>` and `<meta>` tags (for .astro pages)

### Where to edit:

**Blog posts** (`src/content/blog/*.md`):
- Title: `title:` in frontmatter (this is the ONLY title field — no `seoTitle`/`metaTitle` overrides exist)
- Description: `description:` in frontmatter
- Note: There is no content schema validation (`src/content/config.ts` doesn't exist), so wrong field names fail silently

**Astro pages** (`src/pages/*.astro`):
- Look for `title` prop passed to Layout component
- Look for `description` prop passed to Layout component
- Or check the `<head>` section for direct `<title>` and `<meta name="description">` tags

---

## Phase 3 — Report

After rewrites, produce a summary table:

```
| Page | Old Title | New Title | Old CTR | Target CTR |
```

And save to `docs/key_findings/YYYYMMDD-HHmm-seo-meta-rewrites-seo-meta-agent.md` (use current date and 24h time) with:
- Full before/after for each page
- Rationale for each rewrite
- "Check back in 2-4 weeks" reminder to measure CTR impact via Search Console

---

## Phase 4 — Build Validation

After all changes, run:
```bash
npm run build 2>&1 | head -50
```

If the build fails:
1. Read the error output
2. Fix the issue (likely a frontmatter or syntax error)
3. Re-run the build until it passes
4. Only then proceed to the report

**Do NOT skip this step.** There is no content schema validation in this project — wrong field names or malformed frontmatter will silently fail at build time.

---

## Quality Standards

- **Never keyword-stuff.** If a title reads like an SEO tool wrote it, rewrite it.
- **Brand voice first.** The title should sound like Member Solutions — an empathetic operator who's been through it — not a generic listicle.
- **Test by reading aloud.** Would a gym owner click this? Would they scroll past the other 9 results?
- **Don't change page content.** Only title tags and meta descriptions. Content rewrites are a separate skill.
- **Preserve existing high performers.** If a page already has good CTR for its position (like /types-of-memberships/ at 0.96% in position 2.9), make only minor optimizations — don't break what works.
