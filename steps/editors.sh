# shellcheck shell=bash

step_editors() {
    local ext
    command -v code &>/dev/null || return 0
    log_info "Installing VS Code extensions..."
    while IFS= read -r ext || [[ -n "$ext" ]]; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        code --install-extension "$ext" --force &>/dev/null || log_warning "code: failed to install $ext"
    done < "$SCRIPT_DIR/config/vscode-extensions.txt"
    log_success "VS Code extensions installed"
}
