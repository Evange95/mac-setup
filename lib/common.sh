# shellcheck shell=bash
# Shared helpers for setup steps. Must stay bash 3.2 compatible (macOS /bin/bash).

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Symlink a repo-managed file into place. Existing regular files are backed up first;
# stale symlinks are replaced. Re-running with a correct link does nothing.
link_file() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"

    if [[ -L "$dest" ]]; then
        [[ "$(readlink "$dest")" == "$src" ]] && return 0
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        local backup
        backup="$dest.backup.$(date +%Y%m%d%H%M%S)"
        mv "$dest" "$backup"
        log_warning "Backed up $dest to $backup"
    fi

    ln -s "$src" "$dest"
    log_success "Linked $dest -> $src"
}

# Copy a file that other tools also write to (so it must not be a symlink into the repo).
copy_file() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
}

# Run a command whose failure should not abort the setup (e.g. admin-only settings on a managed Mac).
try() {
    "$@" || log_warning "Failed (continuing): $*"
}

# Make Homebrew, mise-managed tools and native installers visible to the current session.
load_session_env() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_bin" ]]; then
            eval "$("$brew_bin" shellenv)"
            break
        fi
    done
    export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
}
