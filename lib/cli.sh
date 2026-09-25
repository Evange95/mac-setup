# shellcheck shell=bash disable=SC2034,SC2086  # vars are read by setup.sh; step lists are split on purpose
# Argument parsing and step selection. Must stay bash 3.2 compatible (macOS /bin/bash).

# Canonical execution order. Each name maps to steps/<name>.sh defining step_<name>.
ALL_STEPS=(xcode homebrew packages languages shell iterm editors git ssh security macos dirs docker verify)

PROFILES=(personal work)

# Steps a profile leaves out unless explicitly requested with --only
profile_skips() {
    case "$1" in
        work) echo "security" ;;
        *) echo "" ;;
    esac
}

usage() {
    cat << EOF
Usage: ./setup.sh [options]

Options:
  --profile NAME    personal (default) or work. Can also be set as PROFILE in setup.conf
  --only a,b        run only these steps
  --skip a,b        skip these steps
  --dry-run         print the steps that would run, then exit
  -h, --help        show this help

Steps: ${ALL_STEPS[*]}
EOF
}

_contains() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Sets PROFILE, ONLY, SKIP, DRY_RUN. PROFILE keeps any value already set (from setup.conf).
parse_args() {
    PROFILE="${PROFILE:-personal}"
    ONLY=""
    SKIP=""
    DRY_RUN=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile) PROFILE="$2"; shift 2 ;;
            --only) ONLY="$2"; shift 2 ;;
            --skip) SKIP="$2"; shift 2 ;;
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1" >&2; usage >&2; return 1 ;;
        esac
    done

    if ! _contains "$PROFILE" "${PROFILES[@]}"; then
        echo "Unknown profile: $PROFILE (expected: ${PROFILES[*]})" >&2
        return 1
    fi
}

# Prints the selected steps, one per line, in canonical order.
resolve_steps() {
    local requested name
    for requested in ${ONLY//,/ } ${SKIP//,/ }; do
        if ! _contains "$requested" "${ALL_STEPS[@]}"; then
            echo "Unknown step: $requested (expected: ${ALL_STEPS[*]})" >&2
            return 1
        fi
    done

    # shellcheck disable=SC2046
    set -- $(profile_skips "$PROFILE")
    local profile_skip=("$@")

    for name in "${ALL_STEPS[@]}"; do
        if [[ -n "$ONLY" ]]; then
            _contains "$name" ${ONLY//,/ } || continue
        else
            _contains "$name" "${profile_skip[@]}" && continue
        fi
        _contains "$name" ${SKIP//,/ } && continue
        echo "$name"
    done
}
