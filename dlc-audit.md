# AI-DLC Compliance Audit

Usage: `/dlc-audit [action]`

**Actions:**
- `assess` (default) — Run the full 8-dimension compliance assessment
- `init` — Detect missing foundational docs and create skeleton templates
- `full` — Run `init` first (create anything missing), then `assess`

**Arguments:** $ARGUMENTS

---

## Purpose

Deep assessment of AI-DLC (AI-Driven Development Lifecycle) process adherence. Goes beyond document existence checks to evaluate whether practices are actually being followed.

> `/motherhen` checks "do the docs exist?" — `/dlc-audit` checks "are we actually following the practices?"

---

## Instructions for Claude

### 0. Parse Arguments

Extract `action` from: `$ARGUMENTS`

If empty or unrecognized, default to `assess`.

---

## Phase 1 — Detect & Gather

Read project state files to understand the current repo:

**Project identity (read if they exist):**
- `CLAUDE.md` — architecture, conventions, deployment state
- `CHANGELOG.md` — version history
- `pyproject.toml` or `package.json` — project metadata
- `SECURITY.md` — security controls

**Git state (run these):**
```bash
# Recent commits (bolt cadence visibility)
git log --oneline -20

# Working tree status
git status --short

# Latest tag
git describe --tags --abbrev=0 2>/dev/null

# Captain's log recency
ls -lt docs/captains_log/ 2>/dev/null | head -5
```

**Check for the 14 foundational documents:**

| # | Document | Path |
|---|----------|------|
| 1 | Requirements | `docs/REQUIREMENTS.md` |
| 2 | Traceability Matrix | `docs/TRACEABILITY-MATRIX.md` |
| 3 | User Stories | `docs/USER-STORIES.md` |
| 4 | AI Context File | `CLAUDE.md` |
| 5 | Security Controls | `SECURITY.md` |
| 6 | PM Framework | `docs/pm/FRAMEWORK.md` |
| 7 | Solo+AI Workflow Guide | `docs/standards/SOLO-AI-WORKFLOW-GUIDE.md` |
| 8 | CI/CD Deployment Proposal | `docs/standards/CICD-DEPLOYMENT-PROPOSAL.md` |
| 9 | Multi-Developer Guide | `docs/standards/MULTI-DEVELOPER-GUIDE.md` |
| 10 | Infrastructure Playbook | `docs/standards/INFRASTRUCTURE-PLAYBOOK.md` |
| 11 | Cost Management Guide | `docs/standards/COST-MANAGEMENT-GUIDE.md` |
| 12 | Security Review Protocol | `docs/standards/SECURITY-REVIEW-PROTOCOL.md` |
| 13 | Ops Readiness Checklist | `docs/standards/OPS-READINESS-CHECKLIST.md` |
| 14 | AI-DLC Case Study | `docs/standards/CALLHERO-AI-DLC-CASE-STUDY.md` |

Check existence of each. Record which exist and which are missing.

---

## Phase 2 — Foundation Check (init and full modes only)

**Skip this phase if action is `assess`.**

For each of the 14 foundational documents that is MISSING, create a skeleton template. These templates contain structure and TODO markers — never generate fake content.

Each template should:
- Have a clear title and purpose statement
- Include section headers appropriate to the document type
- Mark every section body with `<!-- TODO: ... -->` instructions explaining what to fill in
- Include examples of what good content looks like (as comments, not as actual content)

### Template Specifications

**If `docs/REQUIREMENTS.md` is missing:**
Create with sections: Purpose, Functional Requirements (FR-001 template), Non-Functional Requirements (NFR-001 template), Security Requirements (SEC-001 template). Include a note about ID numbering convention.

**If `docs/TRACEABILITY-MATRIX.md` is missing:**
Create with a table template: `| Req ID | Description | Code Path | Test File | Deploy Artifact | Status |` and instructions for maintaining bidirectional traceability.

**If `docs/USER-STORIES.md` is missing:**
Create with the format: `As a [role], I want [capability], so that [benefit]` plus acceptance criteria template.

**If `CLAUDE.md` is missing:**
Create with sections: What This Project Does, Architecture, Project Structure, Dev Environment, Conventions, Current Status. Note that this is the persistent AI context file.

**If `SECURITY.md` is missing:**
Create with sections: Security Model, Authentication, Authorization, Data Protection, Vulnerability Reporting, Audit History.

**If `docs/pm/FRAMEWORK.md` is missing:**
Create `docs/pm/` directory and FRAMEWORK.md with sections: Sprint Model (bolt cadence), Sizing Convention (S/M/L/XL), Backlog Management, Blocker Tracking, Retrospectives.

**If `docs/standards/SOLO-AI-WORKFLOW-GUIDE.md` is missing:**
Create with sections: Bolt-Driven Development, Five Questions Pattern, Context Hygiene, Captain's Logs, Session Lifecycle.

**If `docs/standards/CICD-DEPLOYMENT-PROPOSAL.md` is missing:**
Create with sections: Current State (manual deploy), Proposed Pipeline, Environments, Rollback Strategy, Prerequisites.

**If `docs/standards/MULTI-DEVELOPER-GUIDE.md` is missing:**
Create with sections: Branch Strategy, Code Review Process, Shared Context Management, Onboarding Checklist.

**If `docs/standards/INFRASTRUCTURE-PLAYBOOK.md` is missing:**
Create with sections: Cloud Provider, IaC Tooling, Networking, IAM Patterns, Monitoring, Disaster Recovery.

**If `docs/standards/COST-MANAGEMENT-GUIDE.md` is missing:**
Create with sections: Budget, Cost Monitoring, Alert Thresholds, Kill Switch, Cost Review Cadence.

**If `docs/standards/SECURITY-REVIEW-PROTOCOL.md` is missing:**
Create with sections: Review Cadence, Five-Persona Review Process, Finding Severity Levels, Disposition Workflow, Review Archive.

**If `docs/standards/OPS-READINESS-CHECKLIST.md` is missing:**
Create with sections: Monitoring, Alerting, Runbooks, Incident Response, Backup & Recovery, scored checklist format.

**If `docs/standards/CALLHERO-AI-DLC-CASE-STUDY.md` is missing:**
Create with sections: Executive Summary, Project Overview, AI-DLC Phase Mapping, Shortcomings, Lessons Learned. Note: this is project-specific; for non-CallHero repos, skip this document or create a generic AI-DLC assessment template instead.

After creating templates, report what was created:

```
### Foundation Bootstrap
Created [N] foundational documents:
- docs/REQUIREMENTS.md (skeleton)
- docs/standards/COST-MANAGEMENT-GUIDE.md (skeleton)
- ...

All documents contain TODO markers. Fill in project-specific content before running `assess`.
```

If all 14 documents already exist, report:
```
### Foundation Status: Complete
All 14 foundational documents exist. Proceeding to assessment.
```

---

## Phase 3 — Deep Assessment (assess and full modes only)

**Skip this phase if action is `init`.**

Evaluate 8 dimensions of AI-DLC process adherence. For each dimension, read the relevant files, run checks, and assign a letter grade.

---

### Dimension 1: Inception Quality

**What to check:**
- Read `docs/REQUIREMENTS.md` — do requirements have IDs (FR-###, NFR-###, SEC-###)?
- Read `docs/USER-STORIES.md` — do stories have acceptance criteria?
- Check `CLAUDE.md` — are architecture decisions documented with rationale?
- Check for ADR (Architecture Decision Record) patterns in docs or captain's logs

**Grading:**
- **A** — Requirements have IDs, user stories have acceptance criteria, architecture decisions are documented with rationale, trade-offs are explicit
- **B** — Requirements and user stories exist with IDs and structure, architecture is documented but rationale may be thin
- **C** — Documents exist but are incomplete (missing IDs, no acceptance criteria, architecture is a list without rationale)
- **F** — No requirements doc, or requirements are just a wish list without structure

---

### Dimension 2: Construction Discipline

**What to check:**
- `git log --oneline -50` — is bolt cadence visible? (Look for commit messages referencing bolts, sprints, or structured work units)
- Check `docs/captains_log/` — do logs exist for recent sessions? Do they show Five Questions pattern usage?
- Check if code changes have corresponding test changes: `git log --oneline --name-only -20` — do commits that touch source code also touch `tests/`?
- Get actual test count if possible

**Grading:**
- **A** — Bolt cadence clear in git history, captain's logs with Five Questions evidence, code+test changes are paired, test count matches docs
- **B** — Structured commit history, tests exist and pass, captain's logs present but may not show Five Questions consistently
- **C** — Tests exist but are sparse or disconnected from code changes, commit history is unstructured, no captain's logs
- **F** — No tests, no structured development cadence, no session documentation

---

### Dimension 3: Security Rigor

**What to check:**
- Check `docs/security/` and `docs/reviews/` for dated audit files — when was the last review?
- Read most recent security review — does it cover all code paths? Are findings categorized by severity?
- Check `SECURITY.md` — are findings tracked with dispositions (fixed, accepted, deferred)?
- Look for deferred items — are they re-evaluated in subsequent reviews?
- `git log --since="30 days ago" --oneline -- "*.py" "*.js" "*.ts"` — code changes since last review?

**Grading:**
- **A** — Review within 30 days (or no code changes since), all code paths covered, findings have dispositions, deferred items are tracked and re-evaluated
- **B** — Review exists and covers main paths, findings are categorized, some deferred items may lack re-evaluation dates
- **C** — Review exists but is stale (>60 days with code changes), or findings lack dispositions
- **F** — No security review, or review is >90 days old with significant code changes

---

### Dimension 4: Ops Readiness Depth

**What to check:**
- Read `docs/standards/OPS-READINESS-CHECKLIST.md` — what's the current score?
- Check if every function/service has corresponding monitoring (cross-reference CLAUDE.md with alarm configuration)
- Check if runbook exists and has recovery procedures (not just "restart the service")
- Check if monitoring covers critical paths

**Grading:**
- **A** — Checklist score >=95%, every function has alarms, runbook has tested recovery procedures with step-by-step commands, dashboards exist
- **B** — Checklist score >=90%, most functions have alarms, runbook exists with procedures
- **C** — Checklist score 70-89%, some functions lack monitoring, runbook is thin or untested
- **F** — Checklist score <70%, no runbook, no alarms, or no monitoring

---

### Dimension 5: Traceability Completeness

**What to check:**
- Read `docs/REQUIREMENTS.md` — collect all FR-### IDs
- Read `docs/TRACEABILITY-MATRIX.md` — check if every FR-### appears
- Look for orphan requirements: FRs in requirements doc not in the matrix
- Look for orphan tests: test files not referenced by any requirement
- Check if the matrix has code paths, test files, AND deploy artifacts for each FR

**Grading:**
- **A** — Every FR has code + test + deploy refs in the matrix, no orphan requirements, no orphan tests, matrix is current
- **B** — Most FRs are traced, matrix exists and is mostly complete, minor gaps
- **C** — Matrix exists but has significant gaps (>20% of FRs untraced), or is clearly stale
- **F** — No traceability matrix, or matrix covers less than half of requirements

---

### Dimension 6: Context Hygiene

**What to check:**
- Read `CLAUDE.md` — check date references, test counts, deploy counts. Are they current?
- Compare CLAUDE.md test count against actual test count
- Check `docs/captains_log/` — are there logs for recent sessions (within last 7 days)?
- Check if `CHANGELOG.md` has an `[Unreleased]` section with current work

**Grading:**
- **A** — CLAUDE.md has accurate metrics (test count within +/-2, deploy count current, dates within 3 days), captain's logs exist for recent sessions, changelog is current
- **B** — CLAUDE.md is mostly accurate (metrics within +/-5), captain's logs exist but may be sparse, changelog has unreleased section
- **C** — CLAUDE.md has stale metrics (off by >5) or stale dates (>7 days), captain's logs are sporadic
- **F** — CLAUDE.md has inaccurate information, no captain's logs, changelog is abandoned

---

### Dimension 7: Cost Awareness

**What to check:**
- Check if cost tracking is IMPLEMENTED (not just documented): look for cost-related functions, metrics, budget definitions in infrastructure code
- Check `docs/standards/COST-MANAGEMENT-GUIDE.md` — does it have actual numbers, not just placeholders?
- Look for budget alerts in infrastructure templates or docs
- Check for kill switch: search for kill-switch script or documented emergency cost procedure
- Look for cost trend visibility: dashboards, reports, or CLI tools

**Grading:**
- **A** — Cost tracking implemented in code (not just docs), budget alerts configured, kill switch exists, cost trend is visible via dashboard or reports
- **B** — Cost tracking documented with actual numbers, budget exists, some monitoring in place
- **C** — Cost management guide exists but is generic/placeholder, no automated tracking
- **F** — No cost awareness documentation or tooling

---

### Dimension 8: Human-AI Collaboration Quality

**What to check:**
- Read recent captain's logs — is there evidence of human decisions (not just "AI did X")? Look for phrases like "decided to", "chose", "overrode", "reviewed and approved"
- Check security reviews — are findings human-triaged (marked as accepted/deferred by a human, not just auto-generated)?
- Check deploy history — are deploys human-approved?
- Look for evidence the human is steering, not just accepting: architecture decisions with rationale, rejected AI suggestions, scope decisions

**Grading:**
- **A** — Captain's logs show clear human decision-making, security findings are human-triaged with rationale, deploys have human approval evidence, architecture choices show human judgment
- **B** — Human decisions are visible in some logs, security reviews exist with dispositions, deploys are generally human-initiated
- **C** — Logs exist but read like AI autopilot output (no human voice), security findings lack human triage, deploys appear automated without review
- **F** — No evidence of human decision-making in the development process

---

## Phase 4 — Present Dashboard

Format results as a compliance report:

```
## AI-DLC Compliance Report
### Generated: <date>
### Repository: <repo name from CLAUDE.md or git remote>

### Foundation Status
| # | Document | Status | Path |
|---|----------|--------|------|
| 1 | Requirements | EXISTS / CREATED / MISSING | docs/REQUIREMENTS.md |
| 2 | Traceability Matrix | EXISTS / CREATED / MISSING | docs/TRACEABILITY-MATRIX.md |
| ... | ... | ... | ... |

[N]/14 foundational documents present.

### Process Adherence (8 Dimensions)
| # | Dimension | Grade | Details |
|---|-----------|-------|---------|
| 1 | Inception Quality | A/B/C/F | [one-line summary] |
| 2 | Construction Discipline | A/B/C/F | [one-line summary] |
| 3 | Security Rigor | A/B/C/F | [one-line summary] |
| 4 | Ops Readiness Depth | A/B/C/F | [one-line summary] |
| 5 | Traceability Completeness | A/B/C/F | [one-line summary] |
| 6 | Context Hygiene | A/B/C/F | [one-line summary] |
| 7 | Cost Awareness | A/B/C/F | [one-line summary] |
| 8 | Human-AI Collaboration | A/B/C/F | [one-line summary] |

**Overall Grade: [A-F]**
```

### Overall Grade Calculation

- **A** — All 8 dimensions are A or B, with at least 5 A's
- **B** — All 8 dimensions are A, B, or C, with at least 5 A/B's
- **C** — Any dimension is C but none are F, or fewer than 5 A/B's
- **F** — Any dimension is F

---

## Phase 5 — Action Items & Offer to Fix

After the dashboard, list specific actions sorted by urgency:

```
### Action Items

**Critical (grade F — fix immediately):**
- [Dimension]: [specific action with file path and what to change]

**Improvement (grade C — address soon):**
- [Dimension]: [specific action]

**Polish (grade B — optional refinement):**
- [Dimension]: [specific action]

**Exemplary (grade A — maintain):**
- [Dimension]: [brief confirmation of what's working well]
```

Then offer the user options:

1. **Fix all items now** — work through Critical + Improvement items
2. **Fix critical only** — just the F-grade items
3. **Just the report** — no changes, informational only
4. **Open a bolt** — if enough items exist, create a new bolt to address them

If the user chooses to fix, work through items by priority (F first, then C), updating grades as each is resolved.

---

## Important Notes

- **Repo-agnostic:** This command works on any repo, not just CallHero. Foundation paths are standard conventions. Assessment evaluates whatever exists.
- **Non-destructive:** `init` mode never overwrites existing files. It only creates files that are missing.
- **Honest grading:** Don't inflate grades. If a practice is documented but not followed, that's a C, not a B. If documents exist but are stale placeholders, that's a C or F.
- **Complement to /motherhen:** Motherhen checks project-specific health (test counts, sprint tracking, release hygiene). DLC-audit checks framework-level process adherence. They don't overlap — they complement.
- **Foundation doc #14 (Case Study):** For non-CallHero repos, skip `CALLHERO-AI-DLC-CASE-STUDY.md` and count foundation as /13 instead of /14.
