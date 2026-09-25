---
name: qb
description: Shortcut alias for /qx bryant — logs a question for Bryant (Group CEO / interim BUL). See /qx for full behavior.
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
argument-hint: "<question text>"
---

# /qb — Question for Bryant (alias for `/qx bryant`)

Thin shortcut that preserves the muscle-memory of `/qb <question>` while delegating all logic to the generalized `/qx` skill. Everything — routing to `docs/strats/questions/questions4strozinsky.md`, generating the `QB-NNN` id, appending the teamtodo row — is handled by qx.

## Instruction

When invoked, treat this as `/qx bryant $ARGUMENTS` and follow the qx skill's instructions verbatim. Do not duplicate qx's logic here.
