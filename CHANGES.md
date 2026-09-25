# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> **Note:** This file is named `CHANGES.md` (not `CHANGELOG.md`) to avoid a case-insensitive filename collision with the `changelog.md` slash command on macOS.

## [Unreleased]

### Added
- Synced 57 skills from global + repo-local sources — now 94 skills total (feat/sync-external-skills sweep, 2026-07-25)
- New skills: `changeloggy` (date-bucketed git activity), `gitsmith` (session git-hygiene agent), `wrapit` (session recap under docs/wrapit/)
- New consolidated skill: `discuss` (config-driven, replaces discuss-cgii + discuss-jenmatrix)
- Companion private repo [`msifoss/skillzees-private`](https://github.com/msifoss/skillzees-private) for CallHero-specific skills
- Wired Librarian, Sentinel, and Evolver agents into the `bolt-lfg` pipeline

### Changed (catalog cleanup 2026-09-24 — panel-driven, chore/skills-catalog-cleanup)
- Merged `chealth` + `prodstatus` → `callhero-health` with dashboard/comprehensive modes (extracted to skillzees-private)
- Merged `discuss-cgii` + `discuss-jenmatrix` → `discuss` (config-driven, no project hardcoding)
- Killed `staff-panel` (EZFacility duplicate); migrated its frontmatter to `staff`
- Shrunk `qb` (129L → 15L) and `ql` (131L → 15L) to thin aliases that call `qx`
- Added YAML frontmatter to 11 skills that had none: staff, pm, mytodo, chealth, prodstatus, ingest, comparison-builder, feature-get, test-cycle, weekly-update, partner-pull
- Fixed stale/invalid `allowed-tools`: `vehicle-finder` (removed non-existent TaskCreate/Update/List); `dlc-audit` (Task → Agent)
- Fixed skill-count fossils: CLAUDE.md structure comment (34 → 89), handoff quote (34 → 94)
- Added `mcp__weeklyops__*` availability warnings to `ai-effort`, `feature-get`, `weekly-update`
- Softened CONFIDENTIAL notices with specific-reference framing where kept public
- Postponed `triplecrown` retirement (Desktop endpoint returned 404); notice updated
- `README.md` command count corrected from 30 → 33; added `/compose`, `/dlc-loop`, `/route` entries
- `README.md` sanitized (removed internal Azure DevOps URL from origin sentence)
- `SECURITY.md` supported-versions table updated to 3.0.0

### Removed (extracted to skillzees-private)
- `callhero-health` (was `chealth` + `prodstatus`) — internal AWS resource names including an api-keys DynamoDB table
- `ingest` — CallHero data pipeline

### Security
- Discovered public repo was exposing internal `callhero-*` AWS resource names (CloudFormation stacks, Lambda names, SQS queues, RDS ids, and a `callhero-api-keys-${stage}` DynamoDB table). No credentials leaked, but names give reconnaissance leverage. Fix: extracted to private companion repo.

**Net skills:** 94 → 89 (5 removed public + 1 discuss consolidation; 2 more live in skillzees-private).

## [3.0.0] - 2026-04-04

### Added
- Expanded to 34 skills (since 2.0.0)
- Synced all global commands to repo

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
