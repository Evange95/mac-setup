# shellcheck shell=bash
# Memory and privacy settings for Firefox. No sudo: policies are user defaults, and
# user.js lives in the profile.

FIREFOX_PROFILES="${FIREFOX_PROFILES:-$HOME/Library/Application Support/Firefox/Profiles}"

# user.js is read by Firefox and never written, so it is linked like the other dotfiles
link_firefox_prefs() {
    local profile linked=0
    for profile in "$FIREFOX_PROFILES"/*/; do
        # A real profile has prefs.js; skip anything else that lives in the folder
        [[ -f "${profile}prefs.js" ]] || continue
        link_file "$SCRIPT_DIR/config/firefox/user.js" "${profile}user.js"
        linked=$((linked + 1))
    done
    if [[ $linked -eq 0 ]]; then
        log_info "No Firefox profile yet: open Firefox once, then rerun ./setup.sh --only firefox"
    else
        log_success "Firefox preferences linked into $linked profile(s); restart Firefox to apply"
    fi
}

step_firefox() {
    # No telemetry or studies (enterprise policies read from the user defaults)
    defaults write org.mozilla.firefox EnterprisePoliciesEnabled -bool true
    defaults write org.mozilla.firefox DisableTelemetry -bool true
    defaults write org.mozilla.firefox DisableFirefoxStudies -bool true

    link_firefox_prefs
}
