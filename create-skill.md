# /create-skill — Scaffold a New Skill or Command

Usage: `/create-skill [skill-name] [--type command|skill] [description]`

**Arguments:** $ARGUMENTS

---

## Purpose

Meta-tool that scaffolds new AI-DLC skills and commands with correct structure, frontmatter, gates, and integration points. The self-improvement flywheel — our skills can create new skills.

> Every great system can extend itself. This command ensures new skills follow our patterns, integrate with the pipeline, and work on day one.

---

## Instructions for Claude

### Step 0: Parse Arguments

Extract from $ARGUMENTS:
- **name:** The skill name (kebab-case, e.g., `api-scanner`)
- **type:** `command` (lightweight, single file) or `skill` (multi-phase, directory-based). Default: `command`
- **description:** What the skill does (remaining text after name and type)

**If name is missing:** Ask "What should this skill be called? (kebab-case, e.g., `api-scanner`)"
**If description is missing:** Ask "What should this skill do? (one sentence)"

---

### Step 1: Research Existing Patterns

Before scaffolding, understand the ecosystem:

1. **Check for conflicts:** Search `skills/commands/` and `skills/skills/` for existing skills with the same or similar name
2. **Find similar skills:** Identify 1-2 existing skills closest in purpose to the new one — these become pattern references
3. **Check integration points:** Which existing skills should this one chain with?

```bash
# Check for name conflicts
ls skills/commands/${name}.md 2>/dev/null
ls skills/skills/${name}/ 2>/dev/null

# Find similar skills by searching descriptions
grep -r "Purpose" skills/commands/*.md skills/skills/*/SKILL.md | head -20
```

GATE: No name conflict. If conflict found, suggest an alternative name.

---

### Step 2: Gather Requirements (Interactive)

Ask these questions one at a time (skip any the user already answered):

**2a. What triggers this skill?**
- User invokes it directly (slash command)
- Called by another skill in a pipeline
- Both

**2b. What tools does it need?**
- Read-only (Read, Glob, Grep) — for analysis skills
- Read-write (+ Edit, Write, Bash) — for generation skills
- Full (+ Agent, Task) — for orchestration skills

**2c. Where does it fit in the pipeline?**
- Before planning (exploration, research)
- During planning (enrichment, validation)
- During work (implementation, generation)
- After work (review, audit, documentation)
- Standalone (independent of bolt pipeline)

**2d. What artifacts does it produce?**
- Documents (where? what format?)
- Code changes
- Reports / dashboards
- Configuration files

**2e. Does it need personas or panels?**
- No personas (straightforward execution)
- Single persona (focused expert)
- Multi-persona panel (adversarial analysis)

---

### Step 3: Scaffold the Skill

#### If type = `command`:

Create `skills/commands/${name}.md`:

```markdown
# /${name} — ${Title}

Usage: \`/${name} [arguments]\`

**Arguments:** $ARGUMENTS

---

## Purpose

${description}

---

## Instructions for Claude

### Step 0: Setup

[Parse arguments and check preconditions]

${If pipeline integration:}
Check for per-project config:
\`\`\`bash
ls .ai-dlc.local.yaml 2>/dev/null
\`\`\`

### Step 1: ${First Phase Name}

[Phase instructions]

GATE: STOP. [Verification condition]. If not met, [recovery instruction]. Do NOT proceed to Step 2 until [condition].

### Step 2: ${Second Phase Name}

[Phase instructions]

${If produces artifacts:}
### Step N: Output

Write to \`${artifact_path}\`:

\`\`\`markdown
---
date: YYYY-MM-DD
topic: [kebab-case]
---
# [Title]
\`\`\`

---

## Integration

${Integration points with other skills}
```

#### If type = `skill`:

Create directory `skills/skills/${name}/` with `SKILL.md`:

```markdown
---
name: ${name}
description: ${description}
user-invocable: true
allowed-tools: ${tools}
argument-hint: ${hint}
---

# /${name} — ${Title}

${Same structure as command but with:}
- Full YAML frontmatter
- Richer phase structure
- Persona definitions (if panel-based)
- Quality standards section
- Adaptation notes
```

---

### Step 4: Wire Integration

#### 4a. Update install-skills.sh

Verify the new skill will be picked up by `scripts/install-skills.sh` (it should — the script uses glob patterns).

#### 4b. Update README

Add the new skill to the appropriate table in `skills/README.md`:

**For commands:** Add row to Commands Reference table
**For skills:** Add row to Skills Reference table

#### 4c. Update Architecture Diagram

If the architecture diagram in `skills/README.md` needs updating (new directory), update it.

#### 4d. Suggest Pipeline Integration

If the skill fits into the bolt pipeline, suggest where to add a call:
- In `/bolt-lfg` (which step?)
- In `/slfg` (which step?)
- As a standalone recommendation

---

### Step 5: Install and Verify

Install the new skill:

```bash
bash scripts/install-skills.sh
```

Verify it works:
```bash
# For commands: check it exists in ~/.claude/commands/
ls ~/.claude/commands/${name}.md

# For skills: check it exists in ~/.claude/skills/
ls ~/.claude/skills/${name}/SKILL.md
```

---

### Step 6: Report

```
## Skill Created ✓

**Name:** /${name}
**Type:** ${type}
**Location:** skills/${type}s/${name}${type == 'skill' ? '/SKILL.md' : '.md'}
**Tools:** ${tools}
**Pipeline position:** ${position}
**Artifacts:** ${artifact_path}

### Integration Points
- ${upstream skills that feed into this}
- ${downstream skills this feeds into}

### Next Steps
- Test the skill: \`/${name} [test arguments]\`
- Refine based on usage
- Run \`/heal-skill ${name}\` after testing to fix any issues
```

---

## Meta-Skill Patterns

This command follows AI-DLC skill conventions:
- Frontmatter for skills, no frontmatter for commands
- Gates between phases with STOP + verification
- Per-project config check (`.ai-dlc.local.yaml`)
- Artifact paths use `docs/[type]/YYYY-MM-DD-[topic].*` pattern
- Integration section documenting upstream/downstream chains
- Install via `scripts/install-skills.sh` glob patterns
