#!/bin/bash
# Read-only inventory of what is installed and running on this Mac: no sudo, changes nothing.
# Used to compare the real machine with what this repo declares.
#   ./scripts/inventory.sh        writes logs/inventory-<timestamp>.txt (gitignored)
# Collects names and versions only: no shell history, no environment, no file contents.
# shellcheck disable=SC2012  # ls is fine here: output is for reading, not parsing

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$SCRIPT_DIR/logs"
OUT="$OUT_DIR/inventory-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$OUT_DIR"

section() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" > /dev/null 2>&1; }

# run <label> <command...>: section header, then the command's output (or why there is none)
run() {
    local label="$1"
    shift
    section "$label"
    if ! have "$1"; then
        echo "(not installed: $1)"
        return 0
    fi
    "$@" 2>&1 || echo "(exit $?)"
}

list_dir() {
    section "$1"
    if [[ -d "$2" ]]; then ls -1 "$2" 2>&1; else echo "(missing)"; fi
}

# Sum memory and CPU per app (processes inside Foo.app are counted as Foo.app)
top_processes() {
    ps -axo rss=,pcpu=,comm= | awk '
        {
            rss = $1; cpu = $2; $1 = ""; $2 = ""; name = $0
            if (match(name, /[^\/]+\.app/)) name = substr(name, RSTART, RLENGTH)
            else { n = split(name, parts, "/"); name = parts[n] }
            sub(/^ +/, "", name)
            mem[name] += rss; load[name] += cpu; count[name]++
        }
        END {
            for (k in mem) printf "%8.0f MB %6.1f%% cpu %4d procs  %s\n", mem[k] / 1024, load[k], count[k], k
        }' | sort -rn | head -40
}

collect() {
    echo "mac-setup inventory — $(date)"

    section "Hardware and OS"
    sw_vers 2>&1
    sysctl -n machdep.cpu.brand_string hw.model 2>&1
    echo "cores: $(sysctl -n hw.ncpu 2> /dev/null) (performance: $(sysctl -n hw.perflevel0.physicalcpu 2> /dev/null), efficiency: $(sysctl -n hw.perflevel1.physicalcpu 2> /dev/null))"
    echo "ram: $(($(sysctl -n hw.memsize 2> /dev/null || echo 0) / 1073741824)) GB"
    df -h / /System/Volumes/Data 2>&1
    echo "uptime: $(uptime)"

    section "Memory pressure and swap"
    sysctl -n vm.swapusage 2>&1
    memory_pressure 2>&1 | tail -n 5
    vm_stat 2>&1 | head -n 12
    pmset -g therm 2>&1

    section "Top apps by memory (RSS, summed per app)"
    top_processes

    run "Homebrew: formulae installed on request" brew leaves --installed-on-request
    run "Homebrew: all formulae (with dependencies)" brew list --formula
    run "Homebrew: casks" brew list --cask
    run "Homebrew: taps" brew tap
    run "Homebrew: services" brew services list
    run "Mac App Store apps" mas list

    list_dir "/Applications" /Applications
    list_dir "$HOME/Applications" "$HOME/Applications"

    # Everything that starts by itself: the usual source of background CPU and memory
    list_dir "LaunchAgents (user)" "$HOME/Library/LaunchAgents"
    list_dir "LaunchAgents (system-wide)" /Library/LaunchAgents
    list_dir "LaunchDaemons (system-wide)" /Library/LaunchDaemons
    list_dir "Privileged helper tools" /Library/PrivilegedHelperTools
    section "Login items"
    osascript -e 'tell application "System Events" to get the name of every login item' 2>&1 || true
    section "Running third-party launchd jobs"
    launchctl list 2>&1 | awk 'NR == 1 || $3 !~ /^com\.apple\./' | sort -k3
    run "System extensions (network filters, endpoint security, ...)" systemextensionsctl list
    section "Third-party kernel extensions"
    kmutil showloaded --list-only 2>&1 | grep -v "com.apple" || echo "(none)"

    run "mise tools" mise ls
    run "npm globals" npm ls -g --depth=0
    run "pnpm globals" pnpm ls -g --depth=0
    run "bun globals" bun pm ls -g
    run "pipx tools" pipx list --short
    run "uv tools" uv tool list
    run "cargo installs" cargo install --list
    run "rustup toolchains" rustup toolchain list
    list_dir "$HOME/go/bin" "$HOME/go/bin"
    list_dir "$HOME/.local/bin" "$HOME/.local/bin"
    list_dir "/usr/local/bin" /usr/local/bin

    section "Other version/package managers present"
    local dir
    for dir in .volta .pyenv .nvm .asdf .sdkman .rbenv .nix-profile .conda miniconda3 anaconda3 .oh-my-zsh; do
        [[ -e "$HOME/$dir" ]] && echo "~/$dir"
    done
    [[ -d /nix ]] && echo "/nix"
    have nix && nix --version 2>&1
    have port && echo "macports"

    run "VS Code extensions" code --list-extensions
    run "Cursor extensions" cursor --list-extensions

    run "Colima" colima list
    run "Docker disk usage" docker system df

    section "zsh interactive startup time (3 runs)"
    local i
    for i in 1 2 3; do
        { /usr/bin/time zsh -i -c exit; } 2>&1 | tail -n 1
    done
}

# Home directory paths carry the account name: replace them before writing
collect 2>&1 | sed "s|$HOME|~|g" > "$OUT"

echo "Inventory written to: $OUT"
echo "Copy it to the clipboard with: pbcopy < \"$OUT\""
