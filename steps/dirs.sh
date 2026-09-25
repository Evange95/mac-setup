# shellcheck shell=bash

step_dirs() {
    mkdir -p "$HOME/Code/personal" "$HOME/Code/work" "$HOME/Code/experiments" "$HOME/Code/open-source"
    log_success "Created ~/Code directory structure"
}
