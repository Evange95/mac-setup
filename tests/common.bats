#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    # shellcheck source=../lib/common.sh
    source "$REPO_DIR/lib/common.sh"
    WORK="$(mktemp -d)"
    echo "managed" > "$WORK/src"
}

teardown() {
    rm -rf "$WORK"
}

@test "link_file creates a symlink and its parent directory" {
    run link_file "$WORK/src" "$WORK/nested/dir/dest"
    [ "$status" -eq 0 ]
    [ "$(readlink "$WORK/nested/dir/dest")" = "$WORK/src" ]
}

@test "link_file backs up an existing regular file" {
    echo "user content" > "$WORK/dest"
    run link_file "$WORK/src" "$WORK/dest"
    [ "$status" -eq 0 ]
    [ -L "$WORK/dest" ]
    backup=$(ls "$WORK"/dest.backup.*)
    [ "$(cat "$backup")" = "user content" ]
}

@test "link_file is a no-op when the link is already correct" {
    ln -s "$WORK/src" "$WORK/dest"
    run link_file "$WORK/src" "$WORK/dest"
    [ "$status" -eq 0 ]
    ! ls "$WORK"/dest.backup.* 2>/dev/null
}

@test "link_file replaces a symlink pointing elsewhere without backup" {
    echo "other" > "$WORK/other"
    ln -s "$WORK/other" "$WORK/dest"
    run link_file "$WORK/src" "$WORK/dest"
    [ "$(readlink "$WORK/dest")" = "$WORK/src" ]
    ! ls "$WORK"/dest.backup.* 2>/dev/null
}

@test "copy_file overwrites the destination with the source" {
    echo "stale" > "$WORK/dest"
    run copy_file "$WORK/src" "$WORK/sub/dest"
    [ "$status" -eq 0 ]
    [ "$(cat "$WORK/sub/dest")" = "managed" ]
}
