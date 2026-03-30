# Skillzees

**30 global slash commands for Claude Code — staff-level engineering practices, portable to every project.**

Skillzees is a collection of Claude Code slash commands (`.md` prompt files) that encode battle-tested workflows for code review, security auditing, sprint management, documentation, compliance, and more. Install once, use everywhere.

Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project — refined across 16 development sprints, 155 security findings, and production deployment.

---

## Quick Start

```bash
# Clone and install
git clone https://github.com/msifoss/skillzees.git /tmp/skillzees
bash /tmp/skillzees/install.sh --from /tmp/skillzees

# Or from an existing clone
bash /path/to/skillzees/install.sh --force
```

All 30 commands are immediately available as `/command-name` in any Claude Code session. Run `/quickstart` to see the essentials.

---

## Commands (30)

### Code Quality & Review

| Command | Description |
|---|---|
| **`/five-persona-review`** | Deep code review from 12 independent expert personas — staff engineer, security, SRE, first principles, and more |
| **`/security-audit`** | Structured security audit covering OWASP Top 10, auth, secrets, encryption, infrastructure, dependencies, and operations |
| **`/arch-audit`** | Multi-persona architectural audit with Mermaid diagrams, findings matrix, and staff-engineer perspectives |
| **`/staff-panel`** | Convene 4 staff engineers + moderator to independently analyze a technical problem and produce consensus |
| **`/dlc-audit`** | AI-DLC compliance audit — 8-dimension process adherence assessment with 0-10 scoring and maturity rating |
| **`/motherhen`** | Project health monitor — adaptive checks for documentation drift, test health, release hygiene, and compliance |

### Planning & Strategy

| Command | Description |
|---|---|
| **`/brainstorm`** | Structured exploration of what to build — collaborative dialogue that produces a brainstorm document before any code |
| **`/deepen-plan`** | Launch 10 domain-specialized research agents in parallel to stress-test and strengthen any plan |
| **`/prd-go`** | Write production-ready PRDs with testable acceptance criteria, data model specs, and F-numbered requirements |
| **`/exec-review`** | Executive review panel — Jim Collins moderates 5 strategic thinkers (Dunford, Larson, Dalio, Leonard, Scott) |
| **`/cost-estimate`** | Development effort estimation with T-shirt sizes, timeline projections, and AI-pair benchmarks |

### Project Management

| Command | Description |
|---|---|
| **`/pm`** | Bolt sprint management — plan, status, close, backlog grooming, and metrics tracking |
| **`/bolt-review`** | End-of-sprint comprehensive review combining PM closure, code review, security scan, and documentation check |
| **`/captainslog`** | Session logs that preserve context between AI conversations — new, update, list, and read actions |
| **`/ticky`** | Full lifecycle Azure DevOps ticket management — draft, submit, sync, and cleanup work items across repos |
| **`/am`** | Account manager daily/weekly workflow — briefings, client prep, negotiations, and expansion signals |

### Development Workflow & Automation

| Command | Description |
|---|---|
| **`/bolt-lfg`** | Autonomous Bolt pipeline — full end-to-end engineering with governance gates, from plan to deploy |
| **`/slfg`** | Swarm mode autonomous pipeline — parallel execution variant that runs independent items simultaneously |
| **`/init-project`** | Scaffold a new project with CI, tests, docs, PM framework, security policy, and budget tracking (AI-DLC standard) |
| **`/setup`** | Configure AI-DLC per-project settings with auto-detected stack defaults |

### Documentation

| Command | Description |
|---|---|
| **`/docs`** | Generate and maintain all project documentation — README, CHANGELOG, SECURITY, audience-specific manuals, runbooks |
| **`/readme`** | Generate a comprehensive, production-quality README |
| **`/changelog`** | Update CHANGELOG.md from git history following Keep a Changelog format |

### Operations & Infrastructure

| Command | Description |
|---|---|
| **`/prodstatus`** | Production health dashboard — read-only AWS infrastructure diagnostics and deployment verification |
| **`/budget`** | Infrastructure cost tracking with per-resource breakdowns and optimization analysis |
| **`/monthly-refresh`** | Datalake monthly data refresh — pull from APS, update snapshots, sync to HubSpot |

### Skill Development & Meta-Tools

| Command | Description |
|---|---|
| **`/create-skill`** | Scaffold a new skill or command with correct structure, frontmatter, and integration points |
| **`/generate-command`** | Quick-create a lightweight single-purpose slash command |
| **`/heal-skill`** | Diagnose and fix broken skills — validates structure, integration, and repair |
| **`/quickstart`** | Get started in 60 seconds — simplifies 30 tools down to 3 essential commands for new users |

---

## How It Works

Each command is a Markdown file containing a structured prompt. When you type `/command-name` in Claude Code, the prompt is loaded and Claude follows its instructions — running tools, reading code, writing files, and producing structured output.

Commands install to `~/.claude/commands/` and are available globally across all projects.

### Command Format

Every command file follows this pattern:

```markdown
# /command-name — One-Line Description

Usage: `/command-name [arguments]`

**Arguments:** $ARGUMENTS

## Purpose
What this command does and when to use it.

## Instructions
Step-by-step instructions for Claude to follow.
```

The `$ARGUMENTS` variable captures everything the user types after the command name.

---

## Project Structure

```
skillzees/
├── CLAUDE.md                  # AI context file
├── README.md                  # This file
├── CHANGES.md                 # Project changelog
├── SECURITY.md                # Security policy
├── LICENSE                    # MIT
├── install.sh                 # Installer (copies .md → ~/.claude/commands/)
├── .gitignore
├── docs/                      # Project standards and requirements
│   ├── REQUIREMENTS.md
│   └── standards/
├── tests/
│   └── validate.sh            # Validation tests
└── *.md                       # 30 slash command files
```

---

## Install Script

```bash
bash install.sh [OPTIONS]
```

| Flag | Effect |
|---|---|
| `--from DIR` | Source directory containing command files |
| `--force` | Overwrite existing commands without prompting |
| `--list` | Show installed vs. available commands |
| `--uninstall` | Remove all installed commands |

### Updating

```bash
cd /path/to/skillzees && git pull && bash install.sh --force
```

### File Mapping

Most files install with the same name. One exception:

| Repo File | Installs As | Why |
|---|---|---|
| `generate-readme.md` | `readme.md` | Avoids collision with `README.md` on case-insensitive filesystems (macOS) |

---

## What `/init-project` Scaffolds

```
my-app/
├── CLAUDE.md                    # AI operating manual
├── README.md                    # Project documentation
├── SECURITY.md                  # Security policy
├── CHANGELOG.md                 # Version history
├── Makefile                     # Standard targets (test, lint, format, audit)
├── .pre-commit-config.yaml      # Format + lint + test on every commit
├── .gitignore                   # Language-appropriate ignores
├── .env.example                 # Environment config template
├── azure-pipelines.yml          # CI pipeline
├── tests/
│   ├── unit/
│   ├── integration/
│   └── mocks/
├── scripts/
├── architecture/                # Mermaid diagrams
└── docs/
    ├── manuals/                 # Audience-specific guides
    ├── captains_log/            # AI session continuity
    ├── security/                # Audit reports
    ├── reviews/                 # Code review logs
    ├── tickets/                 # Work item tracking
    ├── budget/BUDGET.md         # Cost analysis
    └── pm/                      # Sprint management
        ├── FRAMEWORK.md
        ├── CURRENT-SPRINT.md
        ├── SPRINT-LOG.md
        └── BACKLOG.md
```

Supports **Python**, **Node/TypeScript**, and **Go**. Adapts CI, linting, formatting, and testing to your stack.

---

## The Bolt Sprint Framework

One-week sprint cycles optimized for solo developer + AI pair:

```
Monday    → Bolt Planning (15 min)
Tue–Thu   → Build
Friday    → Bolt Review + Retro (15 min)
```

**Four metrics per Bolt:** Commits, Tests Delta, Deploys, Blocked %

**T-shirt sizing:** S (< 1hr) | M (< half day) | L (~ 1 day) | XL (multi-day)

---

## License

MIT
