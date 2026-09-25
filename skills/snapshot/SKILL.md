---
name: snapshot
description: Save a verbatim snapshot of the current session's transcript to docs/transcripts/ as a mid-session checkpoint. Companion to the SessionEnd hook which writes the final version. Currently scoped to the cgii project.
user-invocable: true
allowed-tools: Bash
argument-hint: [optional-slug] — short kebab-case label that appears in the checkpoint filename
---

# /snapshot — Mid-Session Transcript Checkpoint

Save the current session's live transcript (the JSONL Claude Code writes in real time) to `docs/transcripts/` as a mid-session checkpoint.

## When to use

- You want to capture the conversation up to this moment for later replay
- A long decision conversation is about to wrap up and you want it preserved before the session ends
- You want to grep a specific moment later and don't trust that you'll remember to do it at session end

The SessionEnd hook (in `~/.claude/settings.json`) writes a `-final.jsonl` file automatically when the session ends. `/snapshot` writes a `-checkpoint.jsonl` file *now*. Both live in the same directory.

## What it does

1. Determines the current session's transcript path from Claude Code's internal storage.
2. Copies it to `docs/transcripts/YYYYMMDD-HHMM-session-{short8}-checkpoint[-{slug}].jsonl`.
3. Reports the file path so you know where it went.

## Project scope

**Currently scoped to the cgii project.** If invoked from another project's cwd, the skill reports that and exits without copying. To extend coverage, add another `case` arm.

## How to invoke

```
/snapshot
/snapshot section-16-rewrite
/snapshot before-merge
```

The slug is optional. When provided, it appears in the checkpoint filename for findability.

## Instructions (model-facing)

When the user invokes this skill, run a single Bash command that:

1. **Determines the cwd** — check the project's cwd directly. This skill is currently cgii-scoped; if cwd doesn't match, report and exit.
2. **Finds the live transcript path** — the JSONL lives at `~/.claude/projects/<sanitized-cwd>/<session_id>.jsonl`. For cgii, the project dir is `~/.claude/projects/-Users-msichris-repos-cgii/`. The current session_id is not directly visible from the model side, but the **most recently modified `.jsonl` in that directory** is reliably the active session (Claude Code appends in real time as the session runs).
3. **Copies** the most-recently-modified JSONL to `docs/transcripts/YYYYMMDD-HHMM-session-{short8}-checkpoint[-{slug}].jsonl`.
4. **Reports** the destination path back to the user.

### The Bash command

Pass any user-provided slug as `$ARGUMENTS` (the slug, or empty). Use this command (substitute the slug appropriately):

```bash
slug="${ARGUMENTS}"  # passed from invocation; may be empty
cwd=$(pwd)
case "$cwd" in
  */repos/cgii*)
    proj_dir="$HOME/.claude/projects/-Users-msichris-repos-cgii"
    src=$(ls -t "$proj_dir"/*.jsonl 2>/dev/null | head -1)
    if [ -z "$src" ]; then
      echo "ERROR: no transcript JSONL found in $proj_dir"
      exit 1
    fi
    sid=$(basename "$src" .jsonl)
    short=${sid:0:8}
    ts=$(date +%Y%m%d-%H%M)
    if [ -n "$slug" ]; then
      dst="/Users/msichris/repos/cgii/docs/transcripts/${ts}-session-${short}-checkpoint-${slug}.jsonl"
    else
      dst="/Users/msichris/repos/cgii/docs/transcripts/${ts}-session-${short}-checkpoint.jsonl"
    fi
    cp "$src" "$dst" && echo "Checkpoint saved: $dst ($(wc -l < "$dst") lines)"
    ;;
  *)
    echo "SKIP: /snapshot is currently scoped to the cgii project. cwd=$cwd"
    exit 0
    ;;
esac
```

Pass it via the Bash tool. Report the resulting path (and line count) to the user in one short sentence.

## Failure modes

- **No transcript file found:** report it cleanly; don't pretend it worked.
- **docs/transcripts/ doesn't exist:** create it (`mkdir -p`) before the copy. The cgii repo already has this directory, but other projects may not when scope expands.
- **Non-cgii cwd:** report "skipped, scope" and exit 0. Not an error.

## Companion

The SessionEnd hook in `~/.claude/settings.json` writes the `-final.jsonl` variant automatically. Together: checkpoints during, final at end.
