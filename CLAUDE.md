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

## Skills (94)

Skills are full prompt definitions in `skills/<name>/SKILL.md`. Some commands are thin stubs that load their corresponding skill.

| Skill | Description |
|-------|-------------|
| `a2p-audit` | A2P 10DLC website compliance audit against a live URL (16-item Twilio campaign registration check) |
| `add-site` | Add a new site to Anny's registry (GA4 + Search Console) with live verification |
| `ai-effort` | Weekly commit activity scanning and AI time-savings estimates |
| `am` | Account manager daily/weekly workflow (briefings, client prep, negotiations) |
| `bizdig` | Deep-dive HubSpot company dossier with cross-system engagement + billing + O365 sweep |
| `bootstrapper` | Foundation agent — extends /init-project with state file creation and auto-handoff to /pm plan |
| `catchmeup` | First-load orientation for a leader — brings someone new up to speed on the project |
| `changeloggy` | Date-bucketed git activity analysis across one or more repos with exec-level Q&A |
| `chealth` | CallHero comprehensive health check |
| `comparison-builder` | Repeatable competitor-comparison page builder (LLM/human/SEO optimized) |
| `competitor` | Scaffold a new competitor analysis from a template |
| `conversion-plumber` | CTA link audit and conversion path consolidation |
| `costkeeper` | Cost pillar agent — infra cost tracking, anomaly alerts, budget dashboard |
| `customer-clone` | Graduate a preview site to a customer's real domain on 97astro1 |
| `customer-migrate` | End-to-end customer-domain website migration driver for the WebEngine fleet |
| `data-pump` | Seed realistic demo/test data into CRM98 (orgs, leads, programs, drips, notifications) |
| `dealer-monthend-report` | Rocket-styled multi-cycle month-end financial trend report for any APS dealer |
| `dealer-rate-hike` | Detect and explain wholesale rate changes (MSI-to-dealer take rates) for any APS dealer |
| `deployer` | Deployment agent — generic deploy pipeline runner with multi-env verification and runbook generation |
| `design-panel` | Web design review panel (4 designers + Steve Schoger moderator) |
| `discuss-cgii` | cgii-project variant of /discuss — voice-friendly contributor communications |
| `discuss-jenmatrix` | jenmatrix-project variant of /discuss — voice-friendly contributor communications |
| `dlc-audit` | AI-DLC compliance audit with numeric scoring |
| `dns-forensics` | Reconstruct what changed in a domain's DNS when a customer reports their site is down |
| `docs` | Documentation generation (AI-DLC standard) |
| `engagement-report` | Leadership engagement report — measures contribution by deliverables, decisions, accountability |
| `evolver` | Context evolution agent — proposes CLAUDE.md updates from captain's logs + git history |
| `exec-jam` | Bryant's private executive advisory panel (7 advisors, live strategic analysis) |
| `exec-review` | Executive review panel (5 strategic thinkers — Jim Collins moderator) |
| `feature-get` | Pull platform enhancement ideas from weeklyops-prompt users |
| `fin-audit` | Financial audit panel (McKinsey, Deloitte, EY, PwC, KPMG) |
| `foreman` | Construction supervisor — coordinates bolt execution, detects parallelism, manages blockers |
| `gatekeeper` | Phase gate enforcer — validates AI-DLC exit criteria and supports batch-mode Mission Briefs |
| `gitsmith` | Session git-hygiene agent — safe branch at start, best-practices audit mid/end |
| `growth` | EFIT club price-increase impact analysis — revenue trends, fee uptake, payment distribution |
| `handoff` | Inter-skill connector — passes artifacts between skills and bridges format mismatches |
| `hardener` | Ops readiness agent — runs 47-item checklist, scores, and groups hardening bolts |
| `ingest` | CallHero data pipeline — diagnose gaps, backfill, prove parity |
| `init-brain` | Retrofit knowledge management brain into any repo |
| `internal-link-builder` | Internal links and CTAs for top blog posts |
| `interview` | Scaffold a new customer interview file from the template |
| `lfg` | Team router — reads project state and dispatches the right teammate |
| `librarian` | Knowledge retrieval agent — searches all project knowledge for prior decisions |
| `list-sites` | List sites Anny can query (GA4 + Search Console) with active-site indicators |
| `llm-team` | LLM/GEO/AIO optimization panel |
| `marketing-team` | B2B SaaS marketing strategy panel |
| `moat-content-writer` | Billing expertise blog posts leveraging Member Solutions' 35-year data advantage |
| `motherhen` | Project health and compliance monitor |
| `mytodo` | Accurate per-person todo view |
| `newpath` | Scaffold a new candidate strategy path |
| `partner-pull` | Deep-dive HubSpot pull for a 97 Display referral partner (5 analyst-grade deliverables) |
| `pci-sync` | Monthly PCI compliance sync (Mega/Planit Visa Level 4 → Lakey + HubSpot) |
| `perf-check` | Multi-provider performance check (Lighthouse + PageSpeed Insights + CrUX) |
| `pipe-lfg` | Three-pillar pipeline health check (CRM98, 98agents, webengine) |
| `planroom` | Strategic planning collaboration guide for non-technical leaders (git without git) |
| `pm` | Project management update |
| `prd-go` | Production-ready PRD writer |
| `prodstatus` | Production health dashboard |
| `qb` | Question log for leadership |
| `ql` | Log questions for leadership (generic variant of qb/qx) |
| `qualitygate` | Quality pillar agent — coverage thresholds, pre-commit compliance, Ascent verification |
| `qx` | Log a question for any named leader (Bryant, Miranda, Arpit, Stefano, Maria, Joanne, etc.) |
| `radar` | Strategic radar — assess current state, prioritize opportunities, maintain backlog |
| `refine-clone` | Full-cycle refinement of a cloned Astro site (marketing → design → rebuild → validation) |
| `refine-page` | Full-cycle page refinement |
| `remove-site` | Mark a site as removed (soft delete) in Anny's registry |
| `repo-activity` | Summarize today's repo activity (git + captain's logs + memory + session) into weeklyops |
| `reqs` | Requirements engineer — extracts structured REQ-NNN from brainstorms and rough notes |
| `scribe` | Captain's log agent — enhances /captainslog with search and auto-retrieval |
| `sentinel` | Security pillar agent — triages findings, tracks dispositions, flags regressions |
| `seo-meta-agent` | Title tag and meta description rewriter |
| `seo-rank` | Keyword ranking audit for a fleet site (all keywords × locations) |
| `sitrep` | Executive situation report |
| `snapshot` | Save a verbatim snapshot of the current session's transcript as a checkpoint |
| `speccer` | Specification writer — converts requirements to user stories and technical specs |
| `staff` | Staff engineer panel analysis |
| `staff-panel` | Staff engineer panel (EZFacility growth-plan variant with platform decisions focus) |
| `staff-rfc` | Staff engineer RFC proposals |
| `switch-site` | Switch local Anny to query a different registered site |
| `tasko` | Prioritized snapshot of one HubSpot owner's open work with follow-up modes |
| `test-cycle` | Dev → Test → Report → Backlog loop |
| `ticky` | Azure DevOps work item lifecycle |
| `toolkit-sync` | Monthly MSI Toolkit (CSIPay/Pyxis) sync into Lakey live_toolkit_merchant_month |
| `tracer` | Traceability agent — auto-maintains REQ→Story→Code→Test→Deploy matrix |
| `triplecrown` | Merchant legitimacy & fraud investigation for Member Solutions boarding |
| `truck-incentives` | Canadian truck financing deals research |
| `vehicle-finder` | Dealership vehicle search and scoring |
| `vertical-builder` | Martial arts/fitness vertical page builder |
| `webby` | Simple website collaborator guide |
| `webgeni` | Marketing team orchestrator |
| `webteam` | Astro website repo team sync |
| `weekly-update` | OKR-disciplined weekly self-review |
| `weeklyreport` | Scaffold the current week's report file at docs/weekly_reports/YYYY-WW |
| `wrapit` | Wrap up the current session into one durable recap under docs/wrapit/ |

## Conventions

- **File naming:** Command files are lowercase kebab-case `.md` files
- **macOS collision avoidance:** `generate-readme.md` installs as `readme.md` to avoid conflicting with `README.md`. Project changelog is `CHANGES.md` to avoid conflicting with `changelog.md` command
- **Install mapping:** The `COMMANDS` array in `install.sh` maps `source:destination` — most are identity mappings except `generate-readme.md:readme.md`
- **Command format:** Each `.md` file follows the pattern: Usage line, Arguments (`$ARGUMENTS`), Purpose section, Instructions for Claude, Parse Arguments, Action-specific sections
- **Multi-action commands** (pm, budget, captainslog, docs, dlc-audit): Have a default action and use `$ARGUMENTS` for action routing

## Current State

- **Version:** v3.0.0 (+ unreleased: 57 new skills synced from global + repo-local sources on 2026-07-25)
- **Commands:** 33
- **Skills:** 94
- **Last verified:** 2026-07-25 via feat/sync-external-skills sweep
- **Origin:** Born from the [callhero](https://dev.azure.com/membersolutionsinc/DevOps/_git/callsync-hubspot) project
- **License:** MIT
