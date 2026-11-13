# shellcheck shell=bash

ZED_SETTINGS="${ZED_SETTINGS:-$HOME/.config/zed/settings.json}"

# Zed rewrites its settings file, so it is never linked: a missing file is created,
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
    _ensure_setting "$ZED_SETTINGS" "telemetry" \
        '{
    "telemetry": { "diagnostics": false, "metrics": false }
}' '"telemetry": { "diagnostics": false, "metrics": false }'
}
