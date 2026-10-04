# shellcheck shell=bash

APPS_DIR="${APPS_DIR:-/Applications}"

# Apps replaced in the Brewfiles; brew bundle doesn't remove them
_warn_replaced_apps() {
    if [[ -d "$APPS_DIR/Ice.app" ]]; then
        log_warning "Ice is replaced by Thaw (Ice is broken on macOS 27): brew uninstall --cask jordanbaird-ice"
    fi
}

step_packages() {
    local brewfile
    for brewfile in "$SCRIPT_DIR/Brewfile" "$SCRIPT_DIR/Brewfile.$PROFILE"; do
        [[ -f "$brewfile" ]] || continue
        log_info "Installing $(basename "$brewfile")..."
        # --no-upgrade: installing must not silently upgrade what is already there (use `update` alias)
        brew bundle --no-upgrade --file="$brewfile" || log_warning "Some items in $(basename "$brewfile") failed"
    done
    _warn_replaced_apps
}
