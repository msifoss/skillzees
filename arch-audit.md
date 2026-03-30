# Multi-Persona Architectural Audit

Usage: `/arch-audit [options]`

**Arguments:** $ARGUMENTS

---

## Purpose

Conducts a deep architectural audit of the codebase from multiple staff-engineer perspectives. Each persona independently evaluates architecture, identifies structural risks, and proposes improvements. Produces current-state Mermaid diagrams, a unified findings matrix, and suggested backlog items.

---

## Instructions for Claude

### 0. Parse Arguments

Extract parameters from: `$ARGUMENTS`

**Parameters:**

| Parameter | Format | Default | Description |
|-----------|--------|---------|-------------|
| `depth` | `depth:deep` | `strategic+tactical` | `deep` = code-level citations with file:line. `strategic+tactical` = arch observations + key code examples. `strategic` = architecture-only, no code diving. |
| `focus` | `focus:auth` | full codebase | Narrow all personas to a specific subsystem for extra-deep analysis |
| `persona` | `persona:larson` | all | Run only one persona's analysis |
| `personas` | `personas:larson,stripe,cloudflare` | `larson,spacex,aws,anthropic` | Custom persona panel (comma-separated). See Persona Library below. |

**Examples:**
- `/arch-audit` — full audit, all personas, strategic+tactical depth
- `/arch-audit depth:deep` — full audit with code-level citations
- `/arch-audit focus:auth depth:deep` — deep dive on auth subsystem
- `/arch-audit persona:aws` — only the AWS perspective
- `/arch-audit personas:larson,stripe,cloudflare depth:strategic` — custom panel, strategic depth

### 1. Read the Codebase

Before auditing, build a comprehensive understanding of the system:

**Always read:**
- `CLAUDE.md` — architecture, conventions, current state
- `README.md` — public-facing description
- `SECURITY.md` — security controls and known limitations
- Project config (`pyproject.toml`, `package.json`, `Cargo.toml`, etc.)

**Then read the architecture:**
- Application entry point and factory
- Core infrastructure (DB, auth, middleware, config)
- Module/service boundaries
- Route definitions (all endpoints)
- Data models and migrations
- Test infrastructure

**At `deep` depth, additionally read:**
- Every repository/service file
- All middleware and dependency injection
- Error handling chains
- Configuration validation

**If `focus` is set:**
- Read the focused subsystem exhaustively
- Read adjacent subsystems for boundary analysis
- Read tests covering the focused area

### 2. Generate Current-State Architecture Diagrams

Create Mermaid diagrams in `docs/architecture/`. These represent the system as it exists today.

**Required diagrams:**

#### a. C4 Context Diagram (`docs/architecture/c4-context.md`)
System context: the application and its external dependencies (databases, clients, etc.)

#### b. C4 Container Diagram (`docs/architecture/c4-container.md`)
Internal containers: app server, database, background workers, etc.

#### c. Module Dependency Graph (`docs/architecture/module-dependencies.md`)
How modules depend on core and on each other. Show plugin boundaries.

#### d. Request Flow Sequence (`docs/architecture/request-flow.md`)
Sequence diagram for a typical authenticated, tenant-scoped request showing the full dependency chain.

#### e. Data Model ER Diagram (`docs/architecture/data-model.md`)
Entity-relationship diagram of all models with tenant_id relationships.

**Format each diagram file as:**
```markdown
---
type: architecture-diagram
diagram: [c4-context|c4-container|module-dependencies|request-flow|data-model]
generated: YYYY-MM-DD
version: X.Y.Z
generator: /arch-audit
---

# [Diagram Title]

## Description
[1-2 sentence description of what this diagram shows]

## Diagram

```mermaid
[diagram code]
```

## Notes
[Any caveats, simplifications, or things not shown]
```

### 3. Conduct Persona Analyses

Each persona reviews independently. Do NOT let one persona's findings influence another.

**Finding format (per persona):**

At `deep` depth, each finding includes:
- **Title** — concise name
- **Severity** — Critical / High / Medium / Low
- **Effort** — S (< 1hr) / M (< half day) / L (~ 1 day) / XL (multi-day)
- **Description** — what the issue is and why it matters
- **Location** — file:line references
- **Recommendation** — specific refactor or change proposed

At `strategic+tactical` depth:
- Same as deep but Location shows file-level references (no line numbers), and 3-5 findings per persona

At `strategic` depth:
- Title, Severity, Effort, Description, Recommendation only. No code references. 3-5 findings per persona.

**Finding count targets:**
- `deep`: 5-10 findings per persona
- `strategic+tactical`: 3-5 findings per persona
- `strategic`: 3-5 findings per persona

---

### Persona Library

#### Default Panel (always available)

**Will Larson (larson)**
Staff engineer, systems thinker, author of "An Elegant Puzzle" and "Staff Engineer."
**Evaluates:** Incremental evolution, complexity allocation, "work that begets work" patterns, migration strategy, organizational scaling, technical leverage.
**Asks:**
- Is complexity allocated to the right places?
- Can this system evolve incrementally, or does it require coordinated migrations?
- Are there patterns that will generate compounding maintenance work?
- Does the architecture support the team structure that will operate it?
- Where are the "load-bearing" abstractions — and are they solid?

**SpaceX Staff Engineer (spacex)**
Reliability-first engineer from a high-consequence environment.
**Evaluates:** Failure modes, single points of failure, blast radius, ruthless simplification, unnecessary complexity, graceful degradation.
**Asks:**
- What are the single points of failure?
- What happens when each component fails? Is the blast radius contained?
- What can be eliminated without losing functionality?
- Are there unnecessary layers of indirection?
- Does the system degrade gracefully or fail catastrophically?
- Is every piece of complexity earning its keep?

**AWS Staff Engineer (aws)**
Builder of multi-tenant services at hyperscale.
**Evaluates:** Tenant isolation, service boundaries, operational excellence, noisy-neighbor prevention, resource accounting, observability, blast radius isolation.
**Asks:**
- Will the tenant isolation model hold under adversarial conditions?
- Are service boundaries clean — or will they cause cascading failures?
- Can you operate this at 10x scale without redesign?
- Is there per-tenant resource accounting and throttling?
- Can you debug a production issue for one tenant without affecting others?
- What's the operational runbook look like?

**Anthropic Staff Engineer (anthropic)**
Security-conscious engineer focused on correctness and safety.
**Evaluates:** Security-by-design, implicit trust boundaries, type safety, correctness guarantees, defense in depth, developer velocity impact.
**Asks:**
- Are there implicit trust boundaries that should be explicit?
- Is the type system being used to prevent entire classes of bugs?
- Where does the system rely on convention instead of enforcement?
- Are security controls layered (defense in depth) or single-point?
- Does the security model help or hinder developer velocity?
- What happens if a developer makes a "reasonable mistake"?

#### Extended Personas (available via `personas:` parameter)

**Stripe Staff Engineer (stripe)**
Payments infrastructure, API design, backwards compatibility.
**Evaluates:** API design quality, versioning strategy, idempotency, backwards compatibility, developer experience, error message quality.

**Cloudflare Staff Engineer (cloudflare)**
Edge computing, latency-sensitive systems, DDoS resilience.
**Evaluates:** Latency paths, caching strategy, connection management, resource exhaustion, geographic distribution readiness.

**Google Staff Engineer (google)**
Large-scale distributed systems, SRE principles.
**Evaluates:** SLO/SLI definition, error budgets, capacity planning, dependency management, graceful degradation.

**Netflix Staff Engineer (netflix)**
Chaos engineering, resilience, microservice patterns.
**Evaluates:** Failure injection readiness, circuit breakers, bulkheads, fallback behavior, deployment safety.

---

### 4. Synthesize Consensus View

After all personas have reviewed independently:

1. **Identify overlapping findings** — issues raised by 2+ personas
2. **Rank by consensus strength** — findings with 3+ personas agreeing are highest confidence
3. **Note disagreements** — where personas contradict each other, explain the tension
4. **Produce a "Where They Agree" section** highlighting the strongest architectural signals

### 5. Build Unified Severity/Effort Matrix

Deduplicate all findings across personas into a single matrix:

```
| # | Finding | Severity | Effort | Personas | Description |
```

Sort by: Critical first, then High, Medium, Low. Within severity, sort by effort (smallest first — quick wins rise to the top).

### 6. Propose Architecture Improvements (Diagrams)

For findings that suggest structural changes, create proposed-state diagrams in the audit report itself (not in `docs/architecture/` — those are current-state only).

Use the same Mermaid format but title them "Proposed: [description]" and annotate what changed from current state.

### 7. Suggest Backlog Additions

For each finding at Medium severity or above, propose a backlog item:

```
| # | Item | Size | Priority | Source Finding |
|---|------|------|----------|---------------|
| B-XX | [title] | S/M/L/XL | P1-P4 | F-[number] |
```

Use the next available B-XX number from the project's BACKLOG.md.

### 8. Output Report

Save the main audit to `docs/audits/YYYY-MM-DD-arch-audit-vX.Y.Z.md`:

```markdown
---
type: architectural-audit
title: Multi-Persona Architectural Audit
date: YYYY-MM-DD
version: X.Y.Z
depth: [deep|strategic+tactical|strategic]
focus: [area or "full codebase"]
personas: [list]
findings: { critical: N, high: N, medium: N, low: N, total: N }
consensus_findings: N
suggested_backlog_items: N
tags: [architecture, audit, ...]
---

# Architectural Audit — vX.Y.Z

## Executive Summary
[1 paragraph: what was audited, key themes, top concern, overall assessment]

## Architecture Diagrams
[Reference the docs/architecture/ files with brief descriptions]

## Persona Analyses

### Will Larson — Systems & Scaling
**Top Findings (ranked):**
[Numbered list with full finding details per depth level]

### SpaceX — Reliability & Simplification
[Same format]

### AWS — Multi-Tenancy & Operations
[Same format]

### Anthropic — Security & Correctness
[Same format]

## Consensus View
### Where They Agree
[Findings flagged by 2+ personas, ranked by consensus strength]

### Notable Tensions
[Where personas disagree and why both perspectives have merit]

## Unified Findings Matrix
[Deduplicated table sorted by severity then effort]

## Proposed Architecture Changes
[Mermaid diagrams showing proposed improvements, annotated]

## Suggested Backlog Additions
[B-XX items with size and priority]
```

### 9. Offer Next Steps

After presenting the report, ask the user:

1. **Add backlog items** — merge suggested B-XX items into BACKLOG.md
2. **Fix critical findings now** — start working through Critical items immediately
3. **Just the report** — save and done
4. **Open a bolt** — create a new sprint targeting the top findings
