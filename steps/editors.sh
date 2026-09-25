# shellcheck shell=bash

# Microsoft-licensed extensions that are not available in Cursor's marketplace
CURSOR_UNAVAILABLE=" ms-python.vscode-pylance github.copilot-chat "

_install_extensions() {
    local cli="$1" ext
    command -v "$cli" &>/dev/null || return 0
    log_info "Installing $cli extensions..."
    while IFS= read -r ext || [[ -n "$ext" ]]; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        [[ "$cli" == "cursor" && "$CURSOR_UNAVAILABLE" == *" $ext "* ]] && continue
        "$cli" --install-extension "$ext" --force &>/dev/null || log_warning "$cli: failed to install $ext"
    done < "$SCRIPT_DIR/config/vscode-extensions.txt"
    log_success "$cli extensions installed"
}

step_editors() {
    _install_extensions code
    _install_extensions cursor
}
