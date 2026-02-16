# Solo+AI Workflow Guide — Skillzees

## Development Model

Skillzees is developed solo with AI pair (Claude Code). Each command file is a self-contained markdown prompt — there's no traditional application code, just prompt engineering.

## Workflow

1. **Identify need** — A repeated pattern or missing capability during project work
2. **Draft command** — Write the `.md` file following the multi-action pattern (Usage, Arguments, Purpose, Instructions, Actions)
3. **Test locally** — Install via `bash install.sh --from . --force` and invoke in a Claude Code session
4. **Iterate** — Refine based on actual Claude behavior
5. **Validate** — Run `bash tests/validate.sh` to ensure consistency
6. **Commit and push** — Add to repo, update install.sh COMMANDS array, README tables, and header comment

## Conventions

- Commands that take no arguments still include `$ARGUMENTS` for consistency (exception: `generate-readme.md` legacy format)
- Multi-action commands always have a default action
- New commands must be added to three places: COMMANDS array, header comment, README tables
- File mapping table in README must stay in sync with COMMANDS array
