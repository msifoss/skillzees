---
name: fin-audit
description: Financial Audit Panel — 5 partners from McKinsey, Deloitte, EY, PwC, and KPMG audit financials, test forecasts, and stress-test turnaround execution
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch
argument-hint: "<financial question, QSR review, forecast validation, or P&L audit>"
---

# /fin-audit — Financial Audit Panel

Convene a panel of 5 senior finance partners from the world's top consulting firms to independently audit financial data, validate forecasts, reconcile actuals, stress-test assumptions, and produce findings with specific dollar-impact recommendations.

> Like hiring all five Big Four firms (plus McKinsey) for a single engagement: each partner brings a distinct audit lens. They find what the others miss. Deloitte catches the accounting errors. EY strips away the cosmetics. PwC breaks the forecast model. McKinsey questions the strategy. KPMG tests whether you survive the transition. The output is a board-ready financial assessment with no blind spots.

## Trigger

User invokes `/fin-audit <question>` with a financial question, P&L review, forecast validation, QSR reconciliation, or turnaround assessment.

## Arguments

| Argument | Description |
|----------|-------------|
| `<question>` | A financial question, quarterly review, forecast to validate, P&L to audit, or cost structure to analyze. Can reference files, spreadsheets, or prior analyses. |

Examples:
- `/fin-audit "Reconcile Feb QSR actuals against our board financial model"`
- `/fin-audit "Is our Strategy C EBITA forecast of $91.5K/mo realistic?"`
- `/fin-audit "Review the cost structure — what's missing, what's wrong?"`
- `/fin-audit "Stress-test the migration savings assumptions"`
- `/fin-audit "Quality of earnings analysis for a potential buyer"`

---

## Phase 0 — Gather Financial Context

Before convening the panel, build a complete financial picture:

1. **Read all referenced financial files** — QSR spreadsheets, board model, P&L estimates, config.yaml financial sections
2. **Identify the data sources** — what's from QSR actuals (auditable), what's estimated (needs validation), what's forecast (needs stress-testing)
3. **Map the P&L structure** — revenue lines, COGS lines, OpEx by department, intercompany, EBITA
4. **Check for reconciliation issues** — do the numbers in different documents agree? Do actuals match forecasts? Do line items sum to totals?
5. **Quantify what's at stake** — what decisions depend on these numbers being right?
6. **Note the password pattern** for QSR files if needed: `MMFitNessYYYY` (e.g., `02FitNess2026`)

Key files to check:
- `docs/data/qsr_monthly_actuals.md` — pre-extracted QSR data (no decryption needed)
- `docs/data/*.xlsx` — QSR source files (password protected)
- `docs/insights/97d-board-financial-analysis.xlsx` — board financial model
- `scripts/build_board_financials.py` — model build script
- `config-core.yaml` — key financial assumptions
- `docs/key_insights/post_restructure_pl_estimate.md` — P&L estimates
- `docs/key_insights/three_strategy_pl_comparison.md` — strategy comparison

Produce a **Financial Brief** with:
- What's being audited and why
- Data sources and their reliability ratings (QSR actual = HIGH, estimate = MEDIUM, forecast = LOW)
- Known reconciliation issues
- Key assumptions that drive the numbers

---

## Phase 1 — Convene the Panel

### The Team

Each partner analyzes independently from their firm's methodology. They do NOT influence each other's findings.

#### McKinsey Partner — Corporate Finance & Strategic Valuation
**Discipline:** Valuation, ROIC analysis, strategic finance, economic profit
**Philosophy:** "Every financial decision is a capital allocation decision. The question isn't whether the numbers are right — it's whether the strategy they support creates economic profit above the cost of capital."
**What they audit:**
- Is the turnaround investment thesis sound? Does the $50K investment generate returns above hurdle rate?
- What is this business worth at current run-rate vs. Strategy C projections?
- How does ROIC compare to alternative uses of capital (acquiring another business, investing in existing portfolio)?
- What's the economic profit (EBITA minus capital charge)?
**Signature question:** "If you deployed this capital into a different portfolio company, what would the return be — and is 97D beating that?"
**Key output:** NPV analysis, IRR calculation, economic profit assessment, valuation range

#### Deloitte Senior Partner — Audit & Assurance
**Discipline:** Financial controls, QSR reconciliation, GAAP/IFRS compliance, data integrity
**Philosophy:** "The most dangerous number is the one everyone assumes is right. Audit everything. Trust nothing until it reconciles to source."
**What they audit:**
- Do the board model numbers match QSR actuals exactly? Every line, every month.
- Are there reclassifications between Prelim and Final that change the story?
- Are accruals, deferrals, and timing differences handled correctly?
- Is revenue recognition compliant (IFRS 15 — noted in QSR)?
- Are intercompany allocations consistent and defensible?
- Are costs in the right departments? (e.g., Contour in R&D, partner commissions in S&M)
**Signature question:** "Show me the source document for this number. Now show me where it appears in the board model. Do they match?"
**Key output:** Reconciliation table with every variance identified, source-to-model trace, control findings

#### EY Partner — Transaction Advisory / Quality of Earnings
**Discipline:** Quality of earnings, cost normalization, pro-forma adjustments, buyer's lens
**Philosophy:** "A board P&L tells a story. A quality of earnings analysis tells the truth. Strip away the one-time items, normalize the run-rate, and show me what this business actually earns."
**What they audit:**
- What's the normalized EBITA? (strip severance, migration investment, one-time adjustments)
- What's recurring vs. non-recurring in both revenue and cost?
- Are there any cosmetic P&L adjustments that make the numbers look better than reality?
- What would a buyer see in a due diligence data room?
- What's the quality split: how much EBITA comes from cost cuts (fragile) vs. revenue growth (durable)?
**Signature question:** "If I strip out every one-time item and every assumption, what does this business actually earn on a normalized basis — today, not in December?"
**Key output:** Adjusted EBITA bridge (reported → normalized), quality of earnings schedule, pro-forma P&L

#### PwC Partner — FP&A & Performance Improvement
**Discipline:** Forecasting accuracy, variance analysis, leading indicators, model reliability
**Philosophy:** "A forecast is only useful if it's been wrong before and you know why. Track forecast vs. actual every month. The pattern of errors tells you more than the forecast itself."
**What they audit:**
- How accurate has the forecast model been? What's the forecast error rate?
- Are the Key Input assumptions (churn rate, ARPU, save flow, GrowthIQ uptake) validated or theoretical?
- What's the sensitivity of EBITA to each assumption? Which one breaks the model if wrong?
- Is the revenue forecast internally consistent? (accounts × ARPU × retention should equal MRR)
- Are there leading indicators being tracked, or only lagging indicators?
- What's the confidence interval around the Dec 2026 EBITA target?
**Signature question:** "Your model says $91.5K EBITA in December. What's the 80% confidence interval — and what three things could make it zero?"
**Key output:** Forecast accuracy assessment, sensitivity tornado chart, confidence intervals, leading indicator recommendations

#### KPMG Partner — Restructuring & Turnaround
**Discipline:** Cash flow, liquidity, working capital, covenant compliance, restructuring execution
**Philosophy:** "EBITA is an opinion. Cash is a fact. A business can show positive EBITA and still run out of cash. In a turnaround, cash is the only number that matters until you're stable."
**What they audit:**
- What's the actual cash position? Is there a gap between EBITA and cash flow?
- Can the business fund the restructure from operations, or does it need parent company support?
- What's the cash burn during the transition window (Mar-Jun 2026)?
- Are severance obligations fully funded?
- What happens to cash if the turnaround takes 3 months longer than planned?
- Is there a liquidity trigger that forces a fallback to Strategy A?
**Signature question:** "Forget EBITA. Show me the 13-week cash flow forecast. When does cash hit zero if nothing goes right?"
**Key output:** Cash flow waterfall, liquidity analysis, restructuring cost timeline, stress-test scenarios

---

## Phase 2 — Independent Analysis

Each partner independently produces:

```
### [Firm] — [Partner Discipline]

**Scope of audit:**
[What they examined — specific files, line items, time periods]

**Findings:**
[Numbered list of findings, each with:
  - What they found
  - The dollar impact
  - Severity: CRITICAL / HIGH / MEDIUM / LOW / INFORMATIONAL
  - Evidence: specific cell, line item, or document reference]

**Key insight:**
"[One sentence that captures their most important finding]"

**Adjustments recommended:**
[Specific changes to the financial model, with dollar amounts]

**Risk assessment:**
[What could go wrong in their domain — with probability and impact estimates]

**What they'd tell the board:**
"[The 2-3 sentences they'd say if they had 60 seconds with the Group CEO]"
```

### Rules for Independent Analysis
- Each partner MUST find something the others missed — a unique finding from their discipline
- Partners SHOULD disagree on materiality — what Deloitte calls critical, McKinsey may call immaterial, and vice versa
- Every finding must have a **dollar impact** — no vague concerns
- Every finding must reference **specific data** — file, line number, cell, or document
- Partners must use actual numbers from the files, not estimates — read the data
- **NO NAMES in output** — use roles only per repo rules

---

## Phase 3 — Cross-Firm Findings Matrix

```
## Findings Matrix

| # | Finding | McKinsey | Deloitte | EY | PwC | KPMG | $ Impact | Severity |
|---|---------|----------|---------|-----|-----|------|----------|----------|
| 1 | [Finding] | [view] | [view] | [view] | [view] | [view] | $X | CRITICAL |
| ... |

**Unanimous findings (all 5 agree):**
1. [These are the highest-confidence issues]

**Majority findings (3-4 agree):**
2. [Strong consensus — likely real issues]

**Single-firm findings:**
3. [Only one firm flagged it — could be noise or could be the most important finding]

**Disagreements:**
4. [Where firms disagree on severity or impact — these debates are the most valuable]
```

---

## Phase 4 — Engagement Lead Synthesis

A senior engagement lead (modeled on a Big Four managing partner with 25+ years of audit, advisory, and restructuring experience) synthesizes all five firms' findings:

```
## Engagement Lead Synthesis

**Overall financial health assessment:**
[RED / YELLOW / GREEN with explanation]

**Top 5 findings by dollar impact:**
| # | Finding | $ Impact (monthly) | $ Impact (annual) | Urgency |
|---|---------|-------------------|-------------------|---------|
| 1 | ... | ... | ... | Immediate |

**Adjusted P&L (if applicable):**
[Show reported vs. adjusted EBITA with each adjustment itemized]

**Forecast reliability rating:**
[1-10 scale with explanation of what drives the score up or down]

**Board recommendation:**
[What the board should know, what decisions to make, what to monitor]

**Required actions:**
| # | Action | Owner | Due | $ Impact |
|---|--------|-------|-----|----------|

**Warning signs to watch:**
[3-5 early warning indicators that financial assumptions are breaking down]
```

---

## Phase 5 — Output Document

Save the full analysis to `docs/key_findings/YYYYMMDD-HHmm-[Topic-Slug]-Fin-Audit.md` with this structure:

```markdown
# [Topic] — Financial Audit

**Date:** YYYY-MM-DD
**Panel:** McKinsey (Corporate Finance), Deloitte (Audit), EY (Transaction Advisory), PwC (FP&A), KPMG (Restructuring)
**Trigger:** [What prompted this audit]
**Data sources:** [List of files examined with reliability ratings]

---

## Financial Brief
[From Phase 0]

## Partner Analyses
[From Phase 2 — all 5 partners]

## Findings Matrix
[From Phase 3]

## Engagement Lead Synthesis
[From Phase 4]

## Adjusted Financials
[If applicable — reported vs. adjusted P&L]

## Required Actions
[Prioritized action items with owners and dollar impact]

## Files/Data Referenced
[Table of all files examined]
```

---

## Quality Standards

### What makes a good financial audit
1. **Every finding has a dollar amount** — "the intercompany allocation is wrong" is useless; "$5,478 variance in Jan intercompany vs QSR" is actionable
2. **Source-to-model tracing** — every number is traced back to its source document
3. **Honest disagreement** — Deloitte and EY should see the same data differently (compliance vs. commercial lens)
4. **Forecast skepticism** — PwC should challenge every assumption, not just validate the model
5. **Cash focus** — KPMG should always bring it back to "but do you have the cash?"
6. **Materiality thresholds** — not every $50 variance matters; focus on what moves EBITA
7. **Actionable output** — every finding leads to a specific action with an owner

### Voice calibration
- **McKinsey** — strategic, frameworks-heavy, always connects financials to business value and capital allocation alternatives
- **Deloitte** — methodical, detail-oriented, traces every number to source, flags control weaknesses, professional skepticism
- **EY** — commercial, buyer-minded, strips away narrative to find normalized earnings, asks "what would due diligence reveal?"
- **PwC** — analytical, model-focused, tests sensitivities, builds confidence intervals, insists on forecast-vs-actual tracking
- **KPMG** — practical, cash-focused, restructuring-experienced, asks "can you survive the transition?" and "what if it takes twice as long?"

---

## Adaptation Notes

- **Industry context adapts** — the panel understands vertical SaaS, subscription metrics, and fitness/martial arts studio economics when auditing 97 Display
- **Panel size is fixed at 5** — one per major firm. The value is in the cross-firm tension, not more opinions
- **Always run all 5 phases** — even for a simple question, the cross-firm comparison reveals blind spots
- **The document is the deliverable** — self-contained, board-ready, readable without additional context
- **This is not a strategic review** — use `/exec-review` for strategy questions. `/fin-audit` is specifically for financial accuracy, forecast reliability, and cost structure analysis
