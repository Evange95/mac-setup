# shellcheck shell=bash

GHOSTTY_APP_SUPPORT="${GHOSTTY_APP_SUPPORT:-$HOME/Library/Application Support/com.mitchellh.ghostty}"

# Ghostty also reads its Application Support folder, after ~/.config, so a setting there
# wins over the managed file. On first launch it writes a template there with comments only.
_ghostty_app_support_config() {
    local file
    for file in "$GHOSTTY_APP_SUPPORT/config.ghostty" "$GHOSTTY_APP_SUPPORT/config"; do
        [[ -f "$file" ]] || continue
        if grep -qE '^[[:space:]]*[^#[:space:]]' "$file"; then
            log_warning "$file overrides the managed config: move its settings to dotfiles/ghostty/config.ghostty, then delete it"
        else
            rm "$file"
            log_info "Removed Ghostty's empty config template ($file)"
        fi
    done
}

# The config names the font by family; if it is missing Ghostty silently uses its built-in one
_ghostty_check_font() {
    local font=MesloLGSNerdFontMono-Regular.ttf
    [[ -f "$HOME/Library/Fonts/$font" || -f "/Library/Fonts/$font" ]] && return 0
    log_warning "Meslo Nerd Font not installed: brew install --cask font-meslo-lg-nerd-font"
}

# Files this repo used to install for iTerm2 (replaced by Ghostty)
_remove_iterm_files() {
    local file
    for file in "$HOME/.iterm2_shell_integration.zsh" \
        "$HOME/Library/Application Support/iTerm2/DynamicProfiles/iterm2-profile.json"; do
        [[ -e "$file" ]] || continue
        rm "$file"
        log_info "Removed $file (iTerm2 is replaced by Ghostty)"
    done
}

step_ghostty() {
    # Ghostty never writes its config, so it is linked. Shell integration needs no
    # setup: Ghostty injects it into zsh by itself.
    link_file "$SCRIPT_DIR/dotfiles/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
    log_success "Ghostty config linked"

    _ghostty_app_support_config
    _ghostty_check_font
    _remove_iterm_files
}
