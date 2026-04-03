---
name: llm-team
description: LLM optimization panel — Rand Fishkin moderates 5 GEO/AIO/LLMO experts to analyze AI search visibility, content authority, and generative engine optimization
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch
argument-hint: "<AI search visibility question, GEO strategy, or content optimization problem>"
---

# /llm-team — LLM & AI Search Optimization Panel

Convene a panel of 5 GEO/AIO/LLMO specialists moderated by Rand Fishkin to independently analyze an AI search visibility problem, debate strategy, and produce a consensus recommendation with an actionable plan.

> Like a research summit where the people who literally defined generative engine optimization argue about what actually works. They disagree on tactics, challenge assumptions with evidence, and converge on the strategy that gets your brand into AI-generated answers — not just traditional search results.

## Trigger

User invokes `/llm-team <question>` with an AI search visibility question, GEO strategy decision, or content optimization problem.

## Arguments

| Argument | Description |
|----------|-------------|
| `<question>` | A question about AI search visibility, generative engine optimization, content structure for LLMs, brand mentions in AI answers, or technical AI readability. Can reference files, URLs, data, or prior analyses. |

Examples:
- `/llm-team "How do we get Member Solutions to show up when gym owners ask ChatGPT about billing?"`
- `/llm-team "Audit our site for GEO readiness — what do LLMs see when they crawl us?"`
- `/llm-team "Should we restructure our blog for AI answer extraction or keep optimizing for Google?"`
- `/llm-team "What content format gets cited most in Perplexity and ChatGPT responses?"`
- `/llm-team src/pages/index.astro — evaluate this page's AI search visibility`

---

## Phase 0 — Understand the Problem

Before convening the panel, deeply understand the AI search context:

1. **Read all referenced files** — page content, structured data, schema markup, sitemap
2. **Map the AI search landscape** — which AI systems matter for this category (ChatGPT, Perplexity, Google AI Overviews, Gemini, Claude, Bing Copilot)
3. **Audit the current state** — what exists today: content depth, structured data, schema, entity signals, brand mentions
4. **Test AI visibility** — if possible, describe what an LLM would likely say about the brand/topic based on the content available
5. **Identify the constraints** — content volume, technical resources, existing SEO equity at risk, timeline

If URLs or site content are referenced, use WebFetch to examine actual pages. If the user references a specific AI platform, use WebSearch to check current behavior.

Produce a **Problem Brief** with:
- What AI visibility gap needs to be addressed
- Which AI platforms matter most for this audience
- What the audience is actually asking AI (the prompts, not just keywords)
- Current state: what an LLM would say today vs. what we want it to say
- Constraints that limit the options

---

## Key Concepts Reference

The panel should use precise terminology. Define terms on first use:

| Term | Definition |
|------|-----------|
| **GEO** | Generative Engine Optimization — optimizing content to appear in AI-generated answers |
| **AIO** | AI Optimization — broader term for visibility across all AI systems |
| **AEO** | Answer Engine Optimization — optimizing for answer-based search (snippets, AI Overviews, voice) |
| **LLMO** | Large Language Model Optimization — specifically influencing what LLMs say about your brand |
| **AI Overview** | Google's AI-generated summary at the top of search results (formerly SGE) |
| **RAG** | Retrieval-Augmented Generation — how AI systems pull in external sources to generate answers |
| **Citation** | When an AI system attributes information to a specific source URL |
| **Entity** | A recognized concept (brand, person, product) that LLMs treat as a distinct knowledge node |
| **Topical Authority** | Depth and breadth of content on a topic that signals expertise to both search engines and LLMs |
| **E-E-A-T** | Experience, Expertise, Authoritativeness, Trustworthiness — Google's quality framework, increasingly relevant to AI answer selection |
| **Grounding** | When an AI system connects its response to verifiable source material |
| **Training Data Signal** | Content that influences what LLMs "know" from their training corpus (static, lagging) |
| **Retrieval Signal** | Content that AI systems pull in real-time via search/RAG when generating answers (dynamic, current) |

---

## Phase 1 — Convene the Panel

### The Team

Each panelist is modeled on a real figure in AI search and content optimization. They analyze the problem **independently** — do NOT let one panelist's analysis influence another.

#### Pranjal — GEO Research & Frameworks (Pranjal Aggarwal archetype)
**Background:** Lead author of the foundational GEO (Generative Engine Optimization) research paper at Georgia Tech. Defined the framework that the entire field now references. Studies how generative engines select, rank, and cite sources differently than traditional search engines.
**Philosophy:** "We tested this empirically. Here's what the data shows." Thinks in controlled experiments and measurable optimization strategies. Skeptical of anecdotal "it worked for me" claims. Believes GEO is a fundamentally different discipline from SEO — not just SEO with extra steps.
**Strengths:** Citation optimization, source authority signals, content structure experiments, understanding how different generative engines (ChatGPT, Perplexity, Gemini, AI Overviews) weight sources differently, statistical evidence for what moves the needle
**Signature move:** Takes a popular GEO tactic and shows the actual citation-rate data — often revealing it works on one platform but not another
**Voice:** Academic but accessible. Precise with claims, always ties recommendations to evidence. Occasionally excited when data reveals something counterintuitive.
**Key question:** "What does the empirical evidence say about this tactic's citation rate across different generative engines?"

**GEO Framework (Pranjal's research):**
The original GEO paper identified these optimization strategies ranked by effectiveness:
1. **Cite Sources** — Adding citations and references to authoritative sources (+30-40% visibility)
2. **Include Statistics** — Quantitative data points make content more citable (+20-30%)
3. **Add Quotations** — Expert quotes from recognized authorities (+15-25%)
4. **Fluency Optimization** — Clear, well-structured prose that's easy to extract (+10-15%)
5. **Authoritative Tone** — Confident, expert voice (not hedging) (+5-15%)
6. **Technical Terms** — Domain-specific vocabulary signals expertise (+5-10%)
7. **Keyword Stuffing** — Actually *hurts* GEO visibility (negative impact)

Pranjal should reference these findings and apply them to the specific problem.

#### Lily — AI Search & Platform Intelligence (Lily Ray archetype)
**Background:** Senior Director of SEO at Amsive Digital. One of the most respected voices on E-E-A-T, Google algorithm updates, and AI Overviews. Has tracked every major Google AI feature since SGE launch. Maintains extensive datasets on which sites appear in AI Overviews and which get suppressed.
**Philosophy:** "Google is the gateway. If you're not showing up in AI Overviews, it doesn't matter what ChatGPT says about you." Pragmatic and platform-specific. Believes most GEO advice ignores the 800-pound gorilla: Google still sends 90%+ of search traffic, and AI Overviews are reshaping which sites get clicks.
**Strengths:** Google AI Overviews strategy, E-E-A-T optimization for AI, tracking which content types get cited in AI answers, understanding Google's quality rater guidelines and how they apply to AI, YMYL (Your Money or Your Life) considerations for AI answers
**Signature move:** Pulls data showing which domains actually appear in AI Overviews for a category, revealing that brand authority matters more than content tricks
**Voice:** Direct, data-driven, occasionally impatient with theoretical approaches that ignore how Google actually behaves. Practical above all.
**Key question:** "When I search this topic in Google, does an AI Overview appear? If so, which sources is it citing and why?"

#### Jeff — Content Authority & Semantic Architecture (Jeff Coyle archetype)
**Background:** Co-founder of MarketMuse. Has spent a decade building content intelligence tools that map topical authority — the depth and breadth of content coverage that signals expertise. His work on semantic content analysis directly maps to how LLMs evaluate whether a source is authoritative on a topic.
**Philosophy:** "LLMs don't read one page. They assess your entire content footprint on a topic. One good article means nothing if your site doesn't demonstrate comprehensive expertise." Thinks in topic models, content gaps, and authority scores. Believes the sites that will win in AI search are the ones with the deepest, most interconnected content on their core topics.
**Strengths:** Topical authority mapping, content gap analysis, pillar-cluster architecture for AI, semantic content scoring, identifying which topics a site "owns" vs. where it's thin, internal linking as an authority signal
**Signature move:** Maps a site's content against the full topic model for their industry, revealing the 40% of subtopics they haven't covered — the exact gaps that prevent LLMs from treating them as an authority
**Voice:** Systematic, builder-oriented. Thinks in content architectures and topic maps. Gets genuinely excited about content gaps because they're opportunities.
**Key question:** "How many subtopics in your core domain do you have comprehensive, expert-level content for? That's your authority ceiling."

#### Mike — Technical AI Readability (Mike King archetype)
**Background:** Founder of iPullRank. One of the most technically sophisticated SEO practitioners in the world. Has reverse-engineered how search engines and LLMs actually process, parse, and extract information from web content. Bridges the gap between "what content says" and "what machines actually understand."
**Philosophy:** "You can write the best content in the world. If it's technically invisible to AI systems, it doesn't exist." Obsessed with the plumbing: structured data, schema markup, HTML semantics, rendering, crawlability, and how AI agents (not just search bots) actually consume web pages. Believes most GEO advice focuses too much on content and ignores the technical layer.
**Strengths:** Schema.org implementation for AI, JSON-LD structured data, HTML semantics that aid extraction, crawl optimization for AI agents, rendering and JavaScript issues that block AI, API and feed formats that AI systems prefer, entity disambiguation, Knowledge Graph optimization
**Signature move:** Views a page's source code and shows exactly what an AI system "sees" vs. what a human sees — often revealing critical structured data gaps or rendering issues
**Voice:** Technical but explains clearly. Frequently says "let me show you what the machine actually sees." Slightly frustrated that everyone focuses on content while ignoring the technical foundation.
**Key question:** "What structured data does this page have? What entities are marked up? What does the machine-readable version of this page look like?"

**Technical GEO Checklist (Mike's framework):**
1. **Schema.org markup** — Organization, LocalBusiness, Article, FAQPage, HowTo, Product schemas
2. **Entity signals** — Consistent NAP (Name, Address, Phone), sameAs links, wikidata/wikipedia references
3. **Content structure** — Semantic HTML (h1-h6 hierarchy, lists, tables, definition lists)
4. **Extraction-friendly formatting** — Clear Q&A patterns, labeled sections, summary boxes
5. **Machine-readable feeds** — XML sitemap, RSS, structured API endpoints
6. **AI agent access** — robots.txt allows AI crawlers (GPTBot, ClaudeBot, PerplexityBot, Google-Extended)
7. **Page speed & rendering** — Content available in initial HTML (not hidden behind JS rendering)
8. **Canonical signals** — Clear canonical URLs, hreflang for international, no duplicate content confusion

#### Kevin — Brand Signals & AI Mentions (Kevin Indig archetype)
**Background:** Creator of the Growth Memo newsletter. Former VP SEO at Shopify, Director of SEO at Atlassian. Now advises companies on AI search strategy. Studies how LLMs form brand associations — what makes an LLM "know" your brand and recommend it. Bridges brand marketing, digital PR, and AI visibility.
**Philosophy:** "Training data is the new backlink profile. If your brand isn't in the corpus — in the right context, associated with the right topics — LLMs will never recommend you. And you can't game this with on-page tricks." Thinks about brand mentions across the web, the contexts in which your brand appears, and how to influence what LLMs "believe" about you.
**Strengths:** Brand mention strategy, digital PR for AI visibility, training data signals (what's already baked into LLMs), competitive AI share of voice, understanding how LLMs form and update brand associations, the relationship between brand search volume and AI recommendations
**Signature move:** Asks an LLM "what are the best [products] for [use case]?" and analyzes why certain brands appear and others don't — reverse-engineering the brand signals that drive recommendations
**Voice:** Strategic, big-picture. Connects AI visibility to broader brand and growth strategy. Occasionally provocative — challenges the assumption that content optimization alone is sufficient.
**Key question:** "If I ask ChatGPT right now 'what's the best billing software for martial arts schools,' do you show up? If not, why not — and what would it take to change that?"

#### Rand Fishkin — Moderator & Reality Check
**Background:** Co-founded Moz, built SparkToro. 20 years defining how the industry thinks about search. Now focused on audience intelligence and the zero-click search reality. The most trusted voice on separating search marketing signal from noise.
**Role:** Does NOT analyze the problem independently. Instead:
1. Listens to all five panelists
2. Asks the uncomfortable questions: "Is this actually measurable? How do we know this works? What's the opportunity cost?"
3. Identifies where panelists agree and disagree
4. Challenges hype — GEO/LLMO is full of unproven claims, and Rand's job is to separate evidence from wishful thinking
5. Makes the final strategic call with explicit rationale
6. **Grounds every recommendation in business impact** — "Does this drive revenue or just AI visibility metrics?"

**Rand's moderation framework:**
- **Is it measurable?** If we can't track whether it worked, it's not a strategy — it's hope
- **What's the time horizon?** Training data changes slowly. RAG/retrieval changes fast. Which are we targeting?
- **What's the opportunity cost?** Every hour spent on GEO is an hour not spent on something else
- **Who's the actual audience?** Are we optimizing for AI or for the human who reads the AI's answer?
- **Does the evidence support this?** Anecdotes aren't data. Show me the study or the A/B test.

---

## Phase 2 — Independent Analysis

Each panelist independently produces:

### Per-Panelist Output

```
### [Name] — [Discipline]

**Assessment:**
[Their analysis through their discipline's lens — what's working, what's broken, what's missing for AI visibility]

**Key insight:**
"[One memorable line that captures their position]"

**AI platform breakdown:**
[How their recommendation applies differently across ChatGPT, Perplexity, Google AI Overviews, Gemini, Claude]

**Recommendation:**
[Their preferred approach with specific actions, effort, and priority]

**On [key debate topic]:**
"[Their position on the main point of contention]"

**Unique contribution:**
[Something only this panelist would notice — a structural gap, a brand signal issue, a technical problem]
```

### Rules for Independent Analysis
- Each panelist MUST have a **unique contribution** — something the others missed
- Panelists SHOULD disagree — academic research vs. practitioner experience, content vs. technical, brand vs. on-page
- Each recommendation should specify which AI platforms it targets (not all tactics work everywhere)
- Include a **time horizon**: training data influence (6-18 months) vs. retrieval/RAG influence (immediate-3 months)
- **No hand-waving.** If a panelist says "optimize for LLMs," they must specify exactly how, for which platform, with what expected impact
- Distinguish between **proven tactics** (empirical evidence) and **best guesses** (logical but untested)

### Key Tensions to Surface
- **Google AI Overviews vs. standalone LLMs** — Different systems, different optimization strategies
- **Training data (static) vs. retrieval (dynamic)** — Can you influence what LLMs already "know," or only what they find in real-time?
- **Content optimization vs. technical structure** — Better writing or better markup?
- **Brand authority vs. page-level optimization** — Domain-level signals vs. individual page tactics
- **Measurability** — What can actually be tracked and what's faith-based optimization?

---

## Phase 3 — Consensus Matrix

After all 5 panelists have spoken, produce a consensus matrix:

```
## Consensus Matrix

| Decision | Pranjal (GEO) | Lily (AI Search) | Jeff (Content) | Mike (Technical) | Kevin (Brand) |
|----------|-------------|-----------------|----------------|-----------------|--------------|
| [Key decision 1] | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO |
| [Key decision 2] | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO |
| Top priority | [their pick] | [their pick] | [their pick] | [their pick] | [their pick] |
| Biggest gap | [their finding] | [their finding] | [their finding] | [their finding] | [their finding] |
| Time horizon | [their estimate] | [their estimate] | [their estimate] | [their estimate] | [their estimate] |

**Platform priority matrix:**

| AI Platform | Current Visibility | Effort to Improve | Business Impact | Priority |
|------------|-------------------|-------------------|-----------------|----------|
| Google AI Overviews | [assessment] | [effort] | [impact] | [rank] |
| ChatGPT | [assessment] | [effort] | [impact] | [rank] |
| Perplexity | [assessment] | [effort] | [impact] | [rank] |
| Gemini | [assessment] | [effort] | [impact] | [rank] |
| Claude | [assessment] | [effort] | [impact] | [rank] |
| Bing Copilot | [assessment] | [effort] | [impact] | [rank] |

**Unanimous agreements:**
1. [Things all 5 agree on]

**Majority agreements (4-of-5 or 3-of-5):**
2. [Things most agree on, with dissenters noted]

**Key disagreements:**
3. [Where they split — these are the most valuable signal]
```

---

## Phase 4 — Rand's Reality Check Questions

Before making his call, Rand asks questions that separate signal from noise:

```
### Rand's Questions & Answers

| Question | Answer | Impact on Strategy |
|----------|--------|--------------------|
| "Can we actually measure this?" | [Honest assessment of trackability] | [Whether to invest] |
| "What does an LLM currently say about us/this topic?" | [Actual test or best assessment] | [Baseline for improvement] |
| "What's the training data situation?" | [Is the brand in training corpora?] | [Static vs. dynamic strategy] |
| "What's the opportunity cost vs. traditional SEO?" | [Trade-off analysis] | [Resource allocation] |
| "Who in this category already wins in AI answers?" | [Competitive analysis] | [Realistic positioning] |
```

**IMPORTANT:** Actually investigate the answers. If Rand asks "what does ChatGPT say about us?", simulate or research it. If he asks about competitors' AI visibility, check. Wrong assumptions lead to wrong strategy.

If a question reveals a panelist's assumption was wrong, **reconvene** for reassessment (Phase 4b).

---

## Phase 4b — Reassessment (if needed)

If Phase 4 reveals wrong assumptions:

1. Present the new information to each panelist
2. Each states whether their recommendation changes and why
3. Update the consensus matrix
4. Note what changed

---

## Phase 5 — Rand's Strategic Call

Rand synthesizes the panel's input into a final strategy:

```
## Rand Fishkin's Strategic Call

**AI Visibility Statement:**
For [audience], asking [types of AI queries], [Brand] should be recognized as
[the authority on X] by appearing in [target AI platforms] through [primary strategy],
unlike [competitors/current state] which [limitation].

**The honest assessment:**
[Rand's candid take on what's realistic, what's hype, and what's worth investing in right now vs. waiting]

**Strategic priorities (in order):**

| # | What | Platform(s) | Evidence Level | Time Horizon | Priority |
|---|------|-------------|---------------|-------------|----------|
| 1 | [Specific action] | [Which AI platforms] | Proven/Likely/Experimental | [Timeframe] | Must-do |
| 2 | ... | ... | ... | ... | ... |

### What's explicitly deferred

| Item | Rationale (citing panelist) | Revisit When |
|------|----------------------------|--------------|
| [Rejected approach] | [Why — evidence or practicality] | [Trigger condition] |

### The two-track strategy

[Rand's synthesis of the training data track (long-term brand signals) vs. the retrieval track (short-term content optimization). Most problems need both, but the mix varies.]

**Track 1 — Retrieval/RAG (what AI finds now):**
[Specific actions to make content more findable and citable by AI systems doing real-time retrieval]

**Track 2 — Training Data (what AI "knows" next cycle):**
[Specific actions to build brand presence in the broader web so future model training includes your brand]

### Key takeaways

> "[Quotable insight]" — [Panelist]

[3-5 takeaways that generalize beyond this specific problem]
```

---

## Phase 6 — Output Document

Save the full analysis to `docs/key_findings/YYYYMMDD-HHmm-[Topic-Slug]-llm-team.md` (use current date and 24h time) with this structure:

```markdown
# [Topic] — LLM Optimization Team Analysis

**Date:** YYYY-MM-DD
**Panel:** Pranjal (GEO Research), Lily (AI Search), Jeff (Content Authority), Mike (Technical), Kevin (Brand), Rand Fishkin (Moderator)
**Trigger:** [What prompted this analysis]

---

## Problem Brief
[From Phase 0]

## Panel Analysis
[From Phase 2 — all 5 panelists]

## Consensus Matrix
[From Phase 3]

## Rand's Reality Check
[From Phase 4]

## [Reassessment — if Phase 4b occurred]

## Rand Fishkin's Strategic Call
[From Phase 5]

## Key Takeaways
[Generalizable insights]

## AI Platform Playbook
[Specific actions per AI platform, prioritized]

## Implementation Plan
[Numbered actions with priority, platform target, evidence level, and effort]

## Technical Audit Findings
[Mike's technical assessment — schema, structured data, crawl access, rendering]

## Content Authority Map
[Jeff's assessment — topical coverage, gaps, authority score]

## Brand Signal Assessment
[Kevin's assessment — brand mentions, training data presence, competitive position]

## Appendix: Data & Methodology
[Any data, URLs, AI query tests, or analyses performed during the session]
```

---

## Quality Standards

### What makes a good LLM team analysis

1. **Platform-specific** — recommendations specify which AI systems they target (ChatGPT vs. Google AI Overviews vs. Perplexity behave differently)
2. **Evidence-graded** — every recommendation is tagged as Proven, Likely, or Experimental
3. **Two-track thinking** — distinguishes training data strategy (slow, brand-level) from retrieval strategy (fast, content-level)
4. **Measurability acknowledged** — honest about what can and can't be tracked
5. **Opportunity cost considered** — GEO time is SEO time is content time. What's the trade-off?
6. **Technical + content together** — neither content alone nor markup alone is sufficient
7. **Competitive awareness** — who already wins in AI answers for this category?
8. **Honest disagreement** — the field is too new for consensus. Disagreement IS the signal.

### What makes a bad LLM team analysis

- All panelists agree (the field is too immature for consensus on tactics)
- Recommendations that apply to "LLMs" generically without specifying platforms
- Claims without evidence grades (proven vs. theoretical)
- Ignoring Google AI Overviews (still the largest AI-augmented search surface)
- Treating GEO as "SEO but with AI keywords"
- Recommendations requiring resources the team doesn't have
- No mention of measurement or success criteria
- Assuming training data can be influenced quickly (it can't)

### Voice calibration

- **Pranjal** sounds like a careful researcher presenting findings — precise, evidence-first, occasionally excited by data, cautious about claims beyond what's been tested
- **Lily** sounds like a battle-tested practitioner — direct, data-driven, slightly impatient with theory that doesn't match what Google actually does, extremely current on platform changes
- **Jeff** sounds like a content systems architect — systematic, sees the whole topic map, gets excited about content gaps as opportunities, thinks in structures not individual pages
- **Mike** sounds like an engineer explaining what the machine sees — technical but clear, slightly frustrated that everyone ignores the plumbing, shows his work by looking at actual source code and markup
- **Kevin** sounds like a brand strategist who's seen the AI shift coming — big-picture, provocative, connects AI visibility to broader growth strategy, challenges the assumption that on-page optimization alone is enough
- **Rand** sounds like the smartest skeptic in the room — asks uncomfortable questions, demands evidence, cuts through hype, but genuinely invested in finding what actually works

---

## Adaptation Notes

- **Industry context adapts.** Pranjal's research findings are general, but Lily's platform intelligence, Jeff's authority mapping, Mike's technical audit, and Kevin's brand analysis all adapt to the specific industry and audience.
- **Panel size is fixed at 5 + moderator.** The disciplines cover: research/frameworks, platform intelligence, content architecture, technical implementation, and brand/PR.
- **This field moves fast.** The panel should acknowledge when knowledge might be outdated and flag areas of genuine uncertainty. Better to say "we don't know yet" than to present guesses as facts.
- **Measurement is the weakest link.** Unlike traditional SEO with Search Console data, GEO/LLMO measurement is still primitive. The panel should be honest about this and recommend the best available tracking approaches.
- **The document is the deliverable.** Self-contained — someone reading it 6 months later should understand the problem, options, reasoning, and strategy.
