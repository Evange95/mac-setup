#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/security.sh"
    STATE="$(mktemp)"
}

teardown() { rm -f "$STATE"; }

probe() { [ -s "$STATE" ]; }
apply() { echo on > "$STATE"; }
refuse() { return 1; }

@test "_ensure skips the command when the probe already passes" {
    echo on > "$STATE"
    run _ensure probe "Thing" "hint" false
    [ "$status" -eq 0 ]
    [[ "$output" == *"Thing: already set"* ]]
}

@test "_ensure applies and confirms with the probe" {
    run _ensure probe "Thing" "hint" apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"Thing: applied"* ]]
}

@test "_ensure warns with the hint when the change does not stick, without aborting" {
    run _ensure probe "Thing" "do it by hand" refuse
    [ "$status" -eq 0 ]
    [[ "$output" == *"Thing: could not be applied"*"do it by hand"* ]]
}
