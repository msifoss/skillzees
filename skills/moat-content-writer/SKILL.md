---
name: moat-content-writer
description: Create billing expertise blog posts that leverage Member Solutions' unique 35-year data advantage — content no competitor can replicate
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch
argument-hint: "[post-number 1-5 | outline | all]"
---

# /moat-content-writer — Billing Expertise Content Creator

Creates blog posts that leverage Member Solutions' unique competitive advantage: 35 years of billing recovery data across 11,000+ schools. This is content no competitor can replicate because no competitor has the experience.

> "114 blog posts and zero leverage your competitive advantage — billing recovery expertise. That's your moat. Boxing gym names is not." — Jimmy

## Trigger

User invokes `/moat-content-writer` with an optional argument.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Show the 5-post plan with outlines |
| `outline` | Generate detailed outlines for all 5 posts |
| `all` | Write all 5 posts |
| `1` through `5` | Write a specific post by number |

---

## The 5 Moat Content Posts

| # | Title | Topic | Target Query | Buyer Stage |
|---|-------|-------|-------------|-------------|
| 1 | What Actually Happens When a Member's Payment Fails | Recovery process: software email vs. human team | payment failed gym membership | Awareness |
| 2 | Revenue Recovery Benchmarks: What 11,000+ Schools Taught Us | Delinquency rates, seasonal patterns, recovery timelines | gym membership recovery rate | Consideration |
| 3 | The Hidden Cost of DIY Billing | Time + lost revenue audit for the school owner | gym billing cost, diy billing gym | Consideration |
| 4 | 5 Billing Scenarios Every Martial Arts School Faces | Summer cancellations, chargebacks, family plans, expired cards, belt test timing | martial arts billing problems | Awareness |
| 5 | From Spreadsheets to a Billing Team: Your First 90 Days | Onboarding story, fear reduction, what to expect | switch billing company gym | Decision |

---

## Coordination

**Execution order:** This skill creates NEW blog post files — it does not edit existing posts. It is safe to run at any time, including in parallel with other skills.

**Safe to run in parallel with:** ALL other skills (seo-meta-agent, conversion-plumber, internal-link-builder, vertical-builder). This skill only creates new files in `src/content/blog/`.

**Note:** After moat content posts are created, the internal-link-builder may want to add links FROM existing posts TO these new posts. Run internal-link-builder after moat-content-writer if cross-linking is desired.

---

## Phase 0 — Load Context (Before Writing Any Post)

**MANDATORY:** Read these files before writing:

1. `docs/brand/POSITIONING.md` — the three pillars, competitive alternative, "not just an app"
2. `docs/brand/VOICE.md` — tone, word choices, headline patterns, what to avoid
3. `docs/brand/BUYER.md` — buyer persona, pain points, fears at conversion
4. `docs/brand/PROOF.md` — available testimonials, stats, case study templates

Also read 2-3 existing blog posts to match the content format:
- Check frontmatter structure (title, description, date, author, category, image, etc.)
- Check markdown formatting conventions
- Check CTA section format
- Check image/asset patterns

---

## Phase 1 — Outline (if `outline` or no argument)

For each post, produce:

```markdown
## Post [#]: [Title]

**Target query:** [Primary search query]
**Target word count:** [1,500-2,500 words]
**Buyer stage:** [Awareness / Consideration / Decision]
**Service page link:** [Which service page this naturally links to]

### Outline:
1. [Section] — [What it covers, 2-3 sentences]
2. [Section] — ...
3. ...

### The "only MS could write this" angle:
[Explain what makes this post impossible for competitors to replicate — the specific data, experience, or process knowledge required]

### Internal links planned:
- [Service page] — at [which section]
- [Other blog post] — cross-reference
- /free-billing-assessment/ — CTA section

### CTA approach:
[Contextual CTA copy specific to this post's topic]
```

**GATE:** Present all 5 outlines and get user approval before writing.

---

## Phase 2 — Write

For each post to write:

### Content Rules

1. **Voice:** Follow VOICE.md exactly. Empathetic seasoned operator, not corporate, not a software company blog. Write like you've personally seen this scenario 10,000 times.

2. **Data and specifics:** This is moat content — it must include specific numbers, benchmarks, timelines, or process details that demonstrate deep expertise. NOT vague advice. Examples:
   - BAD: "Payment recovery is important for gyms."
   - GOOD: "When a credit card declines on a Tuesday, most software sends an email. By Friday, 40% of those members have mentally moved on. By the following Tuesday, you've lost them. That's the window — and email alone can't close it."

3. **The "competitor comparison" moment:** Each post should have ONE section that implicitly (never explicitly) shows what software-only solutions miss. Frame it as "what typically happens" vs. "what should happen."

4. **Structure:**
   - Opening hook — a scenario the reader recognizes (2-3 sentences)
   - The problem — what most people get wrong (1-2 paragraphs)
   - The substance — the expertise, benchmarks, process knowledge (bulk of the post)
   - The bridge — connecting this knowledge to "maybe you shouldn't be handling this yourself"
   - CTA — contextual, specific to the post topic

5. **Formatting:**
   - H2 sections with clear, scannable headers
   - Bullet lists for actionable items
   - Bold key stats and benchmarks
   - Tables for comparisons or benchmarks where appropriate
   - Pull quotes for memorable lines
   - 1,500-2,500 words — substantial but not padded

6. **Internal links:**
   - 2-3 links to service pages (natural placement)
   - 1-2 links to related blog posts
   - CTA links to /free-billing-assessment/

7. **CTA link target:** Blog post CTAs must link to `/free-billing-assessment/` (the full-nav version), never to `/lp/free-billing-assessment/`. The `/lp/` variant is for external paid traffic only — internal site links should always use the main page URL.

8. **What NOT to do:**
   - Don't name-drop competitors (Zen Planner, Spark, etc.) — this isn't comparison content
   - Don't make up fake statistics — use ranges and qualifiers ("in our experience," "across thousands of schools")
   - Don't be salesy — the expertise IS the pitch
   - Don't use jargon without explanation
   - Don't pad with generic advice that could be on any fitness blog

### Frontmatter

Match the existing blog post format. Typical:

```yaml
---
title: "Post Title"
description: "150-160 char description"
pubDate: YYYY-MM-DD
author: "Member Solutions"
tags: ["billing", "revenue-recovery"]
image: "/images/blog/[slug].jpg"
imageAlt: "Alt text for the image"
draft: false
---
```

**IMPORTANT:** Use `pubDate:` (not `date:`), `tags:` array (not `category:`). Check 2-3 existing posts in `src/content/blog/` to confirm the exact frontmatter fields before writing. There is no content schema validation — wrong field names will silently fail.

---

## Phase 3 — Review & Publish

After writing each post:

1. **Read it aloud test:** Does every sentence sound like something a billing expert would say at an industry conference, not something a content mill would produce?
2. **The "only MS" test:** Could a competitor write this post? If yes, it's not moat content. Add specifics.
3. **Link check:** Are internal links pointing to correct URLs? Is the CTA linking to /free-billing-assessment/?
4. **Frontmatter check:** Does it match the existing blog post format?
5. **Save the file** to `src/content/blog/[slug].md`

---

## Phase 4 — Build Validation

After creating each post (or all posts), run:
```bash
npm run build 2>&1 | head -50
```

If the build fails:
1. Read the error — likely a frontmatter issue (wrong field name, missing required field)
2. Compare your frontmatter against an existing working post in `src/content/blog/`
3. Fix and re-build until it passes

**Common pitfalls (no content schema exists — errors are silent):**
- Using `date:` instead of `pubDate:` — post will have no date
- Using `category:` instead of `tags:` — post won't show in any category
- Missing `description:` — SEO meta will be empty

---

## Phase 5 — Report

After all posts are written, save a summary to `docs/key_findings/YYYYMMDD-HHmm-moat-content-creation-moat-content-writer.md` (use current date and 24h time):

```markdown
# Moat Content Creation Report

## Posts Created
| # | Title | Slug | Word Count | Service Pages Linked | Target Query |
|---|-------|------|------------|---------------------|-------------|

## Content Moat Strategy
[Summary of how these 5 posts work together to establish billing expertise authority]

## Measurement Plan
- Track organic impressions/clicks for each post via Search Console (give 4-8 weeks to index)
- Monitor internal link clicks to service pages via GA4
- Track /free-billing-assessment/ referrals from blog posts

## Future Moat Content Ideas
[2-3 additional post ideas that emerged during writing]
```

---

## Post Details

### Post 1: What Actually Happens When a Member's Payment Fails

**The angle:** Walk through the FULL recovery process step by step — from the moment a card declines to resolution. Show the gap between "software sends an email" (what competitors do) and "a human calls the bank, disputes the chargeback, updates the card, recovers the revenue" (what MS does).

**Key sections:**
- Day 0: The decline (what triggers it, why it happens)
- Day 1-3: The automated response (what software does — and where it stops)
- Day 4-14: The recovery window (phone calls, bank disputes, card updates)
- Day 15-30: The last chance (collections approach, professional follow-up)
- After 30 days: What's actually recoverable and what's lost
- The math: What this costs a 200-member school per year

### Post 2: Revenue Recovery Benchmarks

**The angle:** Industry benchmarks that only someone processing thousands of schools' billing could know. Seasonal patterns, recovery rates by method, delinquency by gym type.

**Key sections:**
- Average delinquency rate by vertical (MA vs. fitness vs. swimming vs. dance)
- Seasonal patterns (January surge, summer drop, holiday cancellations)
- Recovery rate by method (email alone vs. phone vs. full-service team)
- The "silent churn" problem — members who leave without canceling
- Benchmark calculator: "Where does your school fall?"

### Post 3: The Hidden Cost of DIY Billing

**The angle:** A school owner's real time + revenue audit. Hours per week on billing admin + lost revenue from unrecovered payments = the true cost of "saving money" by doing it yourself.

**Key sections:**
- The time audit: 8-12 hours/week most owners don't account for
- The revenue leak: 3-8% of billings lost to unrecovered failures
- The opportunity cost: what those hours could do for the business
- The emotional cost: the awkward conversations, the stress, the late nights
- The math: $99/mo for a team vs. the actual cost of DIY
- When DIY makes sense vs. when it doesn't (be honest)

### Post 4: 5 Billing Scenarios Every Martial Arts School Faces

**The angle:** Hyper-specific scenarios that every MA school owner has dealt with. Show deep industry knowledge. Each scenario includes what typically happens (DIY) vs. what should happen (team approach).

**The 5 scenarios:**
1. Summer vacation: student leaves for camp, parents want to "pause" (not cancel)
2. Card expiration: the most common — and most preventable — revenue loss
3. Family plan confusion: 3 kids, different belt levels, one card, partial cancellation
4. Chargeback dispute: parent disputes a charge, bank sides with them automatically
5. Belt test fees: one-time charges on top of recurring billing — collection timing matters

### Post 5: From Spreadsheets to a Billing Team

**The angle:** Address the #1 fear at conversion: "What happens to my current members' billing if I switch?" Walk through the 90-day onboarding timeline.

**Key sections:**
- Week 1-2: The audit — mapping your current billing (every member, every payment method)
- Week 3-4: The migration — moving billing data without disrupting member payments
- Month 2: The handoff — your billing team takes over, you start getting reports
- Month 3: The difference — what your day looks like now vs. before
- Common fears addressed: "Will members notice?" "What if something goes wrong?" "Can I still see my data?"
- Real talk: what the transition is actually like (honest about the learning curve)
