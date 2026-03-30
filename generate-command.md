# /generate-command — Quick-Create a Lightweight Command

Usage: `/generate-command [name] [what it should do]`

**Arguments:** $ARGUMENTS

---

## Purpose

Rapid command generator for simple, single-purpose slash commands. Lighter than `/create-skill` — no interactive questions, no skill directory, just a working command in seconds.

> Need a quick command? Describe it in English, get a working slash command. For complex multi-phase skills, use `/create-skill` instead.

---

## Instructions for Claude

### Step 1: Parse and Generate

Extract from $ARGUMENTS:
- **name:** First word (kebab-case)
- **description:** Everything after the name

**If name is missing:** Infer from the description (e.g., "check test coverage" → `test-coverage`)

### Step 2: Analyze Requirements

From the description, determine:
- What inputs does it need? (files, arguments, git context)
- What does it produce? (output, files, reports)
- What tools does it need? (Bash, Read, Grep, Write)
- Does it need per-project config? (`.ai-dlc.local.yaml`)

### Step 3: Generate the Command

Write to `skills/commands/${name}.md`:

Follow this template exactly:

```markdown
# /${name} — ${Title}

Usage: \`/${name} [arguments]\`

**Arguments:** $ARGUMENTS

---

## Purpose

${description}

---

## Instructions for Claude

### Step 1: ${First action}

${Instructions derived from the description}

${If multiple steps, add gates between them}

### Step ${N}: Output

${What to display or write}

---

## Integration

- ${How it connects to other skills, if applicable}
```

**Generation rules:**
- Keep it under 100 lines (this is a QUICK command)
- One gate maximum (it's lightweight)
- No personas or panels (use `/create-skill` for those)
- Include a config check ONLY if the command reads project settings
- Use existing patterns from the codebase

### Step 4: Install and Report

```bash
# Install
cp skills/commands/${name}.md ~/.claude/commands/${name}.md

# Verify
ls ~/.claude/commands/${name}.md
```

Report:
```
## Command Generated ✓

**Name:** /${name}
**Location:** skills/commands/${name}.md
**Lines:** [count]

Try it: \`/${name} [example arguments]\`
```

---

## Examples

```
/generate-command test-coverage "show test coverage for the current project"
/generate-command dep-check "check for outdated dependencies"
/generate-command git-summary "summarize recent git activity for standup"
/generate-command env-check "verify all required environment variables are set"
```
