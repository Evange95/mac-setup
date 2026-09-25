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
