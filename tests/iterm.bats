#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PROFILE_JSON="$REPO_DIR/config/iterm2-profile.json"
}

# iTerm2 resolves fonts by PostScript name; font-meslo-lg-nerd-font ships
# "MesloLGSNF-Regular". An unknown name silently falls back to a font without
# Nerd Font glyphs, so eza/starship icons render as "?".
@test "iTerm2 profile uses the Meslo Nerd Font PostScript name" {
    run grep -E '"(Normal|Non Ascii) Font": "MesloLGSNF-Regular [0-9]+"' "$PROFILE_JSON"
    [ "${#lines[@]}" -eq 2 ]
}

# A parent referenced by name must exist or iTerm2 warns on every launch, and
# the default profile isn't reliably named "Default". Without the key iTerm2
# inherits from whichever profile is the default.
@test "iTerm2 profile does not reference a parent profile by name" {
    run grep '"Dynamic Profile Parent Name"' "$PROFILE_JSON"
    [ "$status" -ne 0 ]
}

# Stubs for the macOS commands step_iterm drives; calls are recorded in $CALLS.
_load_step() {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/iterm.sh"
    HOME="$(mktemp -d)"
    CALLS="$HOME/calls"
    ITERM_DEFAULT_GUID=""
    ITERM_RUNNING=1
    defaults() {
        echo "defaults $*" >> "$CALLS"
        if [[ "$1" == read ]]; then
            [[ -n "$ITERM_DEFAULT_GUID" ]] && echo "$ITERM_DEFAULT_GUID" && return 0
            return 1
        fi
    }
    pgrep() { return "$ITERM_RUNNING"; }
    touch "$CALLS"
}

@test "the profile GUID set as default matches the dynamic profile" {
    source "$REPO_DIR/steps/iterm.sh"
    grep -q "\"Guid\": \"$ITERM_PROFILE_GUID\"" "$PROFILE_JSON"
}

@test "makes the Developer profile the default when iTerm2 is not running" {
    _load_step
    run _iterm_set_default_profile
    [ "$status" -eq 0 ]
    grep -q "defaults write com.googlecode.iterm2 Default Bookmark Guid -string $ITERM_PROFILE_GUID" "$CALLS"
    rm -rf "$HOME"
}

@test "does not touch iTerm2 prefs while it is running (it would overwrite them on quit)" {
    _load_step
    ITERM_RUNNING=0
    run _iterm_set_default_profile
    [ "$status" -eq 0 ]
    [[ "$output" == *"Quit iTerm2"* ]]
    ! grep -q "defaults write" "$CALLS"
    rm -rf "$HOME"
}

@test "leaves the default profile alone when it is already the Developer one" {
    _load_step
    ITERM_DEFAULT_GUID="$ITERM_PROFILE_GUID"
    run _iterm_set_default_profile
    [ "$status" -eq 0 ]
    ! grep -q "defaults write" "$CALLS"
    rm -rf "$HOME"
}

@test "warns when the Nerd Font the profile uses is not installed" {
    _load_step
    run _iterm_check_font
    [[ "$output" == *"font-meslo-lg-nerd-font"* ]]
    mkdir -p "$HOME/Library/Fonts" && touch "$HOME/Library/Fonts/MesloLGSNerdFont-Regular.ttf"
    run _iterm_check_font
    [ -z "$output" ]
    rm -rf "$HOME"
}
