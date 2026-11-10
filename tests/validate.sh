#!/usr/bin/env bash
# ============================================================================
# Skillzees Validation Tests
# ============================================================================
# Verifies installer integrity and command file consistency.
#
# Usage: bash tests/validate.sh
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "Skillzees Validation Tests"
echo "========================="
echo ""

# --------------------------------------------------------------------------
# Test 1: install.sh exists and is executable-ready
# --------------------------------------------------------------------------
echo "1. Installer integrity"

if [ -f "${SCRIPT_DIR}/install.sh" ]; then
    pass "install.sh exists"
else
    fail "install.sh not found"
fi

if bash -n "${SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh has valid bash syntax"
else
    fail "install.sh has syntax errors"
fi

echo ""

# --------------------------------------------------------------------------
# Test 2: Every COMMANDS entry has a corresponding source file
# --------------------------------------------------------------------------
echo "2. COMMANDS array → source file mapping"

# Extract source filenames from COMMANDS array
while IFS= read -r line; do
    src_file=$(echo "$line" | sed 's/.*"\(.*\):.*/\1/')
    if [ -f "${SCRIPT_DIR}/${src_file}" ]; then
        pass "${src_file} exists"
    else
        fail "${src_file} referenced in COMMANDS but file not found"
    fi
done < <(grep -E '^\s+"[a-z].*\.md:' "${SCRIPT_DIR}/install.sh")

echo ""

# --------------------------------------------------------------------------
# Test 3: Command files have required structure
# --------------------------------------------------------------------------
echo "3. Command file structure"

while IFS= read -r line; do
    src_file=$(echo "$line" | sed 's/.*"\(.*\):.*/\1/')
    filepath="${SCRIPT_DIR}/${src_file}"

    # Check for $ARGUMENTS reference
    if grep -q '\$ARGUMENTS' "$filepath"; then
        pass "${src_file} has \$ARGUMENTS reference"
    else
        fail "${src_file} missing \$ARGUMENTS reference"
    fi
done < <(grep -E '^\s+"[a-z].*\.md:' "${SCRIPT_DIR}/install.sh")

echo ""

# --------------------------------------------------------------------------
# Test 4: No case-insensitive filename collisions
# --------------------------------------------------------------------------
echo "4. Case-insensitive filename safety"

COLLISIONS=$(ls -1 "${SCRIPT_DIR}"/*.md 2>/dev/null | xargs -I{} basename {} | tr '[:upper:]' '[:lower:]' | sort | uniq -d)
if [ -z "$COLLISIONS" ]; then
    pass "No case-insensitive .md filename collisions"
else
    fail "Case collision detected: ${COLLISIONS}"
fi

echo ""

# --------------------------------------------------------------------------
# Test 5: README lists all commands
# --------------------------------------------------------------------------
echo "5. README completeness"

while IFS= read -r line; do
    dst_file=$(echo "$line" | sed 's/.*:\(.*\)".*/\1/')
    cmd_name="${dst_file%.md}"
    if grep -q "/${cmd_name}" "${SCRIPT_DIR}/README.md"; then
        pass "/${cmd_name} listed in README"
    else
        fail "/${cmd_name} not found in README"
    fi
done < <(grep -E '^\s+"[a-z].*\.md:' "${SCRIPT_DIR}/install.sh")

echo ""

# --------------------------------------------------------------------------
# Test 6: install.sh header lists all commands
# --------------------------------------------------------------------------
echo "6. Header comment completeness"

while IFS= read -r line; do
    dst_file=$(echo "$line" | sed 's/.*:\(.*\)".*/\1/')
    cmd_name="${dst_file%.md}"
    if grep -q "#.*/${cmd_name}" "${SCRIPT_DIR}/install.sh"; then
        pass "/${cmd_name} listed in header comment"
    else
        fail "/${cmd_name} not found in header comment"
    fi
done < <(grep -E '^\s+"[a-z].*\.md:' "${SCRIPT_DIR}/install.sh")

echo ""

# --------------------------------------------------------------------------
# Test 7: install.sh actually runs end-to-end into a scratch HOME
# --------------------------------------------------------------------------
# `bash -n` only checks syntax. This catches runtime aborts such as
# `set -e` + `((VAR++))` exiting on the first increment from 0.
echo "7. Installer smoke test (fresh HOME)"

SMOKE_HOME="$(mktemp -d)"
if HOME="$SMOKE_HOME" bash "${SCRIPT_DIR}/install.sh" --from "$SCRIPT_DIR" </dev/null >"${SMOKE_HOME}/install.log" 2>&1; then
    pass "install.sh exits 0 on a fresh HOME"
else
    fail "install.sh exited non-zero on a fresh HOME (see ${SMOKE_HOME}/install.log)"
fi

EXPECTED_CMDS=$(grep -cE '^\s+"[a-z].*\.md:' "${SCRIPT_DIR}/install.sh")
GOT_CMDS=0
while IFS= read -r line; do
    dst_file=$(echo "$line" | sed 's/.*:\(.*\)".*/\1/')
    [ -f "${SMOKE_HOME}/.claude/commands/${dst_file}" ] && GOT_CMDS=$((GOT_CMDS + 1))
done < <(grep -E '^\s+"[a-z].*\.md:' "${SCRIPT_DIR}/install.sh")
if [ "$GOT_CMDS" -eq "$EXPECTED_CMDS" ]; then
    pass "all ${EXPECTED_CMDS} commands installed"
else
    fail "only ${GOT_CMDS}/${EXPECTED_CMDS} commands installed"
fi

EXPECTED_SKILLS=$(ls -d "${SCRIPT_DIR}"/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
GOT_SKILLS=$(ls "${SMOKE_HOME}"/.claude/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$GOT_SKILLS" -eq "$EXPECTED_SKILLS" ]; then
    pass "all ${EXPECTED_SKILLS} skills installed"
else
    fail "only ${GOT_SKILLS}/${EXPECTED_SKILLS} skills installed"
fi

if HOME="$SMOKE_HOME" bash "${SCRIPT_DIR}/install.sh" --from "$SCRIPT_DIR" </dev/null >/dev/null 2>&1; then
    pass "install.sh re-run (already up to date) exits 0"
else
    fail "install.sh re-run exited non-zero"
fi
rm -rf "$SMOKE_HOME"
# Test 8: Every skill has frontmatter with name + description
# --------------------------------------------------------------------------
# Without a `description`, Claude cannot decide when to use a skill, so it
# only works when typed as /name. `name` must match the directory.
echo "8. Skill frontmatter"

for skill_md in "${SCRIPT_DIR}"/skills/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    skill_name="$(basename "$(dirname "$skill_md")")"

    # tr -d '\r' tolerates CRLF files, which Claude Code loads fine
    if [ "$(head -1 "$skill_md" | tr -d '\r')" != "---" ]; then
        fail "skills/${skill_name}: missing frontmatter (first line must be ---)"
        continue
    fi

    # Frontmatter = lines between the first and second ---
    fm="$(tr -d '\r' < "$skill_md" | awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}')"

    fm_name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1 | tr -d "\"'")"
    if [ "$fm_name" = "$skill_name" ]; then
        pass "skills/${skill_name}: name matches directory"
    else
        fail "skills/${skill_name}: name '${fm_name}' does not match directory"
    fi

    if printf '%s\n' "$fm" | grep -qE '^description:[[:space:]]*[^[:space:]]'; then
        pass "skills/${skill_name}: has description"
    else
        fail "skills/${skill_name}: missing or empty description"
    fi
done

echo ""

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo "========================="
TOTAL=$((PASS + FAIL))
echo "Results: ${PASS}/${TOTAL} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
else
    echo "All tests passed."
    exit 0
fi
