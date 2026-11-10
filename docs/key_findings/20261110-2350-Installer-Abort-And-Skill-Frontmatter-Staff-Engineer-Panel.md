# Installer Abort & Missing Skill Frontmatter — Staff Engineer Panel Analysis

**Date:** 2026-11-10
**Panel:** Tim (SpaceX), Rob (Roblox), Fran (Meta), Al (AWS — Systems Manager / instance bootstrap team), Will Larson (Moderator)
**Trigger:** Installing skillzees into a Claude Code cloud session. `install.sh` stopped after the first command, and 11 skills appeared without descriptions.

---

## Problem Statement

### What's happening

1. **`install.sh` aborts on any fresh machine.** It runs under `set -euo pipefail` and counts with `((INSTALLED++))`. Post-increment evaluates to the *old* value, so the first increment from 0 evaluates to `0`, `((…))` returns status 1, and `set -e` kills the script.
2. **11 of 94 skills have no YAML frontmatter.** They are `chealth`, `comparison-builder`, `feature-get`, `ingest`, `mytodo`, `partner-pull`, `pm`, `prodstatus`, `staff`, `test-cycle` and `weekly-update`. Claude Code falls back to the directory name and the first heading, so the model has no "when to use" text and the skills effectively never auto-trigger. `/name` still works.

### Impact

| Metric | Value | Evidence |
|---|---|---|
| Commands installed on a fresh `HOME` | **1 / 33** | `HOME=$(mktemp -d) bash install.sh` → exit 1 after `/init-project` |
| Skills installed on a fresh `HOME` | **0 / 94** | Script dies in Step 2, before Step 4 |
| Exit code | 1 | Fails cloud setup scripts, CI and `curl \| bash` |
| Counter sites affected | 16 | `grep -n '((' install.sh` |
| Skills without auto-trigger text | 11 / 94 (12%) | No `---` header |
| Skills on the repo's "Code Quality" path affected | `staff`, `pm` | Two of the most-used panels |

### Root cause chain

`set -e` → `((X++))` with X=0 evaluates to 0 → arithmetic command status 1 → shell exits → nothing after the first copy runs. `tests/validate.sh` only runs `bash -n` (syntax), so the runtime abort was never exercised.

Skills synced from older sources (pre-frontmatter era) → copied verbatim in the 2026-07-25 sweep → no validator checks frontmatter → silent degradation.

### Constraints

- No CI (`.github/` absent). `tests/validate.sh` is the only gate, and it runs manually.
- Public repo. Small, reviewable diffs are preferred.
- 71 of the 83 existing frontmatter blocks also carry `user-invocable`, `argument-hint` and `allowed-tools`.

---

## Panel Analysis

### Tim — Staff Engineer, SpaceX

**Risk assessment:** P(abort) = 1.0 on every first install. Consequence = the tool's only job fails. This is the top risk score possible for a tool this size. The frontmatter gap is P = 1.0 too, but the consequence is low: degraded discovery, not breakage.

**Options evaluated:**
- `((++X))`: works (pre-increment of 0 evaluates to 1), but stays one refactor away from the same bug. Rejected.
- `((X++)) || true` at 16 sites: noise that hides real failures. Rejected.
- Dropping `set -e`: removes the safety net for `cp` failures. Rejected.
- `X=$((X + 1))`: an assignment always returns 0. **Accepted.**

**Key quote:** "The best fix is the one that can't regress by accident. `$(( ))` in an assignment has no failure mode."

**Recommendation:** a mechanical sed across the 16 sites, about 10 minutes.

**On PR count:** "Two. The installer fix is a P1 bug; the frontmatter is metadata. Don't make the P1 wait on someone reviewing eleven descriptions."

**Unique contribution:** He ran the installer a second time and with `--force` to prove the *other* counter paths (`SKIPPED`, `UPDATED`, `SKILLS_UPDATED`) were also broken. They are: each fails on its first increment.

### Rob — Staff Engineer, Roblox

**Risk assessment:** The house already has the right pattern. `tests/validate.sh:16-17` uses `PASS=$((PASS + 1))`. The installer diverged from it, and that divergence *is* the bug.

**Options evaluated:** He agrees with `$(( ))` because it matches existing code, which keeps cognitive load low.

**Key quote:** "You didn't need a new idiom. You needed the one sitting forty lines away in the test file."

**Recommendation:** Fix the counters, and add a smoke test that actually *runs* the installer into `mktemp -d`.

**Unique contribution — latent bug:** With the counters fixed, Step 3 ("copy any .md not in the known list") now actually runs. It installs `CHANGES.md`, `CLAUDE.md` and `SECURITY.md` into `~/.claude/commands/` as slash commands (`/CLAUDE`, `/CHANGES`, `/SECURITY`). The only exclusion is `README.md`. This was masked by the abort. Verified in a scratch HOME.

### Fran — Staff Engineer, Meta

**Risk assessment:** Two buckets.
- **Fix yesterday:** the counter abort, plus a test that would have caught it.
- **Don't care (yet):** cosmetic frontmatter keys beyond `name` and `description`.

**Key quote:** "`bash -n` is a spell-checker, not a test. Pre-commit is a convenience; CI is the contract, and you have neither."

**Recommendation:** Two PRs. Each PR carries its own guard: PR 1 adds an install smoke test, and PR 2 adds a frontmatter check. Wire `validate.sh` into GitHub Actions later.

**On frontmatter scope:** Only `name` and `description` are required for discovery. `argument-hint` is free UX polish when the skill already documents its arguments. **Do not add `allowed-tools`**, because that changes permission behaviour and isn't metadata.

**Unique contribution:** She noticed `validate.sh` already fails on `main` (2 failures: `generate-readme.md` and `monthly-refresh.md` lack `$ARGUMENTS`). A suite that is always red trains people to ignore it. Fix it in a follow-up rather than smuggling it into these PRs.

### Al — Staff Engineer, AWS (Systems Manager / instance bootstrap)

**Risk assessment:** "I've seen thousands of bootstrap scripts. Non-zero exit in a user-data or setup hook is the #1 cause of half-provisioned machines." Cloud sessions run setup scripts exactly like user-data: an exit 1 here marks the environment's setup as failed.

**Options evaluated:** He agrees with `$(( ))`. For frontmatter, `description` should say *what it does* + *when to use it* + key trigger phrases, because that text is what the model matches against.

**Key quote:** "Your installer isn't a script, it's a bootstrap. Bootstraps must be idempotent and must exit 0 when there's nothing to do."

**Recommendation:** Add a re-run assertion (idempotency) to the smoke test.

**Unique contribution — latent bug:** The header advertises `curl -fsSL …/install.sh | bash`. Under a pipe, `BASH_SOURCE[0]` is empty, so `SCRIPT_DIR` resolves to the cwd and the script errors with "No source directory". Worse, the interactive `read -r` prompts would read the *script itself* from stdin. The documented one-liner cannot work.

---

## Consensus Matrix

| Question | Tim | Rob | Fran | Al |
|---|---|---|---|---|
| Two PRs (one concern each) | YES (5) | YES (4) | YES (5) | NO (2) — "both are tiny" |
| Counter fix = `X=$((X + 1))` | YES (5) | YES (5) | YES (4) | YES (4) |
| Add install smoke test to validate.sh | YES (4) | YES (5) | YES (5) | YES (5) |
| Frontmatter = name + description (+ argument-hint where documented) | YES (4) | YES (3) | YES (4) | YES (4) |
| Add `allowed-tools` to the 11 | NO (5) | NO (4) | NO (5) | NO (4) |
| validate.sh enforces frontmatter | YES (4) | YES (4) | YES (5) | YES (4) |
| Fix Step 3 extra-.md leak in these PRs | NO (4) | YES (3) | NO (4) | NO (3) |
| Total effort | 45 min | 1 h | 1 h | 1 h |

**Unanimous:** the `$(( ))` fix, a smoke test, frontmatter enforcement, and no `allowed-tools`.
**Majority (3-1):** two PRs (Al dissents); defer the Step 3 leak (Rob dissents).

### Vote Tally

| Decision | For | Against | Confidence | Result |
|---|---|---|---|---|
| Two PRs | 3 | 1 | 4.0 | APPROVED |
| `X=$((X + 1))` | 4 | 0 | 4.5 | APPROVED |
| Install smoke test | 4 | 0 | 4.75 | APPROVED |
| Minimal frontmatter | 4 | 0 | 3.75 | APPROVED |
| validate.sh enforces frontmatter | 4 | 0 | 4.25 | APPROVED |
| Fix Step 3 leak now | 1 | 3 | 3.5 | REJECTED (deferred) |

### Dissent Record

| Panelist | Decision | Position | Key Concern | Risk if Ignored |
|---|---|---|---|---|
| Al | Two PRs | AGAINST | Review overhead for two tiny diffs | Low: two short reviews |
| Rob | Defer Step 3 leak | FOR fixing now | The counter fix *activates* the leak, so merging PR 1 makes three junk commands appear | Users see `/CLAUDE`, `/CHANGES`, `/SECURITY` in their command list until the follow-up lands |

---

## Clarifying Questions

| Question | Answer (verified) | Impact |
|---|---|---|
| Is there CI that would have caught this? | No. `.github/` doesn't exist | Smoke test must live in `validate.sh`; CI deferred |
| Does validate.sh pass on `main` today? | No: 2 pre-existing `$ARGUMENTS` failures | New tests can't rely on "suite is green"; flag the follow-up |
| Do the other counter paths also abort? | Yes: rerun (`SKIPPED`) and `--force` (`UPDATED`) both reproduced | The fix must cover all 16 sites, not just `INSTALLED` |
| Does fixing the counters change install output? | Yes: Step 3 now runs and leaks 3 repo docs as commands | Rob's dissent is real, so it must be flagged in the PR body |
| Which frontmatter keys do existing skills use? | `name`, `description` (83/83); `user-invocable`, `argument-hint`, `allowed-tools` (71/83) | Required pair confirmed; `allowed-tools` would change behaviour |
| Is the repo public? | Yes (`gh api`: `visibility: public`) | `chealth` and `prodstatus` are self-labelled CONFIDENTIAL; out of scope, but flag it to the owner |

### Reassessment (Phase 4b)

Learning that the fix *activates* the Step 3 leak moved Fran's confidence on deferring from 5 to 4, but she held: "It's a separate defect with a separate fix and test; ship the P1 now and file it." Will accepted Rob's dissent as a risk item: the leak must be **called out in PR 1's description** with a follow-up.

---

## Will Larson's Decision

**Scope:** Tim's fix, Rob's and Al's tests, Fran's two-PR split and frontmatter scope.

| Step | What | Why | Effort |
|---|---|---|---|
| 1 | PR 1 `fix/install-counter-abort`: replace all 16 `((X++))` with `X=$((X + 1))` | Unanimous; matches `validate.sh` idiom | 10 min |
| 2 | PR 1: validate.sh test 7, which installs into `mktemp -d`, asserts exit 0, 33/33 commands, N/N skills and an idempotent re-run | Fran + Al: test the runtime, not the syntax | 20 min |
| 3 | PR 2 `fix/skill-frontmatter`: add `name` + `description` (+ `argument-hint` where the skill documents args) to the 11 skills | Restores auto-triggering; no behaviour change | 30 min |
| 4 | PR 2: validate.sh test 8, which checks every `skills/*/SKILL.md` opens with frontmatter, has `name` equal to its dir and a non-empty `description` | Prevents the next sync from regressing | 15 min |
| 5 | Both PR bodies list what is deliberately out of scope | Gitsmith rule 4: silence reads as "covered" | 5 min |

**Total: about 1.5 h. Fix the abort, guard it, restore discovery, guard that, and change nothing else.**

### Decision Record

```
DECISION: Split into two PRs (installer fix / skill frontmatter) | VOTE: 3-1 | CONFIDENCE: 4.0 | DISSENT: Al: review overhead for tiny diffs
DECISION: Counters use VAR=$((VAR + 1)) | VOTE: 4-0 | CONFIDENCE: 4.5 | DISSENT: NONE
DECISION: validate.sh runs installer end-to-end in scratch HOME | VOTE: 4-0 | CONFIDENCE: 4.75 | DISSENT: NONE
DECISION: Frontmatter = name + description (+ argument-hint), no allowed-tools | VOTE: 4-0 | CONFIDENCE: 3.75 | DISSENT: NONE
DECISION: validate.sh enforces skill frontmatter | VOTE: 4-0 | CONFIDENCE: 4.25 | DISSENT: NONE
DECISION: Defer Step 3 extra-.md leak to follow-up | VOTE: 3-1 | CONFIDENCE: 3.5 | DISSENT: Rob: PR 1 activates the leak
```

### What's explicitly deferred

| Item | Rationale | Revisit When |
|---|---|---|
| Step 3 installs `CHANGES.md` / `CLAUDE.md` / `SECURITY.md` as commands | Separate defect (Rob) | Immediately after PR 1 merges |
| `curl \| bash` one-liner cannot work (empty `BASH_SOURCE`, `read` consumes stdin) | Separate defect (Al) | Same follow-up as the Step 3 leak |
| Installer copies only `SKILL.md`, not sibling files | No skill has extra files today (0 found) | First skill that ships a script or template |
| 2 pre-existing `$ARGUMENTS` failures | Not caused by this work (Fran) | Next validate.sh touch |
| GitHub Actions running validate.sh | No CI exists; out of scope | When a second contributor starts merging |
| CONFIDENTIAL skills in a public repo | Ownership/policy question, not code | Owner decision |

### Key takeaways

> "`bash -n` is a spell-checker, not a test." — Fran

1. Under `set -e`, use only arithmetic that *assigns* (`x=$((x+1))`), never bare `((x++))`.
2. Fixing an abort exposes the code that never ran. Re-test the whole path after the fix, not just the line you changed (Rob).
3. A bootstrap must exit 0 on a re-run (Al).
4. Validators should check what silently degrades (frontmatter), not only what loudly breaks.

## Files Referenced

| File | Role |
|---|---|
| `install.sh` | Installer; 16 counter sites; Step 3 extra-.md loop |
| `tests/validate.sh` | Only test gate; existing `$(( ))` idiom at lines 16-17 |
| `skills/{chealth,comparison-builder,feature-get,ingest,mytodo,partner-pull,pm,prodstatus,staff,test-cycle,weekly-update}/SKILL.md` | Missing frontmatter |
| `CHANGES.md` | Changelog entries for both PRs |

## Findings to Fix

| # | File | Description | Fix | PR |
|---|---|---|---|---|
| F1 | `install.sh` (16 sites) | `((X++))` + `set -e` aborts on the first increment | `X=$((X + 1))` | 1 |
| F2 | `tests/validate.sh` | No runtime test of the installer | Test 7 smoke install | 1 |
| F3 | 11 × `SKILL.md` | No frontmatter, so no auto-trigger | Add `name` / `description` / `argument-hint` | 2 |
| F4 | `tests/validate.sh` | No frontmatter check | Test 8 | 2 |
| F5 | `install.sh` Step 3 | Repo docs installed as commands | Exclude non-command docs | follow-up |
| F6 | `install.sh` header | `curl \| bash` usage broken | Clone-to-temp wrapper, or `--from` required | follow-up |
| F7 | `generate-readme.md`, `monthly-refresh.md` | Fail the `$ARGUMENTS` check | Add a reference, or exempt | follow-up |
