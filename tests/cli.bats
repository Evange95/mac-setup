#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    # shellcheck source=../lib/cli.sh
    source "$REPO_DIR/lib/cli.sh"
}

@test "defaults to the personal profile with every step" {
    parse_args
    [ "$PROFILE" = "personal" ]
    run resolve_steps
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '%s\n' "${ALL_STEPS[@]}")" ]
}

@test "profile falls back to setup.conf value when no flag is given" {
    PROFILE="work"
    parse_args
    [ "$PROFILE" = "work" ]
}

@test "--profile flag overrides setup.conf value" {
    PROFILE="work"
    parse_args --profile personal
    [ "$PROFILE" = "personal" ]
}

@test "work profile skips security by default" {
    parse_args --profile work
    run resolve_steps
    [ "$status" -eq 0 ]
    [[ "$output" != *security* ]]
    [[ "$output" == *git* ]]
}

@test "--only runs just the listed steps, in canonical order" {
    parse_args --only git,shell
    run resolve_steps
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf 'shell\ngit')" ]
}

@test "--only can force a step the profile would skip" {
    parse_args --profile work --only security
    run resolve_steps
    [ "$output" = "security" ]
}

@test "--skip removes steps" {
    parse_args --skip docker,macos
    run resolve_steps
    [[ "$output" != *docker* ]]
    [[ "$output" != *macos* ]]
    [[ "$output" == *verify* ]]
}

@test "--dry-run sets DRY_RUN" {
    parse_args --dry-run
    [ "$DRY_RUN" = "1" ]
}

@test "unknown step name is rejected" {
    parse_args --only nope
    run resolve_steps
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown step: nope"* ]]
}

@test "unknown profile is rejected" {
    run parse_args --profile gaming
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown profile: gaming"* ]]
}

@test "unknown flag is rejected" {
    run parse_args --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option: --bogus"* ]]
}
