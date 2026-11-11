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

step_packages() {
    local brewfile extra
    for brewfile in "$SCRIPT_DIR/Brewfile" "$SCRIPT_DIR/Brewfile.$PROFILE"; do
        [[ -f "$brewfile" ]] || continue
        log_info "Installing $(basename "$brewfile")..."
        # --no-upgrade: installing must not silently upgrade what is already there (use `update` alias)
        brew bundle --no-upgrade --file="$brewfile" || log_warning "Some items in $(basename "$brewfile") failed. For an app installed by hand, let Homebrew take it over: brew install --cask --adopt <cask>"
    done

    extra="$(undeclared_packages)"
    if [[ -n "$extra" ]]; then
        log_warning "Installed with Homebrew but not declared in this repo:"
        echo "$extra"
        log_warning "Add them to a Brewfile, or review and remove them with ./scripts/cleanup.sh"
    fi
    _warn_replaced_apps
}
