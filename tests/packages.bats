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

# The Nix path reads the Brewfiles; a formula it cannot place would fail the build on the Mac
@test "every Brewfile formula says where it comes from in the Nix path" {
    local name missing=""
    for name in $(sed -n 's/^brew "\([^"]*\)".*/\1/p' "$REPO_DIR"/Brewfile "$REPO_DIR"/Brewfile.*); do
        grep -qE "^  \"?$name\"? = " "$REPO_DIR/nix/formulae.nix" || missing="$missing $name"
    done
    [ -z "$missing" ] || { echo "missing in nix/formulae.nix:$missing"; false; }
}

# nix/brewfile.nix matches from the start of the line: an indented or multi-line entry would be skipped
@test "Brewfile entries are one per line, in the form the Nix path can read" {
    ! grep -hvE '^(#.*|)$|^(brew|cask|tap) "[^"]+"( +#.*)?$|^mas "[^"]+", id: [0-9]+( +#.*)?$' \
        "$REPO_DIR"/Brewfile "$REPO_DIR"/Brewfile.*
}

@test "replaced apps still installed are reported, each with how to remove it" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    APPS_DIR="$(mktemp -d)"
    mkdir "$APPS_DIR/1Password.app" "$APPS_DIR/Google Chrome.app" "$APPS_DIR/Insomnia.app"
    run _warn_replaced_apps
    [[ "$output" == *"brew uninstall --cask 1password"* ]]
    [[ "$output" == *"brew uninstall --cask google-chrome"* ]]
    [[ "$output" == *"brew uninstall --cask insomnia"* ]]
    rm -rf "$APPS_DIR"
}

@test "undeclared Homebrew packages are reported, and removed only with BREW_CLEANUP=uninstall" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    brew() { [[ "$*" == *--force* ]] && echo "FORCED" || echo "Would uninstall formulae: pkhex-cli"; }
    run _brew_cleanup /dev/null
    [[ "$output" == *"pkhex-cli"* && "$output" != *FORCED* ]]
    BREW_CLEANUP=uninstall run _brew_cleanup /dev/null
    [[ "$output" == *FORCED* ]]
}
