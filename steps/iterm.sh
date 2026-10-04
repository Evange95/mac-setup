# shellcheck shell=bash

# Must match "Guid" in config/iterm2-profile.json
ITERM_PROFILE_GUID="developer-mac-setup-profile-001"

# iTerm2 keeps its prefs in memory and writes them back on quit, so they can only
# be changed while it is not running.
_iterm_set_default_profile() {
    local current
    current="$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null || true)"
    [[ "$current" == "$ITERM_PROFILE_GUID" ]] && return 0

    if pgrep -xq iTerm2; then
        log_warning "Quit iTerm2 and rerun ./setup.sh --only iterm to make Developer the default profile"
        return 0
    fi
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$ITERM_PROFILE_GUID"
    log_success "iTerm2 default profile set to Developer"
}

# The profile names the font by PostScript name; if it is missing iTerm2 silently
# falls back to a font without Nerd Font glyphs.
_iterm_check_font() {
    local font=MesloLGSNerdFont-Regular.ttf
    [[ -f "$HOME/Library/Fonts/$font" || -f "/Library/Fonts/$font" ]] && return 0
    log_warning "Meslo Nerd Font not installed: brew install --cask font-meslo-lg-nerd-font"
}

step_iterm() {
    if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
        curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
        log_success "iTerm2 shell integration installed"
    fi

    # Dynamic Profile: auto-loaded by iTerm2, doesn't overwrite the default profile.
    # Edit config/iterm2-profile.json, not the profile in iTerm2's Settings: UI changes
    # to a dynamic profile are discarded when the file is reloaded.
    copy_file "$SCRIPT_DIR/config/iterm2-profile.json" \
        "$HOME/Library/Application Support/iTerm2/DynamicProfiles/iterm2-profile.json"
    log_success "iTerm2 Developer profile deployed"

    _iterm_check_font
    _iterm_set_default_profile
}
