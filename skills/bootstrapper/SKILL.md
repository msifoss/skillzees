---
name: bootstrapper
description: Foundation agent — extends /init-project with state file creation, auto-handoff to /pm plan, and scaffold validation
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "init [name] | validate | upgrade"
---

# /bootstrapper — Foundation Agent

Extends `/init-project` with ai-lfg team awareness. Creates the `.ai-dlc.state.yaml`, validates scaffold completeness against Phase 0 exit criteria, and hands off to `/pm plan` automatically.

## Trigger

User invokes `/bootstrapper init [project-name]` or at project start.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `init [name]` | Full Phase 0 bootstrap with state file | `/bootstrapper init my-app` |
| `validate` | Check existing project against Phase 0 exit criteria | `/bootstrapper validate` |
| `upgrade` | Add ai-lfg state file to an existing AI-DLC project | `/bootstrapper upgrade` |

---

## Action: `init`

### Step 1: Run /init-project

Invoke the standard `/init-project` scaffold. This creates:
- CLAUDE.md, README.md, SECURITY.md, CHANGELOG.md
- Directory structure (docs/, src/, tests/, etc.)
- PM framework (docs/pm/)
- Language-specific config
- CI skeleton
- Pre-commit hooks

### Step 2: Create State File

After `/init-project` completes, create `.ai-dlc.state.yaml` with:
- Project name and version from CLAUDE.md
- Governance model from user selection
- Phase 0 as current phase
- Empty sprint and traceability sections
- All pillar metrics initialized to zero

### Step 3: Validate Phase 0 Gate

Run `/gatekeeper check 0` to validate Phase 0 exit criteria.

### Step 4: Auto-Handoff

Instead of leaving the user to figure out the next step:

```
Phase 0 scaffold complete. Next step: plan your first bolt.
Running /pm plan to set up Bolt 1...
```

This closes the H-011 handoff gap (init-project → pm plan).

---

## Action: `validate`

Run Phase 0 exit criteria checks without modifying anything:

1. CLAUDE.md exists and is project-specific
2. Repository structure matches documented layout
3. Governance model recorded
4. Linting passes
5. Pre-commit hooks configured
6. CI skeleton exists
7. All deliverables committed

Report pass/fail for each.

---

## Action: `upgrade`

For existing projects that don't have a state file:

1. Read CLAUDE.md to extract project identity
2. Detect current phase from artifacts (has requirements? Phase 1+. Has tests? Phase 3+.)
3. Create `.ai-dlc.state.yaml` with detected state
4. Report what was detected and ask user to confirm

---

## Integration Points

- **Extends /init-project:** Wraps the existing scaffold command
- **Gatekeeper:** Validates Phase 0 gate on completion
- **State:** Creates initial state file
- **Handoff:** Fixes H-011 gap by auto-invoking /pm plan
