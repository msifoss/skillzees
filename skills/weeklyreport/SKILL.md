---
name: weeklyreport
description: Scaffold the current week's report file at docs/weekly_reports/YYYY-WW.md with standard sections pre-filled. Uses ISO week (e.g., 2026-W21 for the week of May 18, 2026).
---

# /weeklyreport

When invoked:

1. **Determine the ISO week.** Compute today's ISO year + ISO week (`date +%G-W%V` on macOS). Example: 2026-05-18 → `2026-W21`.
2. **Check for existing file.** If `docs/weekly_reports/<YYYY-WW>.md` exists, print: "This week's report already exists at `<path>`. Open it to continue editing." Do not overwrite.
3. **Create the file** with this scaffold:

   ```markdown
   # Weekly report — <YYYY-WW>

   _Week of <YYYY-MM-DD> (Monday) to <YYYY-MM-DD> (Sunday). Compiled by <author>._

   ## Wins

   -

   ## Losses

   -

   ## Blockers

   -

   ## Next-week focus

   -

   ## Scoreboard

   | Metric | Latest | WoW | Target |
   |---|---|---|---|
   | Net Revenue (TTM) | TBD | TBD | 2-3x baseline |
   | EBITA % | TBD | TBD | >=20% |
   | Open P0 tasks | TBD | TBD | — |
   ```

4. **Confirm.** Print the new file's path.

## Context

Spec §4.5 — Miranda already submits a weekly report to Bryant externally by Friday midday. The in-repo weekly report is **optional/archival**. Use this skill if you want to keep a copy in-repo for the team to reference.
