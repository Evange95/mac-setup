#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# The CV repos build with XeLaTeX (awesome-cv: fontspec, fontawesome, sourcesanspro)
@test "personal profile installs a TeX distribution with XeLaTeX" {
    grep -qE '^cask "basictex"' "$REPO_DIR/Brewfile.personal"
}

# BasicTeX lacks most packages; only the missing ones are installed, so a rerun needs no sudo
@test "TeX packages missing from BasicTeX are installed, and nothing when all are there" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    SCRIPT_DIR="$REPO_DIR" PROFILE=personal
    grep -qx 'latexmk' "$REPO_DIR/config/tex/packages.txt"
    tlmgr() { printf '%s\n' latexmk fontspec; }
    sudo() { echo "sudo $*"; }
    run install_tex_packages
    [[ "$output" == *"update --self"*"sudo "*"install "*"enumitem"*"fontawesome"* ]]
    [[ "$output" != *"install latexmk"* ]]
    tlmgr() { grep -v '^#' "$REPO_DIR/config/tex/packages.txt"; }
    run install_tex_packages
    [[ "$output" == *"already installed"* && "$output" != *"sudo "* ]]
    PROFILE=work
    run install_tex_packages
    [ -z "$output" ]
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

@test "undeclared Homebrew packages are listed against both Brewfiles of the profile" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    SCRIPT_DIR="$REPO_DIR" PROFILE=personal
    brew() {
        local args="$*"
        local file="${args##*--file=}"
        grep -q '^brew "git"' "$file" && grep -q '^cask "obsidian"' "$file" && echo "Would uninstall formulae: pkhex-cli"
    }
    run undeclared_packages
    [[ "$output" == *"pkhex-cli"* ]]
}

# A disabled cask cannot be installed and fails the whole `brew bundle` run
@test "casks Homebrew disabled are not declared" {
    ! grep -qE '^cask "(openemu|melonds)"' "$REPO_DIR"/Brewfile*
}

# The 409… ids were retired by Apple: mas can neither install nor recognise them
@test "Keynote, Numbers and Pages use their current App Store ids" {
    grep -q '^mas "Keynote", id: 361285480' "$REPO_DIR/Brewfile.personal"
    grep -q '^mas "Numbers", id: 361304891' "$REPO_DIR/Brewfile.personal"
    grep -q '^mas "Pages", id: 361309726' "$REPO_DIR/Brewfile.personal"
}

@test "a failed Brewfile run lists what is still missing" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    SCRIPT_DIR="$(mktemp -d)" PROFILE=personal
    touch "$SCRIPT_DIR/Brewfile"
    brew() {
        case "$*" in
            "bundle check"*) printf '%s\n' "brew bundle can't satisfy your Brewfile's dependencies." "→ Cask zed needs to be installed." ;;
            "bundle cleanup"*) ;;
            *) return 1 ;;
        esac
    }
    run step_packages
    [ "$status" -eq 0 ]
    [[ "$output" == *"Still missing"* ]]
    [[ "$output" == *"→ Cask zed needs to be installed."* ]]
    [[ "$output" != *"can't satisfy"* ]]
    rm -rf "$SCRIPT_DIR"
}

# fontawesome asks for the font by name, which XeTeX on macOS only finds among system fonts
@test "TeX fonts loaded by name are copied into ~/Library/Fonts once" {
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/packages.sh"
    SCRIPT_DIR="$REPO_DIR" PROFILE=personal HOME="$(mktemp -d)"
    echo font > "$HOME/src.otf"
    kpsewhich() { echo "$HOME/src.otf"; }
    run install_tex_fonts
    [[ "$output" == *"Installed TeX font FontAwesome.otf"* ]]
    cmp "$HOME/src.otf" "$HOME/Library/Fonts/FontAwesome.otf"
    run install_tex_fonts
    [ -z "$output" ]
    rm -rf "$HOME"
}
