# shellcheck shell=bash

step_languages() {
    # --- mise: node, go, python and their tooling (see config/mise/) ---
    link_file "$SCRIPT_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"

    mise install || log_warning "Some mise tools failed to install; rerun: mise install"

    # --- Rust (personal only) ---
    if [[ "$PROFILE" == "personal" ]]; then
        if ! command -v rustup &>/dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        fi
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env" 2>/dev/null || true
        rustup component add rustfmt clippy rust-analyzer
    fi

    # --- Claude Code (native installer; the npm package is deprecated) ---
    if [[ -x "$HOME/.local/bin/claude" ]]; then
        log_success "Claude Code already installed"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    # --- Migration from Volta / pyenv (replaced by mise) ---
    if [[ -d "$HOME/.volta" || -d "$HOME/.pyenv" ]]; then
        log_warning "Volta/pyenv are no longer used (replaced by mise). Once you have checked nothing depends on them:"
        [[ -d "$HOME/.volta" ]] && log_warning "  rm -rf ~/.volta"
        [[ -d "$HOME/.pyenv" ]] && log_warning "  rm -rf ~/.pyenv && brew uninstall pyenv-virtualenv pyenv"
    fi
}
