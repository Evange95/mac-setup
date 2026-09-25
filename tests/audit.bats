#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/lib/probes.sh"
    source "$REPO_DIR/steps/audit.sh"
    AUDIT_FAILED=0
}

@test "audit_check reports a passing check" {
    run audit_check "Firewall" "enable it" true
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓"*"Firewall"* ]]
    [[ "$output" != *"enable it"* ]]
}

@test "audit_check reports a failing check with its hint and does not abort" {
    run audit_check "Firewall" "enable it" false
    [ "$status" -eq 0 ]
    [[ "$output" == *"✗"*"Firewall"*"enable it"* ]]
}

@test "audit_check counts failures" {
    audit_check "a" "" true > /dev/null
    audit_check "b" "" false > /dev/null
    audit_check "c" "" false > /dev/null
    [ "$AUDIT_FAILED" -eq 2 ]
}

@test "screen lock probe accepts immediate and short delays only" {
    sysadminctl() { echo "sysadminctl[1:2] screenLock delay is immediate" >&2; }
    run screen_lock_ok
    [ "$status" -eq 0 ]

    sysadminctl() { echo "sysadminctl[1:2] screenLock delay is 5 seconds" >&2; }
    run screen_lock_ok
    [ "$status" -eq 0 ]

    sysadminctl() { echo "sysadminctl[1:2] screenLock delay is 300 seconds" >&2; }
    run screen_lock_ok
    [ "$status" -ne 0 ]

    sysadminctl() { echo "sysadminctl[1:2] screenLock is off" >&2; }
    run screen_lock_ok
    [ "$status" -ne 0 ]
}
