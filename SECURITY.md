# Security Policy

## Scope

Skillzees is a collection of markdown prompt files (`.md`) and a bash installer script. It contains **no executable application code**, no authentication, no network access, and no secrets.

## Risk Profile

| Vector | Risk | Mitigation |
|--------|------|------------|
| Prompt injection via command files | Low | Commands are installed by the user intentionally; Claude Code reviews tool calls before execution |
| `install.sh` script execution | Low | Script only copies `.md` files to `~/.claude/commands/`; no elevated privileges required |
| Sensitive data in commands | Low | No secrets, tokens, or credentials are stored in command files |

## Reporting a Vulnerability

If you discover a security issue:

1. **Do not** open a public issue
2. Email the maintainer or open a private security advisory on the [GitHub repo](https://github.com/msifoss/skillzees)
3. Include: description, reproduction steps, and potential impact

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.0 | Yes |
