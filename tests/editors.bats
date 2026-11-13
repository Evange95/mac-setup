#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/editors.sh"
    DIR="$(mktemp -d)"
}

teardown() { rm -rf "$DIR"; }

@test "a missing editor settings file is created with telemetry off" {
    _ensure_setting "$DIR/User/settings.json" "telemetry" '{ "telemetry": { "metrics": false } }' x > /dev/null
    grep -q '"telemetry": { "metrics": false }' "$DIR/User/settings.json"
}

@test "an existing settings file is never rewritten, only reported" {
    echo '{ "editor.fontSize": 13 }' > "$DIR/settings.json"
    run _ensure_setting "$DIR/settings.json" "telemetry" '{}' '"telemetry": { "metrics": false }'
    [[ "$output" == *'"telemetry": { "metrics": false }'* ]]
    [ "$(cat "$DIR/settings.json")" = '{ "editor.fontSize": 13 }' ]
}
