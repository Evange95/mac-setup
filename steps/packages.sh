# shellcheck shell=bash

APPS_DIR="${APPS_DIR:-/Applications}"

_warn_app() {
    [[ -d "$APPS_DIR/$1" ]] && log_warning "$2"
    return 0
}

# Apps replaced in the Brewfiles; brew bundle doesn't remove them (scripts/cleanup.sh does)
_warn_replaced_apps() {
    _warn_app "Ice.app" "Ice is replaced by Thaw (Ice is broken on macOS 27): brew uninstall --cask jordanbaird-ice"
    _warn_app "1Password.app" "1Password is replaced by Proton Pass. After moving your vault: brew uninstall --cask 1password"
    _warn_app "Google Chrome.app" "Chrome is no longer installed (its updater keeps running in the background): brew uninstall --cask google-chrome"
    _warn_app "Insomnia.app" "Insomnia is replaced by Bruno: brew uninstall --cask insomnia"
    _warn_app "Notion Calendar.app" "Notion Calendar is no longer installed: brew uninstall --cask notion-calendar"
    _warn_app "iTerm.app" "iTerm2 is replaced by Ghostty: brew uninstall --cask iterm2"
    _warn_app "Visual Studio Code.app" "VS Code is replaced by Zed: brew uninstall --cask visual-studio-code"
    _warn_app "Amphetamine.app" "Amphetamine is replaced by Vorssaint's keep-awake: delete it from Launchpad"
    if [[ -e "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/tailscale" && -d "$APPS_DIR/Tailscale.app" ]]; then
        log_warning "Tailscale is installed twice (app + Homebrew daemon). Keep the app: sudo brew services stop tailscale && brew uninstall tailscale"
    fi
}

# Prints the path of a temporary Brewfile with everything the profile declares
declared_brewfile() {
    local brewfile declared
    declared="$(mktemp)"
    for brewfile in "$SCRIPT_DIR/Brewfile" "$SCRIPT_DIR/Brewfile.$PROFILE"; do
        [[ -f "$brewfile" ]] && cat "$brewfile" >> "$declared"
    done
    echo "$declared"
}

# Prints what Homebrew has installed that the profile does not declare (nothing if in sync)
undeclared_packages() {
    local declared
    declared="$(declared_brewfile)"
    brew bundle cleanup --file="$declared" 2>/dev/null || true
    rm -f "$declared"
}

# Prints what a Brewfile declares that is not installed, one "→ ..." line each
missing_packages() {
    brew bundle check --no-upgrade --verbose --file="$1" 2> /dev/null | grep '^→' || true
}

# Prints the packages listed in a file that TeX Live does not have installed
missing_tex_packages() {
    local installed pkg
    installed="$(tlmgr info --only-installed --data name 2> /dev/null)"
    while read -r pkg _; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        echo "$installed" | grep -qxF "$pkg" || echo "$pkg"
    done < "$1"
}

# BasicTeX is a minimal TeX Live: add the packages from config/tex/packages.txt
install_tex_packages() {
    grep -q '^cask "basictex"' "$SCRIPT_DIR/Brewfile.$PROFILE" 2> /dev/null || return 0
    if ! command -v tlmgr > /dev/null 2>&1; then
        log_warning "tlmgr not found (BasicTeX not installed?): TeX packages skipped"
        return 0
    fi
    local missing
    missing="$(missing_tex_packages "$SCRIPT_DIR/config/tex/packages.txt" | tr '\n' ' ')"
    if [[ -z "${missing// /}" ]]; then
        log_success "TeX packages already installed"
        return 0
    fi
    log_info "Installing TeX packages (asks for sudo): $missing"
    # BasicTeX is owned by root; sudo resets PATH, hence the full path. The tlmgr in the
    # BasicTeX pkg is older than the package repository and refuses to install until updated
    local tlmgr
    tlmgr="$(command -v tlmgr)"
    try sudo "$tlmgr" update --self
    # shellcheck disable=SC2086
    try sudo "$tlmgr" install $missing
}

# TeX fonts that packages load by name (fontawesome: \newfontfamily{\FA}{FontAwesome}).
# XeTeX on macOS resolves names through the system only, not the TeX tree, and ignores
# symlinks there, so they are copied into ~/Library/Fonts
TEX_SYSTEM_FONTS="FontAwesome.otf"

install_tex_fonts() {
    grep -q '^cask "basictex"' "$SCRIPT_DIR/Brewfile.$PROFILE" 2> /dev/null || return 0
    command -v kpsewhich > /dev/null 2>&1 || return 0
    local font src dest
    for font in $TEX_SYSTEM_FONTS; do
        src="$(kpsewhich "$font" 2> /dev/null)" || true
        dest="$HOME/Library/Fonts/$font"
        if [[ -z "$src" ]]; then
            log_warning "TeX font $font not found (is its package in config/tex/packages.txt installed?)"
        elif ! cmp -s "$src" "$dest"; then
            mkdir -p "$HOME/Library/Fonts"
            cp "$src" "$dest"
            log_success "Installed TeX font $font into ~/Library/Fonts"
        fi
    done
}

step_packages() {
    local brewfile extra
    for brewfile in "$SCRIPT_DIR/Brewfile" "$SCRIPT_DIR/Brewfile.$PROFILE"; do
        [[ -f "$brewfile" ]] || continue
        log_info "Installing $(basename "$brewfile")..."
        # --no-upgrade: installing must not silently upgrade what is already there (use `update` alias)
        if ! brew bundle --no-upgrade --file="$brewfile"; then
            # One failure can stop the casks queued after it without a message of their own
            log_warning "Some items in $(basename "$brewfile") failed. Still missing:"
            missing_packages "$brewfile"
            log_warning "Install one by itself to see its error: brew install --cask <cask> (add --adopt for an app installed by hand)"
        fi
    done

    install_tex_packages
    install_tex_fonts

    extra="$(undeclared_packages)"
    if [[ -n "$extra" ]]; then
        log_warning "Installed with Homebrew but not declared in this repo:"
        echo "$extra"
        log_warning "Add them to a Brewfile, or review and remove them with ./scripts/cleanup.sh"
    fi
    _warn_replaced_apps
}
