#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/editors.sh"
    DIR="$(mktemp -d)"
}

teardown() { rm -rf "$DIR"; }

@test "a missing editor settings file is created with telemetry off" {
    _ensure_setting "$DIR/User/settings.json" "telemetry.telemetryLevel" '{ "telemetry.telemetryLevel": "off" }' x > /dev/null
    grep -q '"telemetry.telemetryLevel": "off"' "$DIR/User/settings.json"
}

@test "an existing settings file is never rewritten, only reported" {
    echo '{ "editor.fontSize": 13 }' > "$DIR/settings.json"
    run _ensure_setting "$DIR/settings.json" "telemetry.telemetryLevel" '{}' '"telemetry.telemetryLevel": "off"'
    [[ "$output" == *'"telemetry.telemetryLevel": "off"'* ]]
    [ "$(cat "$DIR/settings.json")" = '{ "editor.fontSize": 13 }' ]
}

@test "no extension is both installed and removed" {
    local ext
    for ext in "${VSCODE_REPLACED_EXTENSIONS[@]}"; do
        ! grep -qix "$ext" "$REPO_DIR/config/vscode-extensions.txt"
    done
}
