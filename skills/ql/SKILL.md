---
name: ql
description: Shortcut alias for /qx with default leader — logs a question for leadership (falls back to project-configured default leader). See /qx for full behavior.
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
argument-hint: "<question text>"
---

# /ql — Question for Leadership (alias for `/qx`)

Thin shortcut that preserves the muscle-memory of `/ql <question>` while delegating all logic to the generalized `/qx` skill. qx will pick the project's default leader from context (config.yaml / prior usage) when no first name is supplied.

## Instruction

When invoked, treat this as `/qx $ARGUMENTS` and follow the qx skill's instructions verbatim. If qx cannot determine a leader from context, let qx prompt the user for a first name — do not hard-code one here.
