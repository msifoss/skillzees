# Changelog Update

Usage: `/changelog [version]`

**Arguments:** $ARGUMENTS

---

## Purpose

Updates `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Analyzes recent git history and code changes to generate accurate, comprehensive changelog entries.

---

## Instructions for Claude

### 0. Parse Arguments

Extract `version` from: `$ARGUMENTS`

- If version provided (e.g., `1.2.0`), create a release entry
- If no version, update the `[Unreleased]` section
- If `release [version]`, move Unreleased items into a versioned entry

### 1. Gather Changes

```bash
# Find the last changelog entry date/commit
git log --oneline -1 CHANGELOG.md

# All commits since last changelog update
git log --oneline [last-changelog-commit]..HEAD

# Files changed
git diff --stat [last-changelog-commit]..HEAD
```

### 2. Read Changed Files

For each significantly changed file, read it to understand the nature of the change. Categorize each change:

| Category | Meaning |
|----------|---------|
| **Added** | New features, new files, new capabilities |
| **Changed** | Modifications to existing functionality |
| **Fixed** | Bug fixes |
| **Removed** | Deleted features, files, dead code |
| **Security** | Security-related changes |
| **Documentation** | Doc-only changes (if significant) |

### 3. Write Changelog Entry

Read existing `CHANGELOG.md` and append/update:

**For Unreleased:**
```markdown
## [Unreleased]

### Added
- [Description of new feature] ([relevant context])

### Changed
- [What changed and why]

### Fixed
- [What was broken and how it was fixed]
```

**For a Release:**
```markdown
## [X.Y.Z] - YYYY-MM-DD (Bolt [N] — [Name])

### Added
- [entries]

### Changed
- [entries]

### Fixed
- [entries]

### Removed
- [entries]
```

### 4. Quality Rules

- Each entry should explain the **user-facing impact**, not implementation details
- Use past tense ("Added", "Fixed", not "Add", "Fix")
- Include file/function references for developer-facing changes
- Group related changes under a sub-heading if they're part of the same feature
- Mention test count changes if significant (e.g., "Test count: 89 → 101")
- Include security findings resolved if applicable
- Note breaking changes prominently

### 5. Confirm

Show the proposed changelog entry and ask the user to confirm before writing.
