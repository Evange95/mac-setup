# shellcheck shell=bash

step_xcode() {
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
    else
        xcode-select --install
        log_warning "Please complete the Xcode installation popup, then press Enter to continue..."
        read -r
    fi
}
