---
name: speccer
description: Specification writer — converts requirements to user stories and technical specs with Five Questions automation
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "stories | spec | five-questions | validate"
---

# /speccer — Specification Writer

Converts requirements into user stories, technical specifications, and acceptance criteria. Automates the Five Questions Pattern to surface hidden assumptions before construction begins.

> "Working code is reviewed better than abstract specs. But specs that surface wrong assumptions prevent canary-bugs." — AI-DLC Phase 2

## Trigger

User invokes `/speccer [action]` or after `/reqs` completes.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `stories` | Generate user stories from requirements | `/speccer stories` |
| `spec` | Generate technical specification | `/speccer spec` |
| `five-questions` | Run Five Questions Pattern on a feature | `/speccer five-questions auth` |
| `validate` | Run Momus + Metis validation gates | `/speccer validate` |

---

## Action: `stories`

### Step 1: Read Requirements

```bash
cat docs/requirements.md 2>/dev/null
```

If no requirements doc exists, suggest running `/reqs extract` first.

### Step 2: Generate User Stories

For each functional requirement (REQ-0XX), generate one or more user stories:

```markdown
### US-001: [Story Title]

**As a** [role],
**I want to** [action],
**So that** [benefit].

**Acceptance Criteria:**
- [ ] Given [precondition], when [action], then [result]
- [ ] Given [error condition], when [action], then [error handling]
- [ ] Given [edge case], when [action], then [expected behavior]

**Priority:** Must-have | Should-have | Nice-to-have
**Size:** S | M | L | XL
**Traces to:** REQ-NNN
```

**INVEST criteria for each story:**
- **I**ndependent — no blocking dependencies between stories
- **N**egotiable — flexible solution, not over-specified
- **V**aluable — delivers user/business value
- **E**stimable — team can size with confidence
- **S**mall — fits in one bolt (1-4 hours)
- **T**estable — acceptance criteria concrete and verifiable

### Step 3: Generate Non-Functional Stories

For non-functional requirements (REQ-3XX, REQ-4XX, REQ-5XX), generate constraint stories:

```markdown
### US-050: [Constraint Title]

**As a** system operator,
**I want** [constraint],
**So that** [quality attribute].

**Acceptance Criteria:**
- [ ] [Measurable threshold — e.g., "p99 latency < 200ms"]

**Traces to:** REQ-3XX
```

### Step 4: Initialize Traceability Matrix

Create or update `docs/traceability-matrix.md`:

```markdown
| REQ | Story | Spec | Code Path | Test ID | Deploy |
|-----|-------|------|-----------|---------|--------|
| REQ-001 | US-001, US-002 | — | — | — | — |
| REQ-002 | US-003 | — | — | — | — |
```

### Step 5: Save

Write to `docs/user-stories.md`. Update state file with story count.

**GATE:** Present stories to user for approval before saving.

---

## Action: `five-questions`

The Five Questions Pattern surfaces hidden assumptions before they become canary-bugs.

### How It Works

For a given feature area, the AI generates 5 assumptions it's making about the implementation. The human validates each one.

### Step 1: Identify Feature Area

```
Feature: [name or description]
Requirements: [REQ-NNN list]
Stories: [US-NNN list]
```

### Step 2: Generate 5 Assumptions

Think deeply about what you're assuming. Focus on:
1. **Data assumptions** — format, volume, retention, ownership
2. **Behavior assumptions** — edge cases, error states, concurrency
3. **Integration assumptions** — APIs, protocols, auth, rate limits
4. **Performance assumptions** — scale, latency, throughput
5. **Security assumptions** — trust boundaries, access control, data sensitivity

```markdown
## Five Questions: [Feature Name]

I'm making these 5 assumptions. Please validate each:

### Assumption 1: [Data format]
I'm assuming [specific assumption].
- If CORRECT: [what I'll build]
- If WRONG: [what changes]
- **Your response:** Correct / Wrong / Partially correct

### Assumption 2: [Behavior]
...

### Assumption 3: [Integration]
...

### Assumption 4: [Performance]
...

### Assumption 5: [Security]
...
```

### Step 3: Process Responses

**GATE:** Wait for human to respond to all 5 questions.

For each response:
- **Correct:** Proceed as planned
- **Wrong:** Update the requirement/story with the correction
- **Partially correct:** Clarify and update

### Step 4: Document

Append the Five Questions cycle to `docs/five-questions-log.md`:

```markdown
## Five Questions: [Feature] — Cycle [N]

**Date:** YYYY-MM-DD
**Feature:** [name]
**Requirements:** [REQ-NNN]

| # | Assumption | Response | Impact |
|---|-----------|----------|--------|
| 1 | [assumption] | Correct | None |
| 2 | [assumption] | Wrong | Updated REQ-003 acceptance criteria |
| 3 | [assumption] | Partially | Clarified data format in spec |
| 4 | [assumption] | Correct | None |
| 5 | [assumption] | Wrong | Added new REQ-105 for data migration |
```

---

## Action: `spec`

Generate a technical specification from requirements and user stories.

### Step 1: Read Inputs

```bash
cat docs/requirements.md 2>/dev/null
cat docs/user-stories.md 2>/dev/null
ls docs/decisions/ADR-*.md 2>/dev/null
```

### Step 2: Generate Technical Spec

Structure:

```markdown
# Technical Specification: [Project/Feature]

## Overview
[2-3 sentence summary]

## Architecture
[Component diagram, data flow, key interfaces]

## Components

### [Component 1]
- **Purpose:** [what it does]
- **Interface:** [API/method signatures]
- **Dependencies:** [what it needs]
- **Stories:** [US-NNN list]
- **Requirements:** [REQ-NNN list]

### [Component 2]
...

## Data Model
[Entity definitions, relationships, constraints]

## API Contracts
[Endpoint definitions, request/response schemas]

## Error Handling
[Error codes, recovery strategies, user-facing messages]

## Security Considerations
[Auth, encryption, input validation, rate limiting]

## Performance Targets
[Latency, throughput, concurrency, resource limits]

## Dependency Graph
[Which components depend on which, build order]
```

### Step 3: Save

Write to `docs/technical-spec.md`. Update traceability matrix Spec column.

---

## Action: `validate`

Run two validation gates from AI-DLC Phase 2.

### Momus Gate (Error Path Validation)

For each component in the spec, verify:
- [ ] Error paths documented
- [ ] Constraints specified
- [ ] Dependencies listed
- [ ] Race conditions considered
- [ ] Edge cases documented

### Metis Gate (Solution Fitness)

For each feature, verify:
- [ ] Solution addresses original requirement (no drift)
- [ ] No gold-plating (no unnecessary features)
- [ ] Component boundaries are clear
- [ ] Interfaces are minimal
- [ ] Spec is implementable in bolt-sized chunks

### Report

```markdown
## Specification Validation Report

### Momus Gate (Error Paths)
| Component | Error Paths | Constraints | Dependencies | Race Conditions | Edge Cases | Score |
|-----------|------------|------------|-------------|----------------|------------|-------|
| Auth | YES | YES | YES | NO | YES | 4/5 |

### Metis Gate (Solution Fitness)
| Feature | Addresses REQ | No Gold-Plating | Clear Boundaries | Minimal Interface | Bolt-Sized | Score |
|---------|-------------|----------------|-----------------|------------------|-----------|-------|
| Login | YES | YES | YES | YES | YES | 5/5 |

### Verdict
- Momus: [PASS/FAIL] ([X]/[Y] components pass)
- Metis: [PASS/FAIL] ([X]/[Y] features pass)
- Overall: [PASS/FAIL]
```

---

## Integration Points

### With Reqs
- Reads `docs/requirements.md` as primary input
- Stories trace to requirements via "Traces to" field

### With Tracer
- Initializes traceability matrix with REQ->Story->Spec links
- Tracer can verify the links are valid

### With Gatekeeper
- GATE-P2-01: All requirements have stories
- GATE-P2-02: Stories have Given-When-Then criteria
- GATE-P2-04: Traceability matrix links REQ->Story->Spec

### With Foreman
- User stories become bolt work items
- Size estimates (S/M/L/XL) guide bolt planning

### With State
- Updates `traceability.stories` and `traceability.specs` counts

---

## Quality Standards

- Every story must pass INVEST criteria
- Acceptance criteria must be in Given-When-Then format
- Five Questions must be run at least once per feature area
- No story should exceed XL size (split if too large)
- Tech spec must be implementable — no vague "improve performance" items
- Traceability matrix must have no orphan stories (every US traces to a REQ)
