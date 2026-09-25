#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "mise activation is not cached (its output embeds the PATH at generation time)" {
    ! grep -qE '_cached_init +mise' "$REPO_DIR/dotfiles/zsh/zshrc"
    grep -q 'eval "$(mise activate zsh)"' "$REPO_DIR/dotfiles/zsh/zshrc"
}
