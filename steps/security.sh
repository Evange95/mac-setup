# shellcheck shell=bash
# Needs admin rights. Skipped by default in the work profile, where MDM usually owns these settings.

step_security() {
    # --- Firewall ---
    try sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    try sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

    # --- FileVault ---
    if fdesetup status | grep -q "FileVault is On"; then
        log_success "FileVault is already enabled"
    else
        log_warning "FileVault is not enabled. Enable it in System Settings > Privacy & Security > FileVault"
    fi

    # --- Touch ID for sudo (sudo_local survives macOS updates) ---
    local sudo_local="/etc/pam.d/sudo_local"
    if grep -q "pam_tid.so" "$sudo_local" 2>/dev/null; then
        log_success "Touch ID for sudo already configured"
    else
        echo "auth       sufficient     pam_tid.so" | try sudo tee -a "$sudo_local" > /dev/null
    fi

    # --- Lock Screen ---
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    defaults -currentHost write com.apple.screensaver idleTime -int 300

    # --- Disable auto-login & password hints ---
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    defaults write com.apple.loginwindow RetriesUntilHint -int 0

    # --- Remote Access ---
    sudo systemsetup -f -setremotelogin off 2>/dev/null || true
    sudo systemsetup -setremoteappleevents off 2>/dev/null || true

    # --- Bluetooth & AirDrop ---
    defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false
    defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"

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

    # --- Power: no wake for network access ---
    try sudo pmset -a womp 0

    # --- Privacy ---
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2

    log_success "Security settings applied"
}
