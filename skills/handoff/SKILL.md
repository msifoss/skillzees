---
name: handoff
description: Inter-skill connector — passes artifacts between skills automatically, bridges format mismatches
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: "check | connect | map | gaps"
---

# /handoff — Inter-Skill Connector

The connective tissue between skills. Ensures that when one skill produces output, the next skill in the pipeline can discover and consume it without manual bridging.

> "You have 34 skills but your pipeline has seams. ai-lfg should be the connective tissue." — Rob, Roblox

## Trigger

User invokes `/handoff [action]` or another skill needs artifact discovery.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `check` | Verify all handoff connections are healthy | `/handoff check` |
| `connect` | Connect two skills by ensuring format compatibility | `/handoff connect brainstorm pm` |
| `map` | Show the full skill pipeline with handoff points | `/handoff map` |
| `gaps` | Identify broken or missing handoffs | `/handoff gaps` |

---

## Handoff Protocol Registry

Each handoff defines: producer, consumer, artifact path, format, and discovery method.

### Registered Handoffs

| ID | Producer | Consumer | Artifact | Discovery |
|----|----------|----------|----------|-----------|
| H-001 | /brainstorm | /pm plan | `docs/brainstorms/*.md` | /pm plan runs `ls docs/brainstorms/` |
| H-002 | /pm plan | /bolt-lfg | `docs/pm/CURRENT-SPRINT.md` | /bolt-lfg checks file exists |
| H-003 | /deepen-plan | /bolt-lfg | Research Summary in CURRENT-SPRINT.md | /bolt-lfg checks section exists |
| H-004 | /bolt-lfg | /five-persona-review | Changed files (git diff) | **GAP: no scope passing** |
| H-005 | /five-persona-review | /sentinel | `docs/reviews/*five-persona*` | /sentinel scans docs/reviews/ |
| H-006 | /sentinel | /hardener | `SECURITY.md` | /hardener reads SECURITY.md |
| H-007 | /reqs | /speccer | `docs/requirements.md` | /speccer reads requirements.md |
| H-008 | /speccer | /foreman | `docs/user-stories.md` | /foreman reads stories for bolt items |
| H-009 | /speccer | /tracer | `docs/traceability-matrix.md` | /tracer reads existing matrix |
| H-010 | /bolt-lfg | /captainslog | Git context (commits, branch) | /captainslog reads git state |
| H-011 | /init-project | /pm plan | `docs/pm/CURRENT-SPRINT.md` | **GAP: no auto-invocation** |
| H-012 | /qualitygate | /foreman | Quality score + Ascent result | /foreman checks before close |
| H-013 | /evolver | CLAUDE.md | Proposed diff | **Human gate: no auto-edit** |
| H-014 | /tracer | /gatekeeper | Traceability metrics | /gatekeeper reads state file |

### Gap Resolution Plan

| Gap ID | Problem | Fix |
|--------|---------|-----|
| H-004 | /bolt-lfg doesn't tell /five-persona-review what changed | Add `git diff --name-only` scope output at end of bolt work step |
| H-011 | /init-project doesn't auto-invoke /pm plan | Add suggestion at end of init-project: "Run `/pm plan` to start Bolt 1" |

---

## Action: `check`

Verify each registered handoff:

1. Does the artifact path pattern have matching files?
2. Is the artifact recent (modified within last 7 days)?
3. Does the consumer's discovery mechanism find the artifact?

```markdown
## Handoff Health Check

**Date:** YYYY-MM-DD

| ID | Producer → Consumer | Status | Evidence |
|----|---------------------|--------|----------|
| H-001 | brainstorm → pm | HEALTHY | docs/brainstorms/2026-04-04-*.md exists |
| H-004 | bolt-lfg → five-persona | BROKEN | No scope passing mechanism |
| H-011 | init-project → pm | BROKEN | No auto-invocation |

**Healthy:** [X]/[Y] ([Z]%)
```

---

## Action: `connect`

Verify or establish the handoff between two specific skills:

```
/handoff connect brainstorm pm
```

1. Look up the registered handoff for this pair
2. If registered: verify it works (artifact exists, format matches, discovery succeeds)
3. If not registered: analyze both skills to propose a handoff protocol

---

## Action: `map`

Display the full pipeline showing how artifacts flow:

```
/brainstorm ──docs/brainstorms/*.md──→ /pm plan
    │
    └──docs/pm/CURRENT-SPRINT.md──→ /bolt-lfg
                                        │
                                   (git changes)
                                        │
                    ┌───────────────────┘
                    ▼
            /five-persona-review
                    │
             docs/reviews/*
                    │
                    ▼
              /sentinel ──SECURITY.md──→ /hardener
                                             │
                                        (ops score)
                                             │
                                             ▼
                                        /deployer
```

---

## Action: `gaps`

Show all known handoff gaps with severity:

```markdown
## Handoff Gap Report

| Severity | Gap | Impact | Fix |
|----------|-----|--------|-----|
| HIGH | H-004: bolt-lfg → five-persona-review | Reviewer doesn't know what changed, reviews entire codebase | Add git diff scope |
| MEDIUM | H-011: init-project → pm plan | User must manually invoke next step | Add suggestion |
```

---

## Integration Points

- **All skills:** Handoff connects every skill to every other skill in the pipeline
- **State:** Reads project state to determine which handoffs are relevant
- **Gatekeeper:** Handoff health is checked during gate validation
