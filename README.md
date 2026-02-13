# Skillzees

**Global slash commands for Claude Code — battle-tested through 16 development sprints, 155 security findings, and production deployment.**

Skillzees is a portable collection of Claude Code slash commands that bring staff-level engineering practices to every project. Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project, these commands encode the workflows, review processes, and operational standards developed across a full production build.

---

## Quick Install

```bash
git clone https://github.com/msifoss/skillzees.git /tmp/skillzees
bash /tmp/skillzees/install.sh --from /tmp/skillzees
```

Or if you already have it cloned:

```bash
bash /path/to/skillzees/install.sh --from /path/to/skillzees
```

That's it. All commands are immediately available as `/command-name` in any Claude Code session.

---

## Commands

### Project Lifecycle

| Command | Purpose |
|---|---|
| **`/init-project`** | Scaffold a new project with CI, tests, docs, PM framework, security policy, and budget tracking |
| **`/readme`** | Generate a comprehensive, Will-Larson-quality README |
| **`/changelog`** | Update CHANGELOG.md from git history (Keep a Changelog format) |

### Code Quality

| Command | Purpose |
|---|---|
| **`/five-persona-review`** | Deep code review from 5 expert perspectives: Staff Engineer, First Principles, Radical Transparency, CTO/Security, SRE/DevOps |
| **`/security-audit`** | Structured security audit covering auth, input validation, secrets, encryption, network, infrastructure, dependencies, monitoring, and operations |

### Project Management

| Command | Purpose |
|---|---|
| **`/pm`** | Bolt-based sprint management — plan, status, close, backlog grooming, metrics |
| **`/bolt-review`** | End-of-sprint comprehensive review (code + security + docs + budget) |
| **`/captainslog`** | Session logs that preserve context between AI conversations |

### Planning & Cost

| Command | Purpose |
|---|---|
| **`/budget`** | Infrastructure cost tracking, per-resource breakdowns, optimization analysis |
| **`/cost-estimate`** | Development effort estimation with T-shirt sizes and AI-pair benchmarks |

---

## What Gets Scaffolded by `/init-project`

When you run `/init-project my-app`, you get:

```
my-app/
├── CLAUDE.md                    # AI operating manual (source of truth)
├── README.md                    # Comprehensive project docs
├── SECURITY.md                  # Security policy and controls
├── CHANGELOG.md                 # Version history
├── Makefile                     # Standard targets (test, lint, format, audit)
├── .pre-commit-config.yaml      # Format + lint + test on every commit
├── .gitignore                   # Language-appropriate ignores
├── .env.example                 # Environment config template
├── azure-pipelines.yml          # CI pipeline (or GitHub Actions)
├── .vscode/settings.json        # Editor config (format-on-save)
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
    ├── tickets/                 # External dependency tickets
    ├── budget/BUDGET.md         # Cost analysis
    └── pm/                      # Sprint management
        ├── FRAMEWORK.md         # Bolt sprint methodology
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

**Four metrics per Bolt:** Commits, Tests Δ, Deploys, Blocked %

**T-shirt sizing:** S (< 1hr), M (< half day), L (~ 1 day), XL (multi-day)

---

## The Five-Persona Review

| Persona | Focus |
|---|---|
| **Staff Engineer** (Will Larson) | Code quality, error handling, testing gaps |
| **First Principles** (Elon Musk) | Over-engineering, dead code, unnecessary complexity |
| **Radical Transparency** (Ray Dalio) | Docs accuracy, ops readiness |
| **CTO / Security Architect** | Security, architecture, scalability |
| **SRE / DevOps Staff Engineer** | Infrastructure, monitoring, reliability |

Found **155 findings** across 4 rounds in callhero.

---

## Install Script

```bash
bash install.sh [OPTIONS]
```

| Flag | Effect |
|---|---|
| `--from DIR` | Source directory containing .md command files |
| `--force` | Overwrite existing without prompting |
| `--list` | Show installed vs available commands |
| `--uninstall` | Remove all installed commands |

### Updating

```bash
cd /path/to/skillzees && git pull && bash install.sh --force
```

---

## File Mapping

Commands install to `~/.claude/commands/` with these names:

| Repo File | Installed As | Slash Command |
|---|---|---|
| `init-project.md` | `init-project.md` | `/init-project` |
| `five-persona-review.md` | `five-persona-review.md` | `/five-persona-review` |
| `security-audit.md` | `security-audit.md` | `/security-audit` |
| `pm.md` | `pm.md` | `/pm` |
| `budget.md` | `budget.md` | `/budget` |
| `bolt-review.md` | `bolt-review.md` | `/bolt-review` |
| `changelog.md` | `changelog.md` | `/changelog` |
| `cost-estimate.md` | `cost-estimate.md` | `/cost-estimate` |
| `generate-readme.md` | `readme.md` | `/readme` |
| `captainslog.md` | `captainslog.md` | `/captainslog` |

> **Note:** `generate-readme.md` is renamed to `readme.md` during install to avoid conflicting with the repo's own `README.md` on case-insensitive filesystems (macOS).

---

## License

MIT
