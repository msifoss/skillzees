---
name: prd-go
description: Write production-ready PRDs for 97 Display's 3-pillar platform rebuild (Websites/CRM/AI Agents). Follows JW's 16-section template with F-numbered requirements, testable acceptance criteria, and proper data model specs. Stores output in docs/prds/ with timestamped filenames.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: [feature-name or description of what to write a PRD for]
---

# /prd-go — Write a Production-Ready PRD

Usage: `/prd-go [feature or topic]`

**Arguments:** $ARGUMENTS

---

## Purpose

Write PRDs that a developer (Justin) can feed directly into the AI-DLC process to produce working software. Each PRD follows JW's 16-section template, is specific enough to build from, and references the Archaeologist specs and panel decisions that inform scope.

This is not a brainstorming tool. By the time you run `/prd-go`, the feature scope should already be decided (via panel reviews, brainstorms, or direct instruction). This skill turns decisions into buildable specs.

---

## Context Sources

Before writing any PRD, read these to understand what's already been decided:

**Architecture & feature decisions:**
- `docs/key_findings/20260324-1900-Three-Pillar-Architecture-Staff-Engineer-Panel.md` — pillar boundaries, interface contracts, data model
- `docs/key_findings/20260324-2100-CRM-41-Feature-Scope-Validation-Staff-Engineer-Panel.md` — CRM feature list (41 kept, 9 discarded)
- `docs/key_findings/20260324-2200-AI-Agent-Scope-Validation-Staff-Engineer-Panel.md` — 10 agents, build sequence, token budget
- `docs/key_findings/20260324-1600-Feature-Allocation-Version-Build-Staff-Engineer-Panel.md` — V1/V2/V3 allocation, effort estimates

**Legacy system specs (Archaeologist output):**
- `docs/data/OldCRMGit-ce69516d/executive-summary.md` — legacy overview
- `docs/data/OldCRMGit-ce69516d/specs/` — 27 functional area specs (spec-001 through spec-027)

**PRD format reference:**
- `docs/data/Product Requirements Document Template.docx` — JW's 16-section template
- `docs/data/schedule_event_prd (1).docx` — completed example (landscaping SaaS)

**Current state:**
- `docs/STATE.md` — live state snapshot
- `config-core.yaml` — key numbers and config
- `CLAUDE.md` — repo rules (NO NAMES in reports, roles only)

---

## Instructions for Claude

### Step 0: Parse and Validate

Extract the feature topic from $ARGUMENTS.

If no arguments provided, ask: "What feature should this PRD cover? (e.g., 'lead capture form handler', 'GHL CRM integration', 'SEO agent')"

Check if a PRD already exists for this topic:
```bash
ls docs/prds/ 2>/dev/null | grep -i "[relevant-keywords]"
```

If a PRD exists, ask: "A PRD already exists for [topic]: [filename]. Should I update it or create a new version?"

---

### Step 1: Research

Before writing, gather context specific to the feature:

1. **Check panel decisions:** Search `docs/key_findings/` for any panel output that covers this feature. Extract: what's in scope, what's explicitly out, version allocation, effort estimates, risks identified.

2. **Check Archaeologist specs:** If this feature replaces legacy functionality, find the relevant spec in `docs/data/OldCRMGit-ce69516d/specs/` and extract: current behavior, data model, integrations, edge cases.

3. **Check existing PRDs:** Read any related PRDs in `docs/prds/` to avoid contradictions and ensure consistency (shared data models, API conventions, etc.).

4. **Check brainstorms:** Look in `docs/brainstorms/` for any brainstorm document on this topic.

GATE: You must have read at least one panel decision document AND either an Archaeologist spec or a brainstorm before proceeding. If neither exists for this feature, tell the user: "No panel decisions or legacy specs found for [topic]. Should I proceed with what we know, or should we run /brainstorm first?"

---

### Step 2: Determine Pillar Ownership

Classify the feature into the 3-pillar architecture:

- **Pillar 1 (Websites/Astro):** Content, templates, design tokens, static pages, build/deploy pipeline
- **Pillar 2 (CRM):** Lead processing, notifications, integrations, auth, org/location management, portal, reporting, drip campaigns
- **Pillar 3 (AI Agents):** Content generation, SEO optimization, review sync, migration, provisioning, lead scoring

Some features span pillars. Identify the **owning pillar** (where the core logic lives) and **interface pillars** (what it touches). Reference the interface contracts from the Three-Pillar Architecture panel.

---

### Step 3: Write the PRD

Create the output directory if needed:
```bash
mkdir -p docs/prds
```

Generate the filename:
```
YYYYMMDD-HHMM-[feature-name-kebab-case]-prd.md
```
Example: `20260325-1430-lead-capture-form-handler-prd.md`

Use the current date/time for the timestamp.

Write the PRD following this exact structure. Every section is mandatory — if a section truly doesn't apply, include it with "N/A — [reason]".

```markdown
# PRD: [Feature Title]

**Version:** 1.0
**Status:** Draft
**Date:** YYYY-MM-DD
**Pillar:** [1: Websites | 2: CRM | 3: AI Agents] (+ interfaces)
**Target Version:** [V1 | V1.5 | V2a | V2b | V2c | V3]
**Effort Estimate:** [X days raw / Y days with AI-DLC]
**Author:** [Role — no names per repo rules]

---

## 1. Overview

### Problem Statement
[Concrete, workflow-focused. What breaks or doesn't work today? Who is affected?
Reference the legacy system behavior if replacing existing functionality.]

### Business Value
[Operational outcomes, not abstractions. Include dollar amounts where known.
Reference panel decisions on revenue impact, COGS savings, or churn prevention.]

### Context
[Current state, why now, what decisions led here.
Reference specific panel documents and version allocation decisions.]

---

## 2. Goals and Success Metrics

### Goals
- [Goal 1 — measurable]
- [Goal 2 — measurable]

### Success Metrics (KPIs)
| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| [KPI] | [Target] | [How measured] |

---

## 3. Scope

### In Scope
- [Capability or workflow included]

### Out of Scope
- [Explicitly excluded — with reason and version where it's planned]

---

## 4. Target Users and Personas

| Role | Description | Primary Actions |
|------|-------------|-----------------|
| [Role] | [What they do] | [What they do with this feature] |

---

## 5. User Problems and Opportunities

- [Current pain point — reference Jen/Chris transcript or panel findings where applicable]
- [Operational gap]

---

## 6. User Stories

Format: As a [role], I want to [action], so that [outcome].

- [ ] US-001: As a [role], I want to ...
- [ ] US-002: As a [role], I want to ...

---

## 7. Feature Requirements

### F-001: [Requirement Title]
**Purpose:** [Why this requirement exists]
**Actors:** [Which users/systems interact with it]
**Behavior:**
- [System action or workflow step]
- [System action or workflow step]

**Validation Rules:**
- [Required field, limit, or edge case]

**Dependencies:**
- [Internal system, third party, or prior feature]

### F-002: [Requirement Title]
[Same structure]

---

## 8. Data Model and Business Objects

[Entity definitions, relationships, key fields.
Reference Archaeologist specs for legacy data model where applicable.
Reference Three-Pillar Architecture panel for target data model.]

### Entities

#### [Entity Name]
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| [field] | [type] | [Y/N] | [description] |

### Relationships
- [Entity A] → [Entity B]: [relationship description]

### Status Lifecycle
[If applicable: status values and transitions]

---

## 9. API / Integration Requirements

[REST endpoints, webhook contracts, external API dependencies.
Follow the interface contracts from the Three-Pillar Architecture panel.]

### Endpoints

#### [METHOD] [path]
- **Purpose:** [what it does]
- **Auth:** [required role/token]
- **Request:** [key fields]
- **Response:** [key fields]
- **Errors:** [expected error cases]

### External Integrations
- [Service]: [what it's used for, API version, auth method]

---

## 10. UI / UX Requirements

[Screen descriptions, interaction patterns, responsive behavior.
Reference Design Panel findings where applicable.]

### Screens

#### [Screen Name]
- **Entry point:** [how user gets here]
- **Layout:** [key layout decisions]
- **Key interactions:** [what user does]
- **Validation display:** [how errors shown]

---

## 11. Non-Functional Requirements

### Performance
- [Response time, throughput targets]

### Security
- [Auth, tenant scoping, data protection]

### Reliability
- [Transaction atomicity, retry behavior, failure modes]

### Scalability
- [Must support X tenants, Y records]

---

## 12. Dependencies

- [System or feature this depends on — with status]

---

## 13. Risks and Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| [Risk] | [HIGH/MED/LOW] | [Mitigation approach] |

---

## 14. Acceptance Criteria

- [ ] AC-001: [Pass/fail testable criterion]
- [ ] AC-002: [Pass/fail testable criterion]

---

## 15. Release Plan and Rollout Notes

- **Target version:** [V1/V2/V3]
- **Pilot criteria:** [What sites/users go first]
- **Rollout sequence:** [Phased approach]
- **Rollback plan:** [How to undo if it breaks]

---

## 16. Future Enhancements

- [Deferred enhancement — with target version]

---

## Appendix

### A. Legacy System Reference
[Relevant Archaeologist spec reference and key behaviors being replaced]

### B. Panel Decision References
[Which panel documents informed this PRD, with key decisions cited]

### C. Related PRDs
[Links to other PRDs this one depends on or interfaces with]

### D. Open Questions
[Unresolved items that need answers before or during build]
```

---

### Step 4: Cross-Reference Check

After writing the PRD, verify:

1. **No contradictions with panel decisions:** Every feature in scope was approved by a panel. Nothing marked "discarded" is included.
2. **Interface contracts match:** API endpoints and data models align with the Three-Pillar Architecture interface contracts.
3. **No name leaks:** Roles only, no personal names (per CLAUDE.md rules).
4. **Version alignment:** Target version matches the Feature Allocation panel's version assignment.
5. **Dependencies are real PRDs:** If this PRD depends on another feature, check if that PRD exists in `docs/prds/`.

GATE: If any contradictions found, fix them before saving. Note any missing dependency PRDs in the output.

---

### Step 5: Save and Report

Save the PRD to `docs/prds/[timestamp]-[feature]-prd.md`.

Report:

```
## PRD Written

**File:** docs/prds/[filename]
**Feature:** [title]
**Pillar:** [ownership]
**Version:** [target]
**Effort:** [estimate]

### Scope Summary
- [X] requirements (F-001 through F-XXX)
- [X] acceptance criteria
- [X] user stories

### Dependencies
- [List of features this depends on]
- [Missing PRDs that should be written next]

### Open Questions
- [Unresolved items from Appendix D]
```

---

## Quality Standards

**A good PRD from this skill:**
- Can be handed to a developer who has never seen the codebase and they can build from it
- Has F-numbered requirements with specific validation rules, not vague descriptions
- Has acceptance criteria that are binary pass/fail — no "should generally work"
- References the Archaeologist spec for legacy behavior being replaced
- References panel decisions for scope boundaries
- Uses roles, never names
- Includes the data model with field types, not just entity names
- Specifies API contracts with request/response shapes
- Calls out what's explicitly OUT of scope and why

**A bad PRD:**
- Says "handle edge cases appropriately" (which ones?)
- Says "integrate with CRM" (which CRM? which API version? which fields?)
- Omits the data model
- Includes features that panels explicitly discarded
- Uses vague acceptance criteria ("system works as expected")

---

## Integration

- **Upstream:** `/brainstorm` (explores what to build) → `/prd-go` (specifies how)
- **Downstream:** PRDs feed into the AI-DLC process for autonomous development
- **Related:** `/staff` and `/exec-review` produce the decisions that PRDs codify
- **Storage:** All PRDs in `docs/prds/` with timestamp-prefixed filenames
- **Naming:** `YYYYMMDD-HHMM-[feature-kebab-case]-prd.md`
