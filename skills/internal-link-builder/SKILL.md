---
name: internal-link-builder
description: Add internal links and contextual CTAs to top-performing blog posts, connecting organic traffic to service pages and conversion
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, mcp__anny__search_console_top_pages, mcp__anny__ga4_top_pages
argument-hint: "[blog-slug | audit | all | authority-box]"
---

# /internal-link-builder — Blog-to-Conversion Linker

Adds internal links and contextual CTAs to top-performing blog posts. Connects organic traffic to service pages and the conversion path. Turns dead-end blog posts into pipeline generators.

> "Your top blog posts are dead ends. Add contextual CTAs and internal links to service pages." — Jimmy

## Trigger

User invokes `/internal-link-builder` with an optional argument.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Audit top posts and show linking opportunities |
| `audit` | Full audit of internal links across all blog posts |
| `all` | Add links + CTAs to the full priority list |
| `authority-box` | Add/update the author authority box in the blog template |
| `[blog-slug]` | Add links + CTA to a specific blog post |

---

## Coordination

**Execution order:** This skill runs THIRD among blog-editing skills. It adds internal links and bridge sentences — after CTA plumbing and titles are already fixed.

Run order for blog-editing skills:
1. **conversion-plumber** — FIRST (fixes CTA link targets)
2. **seo-meta-agent** — SECOND (fixes titles/metas)
3. **internal-link-builder** — THIRD (this skill — adds internal links + bridge sentences)

**Safe to run in parallel with:** moat-content-writer, vertical-builder (they touch different files).

**NOT safe to run in parallel with:** conversion-plumber, seo-meta-agent (all three edit the same blog posts).

---

## MCP Fallback

If Anny MCP tools (Search Console, GA4) are unavailable:
1. Check for `docs/data/latest-traffic-snapshot.json` — use if <7 days old
2. If no snapshot, use the priority list in `docs/key_findings/20260312-website-structure-vs-traffic-audit-marketing-team.md`
3. If neither available, STOP and ask the user for guidance

---

## Phase 0 — Load Context

1. **Read brand docs:**
   - `docs/brand/POSITIONING.md` — for CTA copy and positioning context
   - `docs/brand/VOICE.md` — for tone in bridge sentences
   - `docs/brand/PAGES.md` — for understanding which service pages map to which topics
2. **Read the site map of service pages:**
   - `/membership-billing-services/` — main services hub
   - `/membership-billing-services/revenue-recovery` — payment recovery
   - `/membership-billing-services/contract-management` — agreements
   - `/membership-billing-services/invoice-management` — billing platform
   - `/membership-billing-services/back-office-team` — the team
   - `/membership-billing-services/martial-arts` — MA vertical
   - `/membership-billing-services/fitness` — fitness vertical
3. **Pull traffic data** to prioritize which posts to work on first:
   - `mcp__anny__search_console_top_pages` (last_28_days, limit 50)
   - `mcp__anny__ga4_top_pages` (last_28_days, limit 50)
4. **Read the blog post template/layout** to understand where CTAs currently render

---

## Phase 1 — Audit

For each blog post in the priority list (top 20 by Search Console clicks):

1. **Read the post** — understand the topic and content
2. **Check existing internal links:**
   - Does it link to any service pages?
   - Does it link to the landing page (/free-billing-assessment/)?
   - Does it link to other relevant blog posts?
3. **Check for CTA section:**
   - Is there a CTA component/section in the post?
   - What does it link to? (Should be /free-billing-assessment/)
   - Is the CTA contextual to the post topic, or generic?
4. **Identify linking opportunities:**
   - Which service page is most relevant to this post's topic?
   - Where in the content is a natural bridge point?
   - What's the contextual CTA copy? (Not generic "Learn more" — specific to the topic)

### Priority List (from marketing team audit):

| Post | SC Clicks | Relevant Service Page | Link Type |
|------|-----------|----------------------|-----------|
| /types-of-memberships/ | 226 | /membership-billing-services/ | Billing management |
| /best-membership-management-software/ | 49 | /membership-billing-services/ | MS as option |
| /membership-business-ideas/ | 47 | /membership-billing-services/ | Billing as foundation |
| /professional-payment-reminder-email-templates/ | 47 | /membership-billing-services/revenue-recovery | "Or let us handle it" |
| /best-boxing-gym-name-ideas/ | 42 | — | Light sidebar CTA only |
| /how-to-start-a-rock-climbing-gym/ | 41 | /membership-billing-services/ | "First thing to outsource" |
| /subscription-vs-membership/ | 37 | /membership-billing-services/ | Membership billing |
| /gym-newsletter-ideas/ | 36 | — | Light CTA |
| /member-appreciation-ideas/ | 35 | — | Light CTA |
| /martial-arts-ads-examples/ | 30 | /membership-billing-services/martial-arts | Bridge to billing |

**GATE:** Present the audit with recommended links/CTAs for each post. Get user approval before editing.

---

## Phase 2 — Add Links & CTAs

For each approved post, make these changes:

### Internal Links (in-content)

Add 1-3 natural internal links within the post body. Rules:
- **Natural placement** — the link should feel like a helpful reference, not a forced insertion
- **Contextual anchor text** — don't say "click here." Say something like "how a dedicated billing team handles this" linking to /membership-billing-services/back-office-team
- **Bridge sentence** — add a sentence or short paragraph that connects the post's topic to billing/MS service. Example for a profit margin post: "Your billing recovery rate is one of the biggest levers on that margin — and most gym owners don't even track it."
- **Max 3 internal links per post** — don't spam
- **At least 1 link to a service page** and **1 link to the landing page**

### DO NOT Add a Standalone CTA Section

**IMPORTANT:** The blog post template (`src/pages/blog/[...slug].astro`, lines ~179-198) already renders a hardcoded CTA box after every post ("Stop Chasing Payments. Let Our Team Handle It." → `/free-billing-assessment/`). Adding a second CTA section in the Markdown body will create a duplicate.

Instead of a standalone CTA block, weave billing bridges into the content naturally:

### Bridge Sentences (in-content, not standalone)

Add 1-2 bridge sentences within the post body that connect the topic to billing/MS. These should feel like natural editorial asides, not CTAs. Place them where the topic naturally connects to billing.

**Bridge sentence examples by topic:**

| Post Topic | Bridge (woven into content) |
|------------|-----------|
| Pricing strategies | "Getting pricing right matters — but collecting those payments matters more. [Your billing recovery rate](/membership-billing-services/revenue-recovery) is the lever most owners overlook." |
| Member retention | "Retention starts with billing. When payments fail silently, [members disappear without anyone noticing](/membership-billing-services/revenue-recovery)." |
| Gym startup guide | "Once you're open, billing is the first thing smart gym owners outsource. [A dedicated billing team](/membership-billing-services/) lets you focus on coaching, not chasing payments." |
| Payment reminders | "Or skip the templates entirely — [a billing team handles the follow-up calls, bank disputes, and recovery](/membership-billing-services/revenue-recovery) so you never send another awkward email." |
| Martial arts marketing | "Getting students in the door is half the battle. [Keeping their payments flowing](/membership-billing-services/martial-arts) is the other half." |
| Revenue/profit | "Your billing recovery rate is the #1 lever on your bottom line — and most owners don't track it. [Here's what a real recovery process looks like](/membership-billing-services/revenue-recovery)." |

**Rules for bridge sentences:**
- Maximum 2 per post — subtlety over volume
- Must include an internal link to a service page
- Must feel like a natural editorial aside, not a sales pitch
- Tone matches VOICE.md — empathetic operator
- Do NOT add horizontal rules, bold headers, or standalone CTA blocks — the template handles conversion

---

## Phase 3 — Authority Box (if `authority-box` argument)

Update the existing AuthorCard component in the blog post template to include a billing expertise authority line.

**NOTE:** The blog template already has an AuthorCard component. Do NOT add a second author section. Instead, modify the existing one.

**Implementation:**
1. Read `src/pages/blog/[...slug].astro` to find the AuthorCard component
2. Read `src/components/blog/AuthorCard.astro` (or similar) to understand its current content
3. Add a one-line authority statement: *"From the Member Solutions team — 35 years helping 11,000+ martial arts schools and fitness studios get paid."*
4. This is a ONE-TIME template change that applies to all posts automatically — do NOT edit individual posts

---

## Phase 4 — Build Validation

After all changes, run:
```bash
npm run build 2>&1 | head -50
```
If the build fails, read the error and fix before reporting. Do NOT skip this step.

---

## Phase 5 — Report

Save changes to `docs/key_findings/YYYYMMDD-HHmm-internal-linking-audit-internal-link-builder.md` (use current date and 24h time):

```markdown
# Internal Linking Audit & Updates

## Posts Updated
| Post | Links Added | CTA Updated | Service Pages Linked |
|------|-------------|-------------|---------------------|

## Links Inventory
- Total internal links added: X
- Posts with CTA sections: Y/Z
- Service pages now linked from blog: [list]

## Next Steps
- Monitor GA4 for increased service page traffic from blog referrals
- Check /free-billing-assessment/ traffic in 2 weeks
```

---

## Quality Standards

- **Natural > optimized.** If a link feels forced, don't add it. A gym owner should read the post and feel the link is genuinely helpful, not inserted for SEO.
- **One CTA per post.** Don't add multiple CTAs — one clear ask at the end.
- **Match the post's voice.** If the post is casual, the CTA should be casual. If it's data-heavy, the CTA should reference data.
- **Don't rewrite post content.** Add links within existing sentences where natural. Add bridge sentences + CTA section. Don't restructure or rewrite paragraphs.
- **Service page relevance.** Don't link to /revenue-recovery from a boxing gym names post. Only link where there's a genuine topical connection.
