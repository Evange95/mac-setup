#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$REPO_DIR/lib/common.sh"
    source "$REPO_DIR/steps/languages.sh"
    SCRIPT_DIR="$(mktemp -d)"
    HOME="$(mktemp -d)"
    mkdir -p "$SCRIPT_DIR/config/mise"
    touch "$SCRIPT_DIR/config/mise/config.toml" "$SCRIPT_DIR/config/mise/personal.toml" "$SCRIPT_DIR/config/mise/work.toml"
}

teardown() { rm -rf "$SCRIPT_DIR" "$HOME"; }

@test "links the global mise config and the active profile's tools into conf.d" {
    PROFILE=personal
    link_mise_config > /dev/null
    [ "$(readlink "$HOME/.config/mise/config.toml")" = "$SCRIPT_DIR/config/mise/config.toml" ]
    [ "$(readlink "$HOME/.config/mise/conf.d/personal.toml")" = "$SCRIPT_DIR/config/mise/personal.toml" ]
    [ ! -e "$HOME/.config/mise/conf.d/work.toml" ]
}

@test "switching profile removes the other profile's link" {
    PROFILE=personal
    link_mise_config > /dev/null
    PROFILE=work
    link_mise_config > /dev/null
    [ ! -e "$HOME/.config/mise/conf.d/personal.toml" ]
    [ -L "$HOME/.config/mise/conf.d/work.toml" ]
}

@test "profile without a tools file links only the global config" {
    rm "$SCRIPT_DIR/config/mise/work.toml"
    PROFILE=work
    run link_mise_config
    [ "$status" -eq 0 ]
    [ -L "$HOME/.config/mise/config.toml" ]
    [ ! -e "$HOME/.config/mise/conf.d/work.toml" ]
}
