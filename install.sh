#!/usr/bin/env bash
# ============================================================================
# Callhero Standard — Claude Code Global Skills Installer
# ============================================================================
# Installs global slash commands and skills for Claude Code on a new machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<your-repo>/main/install.sh | bash
#   -- or --
#   bash install.sh
#   -- or --
#   bash install.sh --from /path/to/source
#
# What it does:
#   1. Creates ~/.claude/commands/ and ~/.claude/skills/ if they don't exist
#   2. Copies all .md command files into ~/.claude/commands/
#   3. Copies all skills (SKILL.md) into ~/.claude/skills/<name>/
#   4. Verifies installation
#
# Commands installed (33):
#   /init-project         Full project scaffold (AI-DLC standard)
#   /five-persona-review  Multi-perspective code review (12 expert personas)
#   /security-audit       Structured security audit (OWASP + cloud + supply chain)
#   /pm                   Bolt sprint management
#   /budget               Infrastructure cost tracking
#   /bolt-review          End-of-sprint comprehensive review
#   /changelog            Keep-a-Changelog format updates
#   /cost-estimate        Development effort estimation
#   /readme               Will-Larson-quality README generation
#   /captainslog          Session logs for AI context continuity
#   /docs                 Documentation generation and maintenance
#   /dlc-audit            AI-DLC compliance audit (8-dimension assessment)
#   /motherhen            Development lifecycle compliance monitor
#   /prodstatus           Production health dashboard (read-only AWS diagnostics)
#   /ticky                Azure DevOps work item lifecycle management
#   /arch-audit           Multi-persona architectural audit
#   /am                   Account manager daily/weekly workflow
#   /bolt-lfg             Autonomous Bolt engineering pipeline
#   /brainstorm           Explore before you plan — structured brainstorming
#   /create-skill         Scaffold a new skill or command
#   /deepen-plan          Parallel research to strengthen any plan
#   /exec-review          Executive review panel (5 strategic thinkers)
#   /generate-command     Quick-create a lightweight command
#   /heal-skill           Diagnose and fix broken skills
#   /monthly-refresh      Datalake monthly data refresh
#   /prd-go               Write production-ready PRDs
#   /quickstart           Get started in 60 seconds
#   /setup                Configure AI-DLC per-project settings
#   /slfg                 Swarm mode autonomous pipeline
#   /staff                Staff engineer panel analysis
#   /compose              Pipeline composer
#   /dlc-loop             Autonomous full-lifecycle DLC execution
#   /route                Skill router
#
# Skills installed (34):
#   ai-effort, am, chealth, conversion-plumber, design-panel, dlc-audit,
#   docs, exec-review, fin-audit, init-brain, internal-link-builder,
#   llm-team, marketing-team, moat-content-writer, motherhen, mytodo,
#   pipe-lfg, pm, prd-go, prodstatus, qb, refine-page, seo-meta-agent,
#   sitrep, staff, staff-rfc, ticky, truck-incentives, vehicle-finder,
#   vertical-builder, webby, webgeni, webteam, weekly-update
# ============================================================================

set -euo pipefail

COMMANDS_DIR="${HOME}/.claude/commands"
SKILLS_DIR="${HOME}/.claude/skills"
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

# Expected command files (source_name:install_name)
# Most files keep their name. generate-readme.md installs as readme.md
# to avoid case-insensitive collision with repo README.md on macOS.
COMMANDS=(
    "init-project.md:init-project.md"
    "five-persona-review.md:five-persona-review.md"
    "security-audit.md:security-audit.md"
    "pm.md:pm.md"
    "budget.md:budget.md"
    "bolt-review.md:bolt-review.md"
    "changelog.md:changelog.md"
    "cost-estimate.md:cost-estimate.md"
    "generate-readme.md:readme.md"
    "captainslog.md:captainslog.md"
    "docs.md:docs.md"
    "dlc-audit.md:dlc-audit.md"
    "motherhen.md:motherhen.md"
    "prodstatus.md:prodstatus.md"
    "ticky.md:ticky.md"
    "arch-audit.md:arch-audit.md"
    "am.md:am.md"
    "bolt-lfg.md:bolt-lfg.md"
    "brainstorm.md:brainstorm.md"
    "create-skill.md:create-skill.md"
    "deepen-plan.md:deepen-plan.md"
    "exec-review.md:exec-review.md"
    "generate-command.md:generate-command.md"
    "heal-skill.md:heal-skill.md"
    "monthly-refresh.md:monthly-refresh.md"
    "prd-go.md:prd-go.md"
    "quickstart.md:quickstart.md"
    "setup.md:setup.md"
    "slfg.md:slfg.md"
    "staff.md:staff.md"
    "compose.md:compose.md"
    "dlc-loop.md:dlc-loop.md"
    "route.md:route.md"
)

# List mode
if [ "$LIST_ONLY" = true ]; then
    echo -e "${BOLD}Callhero Standard — Available Commands${NC}"
    echo ""
    for entry in "${COMMANDS[@]}"; do
        src_file="${entry%%:*}"
        dst_file="${entry##*:}"
        name="${dst_file%.md}"
        if [ -f "${COMMANDS_DIR}/${dst_file}" ]; then
            echo -e "  ${GREEN}✓${NC} /${name} (installed)"
        elif [ -f "${SOURCE_DIR}/${src_file}" ]; then
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
    for entry in "${COMMANDS[@]}"; do
        dst_file="${entry##*:}"
        name="${dst_file%.md}"
        if [ -f "${COMMANDS_DIR}/${dst_file}" ]; then
            rm "${COMMANDS_DIR}/${dst_file}"
            echo -e "  ${RED}✗${NC} Removed /${name}"
        fi
    done
    echo ""
    echo -e "${BOLD}Uninstalling skills...${NC}"
    if [ -d "${SOURCE_DIR}/skills" ]; then
        for skill_dir in "${SOURCE_DIR}"/skills/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name="$(basename "$skill_dir")"
            if [ -d "${SKILLS_DIR}/${skill_name}" ]; then
                rm -rf "${SKILLS_DIR}/${skill_name}"
                echo -e "  ${RED}✗${NC} Removed skill ${skill_name}"
            fi
        done
    fi
    echo -e "\n${GREEN}Done.${NC} Commands and skills removed."
    exit 0
fi

# ============================================================================
# Install
# ============================================================================

echo -e "${BOLD}Callhero Standard — Claude Code Global Skills Installer${NC}"
echo ""

# Step 1: Ensure target directories exist
mkdir -p "$COMMANDS_DIR"
mkdir -p "$SKILLS_DIR"
echo -e "${BLUE}Commands target:${NC} ${COMMANDS_DIR}"
echo -e "${BLUE}Skills target:${NC}   ${SKILLS_DIR}"
echo -e "${BLUE}Source:${NC}          ${SOURCE_DIR}"
echo ""

# Step 2: Copy command files
for entry in "${COMMANDS[@]}"; do
    src_file="${entry%%:*}"
    dst_file="${entry##*:}"
    src="${SOURCE_DIR}/${src_file}"
    dst="${COMMANDS_DIR}/${dst_file}"
    name="${dst_file%.md}"

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

    # Skip if already handled via COMMANDS mapping
    skip=false
    for entry in "${COMMANDS[@]}"; do
        src_file="${entry%%:*}"
        if [ "$cmd" = "$src_file" ]; then
            skip=true
            break
        fi
    done
    if [ "$skip" = true ]; then
        continue
    fi

    # Skip the repo README (not a command file)
    if [ "$cmd" = "README.md" ]; then
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

# Step 4: Install skills (skills/<name>/SKILL.md → ~/.claude/skills/<name>/SKILL.md)
SKILLS_INSTALLED=0
SKILLS_UPDATED=0
SKILLS_SKIPPED=0

if [ -d "${SOURCE_DIR}/skills" ]; then
    echo ""
    echo -e "${BOLD}Installing skills...${NC}"
    for skill_dir in "${SOURCE_DIR}"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        src="${skill_dir}SKILL.md"
        dst_dir="${SKILLS_DIR}/${skill_name}"
        dst="${dst_dir}/SKILL.md"

        if [ ! -f "$src" ]; then
            echo -e "  ${YELLOW}⚠${NC}  ${skill_name} — no SKILL.md, skipping"
            ((SKILLS_SKIPPED++))
            continue
        fi

        mkdir -p "$dst_dir"

        if [ -f "$dst" ]; then
            if diff -q "$src" "$dst" > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC}  ${skill_name} — already up to date"
                ((SKILLS_SKIPPED++))
                continue
            fi

            if [ "$FORCE" = true ]; then
                cp "$src" "$dst"
                echo -e "  ${YELLOW}↻${NC}  ${skill_name} — updated"
                ((SKILLS_UPDATED++))
            else
                echo -en "  ${YELLOW}?${NC}  ${skill_name} — exists and differs. Overwrite? [y/N] "
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    cp "$src" "$dst"
                    echo -e "      ${YELLOW}↻${NC}  Updated"
                    ((SKILLS_UPDATED++))
                else
                    echo -e "      Skipped"
                    ((SKILLS_SKIPPED++))
                fi
            fi
        else
            cp "$src" "$dst"
            echo -e "  ${GREEN}+${NC}  ${skill_name} — installed"
            ((SKILLS_INSTALLED++))
        fi
    done
fi

# Step 5: Summary
echo ""
echo -e "${BOLD}Summary:${NC}"
echo -e "  ${BOLD}Commands:${NC}"
echo -e "    Installed: ${GREEN}${INSTALLED}${NC}"
echo -e "    Updated:   ${YELLOW}${UPDATED}${NC}"
echo -e "    Skipped:   ${SKIPPED}"
echo -e "  ${BOLD}Skills:${NC}"
echo -e "    Installed: ${GREEN}${SKILLS_INSTALLED}${NC}"
echo -e "    Updated:   ${YELLOW}${SKILLS_UPDATED}${NC}"
echo -e "    Skipped:   ${SKILLS_SKIPPED}"
echo ""

# Step 6: Verify
echo -e "${BOLD}Verification:${NC}"
CMD_TOTAL=0
for entry in "${COMMANDS[@]}"; do
    dst_file="${entry##*:}"
    if [ -f "${COMMANDS_DIR}/${dst_file}" ]; then
        ((CMD_TOTAL++))
    fi
done
SKILL_TOTAL=0
SKILL_EXPECTED=0
if [ -d "${SOURCE_DIR}/skills" ]; then
    for skill_dir in "${SOURCE_DIR}"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        ((SKILL_EXPECTED++))
        skill_name="$(basename "$skill_dir")"
        if [ -f "${SKILLS_DIR}/${skill_name}/SKILL.md" ]; then
            ((SKILL_TOTAL++))
        fi
    done
fi
echo -e "  ${CMD_TOTAL}/${#COMMANDS[@]} commands installed in ${COMMANDS_DIR}"
echo -e "  ${SKILL_TOTAL}/${SKILL_EXPECTED} skills installed in ${SKILLS_DIR}"
echo ""

if [ "$CMD_TOTAL" -eq "${#COMMANDS[@]}" ] && [ "$SKILL_TOTAL" -eq "$SKILL_EXPECTED" ]; then
    echo -e "${GREEN}${BOLD}All commands and skills installed successfully.${NC}"
    echo ""
    echo "Slash commands now available in Claude Code:"
    echo ""
    for entry in "${COMMANDS[@]}"; do
        dst_file="${entry##*:}"
        echo "  /${dst_file%.md}"
    done
    echo ""
    echo "Try: claude and then type /init-project my-new-app"
else
    echo -e "${YELLOW}Some items were not installed. Run with --list to check status.${NC}"
fi
