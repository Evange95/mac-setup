# shellcheck shell=bash
# Installs what the Brewfiles declare. With PACKAGE_MANAGER=nix (--nix) the same files are
# read by the flake: formulae come from nixpkgs (nix/formulae.nix), casks and App Store
# apps still from Homebrew, driven by nix-darwin.

APPS_DIR="${APPS_DIR:-/Applications}"

_warn_app() {
    [[ -d "$APPS_DIR/$1" ]] && log_warning "$2"
    return 0
}

# Apps replaced in the Brewfiles; nothing removes them unless BREW_CLEANUP=uninstall
_warn_replaced_apps() {
    _warn_app "Ice.app" "Ice is replaced by Thaw (Ice is broken on macOS 27): brew uninstall --cask jordanbaird-ice"
    _warn_app "1Password.app" "1Password is replaced by Proton Pass. After moving your vault: brew uninstall --cask 1password"
    _warn_app "Google Chrome.app" "Chrome is no longer installed (its updater keeps running in the background): brew uninstall --cask google-chrome"
    _warn_app "Insomnia.app" "Insomnia is replaced by Bruno: brew uninstall --cask insomnia"
    _warn_app "Notion Calendar.app" "Notion Calendar is no longer installed: brew uninstall --cask notion-calendar"
    _warn_app "Amphetamine.app" "Amphetamine is replaced by Vorssaint's keep-awake: delete it from Launchpad"
    if [[ -e "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/tailscale" && -d "$APPS_DIR/Tailscale.app" ]]; then
        log_warning "Tailscale is installed twice (app + Homebrew daemon). Keep the app: sudo brew services stop tailscale && brew uninstall tailscale"
    fi
}

# Lists Homebrew packages that <brewfile> does not declare; removes them if BREW_CLEANUP=uninstall
_brew_cleanup() {
    local brewfile="$1" extra
    if [[ "${BREW_CLEANUP:-none}" == "uninstall" ]]; then
        brew bundle cleanup --force --file="$brewfile" || log_warning "brew bundle cleanup failed"
        return 0
    fi
    extra="$(brew bundle cleanup --file="$brewfile" 2>/dev/null || true)"
    if [[ -n "$extra" ]]; then
        log_warning "Installed with Homebrew but not declared in this repo:"
        echo "$extra"
        log_warning "Add them to a Brewfile, or remove them all with BREW_CLEANUP=\"uninstall\" in setup.conf"
    fi
}

_packages_brew() {
    local brewfile declared
    declared="$(mktemp)"
    for brewfile in "$SCRIPT_DIR/Brewfile" "$SCRIPT_DIR/Brewfile.$PROFILE"; do
        [[ -f "$brewfile" ]] || continue
        log_info "Installing $(basename "$brewfile")..."
        # --no-upgrade: installing must not silently upgrade what is already there (use `update` alias)
        brew bundle --no-upgrade --file="$brewfile" || log_warning "Some items in $(basename "$brewfile") failed"
        cat "$brewfile" >> "$declared"
    done
    _brew_cleanup "$declared"
    rm -f "$declared"
}

_install_nix() {
    command -v nix &>/dev/null && return 0
    log_info "Installing Nix (official installer; asks for confirmation and sudo)..."
    sh <(curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install)
    load_session_env
    command -v nix &>/dev/null || { log_error "Nix was installed but is not on the PATH. Open a new terminal and rerun."; return 1; }
}

_packages_nix() {
    _install_nix || return 1

    local flake="$SCRIPT_DIR#$PROFILE" declared nix_bin
    local nix_flags=(--extra-experimental-features "nix-command flakes")
    # Machine-specific values reach the flake through the environment, hence --impure
    local flake_env=("MAC_SETUP_USER=$USER" "MAC_SETUP_BREW_CLEANUP=${BREW_CLEANUP:-none}")
    nix_bin="$(command -v nix)"

    # As the user, so flake.lock is not created by root. Commit it after the first run.
    nix "${nix_flags[@]}" flake lock "$SCRIPT_DIR"

    log_info "Building and activating the $PROFILE configuration (sudo)..."
    if command -v darwin-rebuild &>/dev/null; then
        sudo env "${flake_env[@]}" "$(command -v darwin-rebuild)" switch --impure --flake "$flake"
    else
        sudo env "${flake_env[@]}" "$nix_bin" "${nix_flags[@]}" run "$SCRIPT_DIR#darwin-rebuild" -- switch --impure --flake "$flake"
    fi
    load_session_env

    # What Homebrew should still own in this mode: casks, App Store apps and the few
    # formulae nix/formulae.nix leaves to it. Everything else it has is a leftover.
    declared="$(mktemp)"
    if env "${flake_env[@]}" nix "${nix_flags[@]}" eval --impure --raw \
        "$SCRIPT_DIR#darwinConfigurations.$PROFILE.config.homebrew.brewfile" > "$declared"; then
        _brew_cleanup "$declared"
    fi
    rm -f "$declared"
}

step_packages() {
    if [[ "${PACKAGE_MANAGER:-brew}" == "nix" ]]; then
        _packages_nix
    else
        _packages_brew
    fi
    _warn_replaced_apps
}
