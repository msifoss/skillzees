# Skillzees — Requirements

## Purpose

Define what each slash command must do and how the installer must behave.

---

## Functional Requirements

### Installer (install.sh)

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-001 | Install all commands to `~/.claude/commands/` | All entries in COMMANDS array are copied to target directory |
| FR-002 | Support `--from DIR` flag for source directory | Installer reads `.md` files from specified directory |
| FR-003 | Support `--force` flag to overwrite without prompting | Existing files are overwritten silently when flag is set |
| FR-004 | Support `--list` flag to show install status | Each command shown with installed/available/not-found status |
| FR-005 | Support `--uninstall` flag to remove commands | All installed command files are deleted from target directory |
| FR-006 | Handle source-to-destination name mapping | `generate-readme.md` installs as `readme.md`; all others are identity-mapped |
| FR-007 | Detect and skip unchanged files | Files that match (via `diff -q`) are not re-copied |
| FR-008 | Report install summary | Show counts of installed, updated, and skipped commands |

### Command Files

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-009 | Each command file must be a valid markdown prompt | File has Usage line, `$ARGUMENTS` reference, Purpose section, and Instructions for Claude |
| FR-010 | Multi-action commands must have a default action | Commands with multiple actions specify which runs when no argument is given |
| FR-011 | Every command in COMMANDS array must have a corresponding `.md` file | `install.sh --list` shows no "not found" entries |
| FR-012 | Every `.md` command file must be listed in COMMANDS array | No orphan command files exist outside the array |
| FR-013 | README must list every command with its purpose | All commands appear in the Commands tables |
| FR-014 | README file mapping table must match COMMANDS array | Source file, installed name, and slash command are consistent |

---

## Non-Functional Requirements

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| NFR-001 | Installer runs on macOS and Linux | `bash install.sh` succeeds on both platforms |
| NFR-002 | No external dependencies for installer | Only bash builtins, `cp`, `diff`, `mkdir`, `rm` used |
| NFR-003 | Case-insensitive filesystem safety | No two files differ only by case (macOS HFS+/APFS compatibility) |
