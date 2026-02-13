# Security Audit

Usage: `/security-audit [scope]`

**Arguments:** $ARGUMENTS

---

## Purpose

Conducts a structured security audit following the methodology that produced 155 findings across 4 rounds in the callhero project. This audit checks OWASP Top 10, cloud-specific risks, supply chain security, and operational security controls.

---

## Instructions for Claude

### 0. Parse Arguments

Extract `scope` from: `$ARGUMENTS`

- If no scope, audit the **entire codebase**
- If scope is `new` or `changes`, audit only uncommitted or recently changed files
- If scope is a path, audit that directory/file

### 1. Inventory

Before auditing, catalog:
- All entry points (APIs, Lambda handlers, CLI commands, web routes)
- All external integrations (APIs, databases, message queues, file storage)
- All authentication/authorization mechanisms
- All secrets and credentials (where stored, how accessed)
- All user-controlled inputs
- All dependencies (with versions)
- All infrastructure definitions (IaC templates, Docker, CI/CD)
- All network boundaries (VPCs, security groups, firewalls)

### 2. Audit Checklist

Work through each category systematically:

#### A. Authentication & Authorization
- [ ] Every endpoint requires authentication
- [ ] API keys are hashed before storage (never plaintext)
- [ ] Sessions have reasonable timeouts
- [ ] Cross-account/cross-service access uses least privilege
- [ ] Service accounts have scoped permissions
- [ ] Token rotation is supported
- [ ] Revocation is immediate (no cache delay beyond acceptable window)

#### B. Input Validation
- [ ] All user input is validated at the boundary
- [ ] Validation uses allowlists, not blocklists
- [ ] Regex patterns are anchored (`^...$`)
- [ ] Input length limits are enforced
- [ ] Defense-in-depth: re-validation after deserialization (e.g., post-SQS)
- [ ] File uploads have size and type restrictions
- [ ] SQL parameters are parameterized (never string-interpolated)
- [ ] HTML output is escaped to prevent XSS

#### C. Secrets Management
- [ ] No secrets in source code (search for API keys, passwords, tokens)
- [ ] No secrets in CI/CD pipeline definitions
- [ ] Secrets use proper secret management (SSM, Secrets Manager, Vault)
- [ ] `.env` files are in `.gitignore`
- [ ] Log output never includes secrets, tokens, or full request bodies
- [ ] Error messages don't leak internal details to callers

#### D. Encryption
- [ ] Data at rest is encrypted (databases, queues, storage)
- [ ] Data in transit uses TLS/HTTPS
- [ ] Database connections enforce SSL (`sslmode=require` or equivalent)
- [ ] KMS keys are properly scoped

#### E. Network Security
- [ ] Services in VPC have minimal egress rules
- [ ] No unnecessary public endpoints
- [ ] Security groups use explicit rules (not defaults)
- [ ] Database is not publicly accessible
- [ ] Bastion/jump hosts use session management (SSM), not SSH keys

#### F. Infrastructure Security
- [ ] IAM roles follow least privilege
- [ ] Resources have deletion protection (production)
- [ ] Backups are configured
- [ ] Stack policies protect stateful resources
- [ ] Resource tags are applied for cost and ownership tracking

#### G. Dependency Security
- [ ] All dependency versions are pinned
- [ ] `pip-audit` / `npm audit` / `govulncheck` passes
- [ ] No known CVEs in dependencies
- [ ] `boto3` / runtime-provided packages not in requirements (AWS Lambda)

#### H. Monitoring & Incident Response
- [ ] All failure modes have alerts
- [ ] Dead letter queues have alarms
- [ ] Error logs are structured and queryable
- [ ] Runbook exists for each alarm
- [ ] Log retention is managed (not indefinite, not too short)
- [ ] Request IDs propagate through the entire pipeline

#### I. Operational Security
- [ ] Deployment requires no manual secret handling
- [ ] Rollback procedure is documented and tested
- [ ] Pre-commit hooks prevent common mistakes
- [ ] CI pipeline includes security scanning
- [ ] Cost monitoring prevents runaway spend

### 3. Output Report

Save to `docs/security/[YYYYMMDD]-[HHMMSS]-security-audit.txt`:

```
================================================================================
SECURITY AUDIT: [Project Name]
Date: [YYYY-MM-DD HH:MM]
Scope: [what was audited]
Auditor: Claude (AI-assisted)
================================================================================

## Summary

| Category | Findings | Critical | High | Medium | Low |
|----------|----------|----------|------|--------|-----|
| Authentication | | | | | |
| Input Validation | | | | | |
| Secrets | | | | | |
| Encryption | | | | | |
| Network | | | | | |
| Infrastructure | | | | | |
| Dependencies | | | | | |
| Monitoring | | | | | |
| Operational | | | | | |
| **Total** | | | | | |

## Findings

### Critical

[C1] [Title]
File: [path:line]
Category: [category]
Description: [what's wrong]
Risk: [what could happen]
Fix: [how to fix it]

### High
[Same format]

### Medium
[Same format]

### Low
[Same format]

## Recommendations

1. [Prioritized list of actions]

## Accepted Risks

| Item | Rationale |
|------|-----------|
| [Known limitation] | [Why it's acceptable] |

================================================================================
END OF AUDIT
================================================================================
```

### 4. Update SECURITY.md

After the audit, update `SECURITY.md` with:
- Audit date and findings count
- Any new security controls documented
- Updated "Known Limitations" section

### 5. Offer to Fix

Ask the user if they want to fix findings now, starting with Critical.
