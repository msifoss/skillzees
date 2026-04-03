# /mytodo — Accurate Per-Person Todo View

Shows a clean, filtered view of all open work items for any team member. Reads from exactly two authoritative sources — no scanning, no guessing.

## Trigger

User invokes `/mytodo` with optional argument.

## Arguments

| Argument | What it does |
|----------|-------------|
| *(none)* | Show my open items (detect user from git config) |
| `bryant` | Show Bryant's open items |
| `todd` | Show Todd's open items |
| `chris` | Show Chris's open items |
| `jonathan` or `jw` | Show Jonathan's open items |
| `all` | Show all open items across everyone |
| `overdue` | Show items past their due date |

---

## How It Works

### Two authoritative sources only

1. **`docs/todo/teamtodo.md`** — all tasks (PPL, INF, MIG, TOOL, FIN, SA, QA, CVC, GATE)
2. **`docs/strats/questions4bryant.md`** — all leadership questions (QB)

Everything else (meeting notes, STATE.md, config.yaml TBDs, open_questions.md) is context, not work items. Do NOT scan those files for todos.

### Status mapping between sources

| questions4bryant.md | teamtodo.md | Meaning |
|---------------------|-------------|---------|
| NEW | NOT_STARTED | Just logged |
| PRIORITY | NOT_STARTED (P0) | Urgent, not yet raised |
| RAISED | IN_PROGRESS | Asked, awaiting response |
| ANSWERED | DONE | Response received |
| DEFERRED | CANCELLED | Parked |

### Category prefixes

| Prefix | Type | Color hint |
|--------|------|-----------|
| QB | Leadership question | Blue |
| PPL | People / delegation | Green |
| INF | Infrastructure | Orange |
| MIG | Migration | Purple |
| TOOL | Tool cancellation | Red |
| FIN | Financial | Yellow |
| SA | Search Atlas | Teal |
| CVC | Customer validation | Pink |
| QA | Quality assurance | Gray |
| GATE | Checkpoint / gate | Bold |
| RR | Results report | Cyan |

---

## Phase 0 — Identify the User

```bash
GIT_NAME=$(git config user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")
```

Match against known collaborators:
- `cfossenier@membersolutions.com` or `msifoss` → Chris
- `Todd Blyth` → Todd
- `bstrozinsky` → Bryant
- `Jonathan Wakefield` or `jwakefield` → Jonathan

If no argument provided and user can't be identified, ask: "Who am I showing todos for?"

---

## Phase 1 — Read Sources

Read both files:

```
docs/todo/teamtodo.md
docs/strats/questions4bryant.md
```

Parse all table rows. For each item, extract:
- **task_id** (e.g., QB-007, PPL-022, TOOL-006)
- **task** (short description)
- **owner** (who's accountable)
- **status** (NOT_STARTED, IN_PROGRESS, BLOCKED, IN_REVIEW, DONE, CANCELLED)
- **priority** (P0, P1, P2, P3)
- **due_date**
- **blocked_by** (if BLOCKED)

For QB items in questions4bryant.md, map status using the table above. Owner comes from the **Owner:** field in each QB entry.

---

## Phase 2 — Filter

**Filter by person:** Match the `owner` field. Also check `delegate` — if someone is delegated work, show it under their name with a "(delegated)" tag.

**Filter out completed:** Exclude DONE and CANCELLED items unless the user asks for them.

**Sort order:**
1. BLOCKED items first (these need attention)
2. Then by priority (P0 → P1 → P2 → P3)
3. Then by due date (soonest first)
4. Then by prefix (QB before PPL before INF before TOOL)

---

## Phase 3 — Display

### Format for a specific person

```
## [Name]'s Open Items

### Blocked (needs attention)
| ID | Task | Blocked By | Due |
|----|------|-----------|-----|
| ... | ... | ... | ... |

### Questions (QB)
| ID | Question | Status | Due |
|----|----------|--------|-----|
| ... | ... | ... | ... |

### Action Items
| ID | Task | Status | Priority | Due |
|----|------|--------|----------|-----|
| ... | ... | ... | ... | ... |

### Tool Cancellations
| ID | Tool | Action | Due |
|----|------|--------|-----|
| ... | ... | ... | ... |

**Summary:** X open items (Y blocked, Z overdue)
```

### Format for `all`

Group by person, then show each person's items in the format above.

### Format for `overdue`

Show all items where `due_date` is before today, regardless of owner. Sort by how overdue (most overdue first).

---

## Rules

- **Never show DONE or CANCELLED items** unless explicitly asked
- **Never scan meeting notes, STATE.md, or config.yaml** — those are context, not sources
- **If a QB item appears in both sources with different statuses, flag it** — "Status drift detected: QB-007 is RAISED in questions file but IN_PROGRESS in task tracker"
- **Show the count** at the end: "X open items (Y blocked, Z overdue)"
- **Keep it short** — this is a quick-glance tool, not a deep analysis
- **Use today's date** for overdue calculation (read from system or context)

---

## Promotion Protocol Reminder

If the user mentions a new action item during conversation that isn't in either source, remind them:

> "That's not tracked yet. Want me to add it to teamtodo.md? I'll need: owner, priority, and due date."

This is the only way new items enter the system — explicitly, into one of the two authoritative sources.
