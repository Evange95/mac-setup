# shellcheck shell=bash

step_docker() {
    # Homebrew's docker-compose is a CLI plugin: register its directory so `docker compose` works
    local docker_config="$HOME/.docker/config.json"
    local plugin_dir="$HOMEBREW_PREFIX/lib/docker/cli-plugins"
    mkdir -p "$HOME/.docker"
    [[ -f "$docker_config" ]] || echo '{}' > "$docker_config"
    if ! jq -e --arg d "$plugin_dir" '(.cliPluginsExtraDirs // []) | index($d)' "$docker_config" &>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        jq --arg d "$plugin_dir" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$d])' "$docker_config" > "$tmp"
        mv "$tmp" "$docker_config"
        log_success "Registered Docker CLI plugins directory"
    fi

    # Rosetta is required by --vz-rosetta (x86 images on Apple Silicon)
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q oahd; then
        try softwareupdate --install-rosetta --agree-to-license
    fi

    # VZ + VirtioFS for native performance on Apple Silicon
    if colima status 2>/dev/null | grep -q "Running"; then
        log_success "Colima is already running"
    else
        colima start \
            --cpu "${COLIMA_CPU:-4}" \
            --memory "${COLIMA_MEMORY:-8}" \
            --disk "${COLIMA_DISK:-60}" \
            --vm-type vz \
            --vz-rosetta \
            --mount-type virtiofs \
            || log_warning "Colima failed to start. Start manually: colima start --vm-type vz --vz-rosetta --mount-type virtiofs"
    fi
}
