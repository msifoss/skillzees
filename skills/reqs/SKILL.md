---
name: reqs
description: Requirements engineer — extracts structured REQ-NNN from brainstorms, conversations, or rough notes
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "extract | review | categorize"
---

# /reqs — Requirements Engineer

Transforms rough ideas into structured, traceable requirements. Reads brainstorm docs, conversations, or freeform notes and produces requirements in AI-DLC REQ-NNN format with categories, priorities, and acceptance criteria.

> "Write just enough requirements to guide construction, not exhaustive specs." — AI-DLC Phase 1

## Trigger

User invokes `/reqs [action]` or after `/brainstorm` completes.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `extract` | Extract requirements from source material | `/reqs extract` |
| `extract [path]` | Extract from a specific file | `/reqs extract docs/brainstorms/2026-04-04-feature.md` |
| `review` | Review existing requirements for completeness | `/reqs review` |
| `categorize` | Auto-categorize uncategorized requirements | `/reqs categorize` |

---

## Action: `extract`

### Step 1: Find Source Material

If no path provided, search for recent sources:

```bash
# Recent brainstorms (last 14 days)
find docs/brainstorms/ -name "*.md" -mtime -14 2>/dev/null | sort -r

# Check for rough notes
ls docs/notes/ 2>/dev/null
```

If multiple sources exist, list them and ask which to process. If one source, proceed.

### Step 2: Read and Analyze

Read the source material. For each distinct capability, feature, constraint, or quality attribute mentioned, draft a requirement.

**Extraction rules:**
- One requirement per distinct capability (don't bundle)
- Extract implicit requirements (if they say "users log in", that implies REQ for auth, session management, password policy)
- Distinguish functional from non-functional
- Preserve the user's language — don't over-formalize
- Flag ambiguous statements with `[CLARIFY]` tag

### Step 3: Assign IDs and Categories

| Category | Range | Examples |
|----------|-------|---------|
| Functional | REQ-0XX | Core features, user actions, business logic |
| Data | REQ-1XX | Storage, models, migrations, retention |
| Integration | REQ-2XX | APIs, webhooks, third-party services |
| Non-Functional | REQ-3XX | Performance, scalability, availability |
| Security | REQ-4XX | Auth, encryption, access control, audit |
| Operational | REQ-5XX | Monitoring, logging, deployment, backup |
| Constraints | REQ-9XX | Budget, timeline, technology, regulatory |

### Step 4: Format Requirements

Use AI-DLC requirements format:

```markdown
### REQ-001: [Short descriptive title]

- **Category:** Functional
- **Priority:** Must Have | Should Have | Nice to Have
- **Source:** [brainstorm doc, conversation, stakeholder]
- **Description:** [1-3 sentences]
- **Acceptance Criteria:**
  - [ ] [Measurable criterion 1]
  - [ ] [Measurable criterion 2]
- **Dependencies:** [REQ-XXX, or "None"]
- **Notes:** [Additional context, clarifications needed]
```

### Step 5: Present for Review

Show the extracted requirements to the user:

```markdown
## Extracted Requirements

**Source:** [file or conversation]
**Date:** YYYY-MM-DD
**Total:** [count]

| ID | Title | Category | Priority | Dependencies |
|----|-------|----------|----------|-------------|
| REQ-001 | User authentication | Functional | Must Have | None |
| REQ-401 | Password hashing | Security | Must Have | REQ-001 |

### Items Needing Clarification

| ID | Question |
|----|----------|
| REQ-003 | [CLARIFY] Does "export" mean CSV, JSON, or both? |
```

**GATE:** Wait for user approval before writing to file. User may add, remove, or modify requirements.

### Step 6: Save

Write to `docs/requirements.md` (create or append).

Update state file:
```yaml
traceability:
  requirements: [new count]
```

---

## Action: `review`

Read existing `docs/requirements.md` and check for:

| Check | What | Fix |
|-------|------|-----|
| Unique IDs | No duplicate REQ-NNN | Renumber duplicates |
| Acceptance criteria | Every REQ has at least one | Flag missing |
| Testability | Criteria are measurable | Flag vague criteria |
| Category range | IDs match category ranges | Flag mismatched |
| Dependencies | Referenced REQs exist | Flag broken refs |
| Priority | All have Must/Should/Nice | Flag missing |

Produce a review report with findings and suggested fixes.

---

## Action: `categorize`

Read existing requirements and auto-assign categories based on content:

- Keywords like "must handle", "users can" → Functional
- Keywords like "store", "database", "retain" → Data
- Keywords like "API", "webhook", "integrate" → Integration
- Keywords like "latency", "uptime", "scale" → Non-Functional
- Keywords like "encrypt", "authenticate", "authorize" → Security
- Keywords like "monitor", "log", "deploy" → Operational
- Keywords like "budget", "deadline", "must use" → Constraint

---

## Integration Points

### With /brainstorm (Handoff)
- Auto-discovers brainstorm docs in `docs/brainstorms/`
- Reads "Key Decisions" and "Constraints" sections as input
- Produces requirements that trace back to brainstorm source

### With Speccer
- Reqs output feeds directly into Speccer's input
- Speccer converts REQ-NNN → US-NNN → technical specs

### With Tracer
- Tracer scans requirements doc for REQ-NNN IDs
- Links requirements to downstream artifacts

### With Gatekeeper
- GATE-P1-01: All requirements have unique IDs
- GATE-P1-02: Requirements are testable

### With State
- Updates `traceability.requirements` count after extraction

---

## Quality Standards

- Every requirement must be independently testable
- No requirement should bundle multiple capabilities
- Priorities must be justified (Must Have = MVP, Should Have = v1.1, Nice to Have = backlog)
- Dependencies must form a DAG (no circular dependencies)
- Ambiguities must be flagged, not silently resolved
