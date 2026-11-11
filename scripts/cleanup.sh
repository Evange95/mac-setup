#!/bin/bash
# Brings the Mac back to what this repo declares and reclaims disk space, without
# reinstalling macOS. By default it only shows what it would do.
#   ./scripts/cleanup.sh                     report, change nothing
#   ./scripts/cleanup.sh --apply             remove undeclared Homebrew packages, unused
#                                            toolchain versions, caches and unused Docker data
#   ./scripts/cleanup.sh --apply --volumes   also delete unused Docker volumes (their data is lost)
#   ./scripts/cleanup.sh --profile work      compare against another profile's Brewfile
# What it cannot judge (apps installed by hand, login items, background services) is
# listed for review and never removed.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=steps/packages.sh
source "$SCRIPT_DIR/steps/packages.sh"

APPLY=0
VOLUMES=0

have() { command -v "$1" > /dev/null 2>&1; }
heading() { printf '\n%b=== %s ===%b\n' "$BLUE" "$1" "$NC"; }

# act <command...>: run it with --apply, otherwise print it
act() {
    if [[ "$APPLY" == "1" ]]; then
        log_info "Running: $*"
        "$@" || log_warning "Failed (continuing): $*"
    else
        echo "  would run: $*"
    fi
}

dir_size() {
    [[ -e "$1" ]] || return 0
    du -sh "$1" 2> /dev/null | cut -f1
}

cleanup_homebrew() {
    heading "Homebrew packages not declared in the Brewfiles ($PROFILE)"
    have brew || { echo "  Homebrew is not installed"; return 0; }

    local extra declared
    extra="$(undeclared_packages)"
    if [[ -z "$extra" ]]; then
        log_success "Nothing installed beyond what the repo declares"
    else
        echo "$extra"
        echo "  (uninstalling an app keeps its data in ~/Library; to keep a package, add it to a Brewfile first)"
        if [[ -f /Library/LaunchDaemons/sh.brew.tailscale.plist ]]; then
            log_warning "The Homebrew Tailscale daemon runs as root. Stop it first: sudo brew services stop tailscale"
        fi
        declared="$(declared_brewfile)"
        act brew bundle cleanup --force --file="$declared"
        rm -f "$declared"
    fi

    echo "  Download cache: $(dir_size "$(brew --cache 2> /dev/null)")"
    act brew autoremove
    act brew cleanup --prune=all
}

cleanup_toolchains() {
    heading "Toolchain versions no config uses (mise)"
    if have mise; then
        mise prune --dry-run 2>&1 | sed 's/^/  /'
        act mise prune --yes
    else
        echo "  mise is not installed"
    fi

    local dir
    for dir in .volta .pyenv .nvm .asdf .oh-my-zsh; do
        if [[ -e "$HOME/$dir" ]]; then
            log_warning "$HOME/$dir ($(dir_size "$HOME/$dir")) is from a tool mise replaced. Once nothing uses it, delete it"
        fi
    done
}

# _cache <label> <directory> <command...>: only for tools that are installed
_cache() {
    local label="$1" dir="$2"
    shift 2
    have "$1" || return 0
    echo "  $label: $(dir_size "$dir")"
    act "$@"
}

cleanup_caches() {
    heading "Package caches (everything here is downloaded again on demand)"
    _cache "pnpm store" "$HOME/Library/pnpm/store" pnpm store prune
    _cache "npm cache" "$HOME/.npm/_cacache" npm cache clean --force
    _cache "uv cache" "$HOME/.cache/uv" uv cache prune
    _cache "Go build cache" "$HOME/Library/Caches/go-build" go clean -cache
}

cleanup_docker() {
    heading "Docker"
    if ! have docker || ! docker info > /dev/null 2>&1; then
        echo "  Docker is not running (start it with 'colima start' to include it)"
        return 0
    fi
    docker system df
    echo "  Removes stopped containers, images no container uses, and the whole build cache."
    act docker system prune --all --force
    act docker builder prune --all --force
    if [[ "$VOLUMES" == "1" ]]; then
        act docker volume prune --all --force
    else
        echo "  Volumes are kept (databases live there). Add --volumes to delete the unused ones."
    fi
}

# App bundles Homebrew casks installed, one name per line
_cask_apps() {
    have brew && have jq || return 0
    brew info --cask --json=v2 --installed 2> /dev/null \
        | jq -r '.casks[].artifacts[]? | .app? // empty | .[] | if type == "string" then . else (.target // empty) end' 2> /dev/null \
        | sed 's|.*/||'
}

# Apps that came from neither Homebrew, the App Store nor Apple
unmanaged_apps() {
    local managed app name
    managed="$(_cask_apps)"
    for app in "$APPS_DIR"/*.app "$HOME/Applications"/*.app; do
        [[ -d "$app" ]] || continue
        name="$(basename "$app")"
        [[ -d "$app/Contents/_MASReceipt" ]] && continue
        echo "$managed" | grep -qxF "$name" && continue
        [[ "$(defaults read "$app/Contents/Info" CFBundleIdentifier 2> /dev/null)" == com.apple.* ]] && continue
        echo "  $app"
    done
}

report_manual() {
    heading "Apps replaced in the repo that are still installed"
    _warn_replaced_apps

    heading "Apps installed by hand (not from Homebrew or the App Store)"
    unmanaged_apps
    echo "  Keep: add a cask to a Brewfile so the repo knows about it. Drop: delete the app, then"
    echo "  'mo' (mole) finds what it left behind in ~/Library."

    heading "Starts by itself (review in System Settings > General > Login Items & Extensions)"
    echo "  Login items: $(osascript -e 'tell application "System Events" to get the name of every login item' 2> /dev/null)"
    local dir
    for dir in "$HOME/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons; do
        [[ -d "$dir" ]] && find "$dir" -name '*.plist' -maxdepth 1 2> /dev/null | sed 's/^/  /'
    done
}

cleanup_logs() {
    heading "Setup logs older than 30 days"
    [[ -d "$SCRIPT_DIR/logs" ]] || return 0
    act find "$SCRIPT_DIR/logs" -type f -mtime +30 -delete
}

main() {
    PROFILE="${PROFILE:-}"
    if [[ -f "$SCRIPT_DIR/setup.conf" ]]; then
        # shellcheck source=/dev/null
        source "$SCRIPT_DIR/setup.conf"
    fi
    PROFILE="${PROFILE:-personal}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply) APPLY=1; shift ;;
            --volumes) VOLUMES=1; shift ;;
            --profile) PROFILE="${2:-}"; shift 2 ;;
            -h | --help) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; return 0 ;;
            *) log_error "Unknown option: $1"; return 1 ;;
        esac
    done
    if [[ ! -f "$SCRIPT_DIR/Brewfile.$PROFILE" ]]; then
        log_error "Unknown profile: $PROFILE"
        return 1
    fi

    local free_before
    free_before="$(df -h "$HOME" | awk 'NR == 2 { print $4 }')"
    load_session_env

    cleanup_homebrew
    cleanup_toolchains
    cleanup_caches
    cleanup_docker
    cleanup_logs
    report_manual

    echo ""
    if [[ "$APPLY" == "1" ]]; then
        log_success "Done. Free disk space: $free_before -> $(df -h "$HOME" | awk 'NR == 2 { print $4 }')"
    else
        log_info "Nothing was changed. Free disk space: $free_before. Rerun with --apply to do the above."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
