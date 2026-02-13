#!/usr/bin/env bash
# ============================================================================
# Callhero Standard — Claude Code Global Skills Installer
# ============================================================================
# Installs global slash commands for Claude Code on a new machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<your-repo>/main/install.sh | bash
#   -- or --
#   bash install.sh
#   -- or --
#   bash install.sh --from /path/to/source/commands
#
# What it does:
#   1. Creates ~/.claude/commands/ if it doesn't exist
#   2. Copies all .md command files into that directory
#   3. Verifies installation
#
# Skills installed:
#   /init-project         Full project scaffold (callhero standard)
#   /five-persona-review  Multi-perspective code review (5 expert personas)
#   /security-audit       Structured security audit (OWASP + cloud + supply chain)
#   /pm                   Bolt sprint management
#   /budget               Infrastructure cost tracking
#   /bolt-review          End-of-sprint comprehensive review
#   /changelog            Keep-a-Changelog format updates
#   /cost-estimate        Development effort estimation
#   /readme               Will-Larson-quality README generation
#   /captainslog          Session logs for AI context continuity
# ============================================================================

set -euo pipefail

COMMANDS_DIR="${HOME}/.claude/commands"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR=""
INSTALLED=0
SKIPPED=0
UPDATED=0

# Colors (if terminal supports them)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' BLUE='' RED='' BOLD='' NC=''
fi

usage() {
    echo "Usage: bash install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --from DIR    Source directory containing .md command files"
    echo "  --force       Overwrite existing commands without prompting"
    echo "  --list        List available commands and exit"
    echo "  --uninstall   Remove all installed commands"
    echo "  -h, --help    Show this help"
}

# Parse arguments
FORCE=false
LIST_ONLY=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --from)
            SOURCE_DIR="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Determine source directory
if [ -z "$SOURCE_DIR" ]; then
    # If running from the commands dir itself, use it
    if [ -f "${SCRIPT_DIR}/init-project.md" ]; then
        SOURCE_DIR="$SCRIPT_DIR"
    else
        echo -e "${RED}Error: No source directory specified and no commands found in script directory.${NC}"
        echo "Use: bash install.sh --from /path/to/commands"
        exit 1
    fi
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory not found: ${SOURCE_DIR}${NC}"
    exit 1
fi

# Expected command files
COMMANDS=(
    "init-project.md"
    "five-persona-review.md"
    "security-audit.md"
    "pm.md"
    "budget.md"
    "bolt-review.md"
    "changelog.md"
    "cost-estimate.md"
    "readme.md"
    "captainslog.md"
)

# List mode
if [ "$LIST_ONLY" = true ]; then
    echo -e "${BOLD}Callhero Standard — Available Commands${NC}"
    echo ""
    for cmd in "${COMMANDS[@]}"; do
        name="${cmd%.md}"
        if [ -f "${COMMANDS_DIR}/${cmd}" ]; then
            echo -e "  ${GREEN}✓${NC} /${name} (installed)"
        elif [ -f "${SOURCE_DIR}/${cmd}" ]; then
            echo -e "  ${YELLOW}○${NC} /${name} (available)"
        else
            echo -e "  ${RED}✗${NC} /${name} (not found in source)"
        fi
    done
    exit 0
fi

# Uninstall mode
if [ "$UNINSTALL" = true ]; then
    echo -e "${BOLD}Uninstalling Callhero Standard commands...${NC}"
    for cmd in "${COMMANDS[@]}"; do
        if [ -f "${COMMANDS_DIR}/${cmd}" ]; then
            rm "${COMMANDS_DIR}/${cmd}"
            echo -e "  ${RED}✗${NC} Removed /${cmd%.md}"
        fi
    done
    echo -e "\n${GREEN}Done.${NC} Commands removed. Claude Code will no longer show these slash commands."
    exit 0
fi

# ============================================================================
# Install
# ============================================================================

echo -e "${BOLD}Callhero Standard — Claude Code Global Skills Installer${NC}"
echo ""

# Step 1: Ensure target directory exists
mkdir -p "$COMMANDS_DIR"
echo -e "${BLUE}Target:${NC} ${COMMANDS_DIR}"
echo -e "${BLUE}Source:${NC} ${SOURCE_DIR}"
echo ""

# Step 2: Copy command files
for cmd in "${COMMANDS[@]}"; do
    src="${SOURCE_DIR}/${cmd}"
    dst="${COMMANDS_DIR}/${cmd}"
    name="${cmd%.md}"

    if [ ! -f "$src" ]; then
        echo -e "  ${YELLOW}⚠${NC}  /${name} — not found in source, skipping"
        ((SKIPPED++))
        continue
    fi

    if [ -f "$dst" ]; then
        # Check if files differ
        if diff -q "$src" "$dst" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC}  /${name} — already up to date"
            ((SKIPPED++))
            continue
        fi

        if [ "$FORCE" = true ]; then
            cp "$src" "$dst"
            echo -e "  ${YELLOW}↻${NC}  /${name} — updated (overwritten)"
            ((UPDATED++))
        else
            echo -en "  ${YELLOW}?${NC}  /${name} — exists and differs. Overwrite? [y/N] "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                cp "$src" "$dst"
                echo -e "      ${YELLOW}↻${NC}  Updated"
                ((UPDATED++))
            else
                echo -e "      Skipped"
                ((SKIPPED++))
            fi
        fi
    else
        cp "$src" "$dst"
        echo -e "  ${GREEN}+${NC}  /${name} — installed"
        ((INSTALLED++))
    fi
done

# Step 3: Also copy any .md files not in the known list (future commands)
for src in "${SOURCE_DIR}"/*.md; do
    [ -f "$src" ] || continue
    cmd="$(basename "$src")"

    # Skip if already handled
    skip=false
    for known in "${COMMANDS[@]}"; do
        if [ "$cmd" = "$known" ]; then
            skip=true
            break
        fi
    done
    if [ "$skip" = true ]; then
        continue
    fi

    # Skip install.sh itself (this file's companion)
    if [ "$cmd" = "install.md" ]; then
        continue
    fi

    dst="${COMMANDS_DIR}/${cmd}"
    name="${cmd%.md}"

    if [ -f "$dst" ] && diff -q "$src" "$dst" > /dev/null 2>&1; then
        continue
    fi

    if [ ! -f "$dst" ] || [ "$FORCE" = true ]; then
        cp "$src" "$dst"
        echo -e "  ${GREEN}+${NC}  /${name} — installed (extra)"
        ((INSTALLED++))
    fi
done

# Step 4: Summary
echo ""
echo -e "${BOLD}Summary:${NC}"
echo -e "  Installed: ${GREEN}${INSTALLED}${NC}"
echo -e "  Updated:   ${YELLOW}${UPDATED}${NC}"
echo -e "  Skipped:   ${SKIPPED}"
echo ""

# Step 5: Verify
echo -e "${BOLD}Verification:${NC}"
TOTAL=0
for cmd in "${COMMANDS[@]}"; do
    if [ -f "${COMMANDS_DIR}/${cmd}" ]; then
        ((TOTAL++))
    fi
done
echo -e "  ${TOTAL}/${#COMMANDS[@]} commands installed in ${COMMANDS_DIR}"
echo ""

if [ "$TOTAL" -eq "${#COMMANDS[@]}" ]; then
    echo -e "${GREEN}${BOLD}All commands installed successfully.${NC}"
    echo ""
    echo "These slash commands are now available in Claude Code:"
    echo ""
    for cmd in "${COMMANDS[@]}"; do
        echo "  /${cmd%.md}"
    done
    echo ""
    echo "Try: claude and then type /init-project my-new-app"
else
    echo -e "${YELLOW}Some commands were not installed. Run with --list to check status.${NC}"
fi
