
function usage() {
    cat <<EOF

EOF
}

function parse_args() {
    local positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            *)
                positional+=("$1")
                ;;
        esac
    done

    case ${#positional[@]} in
        0)
    esac
}
