# Documentation Generator

Usage: `/docs [action] [target]`

**Actions:**
- `generate` (default) — Full documentation generation/update across all types
- `manuals` — Generate just the audience-specific manuals in `docs/manuals/`
- `status` — Show documentation currency report (what's stale, missing, outdated)
- `update [target]` — Update a specific doc (readme, changelog, security, user-guide, developer-guide, operator-runbook, architecture)

**Arguments:** $ARGUMENTS

---

## Purpose

Generates and maintains comprehensive project documentation — from root-level files (README, CHANGELOG, SECURITY) to audience-specific manuals (user guide, developer guide, operator runbook, architecture). This is the command that fills the empty `docs/manuals/` directory scaffolded by `/init-project` and keeps all documentation in sync as the project evolves.

Documentation is only useful when it's current. `/docs generate` is safe to re-run — it preserves user-customized content while updating stale sections with the latest project state.

---

## Instructions for Claude

### 0. Ensure Directories Exist

Before any action, ensure the documentation directories are in place:

```bash
mkdir -p docs/manuals
```

### 1. Parse Arguments

Extract `action` and optional `target` from: `$ARGUMENTS`

**Validation rules:**
- If no arguments provided, default to `generate`
- `action` must be one of: `generate`, `manuals`, `status`, `update`
- For `update`: `target` is required, must be one of: `readme`, `changelog`, `security`, `user-guide`, `developer-guide`, `operator-runbook`, `architecture`
- If an invalid action or target is given, show usage help with valid options

### 2. Gather Project Context

For all actions except `status`, gather this context first:

```bash
# Project structure
find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './__pycache__/*' -not -path './venv/*' -not -path './.venv/*' | head -100

# Recent git history
git log --oneline -20

# Current branch and remote
git branch --show-current
git remote -v 2>/dev/null

# Package/dependency info
cat package.json 2>/dev/null || cat requirements.txt 2>/dev/null || cat go.mod 2>/dev/null || cat Cargo.toml 2>/dev/null || echo "No package manifest found"

# Existing documentation
ls -la README.md CHANGELOG.md SECURITY.md 2>/dev/null
ls -la docs/manuals/ 2>/dev/null

# CLAUDE.md for project context
cat CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found"

# Test structure
find . -type f -name '*test*' -o -name '*spec*' | head -20

# CI/CD config
ls -la .github/workflows/ azure-pipelines.yml Makefile Dockerfile docker-compose.yml 2>/dev/null
```

Read existing documentation files to understand current state and preserve user-customized content.

---

## Action: `status`

Audit the current documentation state and report what exists, what's missing, and what's stale.

### Step 1: Check All Expected Documents

Check for existence and last-modified date of each document:

| Document | Expected Path |
|----------|---------------|
| README | `README.md` |
| CHANGELOG | `CHANGELOG.md` |
| SECURITY | `SECURITY.md` |
| User Guide | `docs/manuals/user-guide.md` |
| Developer Guide | `docs/manuals/developer-guide.md` |
| Operator Runbook | `docs/manuals/operator-runbook.md` |
| Architecture | `docs/manuals/architecture.md` |

### Step 2: Assess Staleness

For each existing document:
- Compare the document's last modification date against recent git activity
- Check if the document references files, features, or APIs that no longer exist
- Check if recent commits introduced features not mentioned in docs

### Step 3: Display Report

```
📋 Documentation Status Report

Root Documents:
  ✅ README.md          — Last updated: [date] ([N] days ago)
  ❌ CHANGELOG.md       — Missing
  ✅ SECURITY.md        — Last updated: [date] ([N] days ago)

Audience Manuals (docs/manuals/):
  ❌ user-guide.md      — Missing
  ❌ developer-guide.md — Missing
  ❌ operator-runbook.md— Missing
  ❌ architecture.md    — Missing

Staleness Warnings:
  ⚠️  README.md references [feature] which was removed in [commit]
  ⚠️  No docs updated since [N] commits ago

Recommendation: Run `/docs generate` to create missing docs and refresh stale ones.
```

---

## Action: `generate`

Full documentation generation/update. Creates or refreshes all document types.

### Step 1: Assess Current State

Read all existing documentation files. For each file that exists, note user-customized sections to preserve on re-generation.

**Preservation rules:**
- If a document exists, read it fully before overwriting
- Preserve any section the user has clearly customized (non-template content)
- Update factual sections (project structure, API reference, dependency lists) with current state
- Keep user-written prose (project description, design rationale, operational notes) intact
- Add new sections for features/files that didn't exist when the doc was last written

### Step 2: Generate Root Documents

Generate each root document following the standards below. If a document already exists and is current, skip it and note that in the output.

#### README.md

Generate a comprehensive README following this quality standard:

1. **Title and Description** — Project name, one-line description, status badges
2. **Quick Start** — Get from zero to running in under 5 commands
3. **Architecture Overview** — High-level system design (1-2 paragraphs or a diagram)
4. **Installation** — Prerequisites, step-by-step install
5. **Configuration** — Environment variables, config files, required secrets
6. **Usage** — Primary use cases with examples
7. **Development** — Setup, testing, linting, formatting commands
8. **Deployment** — How to deploy, CI/CD overview
9. **API Reference** (if applicable) — Endpoints, parameters, response formats
10. **Contributing** — How to contribute, PR process
11. **License** — License type and link

**Quality bar:** A new engineer should be able to clone, install, run, and understand the project from the README alone.

#### CHANGELOG.md

Generate or update following Keep a Changelog format (https://keepachangelog.com):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- [new features from git log]

### Changed
- [modifications from git log]

### Fixed
- [bug fixes from git log]
```

Parse `git log` to populate entries. Group by semantic version tags if they exist.

#### SECURITY.md

Generate a security policy document:

```markdown
# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| [current] | ✅ |

## Reporting a Vulnerability

[Instructions for responsible disclosure]

## Security Controls

[Document actual security measures in place based on codebase analysis]

## Dependencies

[Known dependency security status]
```

### Step 3: Generate Audience Manuals

Generate each manual in `docs/manuals/` following the templates below.

#### docs/manuals/user-guide.md

**Audience:** End-users, non-technical stakeholders
**Tone:** Friendly, task-oriented, no jargon

```markdown
# User Guide

## Getting Started
[First-time setup from a user's perspective]

## Common Tasks
[Step-by-step instructions for primary use cases]

## FAQ
[Anticipated questions and answers]

## Troubleshooting
[Common issues and how to resolve them]

## Getting Help
[Support channels, issue reporting]
```

#### docs/manuals/developer-guide.md

**Audience:** Engineers joining the project
**Tone:** Technical, precise, assumes programming knowledge

```markdown
# Developer Guide

## Prerequisites
[Required tools, versions, accounts]

## Local Development Setup
[Clone, install, configure, run — step by step]

## Project Structure
[Directory layout with explanations]

## Development Workflow
[Branch strategy, commit conventions, PR process]

## Code Conventions
[Style guide, naming conventions, patterns used]

## Testing
[How to run tests, write tests, test conventions]

## Debugging
[Logging, common issues, debugging tools]

## Key Dependencies
[Major libraries/frameworks and why they were chosen]
```

#### docs/manuals/operator-runbook.md

**Audience:** SRE, DevOps, on-call engineers
**Tone:** Procedural, step-by-step, designed for 3 AM incidents

```markdown
# Operator Runbook

## Service Overview
[What this service does, who depends on it, SLA expectations]

## Infrastructure
[Where it runs, resource inventory, network topology]

## Deployment
[Deploy process, rollback procedure, deploy verification]

## Monitoring & Alerting
[What's monitored, alert thresholds, dashboard links]

## Common Operations
[Scaling, restarting, cache clearing, log access]

## Incident Response
[Severity levels, escalation path, communication template]

## Troubleshooting Playbooks
[Symptom → Diagnosis → Fix for known failure modes]

## Disaster Recovery
[Backup strategy, restore procedure, RTO/RPO]
```

#### docs/manuals/architecture.md

**Audience:** Technical leads, architects, senior engineers
**Tone:** Analytical, decision-focused

```markdown
# Architecture

## System Overview

[High-level description]

### System Diagram

[Generate a Mermaid diagram showing major components and their relationships]

## Component Design

[For each major component: responsibility, interfaces, dependencies]

## Data Flow

[Generate a Mermaid sequence or flowchart diagram showing primary data paths]

## Technology Choices

| Technology | Purpose | Why This Choice |
|------------|---------|-----------------|
| [tech] | [what it does] | [rationale] |

## Design Decisions

[Key architectural decisions with context and trade-offs — ADR style]

## Scaling Considerations

[Current limits, bottlenecks, scaling strategy]

## Security Architecture

[Auth model, data protection, network boundaries]
```

### Step 4: Cross-Reference Validation

After generating all documents, check for inconsistencies:

- Do all docs reference the same project name?
- Do setup instructions in the developer guide match the README?
- Does the architecture doc match the actual project structure?
- Does the runbook reference monitoring that actually exists?
- Are dependency versions consistent across docs?

Report any inconsistencies found and fix them.

### Step 5: Summary

```
📚 Documentation Generated

Root Documents:
  ✅ README.md          — [created/updated/unchanged]
  ✅ CHANGELOG.md       — [created/updated/unchanged]
  ✅ SECURITY.md        — [created/updated/unchanged]

Audience Manuals:
  ✅ docs/manuals/user-guide.md         — [created/updated/unchanged]
  ✅ docs/manuals/developer-guide.md    — [created/updated/unchanged]
  ✅ docs/manuals/operator-runbook.md   — [created/updated/unchanged]
  ✅ docs/manuals/architecture.md       — [created/updated/unchanged]

Cross-Reference Check:
  [N] inconsistencies found and fixed
  [or] All documents are consistent

Total: [N] documents, [N] created, [N] updated, [N] unchanged
```

---

## Action: `manuals`

Generate only the audience-specific manuals in `docs/manuals/`. Follows the same process as the manuals portion of `generate` (Step 3), including context gathering and the cross-reference check across the manuals themselves.

### Output

```
📖 Manuals Generated

  ✅ docs/manuals/user-guide.md         — [created/updated/unchanged]
  ✅ docs/manuals/developer-guide.md    — [created/updated/unchanged]
  ✅ docs/manuals/operator-runbook.md   — [created/updated/unchanged]
  ✅ docs/manuals/architecture.md       — [created/updated/unchanged]
```

---

## Action: `update [target]`

Update a single documentation file. The `target` argument specifies which document to update.

### Valid Targets

| Target | File |
|--------|------|
| `readme` | `README.md` |
| `changelog` | `CHANGELOG.md` |
| `security` | `SECURITY.md` |
| `user-guide` | `docs/manuals/user-guide.md` |
| `developer-guide` | `docs/manuals/developer-guide.md` |
| `operator-runbook` | `docs/manuals/operator-runbook.md` |
| `architecture` | `docs/manuals/architecture.md` |

### Process

1. Read the existing document (if it exists)
2. Gather relevant project context
3. Update the document following the same quality standard as `generate`
4. Preserve user-customized content
5. Show a diff summary of what changed

### Output

```
📝 Updated: [target file path]

Changes:
  - [summary of what was added/changed/removed]

Preserved:
  - [sections kept from previous version]
```
