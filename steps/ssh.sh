# shellcheck shell=bash

step_ssh() {
    local ssh_key="$HOME/.ssh/id_ed25519"

    if [[ -f "$ssh_key" ]]; then
        log_success "SSH key already exists"
    else
        log_info "Generating SSH key (you will be prompted for a passphrase)..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$ssh_key"
        # Add key to macOS Keychain (macOS manages ssh-agent via launchd)
        ssh-add --apple-use-keychain "$ssh_key"
    fi

    chmod 700 "$HOME/.ssh"
    chmod 600 "$ssh_key" 2>/dev/null || true
    chmod 644 "$ssh_key.pub" 2>/dev/null || true

    # Only created if missing, to preserve custom entries
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cp "$SCRIPT_DIR/dotfiles/ssh/config" "$HOME/.ssh/config"
        chmod 644 "$HOME/.ssh/config"
        log_success "SSH config created"
    else
        log_success "SSH config already exists (preserved)"
    fi

    # Commit signing (gpg.format=ssh and gpgsign=true come from the shared git config)
    if [[ -f "$ssh_key.pub" ]]; then
        local allowed_signers="$HOME/.ssh/allowed_signers" email
        : > "$allowed_signers"
        for email in "$GIT_USER_EMAIL" "$GIT_WORK_EMAIL" "$GIT_PERSONAL_EMAIL"; do
            [[ -n "$email" ]] || continue
            grep -q "^$email " "$allowed_signers" && continue
            echo "$email namespaces=\"git\" $(cat "$ssh_key.pub")" >> "$allowed_signers"
        done
        git config --global user.signingkey "$ssh_key.pub"
        git config --global gpg.ssh.allowedSignersFile "$allowed_signers"
        log_success "Git commit signing configured with SSH"
    fi
}
