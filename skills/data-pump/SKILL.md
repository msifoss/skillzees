---
name: data-pump
description: Seed realistic demo/test data into CRM98 accounts — orgs, leads, programs, drip campaigns, notifications, reports
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[profile] [options] — e.g. 'standard', 'full --verbose', 'cleanup org-id'"
---

# /data-pump — CRM98 Data Pump

Seed realistic martial arts / fitness studio data into CRM98 accounts. Creates organizations, businesses, locations, users, programs, instructors, testimonials, offers, leads, notifications, drip sequences, integrations, reports, and activity logs.

## When to Use

- Setting up a demo account for a client presentation
- Populating a dev environment with realistic data
- Testing portal UI with volume data (dashboards, lead lists, reports)
- End-to-end pipeline testing (lead → event → notification → drip)
- QA testing with specific data volumes

## Prerequisites

- Docker must be running (`docker compose up -d` in `/Users/msichris/repos/crm98`)
- For `--lead-mode with-events`: the API server must also be running (`pnpm dev`)

## Instructions

Map the user's request to CLI flags and run the command.

**Working directory:** Always `cd /Users/msichris/repos/crm98` first.

**Command:** `node_modules/.bin/tsx scripts/data-pump/index.ts [options]`

### Profiles

| Profile | Locations | Leads | Content | Drip | Integrations | Reports |
|---------|:---------:|:-----:|:-------:|:----:|:------------:|:-------:|
| `minimal` | 1 | 10 | Basic (2 programs, 1 instructor) | No | No | 1 month |
| `standard` | 2 | 100 | Medium (5 programs, 3 instructors) | Yes | 1 | 3 months |
| `full` | 4 | 500 | Full (8 programs, 6 instructors, 4 offers, 10 testimonials) | Yes | 2 | 6 months |

### Request Mapping

| User says | Command |
|-----------|---------|
| "pump a demo studio" | `--profile standard` |
| "pump a minimal account" | `--profile minimal` |
| "pump a full account" | `--profile full --verbose` |
| "seed 200 leads into org X" | `--org-id X --lead-count 200` |
| "pump with events" | `--profile standard --lead-mode with-events --service-token $CRM98_SERVICE_TOKEN` |
| "clean up org X" | `--cleanup --org-id X` |
| "dry run" | `--profile standard --dry-run` |
| "reproducible pump" | `--profile standard --seed 42` |

### Flags Reference

```
--org-id <uuid>        Target existing org (skip org creation)
--profile <name>       minimal | standard | full (default: standard)
--lead-mode <mode>     silent | with-events (default: silent)
--lead-count <n>       Override lead count
--days-back <n>        Days of lead history (default: 90)
--cleanup              Delete all data for --org-id
--dry-run              Print plan without writing
--seed <n>             Deterministic RNG seed
--verbose              Detailed per-insert logging
--api-url <url>        API URL for event mode (default: http://localhost:3000)
--service-token <tok>  Service token for event mode
```

### After Pumping

All pumped users share the password `password123456`. The admin user email follows the pattern `admin@{slug}.test`.

Report the org ID, slug, admin email, and lead count from the summary output so the user can log in immediately.

### Event Mode Notes

`--lead-mode with-events` submits leads via the API instead of direct DB inserts. This triggers the full event pipeline: event creation, notification dispatch (email/SMS/voice), drip enrollment, and integration delivery. Requires a running API server and queue worker. Leads are submitted at ~2/sec to avoid overwhelming the worker. Lead timestamps will be `NOW()` (not backdated).

### Cleanup

`--cleanup --org-id <uuid>` deletes ALL data for that org in reverse FK order (tokens, assignments, users, leads, notifications, drip executions, integrations, etc.) and then the org itself. Irreversible — confirm with the user before running without `--dry-run`.
