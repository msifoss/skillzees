---
name: interview
description: Scaffold a new customer interview file from the template. Prompts for customer name, segment, interviewer, date. Creates docs/research/customer_interviews/YYYYMMDD-<slug>-interview.md and updates the INDEX.
---

# /interview

When invoked:

1. **Gather inputs.** Prompt for:
   - Customer name (full, as you'd write it on a business card)
   - Segment (size · region · vertical, e.g., "mid-sized · UK · martial arts")
   - Interviewer (first name)
   - Date (default: today, YYYY-MM-DD)
   - Format (call / in-person / async)
2. **Generate slug.** Lowercase the customer name, replace spaces with hyphens, strip punctuation. Example: "Acme Fitness - Westwood" → `acme-fitness-westwood`.
3. **Create file.** `docs/research/customer_interviews/<YYYYMMDD>-<slug>-interview.md`. Copy from `docs/research/customer_interviews/_template.md`, then fill in the header block with the gathered inputs.
4. **Update INDEX.** Append a row to `docs/research/customer_interviews/INDEX.md`:

   `| YYYY-MM-DD | <customer name> | <interviewer> | <takeaway-tbd> | <YYYYMMDD>-<slug>-interview.md |`

   The "takeaway" column starts as `TBD` and gets updated after the interviewer writes their notes.
5. **Confirm.** Print the new file's path and remind the interviewer to update the INDEX row's takeaway after the interview, and to promote follow-ups to `DISC-NNN` tasks in `docs/todo/teamtodo.md`.

## Customer name confidentiality

Per spec §4.1: customer names in research files are confidential. They live in the repo, but must be stripped from any externally-published artifact.
