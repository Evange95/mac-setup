#!/bin/bash

#===============================================================================
# macOS Developer Setup
# Usage:  ./setup.sh [--profile personal|work] [--only a,b] [--skip a,b] [--dry-run]
# Config: cp setup.conf.example setup.conf and fill in your details
# Each step lives in steps/<name>.sh; order and profiles are defined in lib/cli.sh.
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/cli.sh
source "$SCRIPT_DIR/lib/cli.sh"

# setup.conf may set PROFILE; --profile overrides it
if [[ -f "$SCRIPT_DIR/setup.conf" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/setup.conf"
fi

parse_args "$@" || exit 1
STEPS="$(resolve_steps)" || exit 1

echo ""
echo "======================================================================="
echo "              macOS Developer Environment Setup"
echo "======================================================================="
echo "Profile: $PROFILE"
echo "Steps:   $(echo "$STEPS" | tr '\n' ' ')"
echo ""

if [[ "$DRY_RUN" == "1" ]]; then
    exit 0
fi

if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is intended for macOS only."
    exit 1
fi

if [[ -z "$GIT_USER_NAME" || -z "$GIT_USER_EMAIL" ]]; then
    log_info "No git identity in setup.conf. Please enter your details:"
    read -rp "  Git name: " GIT_USER_NAME
    read -rp "  Git email: " GIT_USER_EMAIL
    [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]] || { log_error "Git name and email are required."; exit 1; }
fi

# Keep a full log of every run
mkdir -p "$SCRIPT_DIR/logs"
LOG_FILE="$SCRIPT_DIR/logs/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
log_info "Logging to $LOG_FILE"

load_session_env

for step in $STEPS; do
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/steps/$step.sh"
    echo ""
    log_info "=== $step ==="
    "step_$step"
done

echo ""
echo "======================================================================="
echo "                       Setup Complete!"
echo "======================================================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Machine-specific shell settings go in ~/.zshrc.local (not versioned)"
echo "  3. Add your SSH key to GitHub (signing + auth): https://github.com/settings/keys"
echo "  4. Authenticate GitHub CLI: gh auth login"
echo "  5. Set iTerm2 profile to 'Developer' in Settings > Profiles"
echo ""

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    pbcopy < "$HOME/.ssh/id_ed25519.pub"
    log_success "SSH public key copied to clipboard"
fi
