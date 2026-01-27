#!/bin/bash

#===============================================================================
# macOS Developer Setup Script
# Author: Valerio Evangelisti
# Description: Automated setup for a full-stack development environment
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

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is intended for macOS only."
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                     macOS Developer Environment Setup                      ║"
echo "║                         Full-Stack Development                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

#===============================================================================
# SECTION 1: Xcode Command Line Tools
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
# SECTION 2: Homebrew
#===============================================================================
log_info "Installing Homebrew..."

if command -v brew &>/dev/null; then
    log_success "Homebrew already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

brew update
brew upgrade

#===============================================================================
# SECTION 3: CLI Tools & Utilities
#===============================================================================
log_info "Installing CLI tools and utilities..."

CLI_TOOLS=(
    # Core utilities
    git
    curl
    wget
    
    # Modern CLI replacements
    bat           # Better cat
    eza           # Better ls
    ripgrep       # Better grep
    fd            # Better find
    fzf           # Fuzzy finder
    jq            # JSON processor
    yq            # YAML processor
    
    # Development tools
    gh            # GitHub CLI
    lazygit       # Git TUI
    tldr          # Simplified man pages
    direnv        # Per-directory env
    htop          # Process viewer
    btop          # Resource monitor
    tree          # Directory tree
    watch         # Execute commands periodically
    
    # Networking
    httpie        # HTTP client
    
    # Compression
    p7zip
    unzip
)

for tool in "${CLI_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        log_success "$tool already installed"
    else
        log_info "Installing $tool..."
        brew install "$tool"
    fi
done

#===============================================================================
# SECTION 4: Programming Languages
#===============================================================================
log_info "Installing programming languages..."

# --- Go ---
log_info "Installing Go..."
brew install go

# --- Rust ---
log_info "Installing Rust..."
if command -v rustc &>/dev/null; then
    log_success "Rust already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install common Rust tools
log_info "Installing Rust tools..."
rustup component add rustfmt clippy rust-analyzer

# --- Node.js with Volta ---
log_info "Installing Volta (Node.js version manager)..."
if command -v volta &>/dev/null; then
    log_success "Volta already installed"
else
    curl https://get.volta.sh | bash
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"
fi

log_info "Installing Node.js 24 via Volta..."
volta install node@24
volta install npm@latest

# Install global npm packages
log_info "Installing global npm packages..."
volta install pnpm
volta install yarn
volta install typescript
volta install tsx

# --- Bun ---
log_info "Installing Bun..."
if command -v bun &>/dev/null; then
    log_success "Bun already installed"
else
    curl -fsSL https://bun.sh/install | bash
fi

# --- Python with pyenv ---
log_info "Installing pyenv..."
brew install pyenv pyenv-virtualenv

# Initialize pyenv for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

log_info "Installing Python 3.13..."
pyenv install 3.13 --skip-existing
pyenv global 3.13

# Install pipx for global Python tools
log_info "Installing pipx..."
brew install pipx
pipx ensurepath

# Install common Python tools
log_info "Installing Python development tools..."
pipx install poetry
pipx install black
pipx install ruff
pipx install mypy

#===============================================================================
# SECTION 5: Container & Kubernetes Tools
#===============================================================================
log_info "Installing container and Kubernetes tools..."

# Colima (Docker alternative)
brew install colima
brew install docker
brew install docker-compose
brew install docker-credential-helper

# Kubernetes tools
brew install kubectl
brew install k9s
brew install helm
brew install kubectx  # Context/namespace switcher

#===============================================================================
# SECTION 6: Applications (Casks)
#===============================================================================
log_info "Installing applications..."

CASKS=(
    # Terminal & Editor
    iterm2
    visual-studio-code
    
    # AI & Productivity
    claude
    obsidian
    notion
    notion-calendar
    
    # API & Development
    insomnia
    tableplus
    
    # Browser
    google-chrome
    
    # Communication
    slack
    discord
    telegram
    
    # Utilities
    alfred
    1password
    rectangle      # Window management
    
    # Media & VPN
    spotify
    nordvpn
    
    # Crypto
    trezor-suite
    
    # Fonts
    font-meslo-lg-nerd-font
)

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        log_success "$cask already installed"
    else
        log_info "Installing $cask..."
        brew install --cask "$cask" || log_warning "Failed to install $cask"
    fi
done

#===============================================================================
# SECTION 7: Oh My Zsh & Terminal Setup
#===============================================================================
log_info "Setting up Zsh and Oh My Zsh..."

# Install Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh My Zsh already installed"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Powerlevel10k theme
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

#===============================================================================
# SECTION 8: Dotfiles
#===============================================================================
log_info "Creating dotfiles..."

# Backup existing .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

# Create .zshrc
cat > "$HOME/.zshrc" << 'ZSHRC'
#===============================================================================
# Zsh Configuration
#===============================================================================

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
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

# direnv
eval "$(direnv hook zsh)"

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
alias dc="docker-compose"
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"

# Development
alias py="python"
alias pip="pip3"
alias nr="npm run"
alias pn="pnpm"
alias bx="bunx"

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
    lsof -ti:$1 | xargs kill -9
}

# Quick git commit and push
gcp() {
    git add -A && git commit -m "$1" && git push
}

# Docker shell into container
dsh() {
    docker exec -it "$1" /bin/sh
}

# Kubernetes get all in namespace
kga() {
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
# Powerlevel10k
#===============================================================================

# Load Powerlevel10k config if exists
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh

ZSHRC

#===============================================================================
# SECTION 9: Git Configuration
#===============================================================================
log_info "Configuring Git..."

git config --global user.name "Valerio Evangelisti"
git config --global user.email "evangelisti.valerio1995@gmail.com"

# Git defaults
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true
git config --global diff.colorMoved zebra
git config --global core.autocrlf input
git config --global core.editor "code --wait"

# Git aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Create global gitignore
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

#===============================================================================
# SECTION 10: SSH Key Generation
#===============================================================================
log_info "Setting up SSH..."

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
    log_success "SSH key already exists"
else
    log_info "Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "evangelisti.valerio1995@gmail.com" -f "$SSH_KEY" -N ""
    
    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"
    ssh-add --apple-use-keychain "$SSH_KEY"
fi

# Create SSH config
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

chmod 600 "$HOME/.ssh/config"

#===============================================================================
# SECTION 11: macOS Security Settings
#===============================================================================
log_info "Configuring macOS security settings..."

# Enable Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
log_success "Firewall enabled"

# Check FileVault status
if fdesetup status | grep -q "FileVault is On"; then
    log_success "FileVault is already enabled"
else
    log_warning "FileVault is not enabled. Enable it in System Preferences > Security & Privacy > FileVault"
fi

#===============================================================================
# SECTION 12: Directory Structure
#===============================================================================
log_info "Creating project directory structure..."

mkdir -p "$HOME/Code/personal"
mkdir -p "$HOME/Code/work"
mkdir -p "$HOME/Code/experiments"
mkdir -p "$HOME/Code/open-source"

log_success "Created ~/Code directory structure"

#===============================================================================
# SECTION 13: macOS Preferences (Optional but Recommended)
#===============================================================================
log_info "Configuring macOS preferences..."

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

# Enable snap-to-grid for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Keyboard: fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Trackpad: enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Save screenshots to Downloads
defaults write com.apple.screencapture location -string "$HOME/Downloads"

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

#===============================================================================
# SECTION 14: FZF Installation
#===============================================================================
log_info "Setting up FZF key bindings..."
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish

#===============================================================================
# SECTION 15: Start Colima
#===============================================================================
log_info "Starting Colima (Docker runtime)..."
colima start --cpu 4 --memory 8 --disk 60 || log_warning "Colima may need to be started manually"

#===============================================================================
# COMPLETION
#===============================================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                          Setup Complete! 🎉                                ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

log_success "All tools and applications have been installed!"
echo ""
echo "📋 Next Steps:"
echo ""
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo ""
echo "   2. Configure Powerlevel10k theme by running: p10k configure"
echo ""
echo "   3. Add your SSH key to GitHub:"
echo "      cat ~/.ssh/id_ed25519.pub | pbcopy"
echo "      Then paste at: https://github.com/settings/keys"
echo ""
echo "   4. Login to applications:"
echo "      - 1Password"
echo "      - Chrome (for sync)"
echo "      - VSCode (for settings sync)"
echo "      - Notion"
echo "      - Slack, Discord, Telegram"
echo ""
echo "   5. Configure iTerm2:"
echo "      - Set font to 'MesloLGS NF' in Preferences > Profiles > Text"
echo "      - Import your preferred color scheme"
echo ""
echo "   6. Authenticate GitHub CLI:"
echo "      gh auth login"
echo ""
echo "   7. Start Docker (via Colima):"
echo "      colima start"
echo ""
echo "📁 Project directories created:"
echo "   ~/Code/personal"
echo "   ~/Code/work"
echo "   ~/Code/experiments"
echo "   ~/Code/open-source"
echo ""
echo "🔑 Your SSH public key (already copied to clipboard):"
cat ~/.ssh/id_ed25519.pub
echo ""
pbcopy < ~/.ssh/id_ed25519.pub
echo ""
log_success "SSH key copied to clipboard!"
echo ""
