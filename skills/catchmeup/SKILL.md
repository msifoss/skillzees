---
name: catchmeup
description: First-load orientation for a leader. Identifies them by first name, shows their open todos, asks the baseline question, and saves the answer. Triggered by /catchmeup <firstname> or by the natural-language phrase "My name is <firstname>, catch me up." Run once per leader.
---

# /catchmeup

When invoked:

1. **Identify the leader.** Take the first name from the argument or the natural-language phrase. Map first name → last name using `config.yaml` (the `team:` section).
2. **Show open todos.** Read `docs/todo/teamtodo.md` and print the rows where `owner` matches the leader's full name and `status` is not `DONE` or `CANCELLED`. Same filtering behavior as `/mytodo <firstname>`.
3. **Ask the baseline question verbatim:**

   > "What specifically will it take from your department to achieve 2-3x in Net Revenue while maintaining our EBITA margin?"

4. **Wait for the leader's full answer.** Do not paraphrase or summarize while they type.
5. **Save the answer.** Write to `docs/onboarding/baseline-<lastname>.md` using this format:

   ```markdown
   ---
   leader: <firstname> <lastname>
   role: <role from config.yaml>
   date_captured: YYYY-MM-DD
   ---

   # Baseline answer — <firstname> <lastname>

   **Question:** What specifically will it take from your department to achieve 2-3x in Net Revenue while maintaining our EBITA margin?

   **Answer:**

   <the leader's full answer, verbatim>
   ```

6. **Update INDEX.** Append a row to `docs/onboarding/INDEX.md`:

   `| YYYY-MM-DD | <firstname> <lastname> | <one-line summary you generate from the answer> | baseline-<lastname>.md |`

7. **Confirm.** Tell the leader: "Baseline saved to `docs/onboarding/baseline-<lastname>.md`. Welcome to bigify."

## Edge cases

- **Baseline already exists.** If `baseline-<lastname>.md` exists, ask the leader: "You already have a baseline on file from `<date>`. Overwrite (replace), append (add a dated entry below), or cancel?" Default to append.
- **Unknown name.** If the first name isn't in `config.yaml`, ask the leader to confirm spelling or check the roster.
- **Leader runs `/catchmeup` with no argument.** Try the git user's email → first name lookup; if that fails, prompt for the name.

## Why this exists

Captures every leader's uninfluenced first-take on what their department will need to deliver, **before** they've seen the dept-planning templates or anyone else's answer. The baselines get diffed against `docs/departments/<dept>/goals-12mo.md` later to track how thinking evolved.
