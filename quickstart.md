# /quickstart — Get Started in 60 Seconds

Usage: `/quickstart`

**Arguments:** $ARGUMENTS

---

## Purpose

Reduces the cognitive load of 33 tools to 3 commands. For new users who want to start working immediately without reading framework docs.

> You don't need to understand 7 phases, 4 pillars, and 14 templates to start. You need three commands.

---

## Instructions for Claude

Display this guide immediately — no setup required:

```
## AI-DLC Quick Start

You have 33 tools installed. You need 3:

### 1. Build something
/bolt-lfg "what you want to build"

  This runs the full pipeline automatically:
  brainstorm → plan → research → build → review → document

  Just describe what you want. It handles the rest.

### 2. Build something FAST
/slfg "what you want to build"

  Same as /bolt-lfg but runs work items in parallel.
  Use when building multiple independent things.
  Add --speed to skip the ceremony.

### 3. Review code
/five-persona-review

  12 expert personas tear apart your code independently.
  Finds security holes, performance issues, and anti-patterns.

---

## That's it. Start with /bolt-lfg.

## When you need more:

| Need | Command |
|------|---------|
| Explore an idea before building | /brainstorm "idea" |
| Check project health | /motherhen |
| Get strategic advice | /staff-panel "question" |
| Executive-level analysis | /exec-review "question" |
| Configure per-project settings | /setup |
| Manage sprint/backlog | /pm status |
| Security audit | /security-audit |
| Scaffold a new project | /init-project |
| Create a new skill | /create-skill |
| Fix a broken skill | /heal-skill |

## The full inventory
Run: dlc list
```

---

## Integration

- First command new users encounter
- Points to /bolt-lfg, /slfg, /five-persona-review as the core 3
- Reduces the "80 concepts" barrier to "3 commands"
