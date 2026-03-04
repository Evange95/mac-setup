#!/bin/bash

#===============================================================================
# macOS Developer Setup Script
# Description: Automated setup for a full-stack development environment
# Usage: ./mac-setup.sh
# Config: Copy setup.conf.example to setup.conf and fill in your details
#===============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Script directory (for referencing config files)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is intended for macOS only."
    exit 1
fi

echo ""
echo "======================================================================="
echo "              macOS Developer Environment Setup"
echo "              Full-Stack Development"
echo "======================================================================="
echo ""

#===============================================================================
# SECTION 1: Load Configuration
#===============================================================================
if [[ -f "$SCRIPT_DIR/setup.conf" ]]; then
    log_info "Loading configuration from setup.conf..."
    source "$SCRIPT_DIR/setup.conf"
    log_success "Configuration loaded"
else
    log_info "No setup.conf found. Please enter your details:"
    read -rp "  Git name: " GIT_USER_NAME
    read -rp "  Git email: " GIT_USER_EMAIL
    echo ""
fi

if [[ -z "$GIT_USER_NAME" || -z "$GIT_USER_EMAIL" ]]; then
    log_error "GIT_USER_NAME and GIT_USER_EMAIL are required."
    exit 1
fi

#===============================================================================
# SECTION 2: Xcode Command Line Tools
#===============================================================================
log_info "Installing Xcode Command Line Tools..."

if xcode-select -p &>/dev/null; then
    log_success "Xcode Command Line Tools already installed"
else
    xcode-select --install
    log_warning "Please complete the Xcode installation popup, then press Enter to continue..."
    read -r
fi

#===============================================================================
# SECTION 3: Homebrew
#===============================================================================
log_info "Installing Homebrew..."

if command -v brew &>/dev/null; then
    log_success "Homebrew already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Persist Homebrew in login shell for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
fi

# Always set up brew in PATH for this session (both architectures)
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

brew update
brew upgrade || log_warning "Some upgrades failed; continuing"

#===============================================================================
# SECTION 4: Install Everything via Brewfile
#===============================================================================
log_info "Installing packages and applications via Brewfile..."

if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    brew bundle --file="$SCRIPT_DIR/Brewfile" || log_warning "Some Brewfile items may have failed"
    log_success "Brewfile installation complete"
else
    log_error "Brewfile not found at $SCRIPT_DIR/Brewfile"
    exit 1
fi

#===============================================================================
# SECTION 5: Programming Languages
#===============================================================================
log_info "Installing programming languages..."

# --- Rust ---
log_info "Installing Rust..."
if command -v rustc &>/dev/null; then
    log_success "Rust already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Always source cargo env for this session
source "$HOME/.cargo/env" 2>/dev/null || true

# Install common Rust tools
log_info "Installing Rust tools..."
rustup component add rustfmt clippy rust-analyzer

# --- Node.js with Volta ---
log_info "Installing Volta (Node.js version manager)..."
if command -v volta &>/dev/null; then
    log_success "Volta already installed"
else
    curl https://get.volta.sh | bash
fi

# Always set up Volta in PATH for this session
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

log_info "Installing Node.js via Volta..."
volta install node@24
volta install npm@latest

# Install global packages via Volta
log_info "Installing global Node.js packages..."
volta install pnpm
volta install typescript
volta install tsx
volta install @anthropic-ai/claude-code

# --- Bun ---
log_info "Installing Bun..."
if command -v bun &>/dev/null; then
    log_success "Bun already installed"
else
    curl -fsSL https://bun.sh/install | bash
fi

# --- Python with pyenv ---
log_info "Configuring pyenv..."

# Initialize pyenv for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

log_info "Installing Python 3.13..."
pyenv install 3.13 --skip-existing
pyenv global 3.13

# Install pipx tools
log_info "Installing Python development tools..."
pipx ensurepath
pipx install poetry
pipx install black
pipx install ruff
pipx install mypy

#===============================================================================
# SECTION 6: Oh My Zsh & Terminal Setup
#===============================================================================
log_info "Setting up Zsh and Oh My Zsh..."

# Install Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh My Zsh already installed"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Zsh plugins (via Oh My Zsh only — not Homebrew, to avoid double-install)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# fast-syntax-highlighting (replaces zsh-syntax-highlighting — faster, better command highlighting)
if [[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
fi

# zsh-completions (completion definitions for hundreds of tools)
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
fi

# zsh-you-should-use (reminds you about existing aliases)
if [[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]]; then
    git clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"
fi

# Remove old zsh-syntax-highlighting if present (replaced by fast-syntax-highlighting)
if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log_info "Removed old zsh-syntax-highlighting (replaced by fast-syntax-highlighting)"
fi

# Remove Powerlevel10k if present (replaced by Starship)
if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    rm -rf "$ZSH_CUSTOM/themes/powerlevel10k"
    log_info "Removed Powerlevel10k (replaced by Starship)"
fi

#===============================================================================
# SECTION 7: iTerm2 Shell Integration & Profile
#===============================================================================
log_info "Setting up iTerm2..."

# Install shell integration
if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
    curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
    log_success "iTerm2 shell integration installed"
fi

# Deploy Dynamic Profile (auto-loaded by iTerm2, doesn't overwrite default)
if [[ -f "$SCRIPT_DIR/iterm2-profile.json" ]]; then
    mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles/"
    cp "$SCRIPT_DIR/iterm2-profile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/"
    log_success "iTerm2 Developer profile deployed"
fi

#===============================================================================
# SECTION 8: Starship Prompt Configuration
#===============================================================================
log_info "Setting up Starship prompt..."

mkdir -p "$HOME/.config"
if [[ -f "$SCRIPT_DIR/starship.toml" ]]; then
    cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    log_success "Starship config deployed"
fi

# Clean up old Powerlevel10k config
rm -f "$HOME/.p10k.zsh"

#===============================================================================
# SECTION 9: Dotfiles (.zshrc)
#===============================================================================
log_info "Creating dotfiles..."

if [[ -f "$HOME/.zshrc" ]]; then
    log_warning ".zshrc already exists. Creating backup and regenerating."
    log_info "If you have custom changes, restore from backup after reviewing."
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

# Create .zshrc
cat > "$HOME/.zshrc" << 'ZSHRC'
#===============================================================================
# Zsh Configuration
#===============================================================================

# --- Oh My Zsh Performance ---
DISABLE_AUTO_UPDATE="true"       # Update manually with omz update
DISABLE_MAGIC_FUNCTIONS="true"   # Faster paste (no URL escaping)
DISABLE_COMPFIX="true"           # Skip compaudit (saves ~20ms)

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# No theme — using Starship prompt (initialized at bottom)
ZSH_THEME=""

# Load zsh-completions before compinit (must come before OMZ source)
fpath=(${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src $fpath)

# Deduplicate fpath to prevent compinit cache invalidation
fpath=(${(uo)fpath})

# Plugins
plugins=(
    git
    sudo
    zsh-autosuggestions
    fast-syntax-highlighting
    you-should-use
    docker
    kubectl
    golang
    rust
    python
    node
    npm
    fzf
    direnv
)

source $ZSH/oh-my-zsh.sh

#===============================================================================
# Shell Options
#===============================================================================

setopt AUTO_CD                   # Type directory name to cd into it
setopt CORRECT                   # Suggest corrections for mistyped commands

#===============================================================================
# History
#===============================================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY          # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate entries
setopt HIST_SAVE_NO_DUPS         # Don't write duplicates to file
setopt HIST_FIND_NO_DUPS         # Don't show duplicates when searching
setopt HIST_IGNORE_SPACE         # Prefix with space to exclude from history
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt INC_APPEND_HISTORY_TIME   # Append with duration after command finishes
setopt SHARE_HISTORY             # Share history between sessions

#===============================================================================
# Completion
#===============================================================================

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"

# Menu-driven completion
zstyle ':completion:*' menu select

# Case-insensitive, partial-word, and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Group completions by type
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

#===============================================================================
# Key Bindings
#===============================================================================

# Edit current command in $EDITOR (Ctrl+X Ctrl+E)
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

#===============================================================================
# Environment Variables
#===============================================================================

# Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Editor
export EDITOR="code --wait"
export VISUAL="$EDITOR"

# Homebrew
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
source "$HOME/.cargo/env" 2>/dev/null || true

# Volta (Node.js)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)" 2>/dev/null || true

# pipx
export PATH="$HOME/.local/bin:$PATH"

# direnv (must be last hook — after all PATH changes)
eval "$(direnv hook zsh)"
export DIRENV_LOG_FORMAT=""  # Silence loading/unloading messages

#===============================================================================
# Aliases
#===============================================================================

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Modern CLI tools
alias cat="bat"
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --level=2 --icons"
alias grep="rg"
alias find="fd"

# Git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gd="git diff"
alias glog="git log --oneline --graph --decorate"
alias lg="lazygit"

# Docker & Kubernetes
alias d="docker"
alias dc="docker compose"
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"

# Development
alias py="python"
alias pip="pip3"
alias nr="npm run"
alias pn="pnpm"
alias bx="bunx"

# Monitoring (btop supersedes htop)
alias htop="btop"

# Utilities
alias ports="lsof -i -P -n | grep LISTEN"
alias ip="curl -s https://ipinfo.io/ip"
alias localip="ipconfig getifaddr en0"
alias cleanup="brew cleanup && docker system prune -af"
alias update="brew update && brew upgrade && brew cleanup"

# Quick edits
alias zshrc="code ~/.zshrc"
alias reload="source ~/.zshrc"

#===============================================================================
# Functions
#===============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and kill process on port
killport() {
    lsof -ti:"$1" | xargs kill -9
}

# Quick git commit and push
gcap() {
    git add -A && git commit -m "$1" && git push
}

# Docker shell into container
dsh() {
    docker exec -it "$1" /bin/sh
}

# Kubernetes get all in namespace
kgetall() {
    kubectl get all -n "${1:-default}"
}

#===============================================================================
# FZF Configuration
#===============================================================================

# Use fd for fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# FZF options
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --preview "bat --style=numbers --color=always --line-range :500 {}"
'

# Load fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#===============================================================================
# Shell Integration & Extras
#===============================================================================

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# zoxide (smarter cd — replaces z/autojump)
eval "$(zoxide init zsh)"

# Starship prompt (must be last)
eval "$(starship init zsh)"

ZSHRC

#===============================================================================
# SECTION 10: VS Code & Cursor Extensions
#===============================================================================
log_info "Installing editor extensions..."

if [[ -f "$SCRIPT_DIR/vscode-extensions.txt" ]]; then
    if command -v code &>/dev/null; then
        log_info "Installing VS Code extensions..."
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            [[ -z "$ext" || "$ext" == \#* ]] && continue
            code --install-extension "$ext" --force 2>/dev/null || true
        done < "$SCRIPT_DIR/vscode-extensions.txt"
        log_success "VS Code extensions installed"
    fi

    if command -v cursor &>/dev/null; then
        log_info "Installing Cursor extensions..."
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            [[ -z "$ext" || "$ext" == \#* ]] && continue
            cursor --install-extension "$ext" --force 2>/dev/null || true
        done < "$SCRIPT_DIR/vscode-extensions.txt"
        log_success "Cursor extensions installed"
    fi
fi

#===============================================================================
# SECTION 11: Git Configuration
#===============================================================================
log_info "Configuring Git..."

# --- User ---
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# --- Core ---
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global core.editor "code --wait"
git config --global core.pager delta
git config --global core.fsmonitor true
git config --global core.untrackedCache true

# --- Delta (syntax-highlighted diff pager) ---
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme Catppuccin-Mocha
git config --global delta.dark true
git config --global delta.file-decoration-style "blue ol"
git config --global delta.file-style "bold yellow ul"
git config --global delta.hunk-header-decoration-style "blue box"
git config --global delta.hunk-header-style "file line-number syntax"

# --- Diff ---
git config --global diff.algorithm histogram
git config --global diff.colorMoved zebra
git config --global diff.colorMovedWS allow-indentation-change
git config --global diff.mnemonicPrefix true
git config --global diff.renames true

# --- Merge ---
git config --global merge.conflictstyle zdiff3
git config --global merge.autoStash true

# --- Push ---
git config --global push.default simple
git config --global push.autoSetupRemote true
git config --global push.followTags true

# --- Pull ---
git config --global pull.rebase true

# --- Fetch ---
git config --global fetch.prune true
git config --global fetch.pruneTags true
git config --global fetch.all true

# --- Rebase ---
git config --global rebase.autoSquash true
git config --global rebase.autoStash true
git config --global rebase.updateRefs true

# --- Branch & Tag ---
git config --global column.ui auto
git config --global branch.sort -committerdate
git config --global tag.sort version:refname

# --- UX ---
git config --global help.autocorrect prompt
git config --global commit.verbose true
git config --global log.date iso
git config --global status.showUntrackedFiles all
git config --global stash.showPatch true
git config --global grep.patternType perl
git config --global credential.helper osxkeychain

# --- Performance ---
git config --global feature.manyFiles true
git config --global pack.threads 0
git config --global index.threads 0
git config --global maintenance.auto true
git config --global protocol.version 2

# --- Rerere (remember conflict resolutions) ---
git config --global rerere.enabled true
git config --global rerere.autoupdate true

# --- Safety ---
git config --global transfer.fsckObjects true

# --- Aliases (basic) ---
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# --- Aliases (power-user) ---
git config --global alias.undo 'reset --soft HEAD~1'
git config --global alias.amend 'commit --amend --no-edit'
git config --global alias.wip '!git add --all && git commit -m "WIP"'
git config --global alias.ri 'rebase -i'
git config --global alias.rim 'rebase -i main'
git config --global alias.rc 'rebase --continue'
git config --global alias.ra 'rebase --abort'
git config --global alias.ss 'stash push -m'
git config --global alias.sl 'stash list'
git config --global alias.sp 'stash pop'
git config --global alias.sd 'stash drop'
git config --global alias.la "log --all --graph --pretty=format:'%C(auto)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.ds 'diff --staged'
git config --global alias.cleanup '!git branch --merged | grep -v "\\*\\|main\\|master\\|develop" | xargs -n 1 git branch -d'

# --- Global .gitignore ---
cat > "$HOME/.gitignore_global" << 'GITIGNORE'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Environment
.env
.env.local
.env.*.local
.envrc

# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc
.pytest_cache/

# Build
dist/
build/
*.egg-info/
target/

# Logs
*.log
logs/

# Temp
tmp/
temp/
.tmp/
GITIGNORE

git config --global core.excludesfile "$HOME/.gitignore_global"

log_success "Git configured with delta, 30+ settings, and power-user aliases"

#===============================================================================
# SECTION 12: SSH Key Generation & Signing
#===============================================================================
log_info "Setting up SSH..."

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
    log_success "SSH key already exists"
else
    log_info "Generating SSH key (you will be prompted for a passphrase)..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_KEY"

    # Add key to macOS Keychain (macOS manages ssh-agent via launchd)
    ssh-add --apple-use-keychain "$SSH_KEY"
fi

# Harden SSH directory permissions
chmod 700 "$HOME/.ssh"
chmod 600 "$SSH_KEY" 2>/dev/null || true
chmod 644 "$SSH_KEY.pub" 2>/dev/null || true

# Create SSH config (only if it doesn't exist to preserve custom entries)
if [[ ! -f "$HOME/.ssh/config" ]]; then
    cat > "$HOME/.ssh/config" << 'SSHCONFIG'
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
SSHCONFIG

    chmod 644 "$HOME/.ssh/config"
    log_success "SSH config created"
else
    log_success "SSH config already exists (preserved)"
fi

# --- Git Commit Signing with SSH ---
log_info "Configuring git commit signing with SSH..."
git config --global gpg.format ssh
git config --global user.signingkey "$SSH_KEY.pub"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# Create allowed_signers file for local signature verification
ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
if [[ -f "$SSH_KEY.pub" ]]; then
    echo "$GIT_USER_EMAIL namespaces=\"git\" $(cat "$SSH_KEY.pub")" > "$ALLOWED_SIGNERS"
    git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"
    log_success "Git commit signing configured with SSH"
fi

#===============================================================================
# SECTION 13: macOS Security Hardening
#===============================================================================
log_info "Configuring macOS security settings..."

# --- Firewall ---
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
log_success "Firewall enabled with stealth mode"

# --- FileVault ---
if fdesetup status | grep -q "FileVault is On"; then
    log_success "FileVault is already enabled"
else
    log_warning "FileVault is not enabled. Enable it in System Settings > Privacy & Security > FileVault"
fi

# --- Touch ID for sudo ---
log_info "Configuring Touch ID for sudo..."
SUDO_LOCAL="/etc/pam.d/sudo_local"
if [[ -f "$SUDO_LOCAL" ]]; then
    # Sonoma+ method (survives macOS updates)
    if ! grep -q "pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
        echo "auth       sufficient     pam_tid.so" | sudo tee -a "$SUDO_LOCAL" > /dev/null
        log_success "Touch ID for sudo enabled (sudo_local)"
    else
        log_success "Touch ID for sudo already configured"
    fi
else
    # Create sudo_local for Sonoma+
    echo "auth       sufficient     pam_tid.so" | sudo tee "$SUDO_LOCAL" > /dev/null
    log_success "Touch ID for sudo enabled (sudo_local created)"
fi

# --- Lock Screen ---
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults -currentHost write com.apple.screensaver idleTime -int 300
log_success "Lock screen: password immediately after sleep, screensaver after 5 min"

# --- Disable auto-login & password hints ---
sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
defaults write com.apple.loginwindow RetriesUntilHint -int 0

# --- Remote Access ---
sudo systemsetup -f -setremotelogin off 2>/dev/null || true
sudo systemsetup -setremoteappleevents off 2>/dev/null || true
log_success "Remote login and Apple events disabled"

# --- Bluetooth & AirDrop ---
defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false
defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"
log_success "Bluetooth sharing disabled, AirDrop set to Contacts Only"

# --- Gatekeeper ---
sudo spctl --master-enable 2>/dev/null || true

# --- SIP Check ---
if csrutil status 2>/dev/null | grep -q "enabled"; then
    log_success "System Integrity Protection (SIP) is enabled"
else
    log_warning "SIP is disabled! This is a security risk."
fi

# --- Software Updates ---
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
defaults write com.apple.commerce AutoUpdate -bool true
log_success "Automatic software updates enabled"

# --- Power ---
sudo pmset -a womp 0
log_success "Wake for network access disabled"

# --- Secure Keyboard Entry ---
defaults write com.apple.terminal SecureKeyboardEntry -bool true
defaults write com.googlecode.iterm2 "Secure Input" -bool true

# --- Privacy ---
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
log_success "Personalized ads and Siri analytics disabled"

# --- npm security ---
npm config set audit-level moderate 2>/dev/null || true

#===============================================================================
# SECTION 14: Directory Structure
#===============================================================================
log_info "Creating project directory structure..."

mkdir -p "$HOME/Code/personal"
mkdir -p "$HOME/Code/work"
mkdir -p "$HOME/Code/experiments"
mkdir -p "$HOME/Code/open-source"

log_success "Created ~/Code directory structure"

#===============================================================================
# SECTION 15: macOS Preferences
#===============================================================================
log_info "Configuring macOS preferences..."

# Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Finder: show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Enable snap-to-grid for icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Keyboard: fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Trackpad: enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Dock
defaults write com.apple.dock tilesize -int 54

# Save screenshots to Downloads
defaults write com.apple.screencapture location -string "$HOME/Downloads"

# Restart Finder & Dock to apply changes
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

#===============================================================================
# SECTION 16: FZF Installation
#===============================================================================
log_info "Setting up FZF key bindings..."
FZF_INSTALL="$(brew --prefix)/opt/fzf/install"
if [[ -f "$FZF_INSTALL" ]]; then
    "$FZF_INSTALL" --key-bindings --completion --no-update-rc --no-bash --no-fish
else
    log_warning "fzf install script not found; skipping key bindings setup"
fi

#===============================================================================
# SECTION 17: Start Colima (Optimized for Apple Silicon)
#===============================================================================
log_info "Starting Colima (Docker runtime)..."

# Use Apple's Virtualization.framework (VZ) for native performance on M-chip
# VirtioFS for fast file sharing, Rosetta for x86 image compatibility
if colima status 2>/dev/null | grep -q "Running"; then
    log_success "Colima is already running"
else
    colima start \
        --cpu 4 \
        --memory 8 \
        --disk 60 \
        --vm-type vz \
        --vz-rosetta \
        --mount-type virtiofs \
        || log_warning "Colima failed to start. Start manually: colima start --vm-type vz --vz-rosetta --mount-type virtiofs"
fi

#===============================================================================
# SECTION 18: Post-Install Verification
#===============================================================================
echo ""
log_info "Verifying installations..."
echo ""

VERIFY_TOOLS=(git node go rustc python3 docker kubectl helm bun pnpm delta starship zoxide code cursor claude)
PASS=0
FAIL=0

for cmd in "${VERIFY_TOOLS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        VERSION=$("$cmd" --version 2>&1 | head -1)
        log_success "$cmd: $VERSION"
        PASS=$((PASS + 1))
    else
        log_warning "$cmd: NOT FOUND"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
log_info "Verified: $PASS passed, $FAIL missing"

#===============================================================================
# COMPLETION
#===============================================================================
echo ""
echo "======================================================================="
echo "                       Setup Complete!"
echo "======================================================================="
echo ""

log_success "All tools and applications have been installed!"
echo ""
echo "Next Steps:"
echo ""
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo ""
echo "  2. Starship prompt is ready. Edit ~/.config/starship.toml to customize."
echo ""
echo "  3. Add your SSH key to GitHub:"
echo "     cat ~/.ssh/id_ed25519.pub | pbcopy"
echo "     Then paste at: https://github.com/settings/keys"
echo ""
echo "  4. Authenticate GitHub CLI: gh auth login"
echo ""
echo "  5. Set iTerm2 profile to 'Developer' in Settings > Profiles"
echo ""
echo "  6. Login to applications:"
echo "     - 1Password, Chrome, VS Code/Cursor (settings sync)"
echo "     - Notion, Slack, Discord, Telegram"
echo ""

echo "Project directories:"
echo "  ~/Code/personal"
echo "  ~/Code/work"
echo "  ~/Code/experiments"
echo "  ~/Code/open-source"
echo ""

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    echo "SSH public key (copied to clipboard):"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    pbcopy < "$HOME/.ssh/id_ed25519.pub"
    log_success "SSH key copied to clipboard!"
else
    log_warning "SSH public key not found; generate it manually if needed"
fi
echo ""
