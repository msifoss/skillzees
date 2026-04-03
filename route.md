# /route — Skill Router

Usage: `/route <what you want to do>`

**Arguments:** $ARGUMENTS

---

## Purpose

Find the right AI-DLC command for what you want to do. Matches your intent against the full skill catalog and suggests the top 1-3 commands with rationale.

> For humans who don't want to memorize 25+ commands. Describe what you want, get the right slash command.

---

## Instructions for Claude

### Step 1: Read the Skill Catalog

```bash
cat skills/README.md 2>/dev/null || cat ~/.claude/skills/README.md 2>/dev/null
```

If neither exists, read the local repo's `skills/commands/` directory:
```bash
ls skills/commands/*.md 2>/dev/null
```

Parse the **Commands Reference** and **Skills Reference** tables to build a catalog of:
- Command name
- Purpose description
- Key capabilities

### Step 2: Match Intent

Read $ARGUMENTS and match against the catalog. Use these matching strategies in order:

1. **Exact keyword match** — user says "review" → commands with "review" in name/purpose
2. **Purpose match** — user says "check code quality" → `/five-persona-review`, `/arch-audit`
3. **Workflow match** — user says "start a new feature" → `/bolt-lfg`, `/brainstorm`
4. **Domain match** — user says "security" → `/security-audit`, relevant review personas

### Step 3: Rank and Present

Present top 1-3 matches:

```
## Recommended Commands

### 1. /command-name (best match)
**Why:** [1-sentence rationale connecting user intent to command purpose]
**Run:** `/command-name $ARGUMENTS`

### 2. /command-name (also relevant)
**Why:** [1-sentence rationale]
**Run:** `/command-name $ARGUMENTS`

### 3. /command-name (if applicable)
**Why:** [1-sentence rationale]
**Run:** `/command-name $ARGUMENTS`
```

### Step 4: Offer Quick Execution

After presenting matches, ask:
> "Want me to run one of these? Reply with the number (1/2/3) or the command name."

If the user picks one, invoke it immediately with $ARGUMENTS.

---

## Matching Heuristics

| User Intent Pattern | Likely Commands |
|---|---|
| "review", "check", "audit" | `/five-persona-review`, `/arch-audit`, `/security-audit`, `/dlc-audit` |
| "plan", "start", "new feature" | `/bolt-lfg`, `/brainstorm`, `/pm plan` |
| "fast", "parallel", "swarm" | `/slfg` |
| "deploy", "release", "ship" | `/bolt-lfg` (close phase), `/changelog` |
| "security", "vulnerabilities" | `/security-audit`, `/five-persona-review` |
| "architecture", "design" | `/arch-audit`, `/staff-panel`, `/brainstorm` |
| "strategy", "business", "executive" | `/exec-review` |
| "health", "status", "drift" | `/motherhen`, `/prodstatus` |
| "document", "readme", "docs" | `/docs`, `/readme`, `/changelog` |
| "cost", "budget", "estimate" | `/cost-estimate`, `/budget` |
| "ticket", "work item", "devops" | `/ticky` |
| "team", "pipeline", "compose" | `/compose`, `/slfg` |
| "fix skill", "broken command" | `/heal-skill` |
| "new command", "create skill" | `/create-skill`, `/generate-command` |
| "setup", "configure", "init" | `/setup`, `/init-project`, `/quickstart` |
| "log", "decisions", "record" | `/captainslog` |
| "marketing", "seo", "content" | `/marketing-team`, `/llm-team` |
| "website", "web" | `/webteam`, `/webby` |

---

## Edge Cases

- **No match:** "I couldn't find a matching command. Here's the full catalog:" → list all commands with one-line descriptions.
- **Ambiguous:** Present top 3 and ask for clarification.
- **Too broad:** "That could be several things. Are you looking to [option A] or [option B]?"
- **Already specific:** If user says `/staff-panel` verbatim, just run it — don't route.

---

## Integration

- This command is for **human users** who don't know the catalog
- Claude's own skill routing happens via the `using-superpowers` flow (separate mechanism)
- The skill catalog in `skills/README.md` is the single source of truth — no hardcoded mappings here
