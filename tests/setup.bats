#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "every step has a steps/<name>.sh defining step_<name>" {
    source "$REPO_DIR/lib/cli.sh"
    for name in "${ALL_STEPS[@]}"; do
        [ -f "$REPO_DIR/steps/$name.sh" ] || { echo "missing steps/$name.sh"; return 1; }
        run bash -c "source '$REPO_DIR/lib/common.sh'; source '$REPO_DIR/steps/$name.sh'; declare -F step_$name"
        [ "$status" -eq 0 ] || { echo "steps/$name.sh does not define step_$name"; return 1; }
    done
}

@test "--dry-run prints the plan without running anything" {
    run "$REPO_DIR/setup.sh" --profile work --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile: work"* ]]
    [[ "$output" == *"git"* ]]
    [[ "$output" != *"security"* ]]
    [[ "$output" != *"Installing"* ]]
}

@test "--help prints usage" {
    run "$REPO_DIR/setup.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: ./setup.sh"* ]]
}

@test "invalid arguments exit non-zero" {
    run "$REPO_DIR/setup.sh" --only nope --dry-run
    [ "$status" -ne 0 ]
}
