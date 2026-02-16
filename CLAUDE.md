# Skillzees — AI Context File

## What This Project Is

A portable collection of Claude Code slash commands (`.md` prompt files) that encode staff-level engineering practices. Commands are installed globally to `~/.claude/commands/` and become available as `/command-name` in any Claude Code session.

## Project Structure

```
skillzees/
├── CLAUDE.md                  # This file — AI context
├── README.md                  # Project documentation
├── CHANGES.md                 # Project changelog (not changelog.md — that's a command)
├── SECURITY.md                # Security policy
├── LICENSE                    # MIT
├── install.sh                 # Installer script (copies .md → ~/.claude/commands/)
├── .gitignore
├── docs/                      # Project standards and requirements
│   ├── REQUIREMENTS.md
│   └── standards/
├── tests/                     # Validation tests
│   └── validate.sh
├── *.md                       # Slash command files (15 commands)
└── generate-readme.md         # Installs as readme.md (macOS collision avoidance)
```

## Commands (15)

| Command | File | Category |
|---------|------|----------|
| `/init-project` | `init-project.md` | Project Lifecycle |
| `/readme` | `generate-readme.md` | Project Lifecycle |
| `/changelog` | `changelog.md` | Project Lifecycle |
| `/docs` | `docs.md` | Project Lifecycle |
| `/five-persona-review` | `five-persona-review.md` | Code Quality |
| `/security-audit` | `security-audit.md` | Code Quality |
| `/dlc-audit` | `dlc-audit.md` | Code Quality |
| `/motherhen` | `motherhen.md` | Code Quality |
| `/pm` | `pm.md` | Project Management |
| `/bolt-review` | `bolt-review.md` | Project Management |
| `/captainslog` | `captainslog.md` | Project Management |
| `/ticky` | `ticky.md` | Project Management |
| `/budget` | `budget.md` | Planning & Cost |
| `/cost-estimate` | `cost-estimate.md` | Planning & Cost |
| `/prodstatus` | `prodstatus.md` | Operations |

## Conventions

- **File naming:** Command files are lowercase kebab-case `.md` files
- **macOS collision avoidance:** `generate-readme.md` installs as `readme.md` to avoid conflicting with `README.md`. Project changelog is `CHANGES.md` to avoid conflicting with `changelog.md` command
- **Install mapping:** The `COMMANDS` array in `install.sh` maps `source:destination` — most are identity mappings except `generate-readme.md:readme.md`
- **Command format:** Each `.md` file follows the pattern: Usage line, Arguments (`$ARGUMENTS`), Purpose section, Instructions for Claude, Parse Arguments, Action-specific sections
- **Multi-action commands** (pm, budget, captainslog, docs, dlc-audit): Have a default action and use `$ARGUMENTS` for action routing

## Current State

- **Version:** v1.0.0
- **Commands:** 15
- **Origin:** Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project
- **License:** MIT
