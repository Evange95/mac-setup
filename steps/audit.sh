# shellcheck shell=bash
# Read-only security report (no sudo). Runs in every profile: on a managed Mac it shows
# what IT already enforces; on a personal Mac it verifies what steps/security.sh applied.

AUDIT_FAILED=0

# audit_check <label> <hint shown on failure> <command...>
audit_check() {
    local label="$1" hint="$2"
    shift 2
    if "$@" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $label"
    else
        echo -e "  ${RED}✗${NC} $label${hint:+ — $hint}"
        AUDIT_FAILED=$((AUDIT_FAILED + 1))
    fi
}

step_audit() {
    log_info "Security status:"
    audit_check "Firewall enabled" "System Settings > Network > Firewall" firewall_ok
    audit_check "Firewall stealth mode" "System Settings > Network > Firewall > Options" stealth_ok
    audit_check "FileVault" "System Settings > Privacy & Security > FileVault" filevault_ok
    audit_check "System Integrity Protection" "re-enable from Recovery: csrutil enable" sip_ok
    audit_check "Gatekeeper" "sudo spctl --global-enable" gatekeeper_ok
    audit_check "Screen lock within 5s" "System Settings > Lock Screen, or: sysadminctl -screenLock immediate -password -" screen_lock_ok
    audit_check "Remote login (SSH) off" "System Settings > General > Sharing > Remote Login" remote_login_off
    audit_check "Automatic macOS updates" "System Settings > General > Software Update > Automatic updates" auto_updates_ok
    audit_check "Touch ID for sudo" "./setup.sh --only security" touchid_sudo_ok
    audit_check "Time Machine backup destination" "System Settings > General > Time Machine" time_machine_ok

    if [[ $AUDIT_FAILED -eq 0 ]]; then
        log_success "All security checks passed"
    else
        log_warning "$AUDIT_FAILED security check(s) need attention (see above)"
    fi
}
