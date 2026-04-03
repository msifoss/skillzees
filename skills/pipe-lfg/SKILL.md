---
name: pipe-lfg
description: Three-pillar pipeline health check — verifies CRM98, 98agents, and webengine infrastructure is healthy end-to-end
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep, Agent, WebFetch
argument-hint: [full | quick | fix]
---

# /pipe-lfg — Three-Pillar Pipeline Health Check

Comprehensive health check across the CRM98 three-pillar platform (CRM, Agents, WebEngine). Verifies containers, services, event delivery, backups, SSL, and the full provisioning pipeline.

> Like a pre-flight checklist before a rocket launch. Every system, every connection, every backup — verified before you build more.

## Trigger

User invokes `/pipe-lfg` with optional arguments.

## Arguments

| Argument | Description |
|----------|-------------|
| *(none)* or `full` | Run all checks (~30s). Default. |
| `quick` | Run only critical checks (containers + API + agents). ~10s. |
| `fix` | Run all checks, then offer to fix any FAIL/WARN items. |

---

## Infrastructure Reference

These are the known production endpoints. If they change, update this section.

```
CRM VPS:        45.77.216.109 (SSH key: ~/.ssh/vulty_deploy, user: root)
WebEngine VPS:  45.76.12.158  (SSH key: ~/.ssh/webengine_deploy, user: root for infra, deploy for app)
CRM Domain:     crm98.membies.com
Agent Webhook:  http://45.76.12.158:3098/events
Agent Health:   http://45.76.12.158:3098/healthz
```

---

## Phase 1 — Run Checks

Run each check and collect results as PASS, WARN, or FAIL.

### Check 1: CRM Containers (Critical)

SSH into CRM VPS and verify all 5 containers are running and healthy:

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 'docker compose -f /opt/crm98/docker-compose.yml -f /opt/crm98/docker-compose.prod.yml ps --format "{{.Name}} {{.Status}}"'
```

**Expected:** 5 containers (api, worker, caddy, postgres, redis) all showing "Up" with postgres and redis "healthy".

| Situation | Status |
|-----------|--------|
| All 5 up + DB/Redis healthy | PASS |
| All up but DB/Redis not healthy | WARN |
| Any container missing or exited | FAIL |

### Check 2: CRM API Health (Critical)

```bash
curl -sf --connect-timeout 5 https://crm98.membies.com/healthz
```

**Expected:** JSON response with `"status":"ok"`.

| Situation | Status |
|-----------|--------|
| 200 with status ok | PASS |
| 200 but status not ok | WARN |
| Timeout or non-200 | FAIL |

### Check 3: 98agents Health (Critical)

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 'curl -sf --connect-timeout 5 http://45.76.12.158:3098/healthz'
```

Test from CRM VPS (verifies firewall rule + agent server).

**Expected:** JSON with `"status":"ok"`.

| Situation | Status |
|-----------|--------|
| 200 with status ok | PASS |
| Timeout (firewall or agent down) | FAIL |
| Connection refused (PM2 crashed) | FAIL |

### Check 4: PM2 Process (High)

```bash
ssh -i ~/.ssh/webengine_deploy deploy@45.76.12.158 'pm2 list --no-color 2>&1 | grep 98agents'
```

**Expected:** Shows `online` status.

| Situation | Status |
|-----------|--------|
| Status: online, uptime > 1 min | PASS |
| Status: online, restarts > 10 | WARN |
| Status: errored or stopped | FAIL |

### Check 5: Worker Heartbeat (High)

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 "docker exec crm98-postgres-1 psql -U crm98 -d crm98 -c \"SELECT service_name, last_seen, EXTRACT(EPOCH FROM NOW() - last_seen)::int as seconds_ago FROM system_health WHERE service_name = 'queue-worker';\""
```

**Expected:** `last_seen` within the last 10 minutes (600 seconds).

| Situation | Status |
|-----------|--------|
| Heartbeat < 600s ago | PASS |
| Heartbeat 600-1800s ago | WARN |
| Heartbeat > 1800s or no row | FAIL |

### Check 6: Dead Letter Count (High)

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 "docker exec crm98-postgres-1 psql -U crm98 -d crm98 -t -c \"SELECT COUNT(*)::int FROM events WHERE status = 'dead_letter' AND created_at > NOW() - INTERVAL '24 hours';\""
```

| Situation | Status |
|-----------|--------|
| 0 dead letters in 24h | PASS |
| 1-5 dead letters | WARN |
| > 5 dead letters | FAIL |

### Check 7: Event Delivery Success Rate (High)

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 "docker exec crm98-postgres-1 psql -U crm98 -d crm98 -c \"SELECT status, COUNT(*)::int FROM event_deliveries WHERE created_at > NOW() - INTERVAL '24 hours' GROUP BY status;\""
```

| Situation | Status |
|-----------|--------|
| > 90% delivered (or no deliveries) | PASS |
| 70-90% delivered | WARN |
| < 70% delivered | FAIL |

### Check 8: Event Destinations Valid (Medium)

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 "docker exec crm98-postgres-1 psql -U crm98 -d crm98 -c \"SELECT DISTINCT destination_config::jsonb->>'webhookUrl' as url FROM event_destinations WHERE active = true;\""
```

Verify all URLs point to the correct agent endpoint and not stale Docker container URLs.

| Situation | Status |
|-----------|--------|
| All URLs = http://45.76.12.158:3098/events | PASS |
| Mix of URLs (some stale) | WARN |
| Any pointing to Docker internal (http://98agents:3098) | FAIL |

### Check 9: Database Backup (High)

```bash
ssh -i ~/.ssh/vulty_deploy root@45.77.216.109 'ls -lt /opt/crm98/backups/crm98-*.sql.gz 2>/dev/null | head -1'
```

| Situation | Status |
|-----------|--------|
| Backup exists, < 25 hours old | PASS |
| Backup exists, 25-48 hours old | WARN |
| No backup or > 48 hours old | FAIL |

### Check 10: SSL Certificate Expiry (Medium)

```bash
echo | openssl s_client -servername crm98.membies.com -connect crm98.membies.com:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null
```

| Situation | Status |
|-----------|--------|
| Expires > 30 days from now | PASS |
| Expires in 7-30 days | WARN |
| Expires in < 7 days or expired | FAIL |

### Check 11: Git Repos Clean (Low)

```bash
# For whichever repo the user is in:
git status --short
git branch -r | wc -l
```

| Situation | Status |
|-----------|--------|
| Clean working tree, ≤ 2 remote branches | PASS |
| Uncommitted changes or 3-5 stale branches | WARN |
| > 5 stale branches | FAIL |

### Check 12: Pending Migrations (Medium)

```bash
ls packages/db/src/migrations/*.sql 2>/dev/null | while read f; do
  basename "$f"
done
```

Cross-reference with what's been applied. If SQL files exist that haven't been run on production, flag them.

| Situation | Status |
|-----------|--------|
| No pending migrations | PASS |
| Migrations exist (may or may not be applied) | WARN |

### Check 13: WebEngine Sites Serving (Medium)

Pick 2-3 known live sites and verify they return 200:

```bash
curl -sf -o /dev/null -w "%{http_code}" https://chop.membies.com/ 2>&1
```

| Situation | Status |
|-----------|--------|
| All checked sites return 200 | PASS |
| Some return non-200 | WARN |
| All return errors | FAIL |

---

## Phase 2 — Present Dashboard

```
## 🔧 Pipeline Health Report
### Generated: <date>
### Repos: crm98 + 98agents + webengine

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | CRM Containers | PASS/WARN/FAIL | [one-line] |
| 2 | CRM API Health | PASS/WARN/FAIL | [one-line] |
| 3 | 98agents Health | PASS/WARN/FAIL | [one-line] |
| 4 | PM2 Process | PASS/WARN/FAIL | [one-line] |
| 5 | Worker Heartbeat | PASS/WARN/FAIL | [one-line] |
| 6 | Dead Letters (24h) | PASS/WARN/FAIL | [count] |
| 7 | Event Delivery Rate | PASS/WARN/FAIL | [%] |
| 8 | Destinations Valid | PASS/WARN/FAIL | [url check] |
| 9 | DB Backup | PASS/WARN/FAIL | [age] |
| 10 | SSL Expiry | PASS/WARN/FAIL | [days remaining] |
| 11 | Git Clean | PASS/WARN/FAIL | [branch count] |
| 12 | Pending Migrations | PASS/WARN/FAIL | [count] |
| 13 | Sites Serving | PASS/WARN/FAIL | [checked N sites] |

**Result: [X] PASS / [Y] WARN / [Z] FAIL** (of 13 checks)
```

---

## Phase 3 — Action Items

After the dashboard, list specific actions:

```
### Immediate (FAIL items)
- [Specific fix with exact command]

### Soon (WARN items)
- [What to do and when]

### Healthy (PASS items)
- [Brief confirmation]
```

---

## Phase 4 — Offer to Fix (if `fix` mode)

If invoked with `fix`, offer to execute fixes for FAIL and WARN items:

1. **Fix all items now** — work through FAIL first, then WARN
2. **Fix critical only** — just FAIL items
3. **Just the report** — no changes

For each fix, show what will be done and ask for confirmation before executing.

---

## Quick Mode

When invoked with `quick`, run only checks 1-3 (containers, API, agents) and report. Skip everything else. This is for "is production alive?" checks between deploys.

---

## Notes

- This skill requires SSH access to both VPS servers. If keys are not available, those checks will show as SKIP.
- The skill works from any of the three repos — it doesn't depend on which directory you're in.
- Results are not saved to a file unless the user asks. It's a live dashboard, not a document.
- If a check fails with an SSH error, the issue is likely key permissions or server access, not the service itself.
