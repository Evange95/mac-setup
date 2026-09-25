# shellcheck shell=bash
# Read-only checks of macOS security state (no sudo). Used by steps/audit.sh and steps/security.sh.

firewall_ok() { /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; }
stealth_ok() { /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | grep -qE "is on|enabled"; }
filevault_ok() { fdesetup status | grep -q "FileVault is On"; }
sip_ok() { csrutil status | grep -q "enabled"; }
gatekeeper_ok() { spctl --status | grep -q "assessments enabled"; }
touchid_sudo_ok() { grep -q "pam_tid.so" /etc/pam.d/sudo_local; }
remote_login_off() { ! launchctl print system/com.openssh.sshd; }
time_machine_ok() { ! tmutil destinationinfo 2>&1 | grep -q "No destinations"; }
auto_updates_ok() { [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null)" == "1" ]]; }

# Password required at most 5 seconds after sleep/screensaver
screen_lock_ok() {
    local status
    status="$(sysadminctl -screenLock status 2>&1)"
    [[ "$status" == *"delay is immediate"* ]] && return 0
    local seconds
    seconds="$(echo "$status" | sed -n 's/.*delay is \([0-9][0-9]*\) seconds.*/\1/p')"
    [[ -n "$seconds" && "$seconds" -le 5 ]]
}
