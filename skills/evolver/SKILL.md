---
name: evolver
description: Context evolution agent — analyzes captain's logs and git history to propose CLAUDE.md updates, detects stale context
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "evolve | stale | patterns | diff"
---

# /evolver — Context Evolution Agent

The context file (CLAUDE.md) is the highest-leverage artifact in AI-assisted development. Evolver keeps it current by analyzing captain's logs, git history, and usage patterns to propose updates and detect staleness.

> "Stale context produces confidently wrong output. The AI does not know what it does not know." — AI-DLC Solo-AI Governance

## Trigger

User invokes `/evolver [action]` or after sprint completion.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `evolve` | Analyze recent history and propose CLAUDE.md updates | `/evolver evolve` |
| `stale` | Detect stale entries in CLAUDE.md | `/evolver stale` |
| `patterns` | Extract patterns from captain's logs | `/evolver patterns` |
| `diff` | Show proposed CLAUDE.md diff without applying | `/evolver diff` |

---

## Action: `evolve`

The five-phase learning loop from AI-DLC Phase 6:

### Phase 1: Passive Feedback Collection

```bash
# Recent captain's logs (last 30 days)
find docs/captains_log/ -name "caplog-*.txt" -mtime -30 2>/dev/null | sort -r

# Recent commits with lessons
git log --oneline -50

# Recent key findings
find docs/key_findings/ -name "*.md" -mtime -30 2>/dev/null
```

### Phase 2: Pattern Extraction

From the collected feedback, identify:
- **Repeated decisions** — same choice made 3+ times (should be a convention)
- **Repeated mistakes** — same error hit 2+ times (should be a warning)
- **New conventions** — patterns that emerged during construction
- **Obsolete patterns** — referenced conventions no longer in use

### Phase 3: Preference Learning

Compare current CLAUDE.md against actual codebase:
- Are documented conventions followed in the code?
- Are there undocumented conventions in the code?
- Do architecture decisions match what was actually built?

### Phase 4: Context Injection

Propose specific updates to CLAUDE.md:

```markdown
## Proposed CLAUDE.md Updates

### Add
1. **Convention:** [new pattern found in 5+ files]
   - Evidence: [file1, file2, file3...]

### Update
2. **Architecture Decision:** [decision that changed during construction]
   - Old: [what CLAUDE.md says]
   - New: [what the code actually does]
   - Evidence: [commit hash, captain's log]

### Remove
3. **Stale entry:** [reference to deleted file/feature]
   - Why: [file no longer exists / feature deprecated]
```

**GATE:** Present proposals to user. Do NOT auto-edit CLAUDE.md.

### Phase 5: Agent Discovery

Identify opportunities for new automation:
- Repetitive tasks in captain's logs
- Manual processes mentioned 3+ times
- Patterns that could become skills

---

## Action: `stale`

Detect entries in CLAUDE.md that may be outdated:

### Checks

| Check | How |
|-------|-----|
| Referenced files exist | Parse file paths in CLAUDE.md, verify each exists |
| Referenced commands work | Parse command examples, verify they run |
| Dependencies are current | Check version numbers against package files |
| Architecture matches code | Compare described structure against actual `tree` |
| Conventions match code | Grep for described patterns in src/ |

### Report

```markdown
## Staleness Report

**CLAUDE.md last modified:** [date]
**Days since update:** [count]

| Line | Content | Issue | Severity |
|------|---------|-------|----------|
| 23 | "src/auth/ handles authentication" | src/auth/ doesn't exist | HIGH |
| 45 | "Uses Express 4.x" | package.json shows Express 5.x | MEDIUM |
| 67 | "Run `make test`" | No Makefile exists | HIGH |

**Staleness score: [X]%** (0% = perfectly current)
```

---

## Action: `patterns`

Extract patterns from captain's logs without proposing CLAUDE.md changes:

```markdown
## Pattern Catalog

**Source:** [N] captain's logs from [date range]

### Recurring Decisions
| Pattern | Frequency | Last Seen | Example |
|---------|-----------|-----------|---------|
| Use repository pattern for data access | 4 times | B-012 | caplog-20260401 |

### Recurring Problems
| Problem | Frequency | Solution | Prevention |
|---------|-----------|----------|-----------|
| Timezone handling in date comparisons | 3 times | Use UTC everywhere | Add to CLAUDE.md conventions |

### Emerging Conventions
| Convention | Evidence | Files |
|-----------|----------|-------|
| Structured logging with correlation IDs | 8 files | src/api/*.py |
```

---

## Action: `diff`

Show what `/evolver evolve` would propose without making changes. Dry run mode.

---

## Integration Points

- **Scribe:** Reads captain's logs for pattern extraction
- **State:** Reads project phase to adjust analysis depth
- **Gatekeeper:** GATE-P6-03 (context files updated with learnings)
- **Librarian:** Pattern catalog feeds into knowledge retrieval
- **Motherhen:** Complementary — Motherhen monitors health, Evolver improves context
