# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> **Note:** This file is named `CHANGES.md` (not `CHANGELOG.md`) to avoid a case-insensitive filename collision with the `changelog.md` slash command on macOS.

## [1.0.0] - 2026-02-15

### Added
- 15 slash commands for Claude Code covering project lifecycle, code quality, project management, planning, cost, and operations
- `install.sh` with `--from`, `--force`, `--list`, and `--uninstall` support
- macOS case-insensitive filename collision handling (`generate-readme.md` → `readme.md`)

### Commands
- `/init-project` — Full project scaffold (callhero standard)
- `/five-persona-review` — Multi-perspective code review (5 expert personas)
- `/security-audit` — Structured security audit (OWASP + cloud + supply chain)
- `/pm` — Bolt sprint management
- `/budget` — Infrastructure cost tracking
- `/bolt-review` — End-of-sprint comprehensive review
- `/changelog` — Keep-a-Changelog format updates
- `/cost-estimate` — Development effort estimation
- `/readme` — Will-Larson-quality README generation
- `/captainslog` — Session logs for AI context continuity
- `/docs` — Documentation generation and maintenance
- `/dlc-audit` — AI-DLC compliance audit (8-dimension assessment)
- `/motherhen` — Development lifecycle compliance monitor
- `/prodstatus` — Production health dashboard (read-only AWS diagnostics)
- `/ticky` — Azure DevOps work item submission
