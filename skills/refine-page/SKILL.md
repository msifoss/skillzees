---
name: refine-page
description: Full-cycle page refinement — marketing panel strategy, design panel polish, conversion audit, and implementation. Adapts to any web project's stack and design system.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch
argument-hint: "<page path or URL to refine>"
---

# /refine-page — Full-Cycle Page Refinement

Takes any web page through a rigorous refinement process: strategic review, conversion audit, design polish, implementation, and deploy.

> Extracted from 3 real refinements (homepage, landing page, pricing page). The pattern: marketing-team strategy → implement approved changes → design-panel polish → implement design fixes → build → ship. This skill codifies that loop so every page gets the same treatment.

## Trigger

User invokes `/refine-page <page>` with a page path, URL, or page name.

## Arguments

| Argument | Description |
|----------|-------------|
| `<page>` | A page file path, a URL on the live site, or a page name (e.g., "pricing", "about us"). |
| `strategy-only` | Run only Phase 1 (marketing panel) — no implementation. |
| `design-only` | Run only Phase 3 (design panel) — assumes strategy is already settled. |
| `implement` | Skip panels, go straight to implementing a prior panel's findings. Requires a key_findings doc reference. |

Examples:
- `/refine-page src/pages/about-us.astro`
- `/refine-page "the services hub page"`
- `/refine-page src/pages/reviews.astro design-only`
- `/refine-page implement docs/key_findings/20260313-about-us-marketing-team.md`

---

## The Process (Overview)

```
Phase 0 — Load Context (project, page, design system, brand)
        ↓
Phase 1 — Marketing Team Strategy
        ↓ (user approves)
Phase 2 — Implement Strategy Fixes
        ↓ (build passes)
Phase 3 — Design Panel Polish
        ↓ (user approves)
Phase 4 — Implement Design Fixes
        ↓ (build passes)
Phase 5 — Final Validation & Ship
```

Each phase has a GATE — user approval before proceeding. No phase auto-advances.

---

## Phase 0 — Load Context

Before any panel convenes, understand the project and the page.

### 1. Discover the project

Detect the tech stack and project conventions:

```
- Framework: Look for astro.config.*, next.config.*, nuxt.config.*, vite.config.*, etc.
- CSS: Check for tailwind.config.*, global CSS files, CSS modules, styled-components
- Package.json: Read for build/dev/deploy scripts
- Project instructions: Read CLAUDE.md, README.md for conventions
- Brand docs: Check for docs/brand/, brand guidelines, style guides
- Design tokens: Check for design system files, theme configs, CSS custom properties
```

### 2. Read the page
Read the full page file. Understand the structure: sections, components used, CTA targets, content flow, layout structure.

### 3. Discover the design system

Look at the project's existing refined/polished pages to extract the established patterns:

**What to look for:**
- Hero treatment (gradient, image, color, typography)
- Button styles (border-radius, padding, colors, hover states)
- Icon system (icon library, SVG style, size conventions)
- Social proof patterns (testimonial cards, review widgets, trust badges)
- CTA patterns (primary/secondary pairing, microcopy, phone numbers)
- Section spacing (consistent padding/margin rhythm)
- Typography scale (heading sizes, weights, line-heights)
- Color palette (brand colors, backgrounds, text colors)
- Card styles (shadows, borders, border-radius, padding)

Document the patterns you find. If the project has a design system doc or style guide, read it.

**If the project has project-level skill files** (e.g., `.claude/skills/refine-page/SKILL.md`), read those first — they may contain project-specific design system details that override this global skill.

### 4. Read brand docs
Look for brand/positioning/voice documentation:
```
docs/brand/           — positioning, voice, buyer persona, proof inventory
docs/                 — any strategy or brand docs
brand/                — brand guidelines
```

If brand docs exist, read positioning and voice docs before panels convene.

### 5. Check page role
If a page strategy doc exists (e.g., `docs/brand/PAGES.md`), look up this page:
- What's the page's job? (convert, educate, validate, capture)
- Who's the audience?
- What CTA should it use?
- Where does it sit in the funnel?

If no page strategy doc exists, infer the role from the page content and URL.

### 6. Check analytics (if available)
If MCP analytics tools are available (GA4, Search Console, etc.), pull traffic data for this page. If unavailable, check for analytics snapshots in docs/ or note "analytics unavailable" and continue.

### 7. Produce a Page Brief
Before any panel convenes, present:
```
Page: [name] ([file path])
Stack: [framework + CSS + relevant tools]
Job: [convert/educate/validate/capture]
Audience: [who visits this page]
Current CTA: [what it links to, what the text says]
Design system compliance: [what matches / what doesn't match established patterns]
Known issues: [anything obviously wrong from the read-through]
Analytics: [traffic, top queries, or "unavailable"]
```

---

## Phase 1 — Marketing Team Strategy

Launch the `/marketing-team` panel focused on this specific page.

### What the marketing team evaluates:

1. **Positioning** — Does the page communicate the right value proposition for its audience?
2. **Conversion architecture** — Are CTAs in the right places? Is there a clear path to action?
3. **Proof placement** — Are testimonials, stats, and trust signals near decision points?
4. **Content flow** — Does the narrative arc move the reader from problem → solution → proof → action?
5. **Objection handling** — Does the page address the buyer's fears at the point they arise?
6. **Anti-pressure language** — Does the page reduce friction with safety-valve copy near CTAs?

### Agent prompt template:
```
You are the /marketing-team panel. Read your skill instructions at
~/.claude/skills/marketing-team/SKILL.md and execute a full panel analysis.

The question: "Review [page name] at [file path]. What's working, what's broken,
what changes would make this page better at its job ([page job])?"

Context:
- This is a [page role] page for [audience]
- Current CTA: [CTA text] → [CTA URL]
- [Include any brand docs found in Phase 0]
- [Include design system patterns found in Phase 0]
- Do NOT recommend changes that conflict with the established design patterns

Execute all phases through April's Strategic Call. Save the key findings doc.
```

**GATE 1:** Present the marketing team's findings and implementation plan to the user. Wait for approval before implementing.

The user may:
- Approve all recommendations
- Approve some, reject others
- Ask for clarification
- Add their own changes

Capture the approved list before proceeding.

---

## Phase 2 — Implement Strategy Fixes

Apply the approved marketing team recommendations. Work through them in this order:

### Implementation order:
1. **Content/copy changes** — Headlines, body text, CTA text, microcopy
2. **Structural changes** — Section order, add/remove sections, layout changes
3. **Proof placement** — Testimonials, trust stats, social proof positioning
4. **CTA consolidation** — Ensure all CTAs point to the correct conversion endpoint
5. **Design system alignment** — Apply established patterns from Phase 0 discovery

### Universal rules:
- Use the project's config/settings for CTA text and URLs where possible (don't hardcode)
- Every CTA button should have anti-pressure or reassurance microcopy nearby
- Phone/contact should appear as secondary CTA if the audience skews older or high-touch
- Use the project's established icon system (don't mix icon libraries)
- Use the project's established button styles (don't introduce new variants)

### Factual accuracy:
- Verify every number, stat, and claim on the page against source data
- If a claim can't be verified, flag it for the user
- Common false claims to watch for: "no fees" (when fees exist conditionally), inflated stats, outdated numbers

### Build check:
Run the project's build command and verify it passes:
```bash
npm run build 2>&1 | tail -10
```
(Adapt to project: `yarn build`, `pnpm build`, etc.)

Must pass before proceeding. If it fails, diagnose and fix.

**GATE 2:** Present the implemented changes to the user. Confirm before moving to design review.

---

## Phase 3 — Design Panel Polish

Launch the `/design-panel` focused on the now-updated page.

### Agent prompt template:
```
You are the /design-panel. Read your skill instructions at
[path to design-panel skill — check .claude/skills/ or ~/.claude/skills/]
and execute a full panel review.

Review: [page name] at [file path]
Page job: [convert/educate/validate/capture]

Context — established design system:
[Include all design system patterns discovered in Phase 0]

The marketing team strategy has already been implemented. Focus on visual
execution, spacing, typography consistency, mobile behavior, and polish.
Do NOT recommend strategy or content changes — only design/visual fixes.

Execute all phases through Steve's Design Call. Save the key findings doc.
```

**GATE 3:** Present the design panel's prioritized fix list to the user. Wait for approval.

---

## Phase 4 — Implement Design Fixes

Apply the approved design fixes. Work through Steve's priority list in order.

### Common design fixes (patterns from prior refinements):

| Pattern | What to check | Common fix |
|---------|--------------|------------|
| Button inconsistency | Mixed border-radius on CTAs | Standardize to project's convention |
| Icon inconsistency | Mixed icon styles (outline + solid, different libraries) | Standardize to project's icon system |
| Hero treatment | Doesn't match other refined pages | Apply project's hero pattern |
| Social proof styling | Doesn't match established review/testimonial pattern | Apply project's proof pattern |
| CTA isolation | CTA without reassurance text below | Add microcopy line |
| Secondary CTA missing | Primary CTA without phone/contact alternative | Add secondary CTA |
| Trust signals buried | Stats/proof in a section below fold | Move into hero zone |
| Heading scale | Inconsistent heading sizes across sections | Standardize to page's scale |
| Card styling | Inconsistent shadows/borders/padding | Pick one treatment and apply consistently |
| Section spacing | Inconsistent vertical padding | Standardize to project's rhythm |

### Build check:
```bash
npm run build 2>&1 | tail -5
```

**GATE 4:** Present final state to user. Ready to ship?

---

## Phase 5 — Final Validation & Ship

### Pre-ship checklist:

- [ ] All CTAs point to the correct conversion endpoint
- [ ] Anti-pressure / reassurance microcopy near CTAs
- [ ] Secondary CTA (phone/contact) present if appropriate
- [ ] Hero treatment matches site standard
- [ ] All buttons match established style
- [ ] Icons are consistent with project's system
- [ ] Trust signals / social proof visible
- [ ] No false or unverified claims
- [ ] Build passes
- [ ] Meta title and description updated for positioning
- [ ] Mobile experience checked (first viewport, CTA visibility)

### If user says "ship it":

Use the project's commit and deploy conventions:
```bash
git add [changed files]
git commit -m "feat: [Page name] refinement — [1-line summary]

[2-3 line description]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

git push origin [branch]
[project deploy command if known]
```

### Save findings:
If not already saved by the sub-panels, save a summary to:
`docs/key_findings/YYYYMMDD-HHmm-[page-slug]-refinement.md` (use current date and 24h time)

---

## Landing Page Variants

If the project uses a dual-page pattern (main page with nav + stripped landing page for ads):
- Check if a landing page variant exists
- If it does, apply the same content/design changes to both versions
- Landing page variants should use a stripped layout (no nav/footer)
- Landing page forms should include source tracking (hidden field)
- Internal CTAs must NEVER point to landing page variant URLs — those are for external traffic only
- Update any landing page index/directory if one exists

---

## Quality Standards

### What makes a good refinement

1. **Strategy before design** — Marketing team sets the narrative and conversion architecture. Design panel polishes the execution. Never reverse this order.
2. **Design system consistency** — The refined page should look like it belongs on the same site as other refined pages. Same hero treatment, same buttons, same icons, same proof patterns.
3. **Honest claims** — Every number, stat, and promise on the page must be verifiable. When in doubt, ask the user.
4. **Buyer-centric copy** — Every headline and CTA should pass the "would the target buyer say this?" test. No jargon. No corporate-speak.
5. **Anti-pressure language** — If the audience has sales-pressure anxiety, every CTA needs a safety valve ("no pitch", "no commitment").
6. **Build passes** — Non-negotiable after every change.
7. **Gates respected** — Never auto-advance past a gate. The user approves before implementation.

### What makes a bad refinement

- Skipping the marketing team and going straight to design (you'll polish the wrong thing)
- Recommending a design that doesn't match the project's established system
- False or unverified claims
- Missing reassurance microcopy near high-commitment CTAs
- Breaking the build and not fixing it before reporting
- Changing the page's strategic role without consulting the marketing team
- Introducing new design patterns that conflict with existing refined pages

---

## Project-Specific Override

If a project has its own `/refine-page` skill at `.claude/skills/refine-page/SKILL.md`, that skill takes precedence over this global one. The project-level skill will contain:
- Project-specific design system patterns (exact Tailwind classes, icon SVGs, color values)
- Project-specific brand doc locations
- Project-specific factual accuracy checks
- Project-specific build and deploy commands
- Project-specific CTA targets and microcopy

This global skill provides the process framework. Project-level skills provide the specifics.
