# Bolt Review — End-of-Sprint Comprehensive Review

Usage: `/bolt-review`

**Arguments:** $ARGUMENTS

---

## Purpose

Conducts a comprehensive end-of-Bolt (sprint) review that combines:
1. PM sprint closure with metrics
2. A focused five-persona review of changes made during the Bolt
3. Security scan of new/changed code
4. Documentation currency check
5. Budget impact assessment

This is the "Friday ritual" that keeps quality high across Bolts.

---

## Instructions for Claude

### 1. Identify the Bolt Scope

```bash
# Read current sprint
cat docs/pm/CURRENT-SPRINT.md

# Find commits in this Bolt
git log --oneline --since="[bolt start date]"

# Files changed
git diff --stat [bolt start]..HEAD
```

### 2. Sprint Metrics

Gather and present:

```
📊 Bolt [N] — [Name] Summary

| Metric | Start | End | Delta |
|--------|-------|-----|-------|
| Tests | [N] | [N] | +[N] |
| Commits | — | [N] | — |
| Deploys | [N] | [N] | +[N] |
| Blocked % | — | [N]% | — |
| Files changed | — | [N] | — |
| Lines added | — | +[N] | — |
| Lines removed | — | -[N] | — |
```

### 3. Focused Code Review

Run a lightweight version of the five-persona review, scoped to files changed during this Bolt only. Focus on:
- New code quality
- Test coverage of new features
- Security implications of changes
- Documentation updates needed

### 4. Security Quick-Scan

Check new/changed code for:
- [ ] No secrets committed
- [ ] Input validation on new endpoints
- [ ] Authentication on new routes
- [ ] SQL parameterization (if DB changes)
- [ ] Dependency versions pinned
- [ ] No new OWASP Top 10 vulnerabilities

### 5. Documentation Currency

Check that these files reflect current state:
- [ ] `CLAUDE.md` — architecture, project structure, status
- [ ] `README.md` — features, setup, usage
- [ ] `CHANGELOG.md` — all changes logged
- [ ] `SECURITY.md` — any new controls or limitations
- [ ] `docs/pm/BACKLOG.md` — completed items marked done
- [ ] Relevant manuals updated

### 6. Budget Impact

If infrastructure changed:
- New resources added? Update `docs/budget/BUDGET.md`
- Resources removed? Update budget
- Cost estimate still accurate?

### 7. Output Report

Present the full review and offer to:
1. Fix any Critical/High findings immediately
2. Archive the Bolt to `docs/pm/SPRINT-LOG.md`
3. Update documentation
4. Create the next Bolt plan

### 8. Retrospective

Ask:
- What shipped this Bolt?
- What blocked us?
- One thing to do differently next Bolt?

Record the answer in the sprint log.
