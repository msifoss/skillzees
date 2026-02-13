# Skillzees

**Global slash commands for Claude Code — battle-tested through 16 development sprints, 155 security findings, and production deployment.**

Skillzees is a portable collection of Claude Code slash commands that bring staff-level engineering practices to every project. Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project, these commands encode the workflows, review processes, and operational standards developed across a full production build.

---

## Quick Install

```bash
git clone https://github.com/YOUR_ORG/skillzees.git /tmp/skillzees
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
| **`/init-project`** | Scaffold a new project with CI, tests, docs, PM framework, security policy, and budget tracking — all pre-configured |
| **`/readme`** | Generate a comprehensive, Will-Larson-quality README |
| **`/changelog`** | Update CHANGELOG.md from git history (Keep a Changelog format) |
| **`/docs`** | Generate audience-specific documentation (manuals, guides, references) |

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

When you run `/init-project my-app`, you get a project with:

```
my-app/
├── CLAUDE.md                    # AI operating manual (source of truth)
├── README.md                    # Comprehensive project docs
├── SECURITY.md                  # Security policy and controls
├── CHANGELOG.md                 # Version history
├── Makefile                     # Standard targets (test, lint, format, audit, etc.)
├── .pre-commit-config.yaml      # Format + lint + test on every commit
├── .gitignore                   # Language-appropriate ignores
├── .env.example                 # Environment config template
├── azure-pipelines.yml          # CI pipeline (or GitHub Actions)
│   (or .github/workflows/ci.yml)
├── .vscode/settings.json        # Editor config (format-on-save)
├── tests/
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── mocks/                   # Test mocks
├── scripts/                     # Operational scripts
├── architecture/                # Mermaid diagrams
└── docs/
    ├── manuals/                 # Audience-specific guides
    ├── captains_log/            # AI session continuity
    ├── security/                # Audit reports and findings
    ├── reviews/                 # Code review logs
    ├── tickets/                 # External dependency tickets
    ├── budget/                  # Cost analysis
    │   └── BUDGET.md
    ├── pm/                      # Sprint management
    │   ├── FRAMEWORK.md         # Bolt sprint methodology
    │   ├── CURRENT-SPRINT.md    # Active sprint
    │   ├── SPRINT-LOG.md        # Sprint archive
    │   └── BACKLOG.md           # Prioritized backlog
    └── story/                   # Project narrative
```

Supports Python, Node/TypeScript, and Go. Adapts CI, linting, formatting, and testing to your stack.

---

## The Bolt Sprint Framework

Skillzees uses **Bolts** — one-week sprint cycles optimized for solo developer + AI pair:

```
Monday    → Bolt Planning (15 min)
Tue–Thu   → Build
Friday    → Bolt Review + Retro (15 min)
```

**Four metrics tracked per Bolt:**

| Metric | What It Measures |
|---|---|
| Commits | Volume of shippable work |
| Tests Δ | Net change in test count |
| Deploys | Production deployments |
| Blocked % | Days blocked / total days |

**T-shirt sizing** instead of story points:

| Size | Meaning |
|---|---|
| S | Single file, < 1 hour |
| M | 2–5 files, < half day |
| L | 5–15 files, ~ 1 day |
| XL | Cross-cutting, multi-day |

---

## The Five-Persona Review

The `/five-persona-review` command runs 5 independent expert reviews:

| Persona | Focus |
|---|---|
| **Staff Engineer** (Will Larson) | Code quality, error handling, testing gaps, operational readiness |
| **First Principles** (Elon Musk) | Over-engineering, unnecessary complexity, dead code |
| **Radical Transparency** (Ray Dalio) | Documentation accuracy, ops readiness, honest assessment |
| **CTO / Security Architect** | Security, architecture, scalability, data protection |
| **SRE / DevOps Staff Engineer** | Infrastructure, monitoring, deployment, reliability |

In callhero, this methodology found **155 findings** across 4 rounds — including critical data-loss bugs, deployment landmines, and security gaps that no single perspective would have caught.

---

## Install Script Reference

```bash
bash install.sh [OPTIONS]
```

| Flag | Effect |
|---|---|
| `--from DIR` | Source directory containing .md command files |
| `--force` | Overwrite existing commands without prompting |
| `--list` | Show installed vs available commands |
| `--uninstall` | Remove all installed commands |
| `-h, --help` | Show help |

The installer:
- Creates `~/.claude/commands/` if it doesn't exist
- Diffs files before overwriting (skips identical files)
- Prompts before overwriting modified files (unless `--force`)
- Picks up any new `.md` files beyond the known set

---

## Updating

Pull the latest and re-run:

```bash
cd /path/to/skillzees
git pull
bash install.sh --force
```

---

## Origin Story

These commands were extracted from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project — an Amazon Connect + HubSpot integration built across 16 Bolts (sprints) in 11 working days. The project shipped:

- 7 Lambda functions (Python 3.12, AWS SAM)
- 101 tests (pytest + moto)
- 155 security findings resolved across 4 audit rounds
- 15 CloudWatch alarms, hourly canary, weekly report
- 14-widget CloudWatch dashboard
- 11 audience-specific documentation manuals
- Full CI pipeline with pre-commit hooks
- Production deployment with cost monitoring and kill switch

The conventions that made this possible are now encoded in these commands, available to every project.

---

## License

MIT
