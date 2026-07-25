---
name: competitor
description: Scaffold a new competitor analysis from the template. Prompts for competitor name, threat level, and a one-line summary. Creates docs/research/competitive/<slug>.md and updates the INDEX.
---

# /competitor

When invoked:

1. **Gather inputs.**
   - Competitor name (display form, e.g., "Mariana Tek")
   - Threat level (high / medium / low — leader's first-take, can revise later)
   - One-line summary (positioning in one sentence)
2. **Generate slug.** Lowercase, hyphens for spaces, strip punctuation. "Mariana Tek" → `mariana-tek`.
3. **Check for existing file.** If `docs/research/competitive/<slug>.md` already exists, print: "Already exists — open the file to update it, or add a follow-up note in the file." Do not overwrite.
4. **Create file.** Copy from `docs/research/competitive/_template.md`, replace `<competitor name>` with the display name, set "Last updated" to today + caller's first name.
5. **Update INDEX.** Append a row to `docs/research/competitive/INDEX.md` (insert at the position matching its threat level — high first, low last):

   `| <display name> | <threat> | YYYY-MM-DD | <one-line summary> |`

6. **Confirm.** Print the new file's path.
