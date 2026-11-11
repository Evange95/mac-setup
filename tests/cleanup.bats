#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/scripts/cleanup.sh"
    HOME="$(mktemp -d)"
    APPS_DIR="$HOME/Apps"
    mkdir -p "$APPS_DIR"
    PROFILE=personal
    CALLS="$HOME/calls"
    brew() {
        echo "brew $*" >> "$CALLS"
        case "$*" in
            "bundle cleanup --file="*) echo "Would uninstall casks: google-chrome" ;;
            "info --cask"*) echo '{"casks":[{"artifacts":[{"app":["Firefox.app"]},{"zap":[]},{"app":[{"target":"Renamed.app"}]}]}]}' ;;
        esac
    }
}

teardown() { rm -rf "$HOME"; }

@test "without --apply nothing is removed, only shown" {
    run cleanup_homebrew
    [[ "$output" == *"google-chrome"* ]]
    [[ "$output" == *"would run: brew bundle cleanup --force"* ]]
    ! grep -q -- "--force" "$CALLS"
    ! grep -q "autoremove" "$CALLS"
}

@test "--apply removes what the Brewfiles do not declare" {
    APPLY=1
    run cleanup_homebrew
    grep -q "bundle cleanup --force --file=" "$CALLS"
    grep -q "autoremove" "$CALLS"
}

@test "a failing command does not stop the cleanup" {
    APPLY=1
    run act false
    [ "$status" -eq 0 ]
    [[ "$output" == *"Failed (continuing)"* ]]
}

@test "Docker volumes are deleted only with --volumes" {
    docker() { echo "docker $*" >> "$CALLS"; }
    APPLY=1
    run cleanup_docker
    ! grep -q "volume prune" "$CALLS"
    VOLUMES=1
    run cleanup_docker
    grep -q "volume prune" "$CALLS"
}

@test "apps from casks and the App Store are not reported as installed by hand" {
    defaults() { return 1; }
    mkdir -p "$APPS_DIR/Firefox.app" "$APPS_DIR/Renamed.app" "$APPS_DIR/Kindle.app/Contents/_MASReceipt" "$APPS_DIR/Pokemon TCG Live.app"
    run unmanaged_apps
    [[ "$output" == *"Pokemon TCG Live.app"* ]]
    [[ "$output" != *Firefox* && "$output" != *Renamed* && "$output" != *Kindle* ]]
}

@test "unknown profile is rejected before anything runs" {
    run main --profile nope --apply
    [ "$status" -ne 0 ]
    [ ! -e "$CALLS" ]
}
