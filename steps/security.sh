# shellcheck shell=bash
# Needs admin rights. Skipped by default in the work profile, where MDM usually owns these settings.
# Each setting is applied only if its probe (lib/probes.sh) fails, then re-checked, so a
# change macOS silently refuses shows up as a warning. The audit step reports the final state.

# _ensure <probe> <label> <hint if still failing> <command...>
_ensure() {
    local probe="$1" label="$2" hint="$3"
    shift 3
    if "$probe" &>/dev/null; then
        log_success "$label: already set"
        return 0
    fi
    "$@" || true
    if "$probe" &>/dev/null; then
        log_success "$label: applied"
    else
        log_warning "$label: could not be applied — $hint"
    fi
}

step_security() {
    _ensure firewall_ok "Firewall" "enable in System Settings > Network > Firewall" \
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    _ensure stealth_ok "Firewall stealth mode" "enable in Firewall > Options" \
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    _ensure gatekeeper_ok "Gatekeeper" "run: sudo spctl --global-enable" \
        sudo spctl --global-enable

    # Touch ID for sudo (sudo_local survives macOS updates)
    _ensure touchid_sudo_ok "Touch ID for sudo" "add 'auth sufficient pam_tid.so' to /etc/pam.d/sudo_local" \
        sudo sh -c 'echo "auth       sufficient     pam_tid.so" >> /etc/pam.d/sudo_local'

    # Screen lock: the old com.apple.screensaver defaults are ignored by current macOS
    if ! screen_lock_ok &>/dev/null; then
        log_info "Setting screen lock to immediate (enter your login password)..."
    fi
    _ensure screen_lock_ok "Password immediately after sleep" "set it in System Settings > Lock Screen" \
        sysadminctl -screenLock immediate -password -

    # systemsetup needs Full Disk Access for the terminal app; without it, it fails quietly
    _ensure remote_login_off "Remote login (SSH) off" \
        "grant Full Disk Access to your terminal, or disable in System Settings > General > Sharing" \
        sudo systemsetup -f -setremotelogin off
    try sudo systemsetup -setremoteappleevents off &>/dev/null

    # Automatic updates live in the system domain (writing the user domain has no effect)
    _ensure auto_updates_ok "Automatic updates" "enable in System Settings > General > Software Update" \
        _enable_auto_updates

    # FileVault can't be enabled unattended (recovery key must be shown to the user)
    if ! filevault_ok &>/dev/null; then
        log_warning "FileVault is off. Enable it in System Settings > Privacy & Security > FileVault"
    fi

    # Disable auto-login and password hints
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    defaults write com.apple.loginwindow RetriesUntilHint -int 0

    # Bluetooth sharing off, AirDrop limited to contacts
    defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false
    defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"

    # No wake for network access
    try sudo pmset -a womp 0

    # Privacy
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
}

_enable_auto_updates() {
    local key
    for key in AutomaticCheckEnabled AutomaticDownload AutomaticallyInstallMacOSUpdates CriticalUpdateInstall ConfigDataInstall; do
        sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate "$key" -bool true
    done
    sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true
}
