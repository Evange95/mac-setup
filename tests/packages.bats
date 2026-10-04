#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# The CV repos build with XeLaTeX (awesome-cv: fontspec, fontawesome, sourcesanspro)
@test "personal profile installs a TeX distribution with XeLaTeX" {
    grep -qE '^cask "mactex-no-gui"' "$REPO_DIR/Brewfile.personal"
}

@test "TeX binaries are on the static PATH for non-login shells" {
    grep -q '/Library/TeX/texbin' "$REPO_DIR/dotfiles/zsh/zshenv"
}

@test "casks from third-party taps declare the tap" {
    grep -q '^tap "vishvavariya/notchy"' "$REPO_DIR/Brewfile.personal"
    grep -q '^cask "notchy"' "$REPO_DIR/Brewfile.personal"
}
