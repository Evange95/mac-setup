# shellcheck shell=bash

step_packages() {
    local brewfile
    for brewfile in "$SCRIPT_DIR/Brewfile" "$SCRIPT_DIR/Brewfile.$PROFILE"; do
        [[ -f "$brewfile" ]] || continue
        log_info "Installing $(basename "$brewfile")..."
        # --no-upgrade: installing must not silently upgrade what is already there (use `update` alias)
        brew bundle --no-upgrade --file="$brewfile" || log_warning "Some items in $(basename "$brewfile") failed"
    done
}
