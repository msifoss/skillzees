# Twelve-Persona Code Review

Usage: `/five-persona-review [scope]`

**Arguments:** $ARGUMENTS

---

## Purpose

Conducts a deep, multi-perspective code review using 12 independent expert personas — 5 core reviewers, 4 specialized analyzers, and 3 adaptive reviewers (framework-specific, test quality, cost). Each persona reviews independently and in parallel via the Agent tool, producing findings categorized by severity. Battle-tested methodology that found 155 security findings across 3 rounds in the AI-DLC reference project, now expanded from 5 to 12 reviewers to match and exceed CE's 14-reviewer breadth.

---

## Instructions for Claude

### 0. Parse Arguments

Extract `scope` from: `$ARGUMENTS`

- If no scope provided, review the **entire codebase**
- If scope is a file path, review that file/directory
- If scope is a feature name, find and review related files
- Examples: `/five-persona-review`, `/five-persona-review src/auth/`, `/five-persona-review "the API layer"`

### 1. Setup Review Environment

**Worktree isolation (recommended):** To avoid disrupting the main working directory during review, use an isolated worktree when available:

```bash
# Check if we're on a feature branch or reviewing a PR
current_branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
```

**If reviewing a PR or specific branch:**
- Use `EnterWorktree` to create an isolated copy for the review
- This prevents review analysis from polluting the main working directory
- Exit the worktree after review is complete

**If reviewing the current working directory:**
- Proceed in-place (worktree not needed for reviewing your own uncommitted work)

### 2. Read the Codebase

Before reviewing, read ALL files in scope. Understand:
- Architecture and data flow
- Error handling patterns
- Security controls
- Test coverage
- Configuration and secrets management
- Infrastructure as code (if present)

### 2b. Check Per-Project Config

Check for `.ai-dlc.local.yaml` in the project root for review customizations:

```bash
ls .ai-dlc.local.yaml 2>/dev/null
```

If found, read it and apply any `review` section overrides:
- `review.focus_areas` — prioritize certain types of findings
- `review.skip_personas` — skip specific personas if not relevant
- `review.extra_context` — additional context passed to all personas

If not found, proceed with default 5-persona configuration.

### 3. Conduct Twelve Independent Reviews

Each persona reviews independently. Do NOT let one persona's findings influence another.

**Execution:** Launch all 12 personas using the Agent tool in parallel where possible (batch into groups of 3-4 agents per message). Each agent gets the codebase context and its persona instructions. Collect all results before proceeding to classification.

#### Core Personas (always run)

#### Persona 1: Staff Engineer (Will Larson)
**Focus:** Code quality, error handling, testing gaps, operational readiness
**Looks for:**
- Error paths that silently fail or lose data
- Missing edge cases in tests
- Code that works but will cause operational pain
- Anti-patterns that will compound over time
- Insufficient logging or observability
- Race conditions and concurrency issues

#### Persona 2: First Principles (Elon Musk)
**Focus:** Over-engineering, unnecessary complexity, dead code
**Looks for:**
- Code that exists "just in case" but serves no current purpose
- Abstractions that add complexity without clear benefit
- Features that could be simpler
- Dependencies that could be eliminated
- Configuration that could be hardcoded (if truly static)
- Speculative future-proofing

#### Persona 3: Radical Transparency (Ray Dalio)
**Focus:** Documentation accuracy, operational readiness, honest assessment
**Looks for:**
- README/docs that don't match the code
- Outdated comments
- Missing runbook entries for failure modes
- Metrics that aren't being tracked but should be
- Gaps between what's claimed and what's real
- Deployment procedures that skip steps

#### Persona 4: CTO / Security Architect
**Focus:** Security, architecture, scalability, data protection
**Looks for:**
- Input validation gaps
- Authentication/authorization weaknesses
- Injection vulnerabilities (SQL, command, XSS)
- Secrets in code or logs
- Overly permissive IAM/RBAC
- Missing encryption (at rest and in transit)
- Network exposure
- Dependency vulnerabilities

#### Persona 5: SRE / DevOps Staff Engineer
**Focus:** Infrastructure, monitoring, deployment, reliability
**Looks for:**
- Missing health checks or monitoring
- Alarm gaps (failure modes without alerts)
- Deployment risks (no rollback, no canary)
- Resource limits not set (memory, CPU, concurrency, timeouts)
- Missing retry/backoff on external calls
- Cost risks (unbounded resource creation)
- Log volume or log loss risks
- Infrastructure drift from IaC

#### Specialized Reviewers (always run)

#### Persona 6: Performance Oracle
**Focus:** Performance bottlenecks, N+1 queries, memory leaks, caching
**Looks for:**
- N+1 database query patterns
- Missing indexes on queried columns
- Unbounded collection loading (loading all records into memory)
- Missing caching where repeated computation is expensive
- Synchronous operations that should be async
- Memory leaks (event listeners, timers, closures holding references)
- Large payload serialization without pagination
- Missing connection pooling

#### Persona 7: Data Integrity Guardian
**Focus:** Data consistency, race conditions, transaction safety, validation
**Looks for:**
- Missing database transactions around multi-step mutations
- Race conditions in concurrent access patterns
- Orphaned records from failed partial operations
- Missing foreign key constraints or cascading deletes
- Data type mismatches between layers (API → DB → response)
- Missing uniqueness constraints where business logic requires them
- Silent data truncation (string lengths, numeric overflow)
- Inconsistent null handling across the stack

#### Persona 8: Architecture Strategist
**Focus:** Coupling, cohesion, boundary violations, dependency direction
**Looks for:**
- Circular dependencies between modules
- Layer violations (UI calling DB directly, skipping service layer)
- God objects or god functions (>200 lines, >5 responsibilities)
- Missing abstractions at integration boundaries (hardcoded vendor calls)
- Shared mutable state between components
- Missing interface definitions at module boundaries
- Inappropriate coupling (feature A directly imports feature B internals)
- Configuration scattered across multiple locations

#### Persona 9: Pattern Recognition Specialist
**Focus:** Design pattern misuse, anti-patterns, code smells
**Looks for:**
- Shotgun surgery (one change requires touching many files)
- Feature envy (methods that use another class's data more than their own)
- Primitive obsession (raw strings/ints instead of value objects for IDs, money, etc.)
- Divergent change (one class changed for multiple unrelated reasons)
- Inappropriate intimacy between classes
- Speculative generality (unused abstractions, unused parameters)
- Refused bequest (subclass ignoring parent behavior)
- Message chains (a.b().c().d() — Law of Demeter violations)

#### Framework-Adaptive Reviewers (auto-selected based on detected stack)

#### Persona 10: Framework Specialist
**Focus:** Framework-specific anti-patterns, idiomatic violations, migration risks
**Auto-adapts to detected stack:**

**If Python/Django/Flask/FastAPI:**
- Missing type hints on public APIs
- Mutable default arguments
- Bare except clauses
- Missing `__all__` in `__init__.py`
- Django: missing `select_related`/`prefetch_related`, raw SQL without parameterization
- FastAPI: missing Pydantic validators, sync blocking in async endpoints

**If TypeScript/Node/React/Next.js:**
- Missing strict TypeScript (`any` type usage, missing null checks)
- React: missing dependency arrays in useEffect, prop drilling >3 levels
- Next.js: client components that should be server components, missing metadata
- Missing error boundaries, unhandled promise rejections
- Node: blocking the event loop, callback hell, missing graceful shutdown

**If Ruby/Rails:**
- Missing scopes (raw `where` chains in controllers)
- Callbacks that should be service objects
- Missing database indexes for association columns
- N+1 queries in views (missing eager loading)
- Missing strong parameters, mass assignment risks

**If Go:**
- Goroutine leaks (missing context cancellation)
- Missing error wrapping (`fmt.Errorf` with `%w`)
- Shared state without mutex protection
- Missing `defer` for cleanup
- Returning concrete types instead of interfaces

**If Rust:**
- Unnecessary cloning (`.clone()` where borrowing suffices)
- Missing error context (`?` without `.context()`)
- Blocking in async context
- `unwrap()` in library code

**If no framework detected:** Skip this persona.

#### Persona 11: Test Quality Analyst
**Focus:** Test coverage gaps, test quality, testing anti-patterns
**Looks for:**
- Missing tests for error paths and edge cases
- Tests that test implementation instead of behavior
- Flaky test patterns (time-dependent, order-dependent, network-dependent)
- Missing integration tests (only unit tests exist)
- Test doubles that hide real bugs (over-mocking)
- Missing assertion messages (bare `assert` without context)
- Test data that doesn't represent production scenarios
- Missing boundary value tests (empty, null, max, negative)
- Snapshot tests that are rubber-stamped without review

#### Persona 12: Cost & Efficiency Reviewer
**Focus:** Infrastructure cost, resource waste, billing surprises
**Looks for:**
- Unbounded resource creation (Lambda concurrency, container scaling without limits)
- Missing auto-scaling down (resources that scale up but never down)
- Oversized compute (instances/containers bigger than workload requires)
- Missing lifecycle policies on storage (S3, logs, backups growing forever)
- Expensive operations in hot paths (API calls per request that could be cached)
- Missing spot/preemptible instances for fault-tolerant workloads
- Cross-region data transfer (AZ-to-AZ, region-to-region charges)
- Missing reserved capacity for predictable workloads
- Logging verbosity in production (CloudWatch/Datadog cost from debug logs)

### 4. Classify Findings

Each finding gets a severity:

| Severity | Meaning | Examples |
|----------|---------|---------|
| **Critical** | Data loss, security breach, or system failure | Missing auth, SQL injection, silent data corruption |
| **High** | Significant operational or security risk | Missing retries, unvalidated input, overpermissive IAM |
| **Medium** | Will cause problems under stress or at scale | Missing monitoring, incomplete error handling |
| **Low** | Code quality, documentation, minor improvements | Naming, comments, minor inefficiencies |

### 5. Deduplicate

After all 12 personas have reviewed, consolidate duplicate findings. Track which personas flagged each issue (consensus = higher confidence). More personas flagging the same issue = higher severity confidence.

### 6. Output Report

Save to `docs/reviews/[YYYYMMDD]-five-persona-code-review.txt`:

```
================================================================================
FIVE-PERSONA CODE REVIEW
Date: [YYYY-MM-DD]
Scope: [what was reviewed]
================================================================================

## Overview

| # | Persona | Focus Area | Findings |
|---|---------|------------|----------|
| 1 | Staff Engineer | Code quality, error handling | [count] |
| 2 | First Principles | Simplification | [count] |
| 3 | Radical Transparency | Docs accuracy, ops readiness | [count] |
| 4 | CTO / Security | Security, architecture | [count] |
| 5 | SRE / DevOps | Infrastructure, monitoring | [count] |
| 6 | Performance Oracle | N+1, memory, caching | [count] |
| 7 | Data Integrity | Transactions, race conditions | [count] |
| 8 | Architecture Strategist | Coupling, boundaries | [count] |
| 9 | Pattern Recognition | Anti-patterns, code smells | [count] |
| 10 | Framework Specialist | [detected framework] patterns | [count] |
| 11 | Test Quality Analyst | Coverage gaps, test smells | [count] |
| 12 | Cost & Efficiency | Resource waste, billing risks | [count] |
| | **Total raw findings** | | **[count]** |

After deduplication: **[count] unique findings**

================================================================================
## CONSOLIDATED FINDINGS — SORTED BY SEVERITY
================================================================================

### CRITICAL ([count])

**F1 — [Title]**
File: [path:line]
Personas: [which personas flagged this]
[Description of the issue]
Fix: [Recommended fix]

---

### HIGH ([count])
[Same format]

### MEDIUM ([count])
[Same format]

### LOW ([count])
[Same format]

================================================================================
## SUMMARY
================================================================================

- Critical: [count] — must fix before deploy
- High: [count] — fix this sprint
- Medium: [count] — fix within 2 sprints
- Low: [count] — address when convenient
- Total unique: [count]
```

### 7. Offer to Fix

After presenting findings, ask the user:
1. Fix all Critical findings now?
2. Fix Critical + High?
3. Fix everything?
4. Just save the report?

If fixing, work through findings by severity (Critical first), updating the report as each is resolved.
