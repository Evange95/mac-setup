#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/ghostty.sh"
    HOME="$(mktemp -d)"
    GHOSTTY_APP_SUPPORT="$HOME/AppSupport"
    SCRIPT_DIR="$REPO_DIR"
    mkdir -p "$GHOSTTY_APP_SUPPORT"
}

teardown() { rm -rf "$HOME"; }

@test "the config is linked where Ghostty reads it" {
    run step_ghostty
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.config/ghostty/config.ghostty")" = "$REPO_DIR/dotfiles/ghostty/config.ghostty" ]
}

# The right Option key must keep typing @ # [ ] on non-US layouts
@test "only the left Option key acts as Alt" {
    grep -qx 'macos-option-as-alt = left' "$REPO_DIR/dotfiles/ghostty/config.ghostty"
}

# Ghostty reads Application Support after ~/.config: a file there silently wins
@test "the comment-only template Ghostty creates on first launch is removed" {
    printf '# template\n\n# font-family = Iosevka\n' > "$GHOSTTY_APP_SUPPORT/config.ghostty"
    run _ghostty_app_support_config
    [ ! -e "$GHOSTTY_APP_SUPPORT/config.ghostty" ]
}

@test "a config with real settings in Application Support is kept and reported" {
    printf '# mine\nfont-size = 15\n' > "$GHOSTTY_APP_SUPPORT/config.ghostty"
    run _ghostty_app_support_config
    [ -e "$GHOSTTY_APP_SUPPORT/config.ghostty" ]
    [[ "$output" == *"overrides the managed config"* ]]
}

@test "warns when the Nerd Font the config uses is not installed" {
    run _ghostty_check_font
    [[ "$output" == *"font-meslo-lg-nerd-font"* ]]
    mkdir -p "$HOME/Library/Fonts" && touch "$HOME/Library/Fonts/MesloLGSNerdFontMono-Regular.ttf"
    run _ghostty_check_font
    [ -z "$output" ]
}

@test "files installed for iTerm2 are removed" {
    mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    touch "$HOME/.iterm2_shell_integration.zsh" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/iterm2-profile.json"
    run _remove_iterm_files
    [ ! -e "$HOME/.iterm2_shell_integration.zsh" ]
    [ ! -e "$HOME/Library/Application Support/iTerm2/DynamicProfiles/iterm2-profile.json" ]
}

@test "iTerm2 and VS Code are no longer installed or configured" {
    ! grep -qE '^cask "(iterm2|visual-studio-code)"' "$REPO_DIR"/Brewfile*
    grep -q '^cask "ghostty"' "$REPO_DIR/Brewfile"
    grep -q '^cask "zed"' "$REPO_DIR/Brewfile"
    ! grep -q 'code --wait' "$REPO_DIR/dotfiles/zsh/zshrc" "$REPO_DIR/dotfiles/git/config"
}
