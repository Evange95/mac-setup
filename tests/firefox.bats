#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/firefox.sh"
    SCRIPT_DIR="$REPO_DIR"
    FIREFOX_PROFILES="$(mktemp -d)"
}

teardown() { rm -rf "$FIREFOX_PROFILES"; }

@test "user.js is linked into every real profile and nowhere else" {
    mkdir -p "$FIREFOX_PROFILES/abc.default-release" "$FIREFOX_PROFILES/xyz.dev" "$FIREFOX_PROFILES/Crash Reports"
    touch "$FIREFOX_PROFILES/abc.default-release/prefs.js" "$FIREFOX_PROFILES/xyz.dev/prefs.js"
    run link_firefox_prefs
    [ "$(readlink "$FIREFOX_PROFILES/abc.default-release/user.js")" = "$REPO_DIR/config/firefox/user.js" ]
    [ -L "$FIREFOX_PROFILES/xyz.dev/user.js" ]
    [ ! -e "$FIREFOX_PROFILES/Crash Reports/user.js" ]
}

@test "an existing user.js is backed up, not lost" {
    mkdir -p "$FIREFOX_PROFILES/abc.default"
    touch "$FIREFOX_PROFILES/abc.default/prefs.js"
    echo 'user_pref("mine", true);' > "$FIREFOX_PROFILES/abc.default/user.js"
    run link_firefox_prefs
    grep -q '"mine"' "$FIREFOX_PROFILES"/abc.default/user.js.backup.*
}

@test "before Firefox has ever run it says what to do instead of failing" {
    run link_firefox_prefs
    [ "$status" -eq 0 ]
    [[ "$output" == *"--only firefox"* ]]
}

@test "user.js contains only user_pref lines and comments" {
    ! grep -vE '^(//.*|)$|^user_pref\("[a-zA-Z0-9._-]+", (true|false|[0-9]+|"[^"]*")\);$' "$REPO_DIR/config/firefox/user.js"
}
