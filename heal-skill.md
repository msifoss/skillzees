# /heal-skill — Diagnose and Fix Broken Skills

Usage: `/heal-skill [skill-name or "all"]`

**Arguments:** $ARGUMENTS

---

## Purpose

Meta-tool that diagnoses and repairs skills that aren't working correctly. Validates structure, frontmatter, cross-references, integration points, and runtime behavior. The self-healing counterpart to `/create-skill`.

> Skills drift. Templates break. Integration points go stale. This command finds what's wrong and fixes it.

---

## Instructions for Claude

### Step 0: Identify Target

Parse $ARGUMENTS:

- **If a skill name:** Heal that specific skill
- **If "all":** Scan and heal all skills
- **If empty:** Ask "Which skill needs healing? (name or 'all' for full scan)"

Locate the skill:
```bash
# Check commands
ls skills/commands/${name}.md 2>/dev/null
ls ~/.claude/commands/${name}.md 2>/dev/null

# Check skills
ls skills/skills/${name}/SKILL.md 2>/dev/null
ls ~/.claude/skills/${name}/SKILL.md 2>/dev/null
```

GATE: Skill must exist somewhere. If not found, suggest `/create-skill ${name}`.

---

### Step 1: Structural Validation

Run these checks on the skill file:

#### 1a. File Structure
| Check | Pass Criteria | Fix |
|-------|--------------|-----|
| File exists in repo | `skills/commands/*.md` or `skills/skills/*/SKILL.md` | Copy from `~/.claude/` to repo |
| File exists in Claude dir | `~/.claude/commands/*.md` or `~/.claude/skills/*/SKILL.md` | Run `install-skills.sh` |
| Files in sync | Repo version matches installed version | Re-run `install-skills.sh` |

#### 1b. Frontmatter (skills only)
| Check | Pass Criteria | Fix |
|-------|--------------|-----|
| Has YAML frontmatter | Starts with `---` | Add frontmatter block |
| Has `name` field | Matches directory name | Fix name field |
| Has `description` field | Non-empty string | Add description |
| Has `user-invocable` | Boolean value | Add `user-invocable: true` |
| Has `allowed-tools` | Comma-separated tool list | Add based on skill content |

#### 1c. Content Structure
| Check | Pass Criteria | Fix |
|-------|--------------|-----|
| Has title line | `# /name — Title` | Add title |
| Has Usage line | `Usage: \`/name ...\`` | Add usage |
| Has `$ARGUMENTS` reference | Somewhere in the file | Add arguments handling |
| Has Purpose section | `## Purpose` heading | Add purpose section |
| Has Instructions section | `## Instructions` heading | Add instructions section |
| Has at least one GATE | `GATE:` keyword present | Add gate after key phases |
| Has Integration section | `## Integration` heading | Add integration section |

---

### Step 2: Reference Validation

#### 2a. Internal References
Check all file paths mentioned in the skill:
```bash
# Extract paths from the skill file
grep -oE 'docs/[a-z_/]+' [skill-file]
grep -oE 'skills/[a-z_/]+' [skill-file]
```

For each path: does the directory exist (or get created by the skill)?

#### 2b. Cross-Skill References
Check all `/command` references in the skill:
```bash
grep -oE '/[a-z-]+' [skill-file] | sort -u
```

For each referenced command: does it exist in `skills/commands/` or `skills/skills/`?

#### 2c. README Registration
Is this skill listed in `skills/README.md`?
- Commands Reference table
- Skills Reference table
- Architecture diagram (if applicable)

---

### Step 3: Integration Validation

#### 3a. Pipeline Consistency
If the skill is referenced in `/bolt-lfg` or `/slfg`:
- Is the invocation correct?
- Does the gate match what the skill actually produces?
- Are artifact paths consistent?

#### 3b. Config Integration
If the skill reads `.ai-dlc.local.yaml`:
- Does it handle missing config gracefully?
- Are the config keys documented in `/setup`?

#### 3c. Knowledge Loop
If the skill produces artifacts:
- Are they in a discoverable location (`docs/[type]/`)?
- Can other skills find them (check brainstorm/solution/log search patterns)?
- Is the naming convention consistent with similar artifacts?

---

### Step 4: Runtime Validation (if applicable)

If the skill uses bash commands, verify they work:

```bash
# Check for hardcoded paths (should use env vars)
grep -n '/Users/' [skill-file]
grep -n '/home/' [skill-file]

# Check for missing env var defaults
grep -oE '\$\{[A-Z_]+\}' [skill-file]  # No default — risky
grep -oE '\$\{[A-Z_]+:-[^}]+\}' [skill-file]  # Has default — good
```

---

### Step 5: Apply Fixes

For each failed check:
1. Show the issue clearly
2. Show the proposed fix
3. Apply the fix
4. Mark as healed

**Order of fixes:**
1. Structural fixes first (frontmatter, sections)
2. Reference fixes (broken paths, missing commands)
3. Integration fixes (README, pipeline, config)
4. Runtime fixes (hardcoded paths, missing defaults)

---

### Step 6: Re-install and Report

After all fixes:

```bash
bash scripts/install-skills.sh
```

Display the healing report:

```
## Skill Healed ✓

**Skill:** /${name}
**Checks run:** [N]
**Issues found:** [N]
**Issues fixed:** [N]
**Issues requiring manual attention:** [N]

### Fixes Applied
| # | Check | Issue | Fix |
|---|-------|-------|-----|
| 1 | [check name] | [what was wrong] | [what was fixed] |

### Manual Attention Needed
| # | Issue | Why Manual | Suggestion |
|---|-------|-----------|------------|
| 1 | [issue] | [why auto-fix isn't safe] | [what to do] |
```

---

### "Heal All" Mode

When $ARGUMENTS is "all":

1. Scan all skills:
```bash
ls skills/commands/*.md
ls skills/skills/*/SKILL.md
```

2. Run Steps 1-4 on each skill
3. Apply fixes for each
4. Produce a consolidated report:

```
## Skills Health Report

| Skill | Type | Checks | Issues | Fixed | Status |
|-------|------|--------|--------|-------|--------|
| /brainstorm | command | 12 | 0 | 0 | ✓ Healthy |
| /bolt-lfg | command | 12 | 1 | 1 | ✓ Healed |
| /staff-panel | skill | 15 | 2 | 2 | ✓ Healed |
| /ticky | skill | 15 | 0 | 0 | ✓ Healthy |

**Total: [N] skills scanned, [N] issues found, [N] fixed.**
```

---

## Integration

- Companion to `/create-skill` (create → use → heal → improve cycle)
- Can be called by `/motherhen` when skill drift is detected
- Validates install-skills.sh still covers all skills
- Updates `skills/README.md` when out of sync
