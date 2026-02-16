# Security Review Protocol — Skillzees

## Scope

Skillzees contains only markdown prompt files and a bash installer. Security review focuses on:

1. **Prompt injection risk** — Could a command file be crafted to make Claude do something unintended?
2. **Installer safety** — Does `install.sh` only copy files and nothing else?
3. **Sensitive data** — Are any secrets, tokens, or credentials accidentally included in command files?

## Review Cadence

- Before each release (version tag)
- After adding commands that reference external services (e.g., `/ticky` references Azure DevOps, `/prodstatus` references AWS)

## Checklist

| # | Check | Status |
|---|-------|--------|
| 1 | No hardcoded secrets in any `.md` file | PASS |
| 2 | `install.sh` only uses `cp`, `mkdir`, `rm`, `diff` — no network calls | PASS |
| 3 | No `eval`, `curl | bash`, or dynamic code execution in installer | PASS |
| 4 | Commands that reference external services document auth requirements | PASS |
| 5 | No command instructs Claude to bypass safety checks | PASS |

**Last reviewed:** 2026-02-15
