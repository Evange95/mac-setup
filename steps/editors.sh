# shellcheck shell=bash

VSCODE_SETTINGS="${VSCODE_SETTINGS:-$HOME/Library/Application Support/Code/User/settings.json}"
ZED_SETTINGS="${ZED_SETTINGS:-$HOME/.config/zed/settings.json}"

# Extensions dropped from config/vscode-extensions.txt: each one is another always-on
# process in the extension host. Built-in features or another tool cover them.
VSCODE_REPLACED_EXTENSIONS=(
    eamodio.gitlens                      # built-in blame + lazygit
    christian-kohler.npm-intellisense    # built-in import completion
    christian-kohler.path-intellisense   # built-in path completion
    ms-azuretools.vscode-docker          # superseded by vscode-containers
    tomoki1207.pdf                       # LaTeX Workshop has its own viewer
    wayou.vscode-todo-highlight          # better-comments already highlights TODOs
    ms-pyright.pyright                   # Pylance (bundled with the Python extension) includes it
)

# Editors rewrite their settings file, so it is never linked: a missing file is created,
# an existing one is only checked.
# _ensure_setting <file> <json key> <full file content if missing> <line to add by hand>
_ensure_setting() {
    local file="$1" key="$2" content="$3" line="$4"
    if [[ ! -f "$file" ]]; then
        mkdir -p "$(dirname "$file")"
        printf '%s\n' "$content" > "$file"
        log_success "Created $file"
    elif ! grep -q "\"$key\"" "$file"; then
        log_warning "$file has no \"$key\". To turn telemetry off add: $line"
    fi
}

step_editors() {
    _ensure_setting "$VSCODE_SETTINGS" "telemetry.telemetryLevel" \
        '{
    "telemetry.telemetryLevel": "off"
}' '"telemetry.telemetryLevel": "off"'
    _ensure_setting "$ZED_SETTINGS" "telemetry" \
        '{
    "telemetry": { "diagnostics": false, "metrics": false }
}' '"telemetry": { "diagnostics": false, "metrics": false }'

    local ext installed
    command -v code &>/dev/null || return 0

    installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    for ext in "${VSCODE_REPLACED_EXTENSIONS[@]}"; do
        if echo "$installed" | grep -qx "$ext"; then
            if code --uninstall-extension "$ext" &>/dev/null; then
                log_info "Removed VS Code extension $ext"
            else
                log_warning "code: failed to remove $ext"
            fi
        fi
    done

    log_info "Installing VS Code extensions..."
    while IFS= read -r ext || [[ -n "$ext" ]]; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        code --install-extension "$ext" --force &>/dev/null || log_warning "code: failed to install $ext"
    done < "$SCRIPT_DIR/config/vscode-extensions.txt"
    log_success "VS Code extensions installed"
}
