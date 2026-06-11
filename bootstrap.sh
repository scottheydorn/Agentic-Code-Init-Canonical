#!/usr/bin/env bash
# =============================================================================
# Agentic Code Init — Bootstrap Script
# =============================================================================
# Fetches the latest AI coding instructions from the canonical GitHub repository
# and installs/symlinks them for all detected AI coding agents.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/scottheydorn/Agentic-Code-Init-Canonical/main/bootstrap.sh | bash
#   # or
#   ./bootstrap.sh [--agent <name>] [--force] [--dry-run] [--no-mcp]
#
# Options:
#   --agent <name>   Install for a specific agent only (copilot|claude|cursor|windsurf|cline|aider)
#   --force          Overwrite existing files without prompting
#   --dry-run        Show what would be done without making changes
#   --no-mcp         Skip MCP configuration template installation
#   --uninstall      Remove all installed files and symlinks
# =============================================================================

set -euo pipefail

# --- Configuration ---
REPO_URL="https://raw.githubusercontent.com/scottheydorn/Agentic-Code-Init-Canonical/main"
CANONICAL_FILE="$HOME/.ai-instructions.md"
MCP_TEMPLATE_URL="${REPO_URL}/mcp-servers/mcp-config.template.json"
VERSION_URL="${REPO_URL}/version.json"
SCRIPT_VERSION="1.0.0"

# --- Colors (disabled if not a terminal) ---
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

# --- Agent Registry ---
# Format: AGENT_NAME|GLOBAL_PATH|PER_PROJECT_FILE|DETECTION_METHOD
declare -a AGENTS=(
  "copilot|${HOME}/.github/copilot-instructions.md|.github/copilot-instructions.md|command:gh"
  "claude|${HOME}/.claude/CLAUDE.md|CLAUDE.md|command:claude"
  "cursor|${HOME}/.cursor/rules/ai-instructions.mdc|.cursorrules|dir:${HOME}/.cursor"
  "windsurf|${HOME}/.windsurf/rules/ai-instructions.md|.windsurfrules|dir:${HOME}/.windsurf"
  "cline|${HOME}/.cline/rules/ai-instructions.md|.clinerules|dir:${HOME}/.cline"
  "aider|${HOME}/.aider.conf.yml|.aider.conf.yml|command:aider"
  "continue|${HOME}/.continue/instructions.md|.continue/instructions.md|dir:${HOME}/.continue"
)

# --- Argument Parsing ---
TARGET_AGENT=""
FORCE=false
DRY_RUN=false
SKIP_MCP=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) TARGET_AGENT="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --no-mcp) SKIP_MCP=true; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --help|-h) 
      echo "Usage: bootstrap.sh [--agent <name>] [--force] [--dry-run] [--no-mcp] [--uninstall]"
      echo ""
      echo "Agents: copilot, claude, cursor, windsurf, cline, aider, continue"
      exit 0 ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
  esac
done

# --- Helper Functions ---
log_info()  { echo -e "${BLUE}ℹ${NC}  $1"; }
log_ok()    { echo -e "${GREEN}✓${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error() { echo -e "${RED}✗${NC}  $1"; }
log_action(){ echo -e "${BOLD}→${NC}  $1"; }

detect_agent() {
  local detection="$1"
  local method="${detection%%:*}"
  local target="${detection#*:}"
  
  case "$method" in
    command) command -v "$target" &>/dev/null ;;
    dir) [[ -d "$target" ]] ;;
    *) return 1 ;;
  esac
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log_action "[dry-run] Would create directory: $dir"
    else
      mkdir -p "$dir"
    fi
  fi
}

create_symlink() {
  local source="$1"
  local target="$2"
  local agent_name="$3"
  
  # Ensure parent directory exists
  ensure_dir "$(dirname "$target")"
  
  if [[ -L "$target" ]]; then
    local current_link
    current_link=$(readlink "$target" 2>/dev/null || true)
    if [[ "$current_link" == "$source" ]]; then
      log_ok "${agent_name}: Already linked → $(basename "$target")"
      return 0
    fi
    if [[ "$FORCE" == true ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        log_action "[dry-run] Would replace symlink: $target → $source"
      else
        rm -f "$target"
        ln -sf "$source" "$target"
        log_ok "${agent_name}: Relinked → $target"
      fi
    else
      log_warn "${agent_name}: Existing symlink points elsewhere (use --force to override)"
      log_info "  Current: $current_link"
      log_info "  Desired: $source"
    fi
  elif [[ -f "$target" ]]; then
    if [[ "$FORCE" == true ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        log_action "[dry-run] Would backup and replace: $target"
      else
        mv "$target" "${target}.bak.$(date +%s)"
        ln -sf "$source" "$target"
        log_ok "${agent_name}: Backed up existing + created symlink"
      fi
    else
      log_warn "${agent_name}: File exists at $target (use --force to override, original will be backed up)"
    fi
  else
    if [[ "$DRY_RUN" == true ]]; then
      log_action "[dry-run] Would create symlink: $target → $source"
    else
      ln -sf "$source" "$target"
      log_ok "${agent_name}: Installed → $(basename "$target")"
    fi
  fi
}

remove_symlink() {
  local target="$1"
  local agent_name="$2"
  
  if [[ -L "$target" ]]; then
    local current_link
    current_link=$(readlink "$target" 2>/dev/null || true)
    if [[ "$current_link" == "$CANONICAL_FILE" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        log_action "[dry-run] Would remove symlink: $target"
      else
        rm -f "$target"
        log_ok "${agent_name}: Removed symlink at $target"
      fi
    else
      log_warn "${agent_name}: Symlink at $target points to something else, skipping"
    fi
  elif [[ -f "$target" ]]; then
    log_warn "${agent_name}: $target is a regular file (not managed by us), skipping"
  fi
}

# --- Cursor-specific handler (uses .mdc frontmatter format) ---
install_cursor() {
  local target="${HOME}/.cursor/rules/ai-instructions.mdc"
  ensure_dir "${HOME}/.cursor/rules"
  
  if [[ -f "$target" && "$FORCE" != true ]]; then
    log_warn "cursor: File exists at $target (use --force to override)"
    return 0
  fi
  
  if [[ "$DRY_RUN" == true ]]; then
    log_action "[dry-run] Would create Cursor rule file: $target"
    return 0
  fi
  
  # Cursor uses .mdc format with YAML frontmatter
  {
    echo "---"
    echo "description: Global AI coding standards and patterns"
    echo "globs:"
    echo "alwaysApply: true"
    echo "---"
    echo ""
    cat "$CANONICAL_FILE"
  } > "$target"
  
  log_ok "cursor: Installed → .cursor/rules/ai-instructions.mdc"
}

# --- Aider-specific handler (uses YAML conventions file) ---
install_aider() {
  local target="${HOME}/.aider.conf.yml"
  
  if [[ -f "$target" && "$FORCE" != true ]]; then
    log_warn "aider: File exists at $target (use --force to override)"
    return 0
  fi
  
  if [[ "$DRY_RUN" == true ]]; then
    log_action "[dry-run] Would create Aider conventions file reference"
    return 0
  fi
  
  # Aider uses a YAML config that can reference a conventions file
  cat > "$target" << AIDER_EOF
# Aider configuration — references canonical AI instructions
# See: https://aider.chat/docs/config/aider_conf.html
read: ${CANONICAL_FILE}
AIDER_EOF
  
  log_ok "aider: Installed → .aider.conf.yml (references canonical file)"
}

# --- Main Logic ---
main() {
  echo ""
  echo -e "${BOLD}�� Agentic Code Init — Bootstrap v${SCRIPT_VERSION}${NC}"
  echo -e "   Repo: github.com/scottheydorn/Agentic-Code-Init-Canonical"
  echo ""
  
  # --- Uninstall mode ---
  if [[ "$UNINSTALL" == true ]]; then
    echo -e "${BOLD}Removing installed files...${NC}"
    echo ""
    for entry in "${AGENTS[@]}"; do
      IFS='|' read -r name path _ _ <<< "$entry"
      remove_symlink "$path" "$name"
    done
    if [[ -f "$CANONICAL_FILE" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        log_action "[dry-run] Would remove: $CANONICAL_FILE"
      else
        rm -f "$CANONICAL_FILE"
        log_ok "Removed canonical file: $CANONICAL_FILE"
      fi
    fi
    echo ""
    log_ok "Uninstall complete."
    return 0
  fi
  
  # --- Step 1: Fetch latest instructions ---
  log_action "Fetching latest instructions from GitHub..."
  
  if [[ "$DRY_RUN" == true ]]; then
    log_action "[dry-run] Would download ${REPO_URL}/ai-instructions.md → $CANONICAL_FILE"
  else
    local temp_file
    temp_file=$(mktemp)
    if curl -fsSL "${REPO_URL}/ai-instructions.md" -o "$temp_file" 2>/dev/null; then
      # Check if content actually changed
      if [[ -f "$CANONICAL_FILE" ]] && diff -q "$temp_file" "$CANONICAL_FILE" &>/dev/null; then
        rm "$temp_file"
        log_ok "Instructions already up to date"
      else
        mv "$temp_file" "$CANONICAL_FILE"
        chmod 644 "$CANONICAL_FILE"
        log_ok "Instructions updated: $CANONICAL_FILE"
      fi
    else
      rm -f "$temp_file"
      log_error "Failed to fetch instructions from GitHub"
      # If canonical file exists locally, continue with it
      if [[ -f "$CANONICAL_FILE" ]]; then
        log_warn "Using existing local copy"
      else
        log_error "No local copy available. Cannot continue."
        exit 1
      fi
    fi
  fi
  
  echo ""
  
  # --- Step 2: Detect and configure agents ---
  log_action "Detecting installed AI coding agents..."
  echo ""
  
  local installed_count=0
  local skipped_count=0
  
  for entry in "${AGENTS[@]}"; do
    IFS='|' read -r name path project_file detection <<< "$entry"
    
    # Skip if targeting a specific agent
    if [[ -n "$TARGET_AGENT" && "$name" != "$TARGET_AGENT" ]]; then
      continue
    fi
    
    # Check if agent is installed/detected
    if detect_agent "$detection"; then
      installed_count=$((installed_count + 1))
      
      # Use special handlers for agents that need non-symlink formats
      case "$name" in
        cursor)
          install_cursor
          ;;
        aider)
          install_aider
          ;;
        *)
          # Standard symlink approach
          create_symlink "$CANONICAL_FILE" "$path" "$name"
          ;;
      esac
    else
      skipped_count=$((skipped_count + 1))
      if [[ -n "$TARGET_AGENT" ]]; then
        log_error "${name}: Not detected on this system"
      fi
    fi
  done
  
  echo ""
  
  # --- Step 3: MCP config template ---
  if [[ "$SKIP_MCP" != true ]]; then
    log_action "MCP configuration..."
    
    # Determine MCP config location based on primary agent
    local mcp_targets=()
    if detect_agent "command:gh"; then
      mcp_targets+=("${HOME}/.copilot/mcp-config.json")
    fi
    
    for mcp_target in "${mcp_targets[@]}"; do
      if [[ -f "$mcp_target" ]]; then
        log_ok "MCP config exists: $mcp_target"
        log_info "  MCP credentials are managed per-agent at invocation time."
        log_info "  Template available at: ${REPO_URL}/mcp-servers/mcp-config.template.json"
      else
        if [[ "$DRY_RUN" == true ]]; then
          log_action "[dry-run] Would install MCP template → $mcp_target"
        else
          ensure_dir "$(dirname "$mcp_target")"
          log_info "No MCP config found. Install template? [y/N] "
          if [[ "$FORCE" == true ]]; then
            curl -fsSL "$MCP_TEMPLATE_URL" -o "$mcp_target" 2>/dev/null && \
              log_ok "MCP template installed: $mcp_target" || \
              log_error "Failed to download MCP template"
            log_warn "  ⚠ Replace <PLACEHOLDER> values with your credentials before use"
          else
            log_info "  Run with --force to auto-install, or manually:"
            log_info "  curl -fsSL ${MCP_TEMPLATE_URL} -o $mcp_target"
          fi
        fi
      fi
    done
    
    echo ""
    log_info "MCP variables will be prompted by agents when capabilities are first invoked."
    log_info "No secrets are stored in the instructions file."
  fi
  
  echo ""
  
  # --- Summary ---
  echo -e "${BOLD}─────────────────────────────────────────${NC}"
  echo -e "${BOLD}Summary${NC}"
  echo -e "  Agents configured: ${GREEN}${installed_count}${NC}"
  echo -e "  Agents not found:  ${YELLOW}${skipped_count}${NC}"
  echo -e "  Canonical file:    ${CANONICAL_FILE}"
  echo -e "  Source repo:       github.com/scottheydorn/Agentic-Code-Init-Canonical"
  echo ""
  echo -e "${BOLD}Next steps:${NC}"
  echo -e "  • MCP credentials are prompted by agents on first use of each capability"
  echo -e "  • Override per-project by adding agent-specific files to project root"
  echo -e "  • Re-run this script anytime to pull latest updates from repo"
  echo ""
  
  # --- Auto-update hint ---
  echo -e "${BOLD}Auto-update (add to shell profile):${NC}"
  echo '  alias ai-sync="curl -fsSL https://raw.githubusercontent.com/scottheydorn/Agentic-Code-Init-Canonical/main/bootstrap.sh | bash"'
  echo ""
}

main "$@"
