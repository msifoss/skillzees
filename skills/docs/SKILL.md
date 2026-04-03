---
name: docs
description: Generate or update project documentation following the AI-DLC documentation standard. Creates README.md, CHANGELOG.md, SECURITY.md, and docs/manuals/ with audience-specific guides.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: [readme | changelog | security | manuals | all]
---

# Docs — Project Documentation Generator

Generate and update project documentation following the AI-DLC documentation standard.

## Usage

```
/docs              # Update all documentation (README + manuals)
/docs readme       # Generate/update README.md only
/docs changelog    # Generate/update CHANGELOG.md only
/docs security     # Generate/update SECURITY.md only
/docs manuals      # Generate/update docs/manuals/ guides only
/docs all          # Generate everything
```

## Documentation Standard

All documentation follows the AI-DLC documentation standard. These are the rules — follow them exactly.

## README.md Structure

The README is the primary document. It must be comprehensive, well-organized, and audience-aware. Length should be proportional to project complexity — a simple CLI tool may need 100-200 lines, while a full-stack application may need 400-700 lines. Prioritize completeness and accuracy over length targets. Follow this exact section order:

```markdown
# Project Name

**One-sentence tagline describing what it does and why.**

> **Status:** Current deployment state, known blockers, phase info.

---

## Table of Contents

[Anchor-linked navigation to every major section]

---

## How It Works

[ASCII diagram or Mermaid showing the data/workflow pipeline]
[Numbered steps explaining the flow]

## Features

[Bulleted by category — e.g., Core, Analytics, Operational]
[Format: **Feature name** — one-sentence description]

## Architecture

[ASCII or Mermaid diagram]
[Account/environment/infrastructure summary if applicable]

## Project Structure

[Tree layout with brief descriptions per file/directory]

## Installation and Setup

[Prerequisites table: Tool | Version | Purpose]
[Step-by-step commands, copy-paste ready]

## Configuration

[Parameter tables: Parameter | Default | Description]
[Environment variables: Variable | Description]

## Usage

[Subsections by audience if applicable]
[Concrete command examples with expected output]

## Error Handling

[Table: Scenario | What Happens | User Sees]

## Testing

[Test count, commands to run, coverage areas]

## Monitoring and Alerting

[If applicable — alarms, thresholds, meanings]

## Cost

[If applicable — per-service breakdown table]
[Format: Service | What It Does | Monthly Cost | Notes]

## Security

[Summary of controls]
[Link to SECURITY.md for details]

## Documentation

[Index linking to all docs in the repo]

## Contributing

[Tools, formatting rules, PR conventions]
```

## CHANGELOG.md Format

Follow "Keep a Changelog" format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description

### Removed
- Removed feature description
```

## SECURITY.md Format

```markdown
# Security

## Controls

[Table of security measures in place]

## Secrets Management

[How secrets/tokens/keys are handled]

## Reporting

[How to report security issues]
```

## docs/manuals/ Structure

Create audience-specific manuals as needed. Not every project needs all of these — use judgment based on project scope:

| Manual | Audience | When to Create | Detection Heuristic |
|---|---|---|---|
| `QUICK_START.md` | New users | Always — 5-minute onboarding | Always create |
| `USER_MANUAL.md` | End users | If there's a UI or user-facing CLI | `package.json` has `bin`, or `argparse`/`click` imports, or HTML/React/Vue files exist |
| `DEVELOPER_GUIDE.md` | Contributors | If accepting contributions | `CONTRIBUTING.md` exists, or repo has >1 contributor in git log |
| `API_REFERENCE.md` | API consumers | If there's an API | Route/endpoint definitions (Flask, FastAPI, Express), or OpenAPI spec exists |
| `DEPLOYMENT_GUIDE.md` | DevOps | If deployed to cloud/servers | `Dockerfile`, `template.yaml`, `serverless.yml`, `.tf` files, or CI/CD config exists |
| `TROUBLESHOOTING.md` | Support/users | If common issues exist | Project has >10 closed issues, or error handling code covers >5 distinct scenarios |

### Manual Template

Every manual follows this structure:

```markdown
# [Title]

> For [audience].

---

## Table of Contents

1. [Section One](#section-one)
2. [Section Two](#section-two)

---

## Section One

[Content with concrete examples, tables, and copy-paste commands]
```

## Style Rules

### Tone
- **README:** Professional, concrete, practical
- **User manuals:** Friendly, accessible, second person ("you")
- **Developer/admin docs:** Precise, technical, imperative ("run", "check", "verify")
- **Troubleshooting:** Diagnostic, systematic, step-by-step

### Formatting
- **Tables** for all reference data (parameters, errors, costs, prerequisites)
- **Code blocks** with language tags (`bash`, `json`, `python`, `sql`, etc.)
- **Bold** for key concepts: `**Feature name** — description`
- **Blockquotes** for tips, warnings, status: `> **Important:** ...`
- **`---`** dividers between major sections
- **Anchor-linked** Table of Contents in every doc over 100 lines

### Code Examples
- Always copy-paste ready
- Include comments explaining *why*, not just syntax
- Show expected output where helpful
- Use realistic values (not lorem ipsum)

### Links
- Internal: relative paths from repo root `[text](docs/manuals/FILE.md)`
- Anchors: lowercase with hyphens `[section](#section-name)`
- Cross-doc: always provide full relative path

### What NOT to Do
- No emojis unless the user explicitly requests them
- No filler text or generic placeholder content
- No "TODO" sections in user-facing docs — either write it or omit it (note: `<!-- TODO: ... -->` markers are acceptable in internal AI-DLC templates)
- No screenshots without alt text descriptions
- No walls of text — use tables, lists, and code blocks to break things up
- **Never include real secrets, API keys, tokens, passwords, or credentials** — always use placeholder values (e.g., `YOUR_API_KEY`, `sk-...`, `<token>`)
- **Never include real AWS account IDs, internal hostnames, or VPC IDs** — use placeholder values. Review architecture sections before publishing.

## Process

1. **Pre-flight check** — run `git status --short` on target files (README.md, CHANGELOG.md, SECURITY.md, docs/manuals/). If any target files have uncommitted changes, warn the user before proceeding. Prefer Edit over Write for existing files to minimize data loss risk.
2. **Read the codebase** — understand the project structure, entry points, config, and features before writing anything. Scope reads by action: `changelog` only needs git history and CHANGELOG.md; `readme` needs CLAUDE.md + architecture files; `security` needs SECURITY.md + security review docs; `all` reads broadly.
3. **Read existing docs** — don't overwrite good content; update and extend. Preserve existing content, add missing sections, don't reorder user-authored sections.
4. **Generate docs** — follow the structure and style rules above exactly
5. **Cross-link** — ensure all docs reference each other appropriately
6. **Verify** — check that all file paths, commands, and examples are accurate for THIS project
