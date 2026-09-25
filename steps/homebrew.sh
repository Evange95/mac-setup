# shellcheck shell=bash

step_homebrew() {
    if command -v brew &>/dev/null; then
        log_success "Homebrew already installed"
    else
        # Needs admin rights to create the Homebrew prefix. On a managed Mac, ask IT first.
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        load_session_env
    fi

    brew update
}
