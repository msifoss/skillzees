# Cost Estimate for Development Work

Usage: `/cost-estimate [scope]`

**Arguments:** $ARGUMENTS

---

## Purpose

Produces a development cost/effort estimate following the callhero standard established in `docs/budget/DEVELOPMENT-COST-ESTIMATE.md`. Breaks work down into T-shirt sizes, maps to hours, and provides a realistic timeline accounting for AI-pair productivity multipliers.

---

## Instructions for Claude

### 0. Parse Arguments

Extract `scope` from: `$ARGUMENTS`

- If scope is a feature description, estimate that feature
- If scope is `backlog`, estimate the entire backlog
- If scope is a file path or ticket reference, estimate that work item
- If no scope, ask the user what to estimate

### 1. Analyze the Work

Read all relevant context:
- Feature requirements (from user input, tickets, or backlog)
- Existing codebase to understand integration points
- Test coverage requirements
- Infrastructure changes needed
- Documentation requirements
- Security review needs

### 2. Break Down Into Tasks

Decompose into concrete tasks with T-shirt sizes:

| Size | Hours (Solo Dev) | Hours (AI Pair) | Description |
|------|-------------------|------------------|-------------|
| **S** | 1-2 hours | 15-30 min | Single file, simple logic |
| **M** | 3-6 hours | 1-2 hours | 2-5 files, moderate complexity |
| **L** | 8-16 hours | 3-6 hours | 5-15 files, cross-cutting |
| **XL** | 16-40 hours | 6-16 hours | Multi-day, architectural |

### 3. Generate Estimate

```markdown
# Development Cost Estimate: [Feature/Scope]

**Date:** [today]
**Estimator:** Claude (AI-assisted)
**Confidence:** [Low/Medium/High]

---

## Task Breakdown

| # | Task | Size | Solo Hours | AI Pair Hours | Dependencies |
|---|------|------|------------|---------------|--------------|
| 1 | [task] | [S/M/L/XL] | [hours] | [hours] | [deps] |
| 2 | [task] | [size] | [hours] | [hours] | [deps] |
| | **Total** | | **[hours]** | **[hours]** | |

## Timeline

| Phase | Duration (AI Pair) | Tasks |
|-------|-------------------|-------|
| Phase 1 | [time] | #1, #2 (parallelizable) |
| Phase 2 | [time] | #3 (depends on Phase 1) |
| Review & Deploy | [time] | Security review, testing, deployment |
| **Total** | **[time]** | |

## Assumptions
- [List assumptions about scope, complexity, external dependencies]

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| [risk] | [impact] | [mitigation] |

## Infrastructure Cost Impact
- Monthly cost delta: [+$X or no change]
- One-time costs: [if any]
```

### 4. Compare with Callhero Benchmarks

Reference callhero's actual delivery data:
- Bolt 1-3 (core pipeline): ~3 days AI pair → 3 Lambda handlers, 21 tests, full IaC
- Bolt 4-9 (features + ops): ~3 days AI pair → monitoring, canary, weekly report, multi-object, cost tracking
- Bolt 10-13 (Phase 2): ~3 days AI pair → RDS, VPC, analytics, transcript search
- Bolt 14-16 (hardening): ~2 days AI pair → CostMonitor, kill switch, security fixes, production readiness

Total: ~11 working days to build a production-grade serverless system with 101 tests, 155 security findings resolved, 7 Lambda functions, and comprehensive documentation.

Use this as calibration for estimates.
