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
