#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/docker.sh"
    CALLS="$(mktemp)"
    EXISTS=1
    docker() {
        [[ "$*" == "context inspect homelab" ]] && return "$EXISTS"
        echo "$*" >> "$CALLS"
    }
}

teardown() { rm -f "$CALLS"; }

@test "no remote Docker context unless HOMELAB_DOCKER_HOST is set" {
    run _docker_remote_context
    [ "$status" -eq 0 ]
    [ ! -s "$CALLS" ]
}

@test "creates the homelab context for the configured host" {
    HOMELAB_DOCKER_HOST="ssh://me@box"
    run _docker_remote_context
    grep -qx "context create homelab --docker host=ssh://me@box" "$CALLS"
}

@test "an existing homelab context follows a changed host" {
    HOMELAB_DOCKER_HOST="ssh://me@newbox" EXISTS=0
    run _docker_remote_context
    grep -qx "context update homelab --docker host=ssh://me@newbox" "$CALLS"
}
