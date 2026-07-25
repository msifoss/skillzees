---
name: radar
description: Strategic radar — assess current state, prioritize opportunities, and maintain the backlog. Pulls analytics, reads project progress, and writes a prioritized "what's next" assessment.
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Agent, Write, Edit, WebFetch, WebSearch, mcp__anny__ga4_traffic_summary, mcp__anny__search_console_summary, mcp__anny__search_console_top_queries, mcp__anny__search_console_top_pages, mcp__anny__ga4_top_pages, mcp__anny__ga4_realtime
argument-hint: "[scan | log | review <item>] or no args for full radar"
---

# /radar — Strategic Radar & Backlog

Pulls analytics, reads project state, and produces a prioritized assessment of what to do next. Maintains `docs/sprints/backlog.md` as the living strategic backlog.

> The difference between /sitrep and /radar: sitrep answers "where are we?" — radar answers "where should we go next and why?"

## Trigger

- `/radar` — Full scan + display prioritized opportunities (does NOT write to file)
- `/radar scan` — Same as no args. Pull data, assess, display.
- `/radar log` — Full scan + write/update `docs/sprints/backlog.md`
- `/radar log "thought or observation"` — Append a specific strategic thought to the backlog without running a full scan
- `/radar review <item>` — Deep-dive on a specific backlog item (pull more data, assess feasibility, refine priority)

## Process

### Step 1 — Gather Signals

Pull from every available source. Skip gracefully if unavailable.

**Analytics (if MCP available):**
- `mcp__anny__ga4_traffic_summary` (last_28_days) — traffic by source, bounce rates
- `mcp__anny__search_console_summary` (last_28_days) — clicks, impressions, CTR, position
- `mcp__anny__search_console_top_queries` (last_28_days, limit 25) — what people search for
- `mcp__anny__search_console_top_pages` (last_28_days, limit 25) — which pages get impressions
- Compare against previous backlog entries if they exist (trend detection)

**Project state:**
- `docs/sprints/progress.md` — what's been done, what's deferred
- `docs/sprints/backlog.md` — existing backlog items (if file exists)
- `config.yaml` — current config state (noindex, CTAs, storylane demos, etc.)
- `git log --oneline -10` — recent momentum direction
- `git status` — uncommitted work

**Brand & strategy:**
- `docs/brand/PAGES.md` — page roles and funnel
- `docs/brand/POSITIONING.md` — current positioning (first 30 lines for context)

**Content inventory:**
- Count of blog posts (`ls src/content/blog/ | wc -l`)
- Count of total pages (from last build output or `progress.md`)

### Step 2 — Assess & Prioritize

Categorize every opportunity into one of these buckets:

| Bucket | Description | Examples |
|--------|-------------|---------|
| **Launch blockers** | Must be done before production domain switch | noindex flip, DNS, SSL, redirects verification |
| **High-leverage SEO** | High impressions + low CTR/position = easy wins | Blog refreshes, title rewrites, content depth |
| **Conversion optimization** | Improve the path from visitor to form submission | CTA placement, form UX, proof positioning |
| **Content moat** | Expertise content competitors can't replicate | Data-driven posts, proprietary insights |
| **Infrastructure** | Technical improvements that enable future work | Tracking, schema markup, performance |
| **Emerging channels** | New traffic sources worth investing in | AI search, referral partnerships, social |
| **Deferred** | Explicitly parked — too risky, too early, or blocked | Blog consolidation, interactive calculators |

For each opportunity, assess:

1. **Impact** (High / Medium / Low) — How much does this move the needle?
2. **Effort** (Hours / Days / Sprint) — How long to execute?
3. **Blocked by** — What prevents starting right now?
4. **Data** — What numbers support this priority? (impressions, CTR, traffic, conversion rate)
5. **Decay** — Does this opportunity get worse if we wait? (SEO positions can slip, seasonal windows close)

### Step 3 — Produce the Radar Report

Display to screen:

```markdown
# Radar — [Date]

## Signal Summary
| Metric | Current | Trend |
|--------|---------|-------|
| Organic clicks (28d) | X | — |
| Impressions (28d) | X | — |
| Overall CTR | X% | — |
| Avg position | X | — |
| GA4 sessions (Google) | X | — |
| GA4 sessions (direct) | X | — |
| AI referrals (ChatGPT) | X | — |
| Blog posts | X | — |
| Total pages | X | — |
| Noindex | true/false | — |

## Top 5 Priorities

### 1. [Title] — [Impact: High] [Effort: X] [Bucket]
**Why now:** [1-2 sentences with data]
**Blocked by:** [nothing / specific blocker]
**First move:** [concrete next action]

### 2. ...
(repeat for top 5)

## Full Backlog (by bucket)

### Launch Blockers
| # | Item | Impact | Effort | Blocked By | Data |
|---|------|--------|--------|------------|------|

### High-Leverage SEO
(same table format)

### Conversion Optimization
...

### Content Moat
...

### Infrastructure
...

### Emerging Channels
...

## Parked (Deferred)
| Item | Why Deferred | Revisit When |
|------|-------------|--------------|

## Changes Since Last Radar
[If previous backlog exists: what moved, what's new, what was completed]
```

### Step 4 — Write to Backlog (if `log` mode)

Write or update `docs/sprints/backlog.md` with the full radar output. The file format:

```markdown
# Strategic Backlog

> Last updated: YYYY-MM-DD
> Generated by /radar — prioritized opportunities with data and reasoning

---

## Signal Summary
[Current metrics snapshot — serves as timestamp for when priorities were assessed]

## Active Priorities (Ranked)
[Top items with full reasoning]

## Backlog by Bucket
[All items organized by category]

## Parked (Deferred)
[Items explicitly not being worked on, with reasoning and revisit triggers]

## Radar Log
[Reverse-chronological entries — dated strategic observations, insights, and priority shifts]

### YYYY-MM-DD — [Title]
[Strategic thought, data point, or priority change with reasoning]
```

The **Radar Log** section at the bottom is append-only — new entries go at the top of the section. This creates a strategic decision journal that explains *why* priorities shifted over time.

When updating an existing backlog:
- Update the Signal Summary with fresh data
- Re-rank Active Priorities based on new data
- Move completed items to `progress.md` (don't delete — note completion)
- Add a Radar Log entry explaining what changed and why
- Keep Parked items unless conditions have changed

### Step 5 — Quick Log Mode

If invoked as `/radar log "some thought"`:
- Read existing `docs/sprints/backlog.md`
- Append a new dated entry to the Radar Log section
- Do NOT run a full scan — just log the thought
- Example: `/radar log "ChatGPT referrals doubled this week — worth investigating /llm-team analysis"`

## Integration with Other Skills

| Skill | How Radar Helps |
|-------|----------------|
| `/webgeni` | Reads backlog to plan sprints — backlog is the input, sprint is the execution |
| `/webby start` | Reads top priorities from backlog for morning briefing |
| `/sitrep` | Sitrep references backlog for "next actions" section |
| `/marketing-team` | Radar findings can trigger panel questions |
| `/webgeni plan` | Sprint planning pulls from active priorities |

## Quality Standards

### What makes a good radar
1. **Data-backed priorities.** Every item cites specific numbers (impressions, CTR, sessions, position).
2. **Honest about blockers.** If something can't start, say why clearly.
3. **Effort estimates are realistic.** "Hours" means one focused session. "Days" means 2-3 sessions. "Sprint" means a full agent-assisted batch.
4. **Decay awareness.** Flag opportunities that get worse if delayed (seasonal content, slipping positions).
5. **Connects to revenue.** Every priority should trace (even indirectly) to "more qualified visitors" or "higher conversion rate."
6. **Actionable first moves.** Each priority has a concrete "first move" — not "investigate further" but "run /marketing-team on X" or "deep-refresh post Y."

### What makes a bad radar
- Priorities without data ("we should probably do X")
- Everything is "high priority" (if everything is urgent, nothing is)
- No blockers identified (there are always blockers — be honest)
- Backlog items with no "first move" (analysis paralysis)
- Ignoring what was deferred and why (repeating rejected ideas)
