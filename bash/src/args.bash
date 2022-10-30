
function usage() {
    cat <<EOF

EOF
}

declare -A args

# defaults:
args[headless]=false
args[silent]=false
args[debug_cpu]=false
args[debug_gpu]=false
args[debug_apu]=false
args[debug_ram]=false
args[profile]=0
args[turbo]=false

function parse_args() {
    local positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;

            -H|--headless)  args[headless]=true  ;;
            -S|--silent)    args[silent]=true    ;;
            -c|--debug_cpu) args[debug_cpu]=true ;;
            -g|--debug_gpu) args[debug_gpu]=true ;;
            -a|--debug_apu) args[debug_apu]=true ;;
            -r|--debug_ram) args[debug_ram]=true ;;
            -t|--turbo)     args[turbo]=true     ;;

            -p|--profile)
                shift
                local flag=$1
                if [[ $# = 0 ]]; then
                    usage; println
                    error "$flag requires an argument; see usage (above)"
                fi
                args[profile]=$1
            ;;

            *) positional+=("$1") ;;
        esac
    done

    case ${#positional[@]} in
        1)
            args[rom]="${positional[1]}";
            if ! [[ -f "${args[rom]}" ]]; then
                error "rom path '${args[rom]}' does not seem to exist!" 6
            fi
            ;;
        0) usage; println; error "missing path to the ROM (.gb file); see usage (above)" 4 ;;
        *) usage; println; error "too many positional arguments; see usage (above)" 5 ;;
    esac
}

# $1: arg name
function arg() {
    if ! [[ -v args["$1"] ]]; then
        error "arg '$1' is not present" 7
    else
        echo "${args[$1]}"
    fi
}

###############################################################################

