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
