# shellcheck shell=bash

_tool_version() {
    case "$1" in
        go) go version ;;
        *) "$1" --version ;;
    esac 2>&1 | head -1
}

step_verify() {
    local tools=(git mise node pnpm bun go golangci-lint python uv ruff docker delta starship zoxide code claude)
    [[ "$PROFILE" == "personal" ]] && tools+=(rustc xelatex latexmk)

    local cmd pass=0 fail=0
    for cmd in "${tools[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_success "$cmd: $(_tool_version "$cmd")"
            pass=$((pass + 1))
        else
            log_warning "$cmd: NOT FOUND"
            fail=$((fail + 1))
        fi
    done

    log_info "Verified: $pass passed, $fail missing"
}
