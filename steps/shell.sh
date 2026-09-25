# shellcheck shell=bash

step_shell() {
    link_file "$SCRIPT_DIR/dotfiles/zsh/zshenv" "$HOME/.zshenv"
    link_file "$SCRIPT_DIR/dotfiles/zsh/zprofile" "$HOME/.zprofile"
    link_file "$SCRIPT_DIR/dotfiles/zsh/zshrc" "$HOME/.zshrc"
    link_file "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"

    # Migrations: plugins now come from Homebrew, prompt from Starship
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        rm -rf "$HOME/.oh-my-zsh"
        log_info "Removed ~/.oh-my-zsh (plugins are now installed via Homebrew)"
    fi
    rm -f "$HOME/.p10k.zsh" "$HOME/.fzf.zsh"
    rm -f "$HOME/.cache/fzf-zsh.zsh" "$HOME/.cache/zoxide-init.zsh" "$HOME/.cache/starship-init.zsh"
    # fpath changed; force a fresh completion dump
    rm -f "$HOME/.zcompdump"*
}
