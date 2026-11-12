# =============================================================================
# Brewfile — packages for every profile
# Profile extras live in Brewfile.<profile>. Language toolchains (node, go, python)
# are managed by mise, not Homebrew — see config/mise/config.toml.
# =============================================================================

# -----------------------------------------------------------------------------
# CLI Tools & Utilities
# -----------------------------------------------------------------------------

# Core utilities
brew "git"
brew "curl"
brew "wget"
brew "coreutils"        # GNU core utilities
brew "jq"               # JSON processor
brew "yq"               # YAML processor

# Modern CLI replacements
brew "bat"              # Better cat
brew "eza"              # Better ls
brew "ripgrep"          # Better grep (rg)
brew "fd"               # Better find
brew "fzf"              # Fuzzy finder
brew "zoxide"           # Smarter cd
brew "btop"             # Resource monitor
brew "xh"               # Friendly HTTP client
brew "tlrc"             # Simplified man pages (`tldr`, official client)
brew "tree"
brew "watch"

# Development tools
brew "mise"             # Toolchain manager (node, go, python, ...)
brew "gh"               # GitHub CLI
brew "lazygit"          # Git TUI
brew "git-delta"        # Syntax-highlighted diff pager
brew "direnv"           # Per-directory env (.envrc)
brew "just"             # Task runner
brew "watchexec"        # Re-run commands on file changes
brew "hyperfine"        # Command benchmarking
brew "shellcheck"       # Shell script linter
brew "git-filter-repo"  # Rewrite git history
brew "rtk"              # Token-optimized CLI proxy for Claude Code
brew "mole"             # Disk cleanup and app leftovers (`mo`)
brew "bats-core"        # Shell script tests (used by this repo)
brew "starship"         # Cross-shell prompt
brew "mas"              # Mac App Store CLI

# Zsh plugins (sourced directly from .zshrc)
brew "zsh-autosuggestions"
brew "zsh-fast-syntax-highlighting"
brew "zsh-completions"
brew "zsh-you-should-use"

# Media & compression
brew "ffmpeg"
brew "webp"             # cwebp/dwebp
brew "p7zip"
brew "unzip"

# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------

brew "colima"                    # Docker runtime for macOS
brew "docker"                    # Docker CLI
brew "docker-compose"            # `docker compose` plugin
brew "docker-buildx"             # `docker buildx` plugin (BuildKit)
brew "docker-credential-helper"  # Credential management

# -----------------------------------------------------------------------------
# Applications (Casks)
# -----------------------------------------------------------------------------

# Terminal & Editors
cask "iterm2"
cask "visual-studio-code"

# AI & Productivity
cask "claude"
cask "notion"

# API client (offline, collections are plain files; replaces Insomnia, which needs an account)
cask "bruno"

# Browser (Safari is the second engine for testing; Chrome's background updater is not worth it)
cask "firefox"

# Utilities
cask "alfred"
cask "proton-pass"
cask "rectangle"         # Window management
cask "vorssaint"         # Menu bar toolkit: keep-awake, system monitor, volume mixer, app uninstaller
mas "Tailscale", id: 1475387142  # Needs App Store sign-in. Do not also install the `tailscale` formula
cask "thaw"              # Menu bar management (fork of Ice, which broke on macOS 27)

# Fonts
cask "font-meslo-lg-nerd-font"
