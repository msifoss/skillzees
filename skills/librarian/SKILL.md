---
name: librarian
description: Knowledge retrieval agent — searches all project knowledge for relevant prior decisions, prevents re-solving solved problems
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: "find [query] | solved [problem] | recall [topic]"
---

# /librarian — Knowledge Retrieval Agent

Searches across all project knowledge sources to find relevant prior decisions, solutions, and context. Prevents the team from re-solving problems that have already been solved.

> "Knowledge compounding: solved problems compound — second occurrence takes minutes, not hours." — AI-DLC

## Trigger

User invokes `/librarian [action]` or when asking "have we solved this before?"

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `find [query]` | Search all knowledge sources | `/librarian find "rate limiting"` |
| `solved [problem]` | Check if a problem has been solved before | `/librarian solved "CORS errors"` |
| `recall [topic]` | Get full context on a topic | `/librarian recall "auth architecture"` |

---

## Knowledge Sources

Librarian searches across ALL project knowledge in priority order:

| Source | Path | Priority | Contains |
|--------|------|----------|----------|
| Solutions | `docs/solutions/*.md` | 1 (highest) | Solved problems with root cause and fix |
| Key Findings | `docs/key_findings/*.md` | 2 | Panel analyses and architectural decisions |
| Captain's Logs | `docs/captains_log/caplog-*.txt` | 3 | Session decisions and lessons learned |
| Brainstorms | `docs/brainstorms/*.md` | 4 | Exploration and design thinking |
| Reviews | `docs/reviews/*` | 5 | Code review findings |
| ADRs | `docs/decisions/ADR-*.md` | 6 | Architecture decision records |
| CLAUDE.md | `CLAUDE.md` | 7 | Current project conventions |

---

## Action: `find`

### Step 1: Search All Sources

```bash
for dir in docs/solutions docs/key_findings docs/captains_log docs/brainstorms docs/reviews docs/decisions; do
  grep -ril "$QUERY" "$dir" 2>/dev/null
done
grep -il "$QUERY" CLAUDE.md 2>/dev/null
```

### Step 2: Extract Context

For each match, read the relevant section and produce a ranked result:

```markdown
## Knowledge Search: "[query]"

**Sources searched:** 7
**Matches found:** [count]

### Match 1: docs/solutions/2026-03-15-rate-limiting.md (SOLUTION)
**Relevance:** HIGH — exact topic match
> **Problem:** API endpoints had no rate limiting, vulnerable to abuse
> **Solution:** Implemented token bucket algorithm with Redis backend
> **Prevention:** Added rate limit middleware as standard for all new endpoints

### Match 2: caplog-20260402-auth-hardening.txt (CAPTAIN'S LOG)
**Relevance:** MEDIUM — mentions rate limiting in security context
> "Added rate limiting to auth endpoints — 5 attempts per minute per IP"
```

---

## Action: `solved`

Specifically searches `docs/solutions/` for matching problems:

```markdown
## Solved Problem Check: "[problem]"

**Result:** YES — solved in docs/solutions/2026-03-15-cors-fix.md

### Previous Solution
- **Symptom:** CORS errors on API calls from frontend
- **Root Cause:** Missing Access-Control-Allow-Origin header on error responses
- **Fix:** Added CORS middleware before error handler
- **Prevention:** Error handler middleware always includes CORS headers

### Applicability
This solution [IS / MAY NOT BE] directly applicable because:
- [reasons why it applies or doesn't]
```

If not found: "No matching solved problem found. If you solve this, consider documenting it in `docs/solutions/`."

---

## Action: `recall`

Get comprehensive context on a topic by searching all sources and synthesizing:

```markdown
## Full Context: "[topic]"

### Architecture Decisions
- ADR-001: Chose JWT for auth (2026-03-01)

### Key Findings
- Staff panel recommended short-lived tokens (2026-03-10)

### Solutions Applied
- JWT rotation implemented with 15m access / 7d refresh (2026-03-15)

### Lessons Learned
- "Never store JWT in localStorage — use httpOnly cookies" (caplog-B005)

### Current State
- CLAUDE.md convention: "All auth uses httpOnly cookie-based JWT"
```

---

## Integration Points

- **Scribe:** Scribe indexes captain's logs, Librarian retrieves from all sources
- **Foreman:** Auto-retrieval during bolt planning (knowledge retrieval loop)
- **Reqs:** Can check if similar requirements were explored before
- **/bolt-lfg:** Step 3b knowledge retrieval uses Librarian
- **Evolver:** Librarian's recall data feeds Evolver's pattern extraction
