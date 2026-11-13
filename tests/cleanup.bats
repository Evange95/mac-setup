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
            "info --cask"*) echo '{"casks":[{"artifacts":[{"app":["Firefox.app"]},{"zap":[]},{"app":[{"target":"Renamed.app"}]}]},{"artifacts":[{"uninstall":[{"quit":["com.nordvpn.macos","com.nordvpn.launcher"],"pkgutil":"x"}]},{"pkg":["NordVPN.pkg"]}]},{"artifacts":[{"uninstall":[{"quit":"com.insta360.linkcontroller"}]}]}]}' ;;
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

@test "a background job whose program was uninstalled is flagged with how to remove it" {
    LAUNCH_DIRS="$HOME/Library/LaunchAgents $BATS_TEST_TMPDIR/LaunchDaemons"
    mkdir -p $LAUNCH_DIRS
    plist() { printf '<plist version="1.0"><dict><key>ProgramArguments</key><array><string>%s</string></array></dict></plist>' "$1"; }
    plist /bin/sh > "$HOME/Library/LaunchAgents/alive.plist"
    plist /opt/gone/bin/tailscaled > "$BATS_TEST_TMPDIR/LaunchDaemons/sh.brew.tailscale.plist"
    run background_jobs
    [[ "$output" == *"alive.plist"* ]]
    [[ "$output" != *"/bin/sh is gone"* ]]
    [[ "$output" == *"/opt/gone/bin/tailscaled is gone"* ]]
    [[ "$output" == *"sudo launchctl bootout system '$BATS_TEST_TMPDIR/LaunchDaemons/sh.brew.tailscale.plist'"* ]]
}

# A pkg cask declares no app; its app is recognised by the bundle id the cask quits on uninstall
@test "apps installed by pkg casks are not reported as installed by hand" {
    defaults() {
        case "$1 $2" in
            "read $APPS_DIR/NordVPN.app/Contents/Info") echo com.nordvpn.macos ;;
            "read $APPS_DIR/Insta360 Link Controller.app/Contents/Info") echo com.insta360.linkcontroller ;;
            *) echo com.example.other ;;
        esac
    }
    mkdir -p "$APPS_DIR/NordVPN.app" "$APPS_DIR/Insta360 Link Controller.app" "$APPS_DIR/Other.app"
    run unmanaged_apps
    [[ "$output" == *"Other.app"* ]]
    [[ "$output" != *NordVPN* && "$output" != *Insta360* ]]
}

@test "unknown profile is rejected before anything runs" {
    run main --profile nope --apply
    [ "$status" -ne 0 ]
    [ ! -e "$CALLS" ]
}
