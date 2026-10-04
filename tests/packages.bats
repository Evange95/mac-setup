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

# macOS 27 draws the menu bar as one window; Ice broke and is unmaintained, Thaw is its fork
@test "menu bar manager is Thaw, not Ice" {
    grep -q '^cask "thaw"' "$REPO_DIR/Brewfile"
    ! grep -q 'jordanbaird-ice' "$REPO_DIR/Brewfile"
}

@test "packages step warns when the replaced Ice app is still installed" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    APPS_DIR="$(mktemp -d)"
    run _warn_replaced_apps
    [ -z "$output" ]
    mkdir "$APPS_DIR/Ice.app"
    run _warn_replaced_apps
    [[ "$output" == *"brew uninstall --cask jordanbaird-ice"* ]]
    rm -rf "$APPS_DIR"
}

# The tldr formula is deprecated as unmaintained; tlrc is the official client (same `tldr` command)
@test "tldr pages come from tlrc" {
    grep -q '^brew "tlrc"' "$REPO_DIR/Brewfile"
    ! grep -q '^brew "tldr"' "$REPO_DIR/Brewfile"
}

@test "Slack and Zoom are installed only on the work profile" {
    ! grep -qE '^cask "(slack|zoom)"' "$REPO_DIR/Brewfile" "$REPO_DIR/Brewfile.personal"
    grep -q '^cask "slack"' "$REPO_DIR/Brewfile.work"
    grep -q '^cask "zoom"' "$REPO_DIR/Brewfile.work"
}

@test "Cursor is not installed or configured" {
    ! grep -rqi 'cursor' "$REPO_DIR/Brewfile" "$REPO_DIR/steps/editors.sh" "$REPO_DIR/steps/verify.sh"
}
