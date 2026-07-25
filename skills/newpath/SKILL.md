---
name: newpath
description: Scaffold a new candidate strategy path. Copies docs/strats/paths/_template/ to docs/strats/paths/path-NNN-<slug>/, prompts for thesis/assumptions/owner, updates docs/strats/INDEX.md. Convention - only Miranda runs this (trust-based, not enforced).
---

# /newpath

When invoked:

1. **Convention reminder.** Print: "By convention, only Miranda proposes new paths (spec §6.2). Continue only if you are Miranda or proposing on her behalf with her sign-off."
2. **Gather inputs.** Prompt for:
   - Path slug (kebab-case, e.g., `vertical-focus-martial-arts`)
   - One-paragraph thesis (the bet, why now, why us)
   - Top 3-5 bets
   - Top 3-5 risks
3. **Pick the next path number.** Scan `docs/strats/paths/` for existing `path-NNN-*` folders, find the highest N, increment. New folder: `path-N+1-<slug>`.
4. **Copy template.** `cp -R docs/strats/paths/_template docs/strats/paths/path-<NNN>-<slug>`
5. **Fill in `README.md`** with the gathered inputs. Status = `ACTIVE`. Created date = today. Owner = Miranda Pruitt (or whoever invoked, per the convention reminder).
6. **Update `docs/strats/INDEX.md`.** Append a row:

   `| path-<NNN>-<slug> | ACTIVE | <one-line thesis> | <owner> | YYYY-MM-DD |`

   If a TBD stub row exists at the bottom of the table (`path-001-tbd`, etc.), prefer replacing one of those with the real path instead of leaving the stub.
7. **Update `docs/STRATEGY.md`** Paths table similarly.
8. **Confirm.** Print the new path's folder path and remind the user to fill in `assumptions.md`, `milestones.md`, `forecast.md`, and `research_links.md`.

## Notes

- The skill does **not** enforce Miranda-only via git user check. Trust-based. The reminder in step 1 is the only guard.
- If three `path-NNN-tbd` stubs are still present at INDEX bottom, the first new path replaces `path-001-tbd`, the second replaces `path-002-tbd`, the third replaces `path-003-tbd`. Beyond three, increment normally.
