# shellcheck shell=bash

_install_extensions() {
    local cli="$1" ext
    command -v "$cli" &>/dev/null || return 0
    log_info "Installing $cli extensions..."
    while IFS= read -r ext || [[ -n "$ext" ]]; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        "$cli" --install-extension "$ext" --force &>/dev/null || log_warning "$cli: failed to install $ext"
    done < "$SCRIPT_DIR/config/vscode-extensions.txt"
    log_success "$cli extensions installed"
}

step_editors() {
    _install_extensions code
    _install_extensions cursor
}
