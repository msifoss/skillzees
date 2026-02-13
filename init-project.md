# Initialize Project — Callhero Standard

Usage: `/init-project [project-name]`

**Arguments:** $ARGUMENTS

---

## Purpose

Scaffolds a new project repository following the battle-tested conventions established in the callhero codebase. This standard was developed through 16 development bolts, 155 security findings (all resolved), 3 five-persona code reviews, and production deployment — representing the collective wisdom of staff engineering, product ownership, CTO oversight, SRE operations, and security leadership.

The result is a project that is:
- **Production-ready from day one** — CI, linting, testing, security controls
- **Operationally mature** — monitoring, runbook, incident response, cost tracking
- **Well-documented** — audience-specific manuals, architecture diagrams, decision records
- **AI-pair-optimized** — CLAUDE.md, captain's logs, bolt-based sprint framework

---

## Instructions for Claude

### 0. Parse Arguments

Extract `project-name` from: `$ARGUMENTS`

**Validation:**
- If no arguments, ask the user for a project name and brief description
- Convert to kebab-case for directory names
- Validate: lowercase alphanumeric + hyphens only

### 1. Gather Project Information

Ask the user the following questions before scaffolding:

1. **Project description** (1-2 sentences — what does this project do?)
2. **Primary language/stack** — Options:
   - Python (Lambda/serverless)
   - Python (Django/FastAPI/Flask)
   - TypeScript/Node.js
   - Go
   - Other (specify)
3. **Infrastructure** — Options:
   - AWS SAM/CloudFormation
   - AWS CDK
   - Terraform
   - None (library/CLI tool)
4. **Git host** — Options:
   - Azure DevOps
   - GitHub
   - GitLab
5. **Does the project need a database?** (yes/no, if yes: what kind?)
6. **Does the project need a browser extension?** (yes/no)

### 2. Initialize Git Repository

```bash
mkdir -p [project-name]
cd [project-name]
git init
```

### 3. Create Directory Structure

Create the full directory tree (adapt based on language/stack answers):

```bash
# Core directories
mkdir -p docs/manuals
mkdir -p docs/captains_log
mkdir -p docs/security
mkdir -p docs/reviews
mkdir -p docs/tickets
mkdir -p docs/budget
mkdir -p docs/pm
mkdir -p docs/story
mkdir -p scripts
mkdir -p architecture
mkdir -p tests/unit
mkdir -p tests/integration
mkdir -p tests/mocks

# Language-specific source dirs
# Python: mkdir -p src/[module_name]
# Node/TS: mkdir -p src
# Go: (use go module structure)

# Infrastructure (if applicable)
# SAM: mkdir -p infrastructure/db infrastructure/events
# Terraform: mkdir -p infrastructure/modules
# CDK: mkdir -p infrastructure/lib
```

### 4. Create Root Files

Generate each of these files, adapting content to the project's language, stack, and purpose:

#### 4a. CLAUDE.md

This is the most critical file — it's the AI's operating manual for the project. Follow this structure:

```markdown
# [Project Name] — [One-Line Description]

## What This Project Does
[2-3 sentence description from user input]

## Architecture
[High-level architecture description — fill in as project develops]

## Project Structure
```
[directory tree — fill with the actual scaffolded structure]
```

## Dev Environment
- [Language version and setup instructions]
- [Package manager and install command]
- [How to run tests]
- [How to format/lint]

## Key External APIs
- [List as project develops]

## Conventions
- [Language]: formatted with [formatter], linted with [linter]
- Tests: [framework] for [language]
- Task runner: `make help` for all targets
- [Infrastructure convention if applicable]

## Current Status ([today's date])
- **Code:** Initial scaffold. 0 tests.
- **Pipeline:** Not yet configured.
- **Deployment:** Not yet deployed.
- **Git:** [host] repo, branch `main`
```

#### 4b. README.md

Follow the `/readme` command standard — comprehensive, Will-Larson-quality:

```markdown
# [Project Name]

**[One-line description]**

[Longer description — 2-3 paragraphs about the problem being solved]

> **Status:** Initial scaffold. Not yet deployed.

---

## Table of Contents
- [How It Works](#how-it-works)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Installation and Setup](#installation-and-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Testing](#testing)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Cost](#cost)
- [Security](#security)
- [Documentation](#documentation)
- [Contributing](#contributing)

[Sections filled with placeholder content appropriate to the stack]
```

#### 4c. SECURITY.md

```markdown
# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability, report it privately:

- **Email:** [to be configured]
- **Scope:** Authentication bypass, data exposure, injection, privilege escalation

Do not test against production systems without authorization.

## Security Audit Status

| Round | Date | Findings | Status |
|-------|------|----------|--------|
| — | — | — | No audits yet |

## Security Controls

### Authentication
- [To be implemented]

### Authorization
- [To be implemented]

### Encryption
- **At rest:** [To be configured]
- **In transit:** HTTPS enforced
- **Secrets:** [To be configured — never commit secrets]

### Input Validation
- [To be implemented]

### Monitoring
- [To be configured]

## Known Limitations
- [Document as they arise]

## Dependency Updates

[Language-specific audit command]:
```bash
# Python: pip-audit
# Node: npm audit
# Go: govulncheck ./...
```
```

#### 4d. CHANGELOG.md

```markdown
# Changelog

All notable changes to [Project Name] are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

## [0.1.0] - [today's date] (Initial Scaffold)

### Added
- Project directory structure
- CLAUDE.md — AI operating manual
- README.md — comprehensive project documentation
- SECURITY.md — security policy and controls
- CHANGELOG.md — this file
- Makefile with standard targets
- CI pipeline configuration
- Pre-commit hooks (formatting + linting + tests)
- PM framework (Bolt-based sprints)
- .gitignore, .env.example, editor config
- docs/ structure (manuals, security, reviews, PM, captain's log)
```

#### 4e. .gitignore (language-appropriate)

Generate based on the primary language. Always include:
```
# Environment
.env
.env.local
.env.*.local
*.pem
*.key

# IDE
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Testing
.coverage
htmlcov/
.pytest_cache/

# Logs
*.log

# Temporary files
tmp/
```

Plus language-specific entries (Python: `__pycache__/`, `.venv/`; Node: `node_modules/`, `dist/`; Go: binary names).

#### 4f. .env.example

```
# ============================================================================
# [Project Name]
# Environment Configuration
# ============================================================================
# Copy this file to .env and fill in your actual values
# NEVER commit .env to version control
# ============================================================================

# [Sections based on project requirements]
```

#### 4g. Makefile

```makefile
.PHONY: help install test unit integration lint format format-check validate build audit clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install all dependencies
	[language-specific install command]

test: ## Run all tests
	[language-specific test command]

unit: ## Run unit tests only
	[language-specific unit test command]

integration: ## Run integration tests only
	[language-specific integration test command]

lint: ## Run linter
	[language-specific lint command]

format: ## Format code
	[language-specific format command]

format-check: ## Check formatting (CI-friendly)
	[language-specific format check]

audit: ## Run dependency vulnerability scan
	[language-specific audit command]

clean: ## Remove build artifacts
	[language-specific clean command]
```

#### 4h. CI Pipeline

**Azure DevOps** (`azure-pipelines.yml`):
```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: ubuntu-latest

stages:
  - stage: Validate
    displayName: Build & Test
    jobs:
      - job: Test
        steps:
          - [language setup]
          - [install dependencies]
          - [check formatting]
          - [lint]
          - [run tests]
          - [infrastructure validate if applicable]
          - [dependency vulnerability scan]
```

**GitHub** (`.github/workflows/ci.yml`):
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - [language setup]
      - [install, format-check, lint, test, audit]
```

#### 4i. Pre-commit Config (`.pre-commit-config.yaml`)

Generate based on language:
- **Python:** Black + pylint + pytest
- **Node/TS:** Prettier + ESLint + test runner
- **Go:** gofmt + golangci-lint + go test

#### 4j. Language Config

- **Python:** `pyproject.toml` with pytest, black, pylint config
- **Node/TS:** `package.json` with scripts, `tsconfig.json`
- **Go:** `go.mod`

#### 4k. VS Code Settings (`.vscode/settings.json`)

```json
{
    "[language]": {
        "editor.defaultFormatter": "[appropriate formatter]",
        "editor.formatOnSave": true
    },
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true
}
```

### 5. Create Documentation Files

#### 5a. PM Framework (`docs/pm/FRAMEWORK.md`)

Use the Bolt sprint framework from callhero — adapted for the new project:

```markdown
# [Project Name] Sprint Framework — Bolts

> "Good process is as lightweight as possible, while being rigorous enough to consistently work."

## Why "Bolts"?
[Same philosophy — short, concentrated sprints for solo + AI pair]

## Cadence
Monday → Bolt Planning (15 min)
Tue-Thu → Build
Friday → Bolt Review + Retro (15 min)

## Metrics
| Metric | What It Measures |
|--------|-----------------|
| Commits | Volume of shippable work |
| Tests Δ | Net change in test count |
| Deploys | Production deployments |
| Blocked % | Days blocked / total days |

## Velocity
T-shirt sizes: S (< 1hr), M (< half day), L (~ 1 day), XL (multi-day)

## Handling External Blockers
1. Separate blocked from executable
2. File tickets immediately
3. Pivot, don't wait
4. Track blocked-time %
5. Follow up weekly

## Artifacts
| File | Purpose | Update Frequency |
|------|---------|-----------------|
| FRAMEWORK.md | How we work | Rarely |
| CURRENT-SPRINT.md | Active Bolt status | Daily |
| SPRINT-LOG.md | Archive of completed Bolts | Weekly |
| BACKLOG.md | Prioritized product backlog | Weekly |
```

#### 5b. Backlog (`docs/pm/BACKLOG.md`)

```markdown
# [Project Name] Product Backlog

> Prioritized by MoSCoW (Must/Should/Could/Won't) within each phase.
> Size: S (< 1hr), M (< half day), L (~ 1 day), XL (multi-day).
> Status: 🟢 executable | 🔴 blocked | ✅ done

Last groomed: [today's date]

---

## Phase 1 — [Core Functionality]

### Must Have
| # | Item | Size | Status | Notes |
|---|------|------|--------|-------|
| 1 | [First critical item] | M | 🟢 | |

### Should Have
| # | Item | Size | Status | Notes |
|---|------|------|--------|-------|

### Could Have
| # | Item | Size | Status | Notes |
|---|------|------|--------|-------|

---

## Won't Do (Decided Against)
| Item | Reason |
|------|--------|
```

#### 5c. Current Sprint (`docs/pm/CURRENT-SPRINT.md`)

```markdown
# Bolt 1 — Project Setup ([today's date])

**Goal:** [Initial scaffold and first working feature]

**Status:** IN PROGRESS

---

## Items

| Item | Size | Status |
|------|------|--------|
| Project scaffold | M | ✅ done |
| [Next item] | | 🟢 |
```

#### 5d. Sprint Log (`docs/pm/SPRINT-LOG.md`)

```markdown
# Sprint Log

Archive of completed Bolts.

---

(No completed Bolts yet)
```

#### 5e. Budget (`docs/budget/BUDGET.md`)

```markdown
# [Project Name] — Budget Overview

**Last updated:** [today's date]

---

## Infrastructure Costs

| Service | What It Does | Monthly Cost | Notes |
|---|---|---|---|
| [To be filled as infrastructure is defined] | | | |

---

## Cost Optimization Options

### Already Implemented
- [List as they arise]

### Available If Needed
| Optimization | Savings | Trade-off |
|---|---|---|
```

### 6. Create Project-Level .claude/ Directory

#### 6a. Settings (`[project]/.claude/settings.local.json`)

```json
{
  "permissions": {
    "allow": []
  }
}
```

(Will be populated as the project grows and specific CLI commands are needed.)

### 7. Create Initial Test File

Generate a placeholder test that validates the project can import/run:

- **Python:** `tests/__init__.py` + `tests/conftest.py` + `tests/unit/__init__.py` + `tests/unit/test_placeholder.py`
- **Node/TS:** `tests/placeholder.test.ts`
- **Go:** `*_test.go`

### 8. Initialize Language Environment

```bash
# Python:
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

# Node/TS:
npm init -y
npm install --save-dev [tooling]

# Go:
go mod init [module-path]
```

### 9. Run Validation

After scaffolding, verify everything works:

```bash
make format-check   # Formatting passes
make lint           # Linting passes
make test           # Tests pass (even if just placeholder)
```

### 10. Create Initial Captain's Log

Use the `/captainslog new project-setup` command to create the first captain's log entry documenting:
- What was scaffolded
- Key decisions made during setup
- Next steps

### 11. Create Initial Commit

```bash
git add -A
git commit -m "Initial scaffold: [project-name] — [one-line description]

Scaffolded with callhero standard:
- CLAUDE.md, README.md, SECURITY.md, CHANGELOG.md
- Bolt-based PM framework (docs/pm/)
- CI pipeline, pre-commit hooks, Makefile
- Test structure with placeholder test
- Documentation structure (manuals, security, reviews, captain's log)
- Budget tracking template

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### 12. Summary Output

After completion, display:

```
Project initialized: [project-name]

📁 Structure:
  [tree output of created directories]

📄 Files created: [count]
  - CLAUDE.md (AI operating manual)
  - README.md (project documentation)
  - SECURITY.md (security policy)
  - CHANGELOG.md (version history)
  - Makefile ([count] targets)
  - [CI file] (CI pipeline)
  - .pre-commit-config.yaml (code quality hooks)
  - docs/pm/FRAMEWORK.md (Bolt sprint framework)
  - docs/pm/BACKLOG.md (product backlog)
  - + [count] more files

✅ Validation:
  - Formatting: PASS
  - Linting: PASS
  - Tests: PASS ([count] tests)

🔧 Next steps:
  1. Update CLAUDE.md with architecture details as they develop
  2. Start Bolt 1 — update docs/pm/CURRENT-SPRINT.md
  3. Set up remote repository and push
  4. Configure CI pipeline in [git host]
  5. Run /captainslog new project-setup to document decisions
```

---

## Design Principles (from callhero)

These principles are baked into every scaffolded project:

1. **CLAUDE.md is the source of truth** — Keep it current. It's the first thing the AI reads.
2. **101 tests before production** — Test early, test everything, test edge cases.
3. **Security by default** — Input validation, encryption, least privilege from day one.
4. **Operational maturity is not optional** — Monitoring, alerting, runbooks, cost tracking.
5. **Document for the audience** — User Manual ≠ Developer Guide ≠ Runbook.
6. **Ship weekly via Bolts** — Short sprints, real metrics, honest retros.
7. **Captain's logs bridge AI sessions** — Write decisions down or they're lost.
8. **Five-persona reviews find what you miss** — Staff engineer, first principles, transparency, CTO/security, DevOps.
9. **Budget-aware from the start** — Track costs before they surprise you.
10. **Pre-commit hooks prevent bad commits** — Format, lint, and test before every commit.
