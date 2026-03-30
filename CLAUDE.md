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
├── *.md                       # Slash command files (30 commands)
└── generate-readme.md         # Installs as readme.md (macOS collision avoidance)
```

## Commands (30)

| Command | File | Category |
|---------|------|----------|
| `/five-persona-review` | `five-persona-review.md` | Code Quality & Review |
| `/security-audit` | `security-audit.md` | Code Quality & Review |
| `/arch-audit` | `arch-audit.md` | Code Quality & Review |
| `/staff-panel` | `staff-panel.md` | Code Quality & Review |
| `/dlc-audit` | `dlc-audit.md` | Compliance & Audit |
| `/motherhen` | `motherhen.md` | Compliance & Audit |
| `/brainstorm` | `brainstorm.md` | Planning & Strategy |
| `/deepen-plan` | `deepen-plan.md` | Planning & Strategy |
| `/prd-go` | `prd-go.md` | Planning & Strategy |
| `/exec-review` | `exec-review.md` | Planning & Strategy |
| `/cost-estimate` | `cost-estimate.md` | Planning & Strategy |
| `/pm` | `pm.md` | Project Management |
| `/bolt-review` | `bolt-review.md` | Project Management |
| `/captainslog` | `captainslog.md` | Project Management |
| `/ticky` | `ticky.md` | Project Management |
| `/am` | `am.md` | Project Management |
| `/bolt-lfg` | `bolt-lfg.md` | Development Workflow |
| `/slfg` | `slfg.md` | Development Workflow |
| `/init-project` | `init-project.md` | Development Workflow |
| `/setup` | `setup.md` | Development Workflow |
| `/docs` | `docs.md` | Documentation |
| `/readme` | `generate-readme.md` | Documentation |
| `/changelog` | `changelog.md` | Documentation |
| `/prodstatus` | `prodstatus.md` | Operations |
| `/budget` | `budget.md` | Operations |
| `/monthly-refresh` | `monthly-refresh.md` | Operations |
| `/create-skill` | `create-skill.md` | Meta-Tools |
| `/generate-command` | `generate-command.md` | Meta-Tools |
| `/heal-skill` | `heal-skill.md` | Meta-Tools |
| `/quickstart` | `quickstart.md` | Meta-Tools |

## Conventions

- **File naming:** Command files are lowercase kebab-case `.md` files
- **macOS collision avoidance:** `generate-readme.md` installs as `readme.md` to avoid conflicting with `README.md`. Project changelog is `CHANGES.md` to avoid conflicting with `changelog.md` command
- **Install mapping:** The `COMMANDS` array in `install.sh` maps `source:destination` — most are identity mappings except `generate-readme.md:readme.md`
- **Command format:** Each `.md` file follows the pattern: Usage line, Arguments (`$ARGUMENTS`), Purpose section, Instructions for Claude, Parse Arguments, Action-specific sections
- **Multi-action commands** (pm, budget, captainslog, docs, dlc-audit): Have a default action and use `$ARGUMENTS` for action routing

## Current State

- **Version:** v2.0.0
- **Commands:** 30
- **Origin:** Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project
- **License:** MIT
