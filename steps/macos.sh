# shellcheck shell=bash
# User-level preferences only (no sudo), safe on managed Macs.

step_macos() {
    # Dark Mode
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

    # Finder: hidden files, extensions, path bar, status bar, no extension-change warning
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Enable snap-to-grid for icons
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    # Keyboard: fast key repeat
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Trackpad: tap to click (built-in and Magic Trackpad; -currentHost covers the login screen)
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Dock
    defaults write com.apple.dock tilesize -int 54

    # Save screenshots to Downloads
    defaults write com.apple.screencapture location -string "$HOME/Downloads"

    # Secure keyboard entry in terminals
    defaults write com.apple.terminal SecureKeyboardEntry -bool true
    defaults write com.googlecode.iterm2 "Secure Input" -bool true

    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
    log_success "macOS preferences applied"
}
