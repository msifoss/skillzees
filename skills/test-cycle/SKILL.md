# /test-cycle — Dev → Test → Report → Backlog Loop

Automated quality cycle that runs after code changes. Tests the platform, logs results, updates the backlog, and feeds findings back into the next dev cycle.

> The discipline loop: build → verify → document → plan → repeat. Every iteration leaves the codebase better than it found it.

## Trigger

- `/test-cycle` — Full cycle: run all tests, report results, update backlog
- `/test-cycle quick` — Unit + type-check only (no E2E, no report)
- `/test-cycle e2e` — E2E Playwright tests only against target environment
- `/test-cycle report` — Skip tests, just generate report from last run
- `/test-cycle loop` — Continuous: dev → test → fix → test until green

## Arguments

| Argument | Description |
|----------|-------------|
| `quick` | Fast: unit tests + type-check only (~5s) |
| `e2e` | E2E only: Playwright against local or production |
| `e2e:prod` | E2E against production (uses prod credentials) |
| `report` | Generate report from most recent test results |
| `loop` | Continuous fix-and-retest until all green |
| *(none)* | Full cycle: unit + integration + E2E + report + backlog |

---

## Phase 0 — Pre-Flight Check

Before running tests, verify the environment:

```bash
# Check project type and test infrastructure
ls package.json pnpm-lock.yaml 2>/dev/null
pnpm type-check 2>&1 | tail -3          # Must pass before testing

# Check if local stack is running (for E2E)
curl -s http://localhost:3080 2>/dev/null | head -1  # Portal
curl -s http://localhost:3000/v1/health 2>/dev/null  # API
```

**If type-check fails:** Stop. Fix type errors first. No point running tests on broken code.

**If local stack not running (and E2E requested):**
- Suggest: `./scripts/local-setup.sh crm98` to start local Docker stack
- Or: run against production with `E2E_BASE_URL=https://crm98.membies.com`

---

## Phase 1 — Run Tests

Execute tests in order, stopping at first failure tier:

### Tier 1: Static Analysis (always run)
```bash
pnpm type-check                    # TypeScript strict mode
pnpm lint                          # ESLint
```
**Gate:** Both must pass. If either fails, report and stop.

### Tier 2: Unit Tests (always run)
```bash
pnpm test                          # Vitest unit tests
```
**Gate:** All tests must pass. Report count and duration.

### Tier 3: Integration Tests (run unless `quick`)
```bash
pnpm test:integration              # Needs Docker PG
```
**Gate:** All tests must pass. If DB unavailable, skip with warning.

### Tier 4: E2E Tests (run if `e2e` or full cycle)

**Against local stack:**
```bash
cd apps/portal
npx playwright test
```

**Against production:**
```bash
cd apps/portal
E2E_BASE_URL=https://crm98.membies.com \
E2E_API_URL=https://crm98.membies.com \
E2E_ADMIN_EMAIL=kaptain@krm.membies.com \
E2E_OWNER_EMAIL=owner@downtownma.com \
npx playwright test
```

**Gate:** Report passed/failed/skipped. Failures don't block the report phase.

---

## Phase 2 — Collect Results

After all tiers complete, collect:

```
Test Cycle Results — [date] [time]
═══════════════════════════════════

Tier 1: Static Analysis
  Type-check: PASS/FAIL
  Lint:       PASS/FAIL

Tier 2: Unit Tests
  Files:    [N] test files
  Tests:    [N] passed, [N] failed
  Duration: [N]ms

Tier 3: Integration Tests
  Tests:    [N] passed, [N] failed (or SKIPPED)
  Duration: [N]ms

Tier 4: E2E Tests
  Target:   [local/production]
  Tests:    [N] passed, [N] failed, [N] skipped
  Duration: [N]s
  Traces:   apps/portal/e2e/results/

Overall: [PASS/FAIL] — [summary sentence]
```

---

## Phase 3 — Analyze Failures

For each failure, diagnose:

1. **Read the error message** — don't guess, read the actual output
2. **Classify the failure:**
   - **Flaky:** Passes on retry (timeout, race condition)
   - **Regression:** Was passing, now broken (code change caused it)
   - **New coverage gap:** Test found a real bug
   - **Test debt:** Test itself is wrong (bad locator, stale assertion)
3. **Determine owner:**
   - Code bug → create backlog item
   - Test bug → fix test immediately
   - Flaky test → add retry, increase timeout, or skip with TODO

---

## Phase 4 — Report

Generate a human-readable report:

```markdown
## Test Cycle Report — [date]

### Summary
[One sentence: "All green" or "3 failures found — 1 regression, 2 test debt"]

### Results
[Table from Phase 2]

### Failures (if any)
| # | Test | Tier | Classification | Action |
|---|------|------|---------------|--------|
| 1 | [test name] | [2/3/4] | [regression/flaky/test-debt] | [fix/backlog/skip] |

### Changes Since Last Cycle
[git log --oneline since last test-cycle report]

### Backlog Updates
- [New items added]
- [Items marked done based on test results]
```

**Save to:** `docs/test-cycles/YYYYMMDD-HHMM-test-cycle.md`

---

## Phase 5 — Update Backlog

Based on test results:

1. **If all green:**
   - Confirm backlog is current
   - Note test counts in completed bolt metrics
   - No new items needed

2. **If failures found:**
   - **Regressions:** Add to backlog as P0 (fix before next deploy)
   - **New bugs:** Add to backlog with appropriate priority
   - **Test debt:** Fix immediately or add as S-sized backlog item

3. **Update test counts** in CLAUDE.md if they've changed

---

## Phase 6 — Loop Mode (if `loop` argument)

When running in loop mode:

```
while failures exist:
    1. Read failure details
    2. Fix the code (smallest possible change)
    3. Run ONLY the failing tests (not full suite)
    4. If fixed → commit with "fix: [description]"
    5. If new failure → add to fix list
    6. Repeat
end

Run full suite to confirm all green
Commit + push
Generate final report
```

**Loop rules:**
- Maximum 5 fix iterations before escalating to user
- Each fix is a separate commit (atomic, reviewable)
- Don't fix non-test code during the loop (scope discipline)
- If a fix introduces a new failure, revert and escalate

---

## Phase 7 — CI Integration Reference

For automated CI, add this to `.github/workflows/ci.yml` after the integration test step:

```yaml
      - name: Install Playwright browsers
        run: npx playwright install chromium
        working-directory: apps/portal

      - name: Seed test data
        run: pnpm db:seed
        env:
          DATABASE_URL: postgresql://crm98:crm98@localhost:5432/crm98_test
          NODE_ENV: test

      - name: Start API for E2E
        run: pnpm --filter @crm98/api dev &
        env:
          DATABASE_URL: postgresql://crm98:crm98@localhost:5432/crm98_test
          REDIS_URL: redis://localhost:6379
          JWT_SECRET: test-secret-do-not-use-in-production
          NODE_ENV: test
          API_PORT: 3000

      - name: Start Portal for E2E
        run: pnpm --filter @crm98/portal dev &

      - name: Wait for services
        run: npx wait-on http://localhost:3000/v1/health http://localhost:5173 -t 30000

      - name: E2E Tests
        run: pnpm --filter @crm98/portal test:e2e
        env:
          E2E_BASE_URL: http://localhost:5173
          E2E_API_URL: http://localhost:3000

      - name: Upload E2E artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-results
          path: apps/portal/e2e/results/
          retention-days: 7
```

**Note:** This CI addition requires `workflow` scope on the GitHub token. Add manually or via GitHub web UI.

---

## Dev Cycle Integration

The test-cycle fits into the bolt workflow like this:

```
/bolt-lfg [feature]
  → brainstorm → plan → code → review → /test-cycle → captainslog → close
                                              ↑
                                    If failures: fix → retest (loop)
```

**When to run /test-cycle:**
- After completing a bolt's code phase (before review)
- After fixing review findings (before closing)
- Before cutting a release tag
- After deploying to production (E2E smoke)
- Weekly maintenance (catch drift)

---

## Quality Standards

### What makes a good test cycle
1. **Fast feedback** — unit tests in <5s, E2E in <60s
2. **Deterministic** — same code = same results (no flaky tests)
3. **Actionable** — every failure has a clear classification and next step
4. **Documented** — report exists for every cycle, not just failures
5. **Integrated** — results feed directly into the backlog

### Anti-patterns
- Running tests without reading failures ("it'll probably pass next time")
- Skipping E2E because "unit tests cover it"
- Fixing tests by weakening assertions instead of fixing code
- Running tests after deploy instead of before
- Not updating test counts in docs when tests are added/removed
