# shellcheck shell=bash

step_iterm() {
    if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
        curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
        log_success "iTerm2 shell integration installed"
    fi

    # Dynamic Profile: auto-loaded by iTerm2, doesn't overwrite the default profile
    copy_file "$SCRIPT_DIR/config/iterm2-profile.json" \
        "$HOME/Library/Application Support/iTerm2/DynamicProfiles/iterm2-profile.json"
    log_success "iTerm2 Developer profile deployed"
}
