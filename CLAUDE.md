# Skillzees — AI Context File

## What This Project Is

A portable collection of Claude Code slash commands and skills that encode staff-level engineering practices. Commands (`.md` prompt files) install to `~/.claude/commands/` and skills (full `SKILL.md` definitions) install to `~/.claude/skills/<name>/`. Both become available in any Claude Code session.

## Project Structure

```
skillzees/
├── CLAUDE.md                  # This file — AI context
├── README.md                  # Project documentation
├── CHANGES.md                 # Project changelog (not changelog.md — that's a command)
├── SECURITY.md                # Security policy
├── LICENSE                    # MIT
├── install.sh                 # Installer script (commands + skills → ~/.claude/)
├── .gitignore
├── docs/                      # Project standards and requirements
│   ├── REQUIREMENTS.md
│   └── standards/
├── tests/                     # Validation tests
│   └── validate.sh
├── skills/                    # Skill definitions (34 skills)
│   ├── ai-effort/SKILL.md
│   ├── am/SKILL.md
│   ├── ...                    # Each skill has its own directory with SKILL.md
│   └── weekly-update/SKILL.md
├── *.md                       # Slash command files (33 commands)
└── generate-readme.md         # Installs as readme.md (macOS collision avoidance)
```

## Commands (33)

| Command | File | Category |
|---------|------|----------|
| `/five-persona-review` | `five-persona-review.md` | Code Quality & Review |
| `/security-audit` | `security-audit.md` | Code Quality & Review |
| `/arch-audit` | `arch-audit.md` | Code Quality & Review |
| `/staff` | `staff.md` | Code Quality & Review |
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
| `/compose` | `compose.md` | Development Workflow |
| `/dlc-loop` | `dlc-loop.md` | Development Workflow |
| `/route` | `route.md` | Development Workflow |
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

## Skills (34)

Skills are full prompt definitions in `skills/<name>/SKILL.md`. Some commands are thin stubs that load their corresponding skill.

| Skill | Description |
|-------|-------------|
| `ai-effort` | Weekly commit activity scanning and AI time-savings estimates |
| `am` | Account manager daily/weekly workflow |
| `chealth` | CallHero comprehensive health check |
| `conversion-plumber` | CTA link audit and conversion path consolidation |
| `design-panel` | Web design review panel (4 designers + moderator) |
| `dlc-audit` | AI-DLC compliance audit with numeric scoring |
| `docs` | Documentation generation (AI-DLC standard) |
| `exec-review` | Executive review panel (5 strategic thinkers) |
| `fin-audit` | Financial audit panel (McKinsey, Deloitte, EY, PwC, KPMG) |
| `init-brain` | Retrofit knowledge management brain into any repo |
| `internal-link-builder` | Internal links and CTAs for top blog posts |
| `llm-team` | LLM/GEO/AIO optimization panel |
| `marketing-team` | B2B SaaS marketing strategy panel |
| `moat-content-writer` | Billing expertise blog posts with data advantage |
| `motherhen` | Project health and compliance monitor |
| `mytodo` | Accurate per-person todo view |
| `pipe-lfg` | Three-pillar pipeline health check |
| `pm` | Project management update |
| `prd-go` | Production-ready PRD writer |
| `prodstatus` | Production health dashboard |
| `qb` | Question log for leadership |
| `refine-page` | Full-cycle page refinement |
| `seo-meta-agent` | Title tag and meta description rewriter |
| `sitrep` | Executive situation report |
| `staff` | Staff engineer panel analysis |
| `staff-rfc` | Staff engineer RFC proposals |
| `ticky` | Azure DevOps work item lifecycle |
| `truck-incentives` | Canadian truck financing deals research |
| `vehicle-finder` | Dealership vehicle search and scoring |
| `vertical-builder` | Martial arts/fitness vertical page builder |
| `webby` | Simple website collaborator guide |
| `webgeni` | Marketing team orchestrator |
| `webteam` | Astro website repo team sync |
| `weekly-update` | OKR-disciplined weekly self-review |

## Conventions

- **File naming:** Command files are lowercase kebab-case `.md` files
- **macOS collision avoidance:** `generate-readme.md` installs as `readme.md` to avoid conflicting with `README.md`. Project changelog is `CHANGES.md` to avoid conflicting with `changelog.md` command
- **Install mapping:** The `COMMANDS` array in `install.sh` maps `source:destination` — most are identity mappings except `generate-readme.md:readme.md`
- **Command format:** Each `.md` file follows the pattern: Usage line, Arguments (`$ARGUMENTS`), Purpose section, Instructions for Claude, Parse Arguments, Action-specific sections
- **Multi-action commands** (pm, budget, captainslog, docs, dlc-audit): Have a default action and use `$ARGUMENTS` for action routing

## Current State

- **Version:** v3.0.0
- **Commands:** 33
- **Skills:** 34
- **Origin:** Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project
- **License:** MIT
