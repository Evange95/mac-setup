# shellcheck shell=bash

# Writes ~/.config/git/<name>.gitconfig and includes it for repos under <dir>.
_git_dir_identity() {
    local name="$1" dir="$2" email="$3"
    local file="$HOME/.config/git/$name.gitconfig"
    printf '[user]\n    email = %s\n' "$email" > "$file"
    git config --global "includeIf.gitdir:$dir.path" "$file"
    log_success "Repos under $dir commit as $email"
}

step_git() {
    link_file "$SCRIPT_DIR/dotfiles/git/config" "$HOME/.config/git/config"
    # Copied, not linked: other tools (e.g. Claude Code) append to this file
    copy_file "$SCRIPT_DIR/dotfiles/git/ignore" "$HOME/.config/git/ignore"

    # Migration: shared settings used to be written into ~/.gitconfig, where they would
    # shadow the managed file. Drop them there, keeping identity and tool-added entries.
    if [[ -f "$HOME/.gitconfig" ]]; then
        local key removed=0
        for key in $(git config -f "$SCRIPT_DIR/dotfiles/git/config" --name-only --list | sort -u) core.excludesfile; do
            if git config --global --get-all "$key" &>/dev/null; then
                if [[ $removed -eq 0 ]]; then
                    cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup.$(date +%Y%m%d%H%M%S)"
                    removed=1
                fi
                git config --global --unset-all "$key"
            fi
        done
        if [[ $removed -eq 1 ]]; then
            log_info "Moved shared settings out of ~/.gitconfig (backup saved next to it)"
        fi
        rm -f "$HOME/.gitignore_global"
    fi

    # Identity: default for every repo, optionally overridden per directory
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    [[ -n "$GIT_WORK_EMAIL" ]] && _git_dir_identity work "$HOME/Code/work/" "$GIT_WORK_EMAIL"
    [[ -n "$GIT_PERSONAL_EMAIL" ]] && _git_dir_identity personal "$HOME/Code/personal/" "$GIT_PERSONAL_EMAIL"

    log_success "Git configured"
}
