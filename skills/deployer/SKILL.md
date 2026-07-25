---
name: deployer
description: Deployment agent — generic deploy pipeline runner, multi-environment verification, runbook generation
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch
argument-hint: "pipeline | verify | runbook | canary"
---

# /deployer — Deployment Agent

Generic deployment agent for Phase 5 operations. Sets up deployment pipelines, verifies multi-environment parity, generates runbooks, and supports canary deployments. Not tied to any specific product or cloud provider.

## Trigger

User invokes `/deployer [action]` or at Phase 5 entry.

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `pipeline` | Generate deployment pipeline configuration | `/deployer pipeline` |
| `verify` | Verify environment parity (dev/staging/prod) | `/deployer verify` |
| `runbook` | Generate runbooks for failure scenarios | `/deployer runbook` |
| `canary` | Set up canary deployment strategy | `/deployer canary` |

---

## Action: `pipeline`

Generate deployment pipeline config based on detected platform:

### Platform Detection

```bash
# Detect CI/CD platform
test -f .github/workflows/*.yml && echo "github-actions"
test -f azure-pipelines.yml && echo "azure-pipelines"
test -f .gitlab-ci.yml && echo "gitlab-ci"
test -f buildspec.yml && echo "aws-codebuild"
test -f cloudbuild.yaml && echo "gcp-cloudbuild"
```

### Pipeline Stages

Following AI-DLC Phase 5 pipeline design:

```
Validate → Dev → Approval → Staging → Prod
   │         │       │          │        │
   lint     smoke   human    full     canary
   test     test    review   tests    → 100%
   scan
   build
```

Generate platform-specific config for all 5 stages.

---

## Action: `verify`

Check environment parity across dev/staging/prod:

| Check | What |
|-------|------|
| Runtime versions | Same language/framework versions |
| Infrastructure topology | Same service architecture |
| Environment variables | Same variable names (different values OK) |
| Dependencies | Same package versions |
| Database schema | Same migrations applied |

```markdown
## Environment Parity Report

| Check | Dev | Staging | Prod | Parity |
|-------|-----|---------|------|--------|
| Node version | 20.x | 20.x | 20.x | YES |
| Database schema | v12 | v12 | v11 | NO — prod behind |
```

---

## Action: `runbook`

Generate runbooks for known failure scenarios:

1. Service down — restart procedure
2. Database connection failure — failover steps
3. High latency — scaling procedure
4. Deployment failure — rollback steps
5. Security incident — response procedure
6. Cost spike — kill switch activation

Each runbook follows the format:
```markdown
## Runbook: [Scenario]

### Detection
[How to know this is happening]

### Impact
[What's affected]

### Steps
1. [Specific action]
2. [Specific action]

### Verification
[How to confirm resolution]

### Post-incident
[What to document]
```

Save to `docs/runbooks/`.

---

## Action: `canary`

Design a canary deployment strategy:
1. Deploy to 10% of traffic
2. Monitor error rate and latency for 15 minutes
3. If metrics within threshold: promote to 100%
4. If metrics degrade: auto-rollback

---

## Integration Points

- **Hardener:** Must pass ops readiness (85/94) before deployment
- **Gatekeeper:** GATE-P5-01 through GATE-P5-09
- **State:** Updates deployment status
- **Costkeeper:** Monitoring deployed alongside application
