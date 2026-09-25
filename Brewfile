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
brew "tldr"             # Simplified man pages
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
brew "p7zip"
brew "unzip"

# -----------------------------------------------------------------------------
# Container & Kubernetes
# -----------------------------------------------------------------------------

brew "colima"                    # Docker runtime for macOS
brew "docker"                    # Docker CLI
brew "docker-compose"            # `docker compose` plugin
brew "docker-credential-helper"  # Credential management
brew "kubernetes-cli"            # kubectl
brew "k9s"                       # Kubernetes TUI
brew "helm"                      # Kubernetes package manager
brew "kubectx"                   # Context/namespace switcher

# -----------------------------------------------------------------------------
# Applications (Casks)
# -----------------------------------------------------------------------------

# Terminal & Editors
cask "iterm2"
cask "visual-studio-code"
cask "cursor"

# AI & Productivity
cask "claude"
cask "notion"

# API & Database clients
cask "insomnia"
cask "tableplus"

# Browsers
cask "google-chrome"
cask "firefox"

# Communication
cask "slack"
cask "zoom"

# Utilities
cask "alfred"
cask "1password"
cask "rectangle"         # Window management
cask "caffeine"          # Prevent sleep
cask "hiddenbar"         # Menu bar management

# Fonts
cask "font-meslo-lg-nerd-font"
