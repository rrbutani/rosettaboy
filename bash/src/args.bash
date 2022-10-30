
function usage() {
    cat <<EOF
rosettaboy-bash ${rosettaboy_version-"0.0.0"}

$(print USAGE brown):
    ${rosettaboy_exe-"rosettaboy-bash"} [OPTIONS] <ROM>

$(print ARGS brown):
    $(print "<ROM>" green)     Path to a .gb file

$(print OPTIONS brown):
    $(print "-a" green), $(print "--debug-apu" green)            Debug APU
    $(print "-c" green), $(print "--debug-cpu" green)            Debug CPU
    $(print "-g" green), $(print "--debug-gpu" green)            Debug GPU
    $(print "-h" green), $(print "--help" green)                 Print help information
    $(print "-H" green), $(print "--headless" green)             Disable GUI
    $(print "-p" green), $(print "--profile <PROFILE>" green)    Exit after N frames [default: 0]
    $(print "-r" green), $(print "--debug-ram" green)            Debug RAM
    $(print "-S" green), $(print "--silent" green)               Disable Sound
    $(print "-t" green), $(print "--turbo" green)                No sleep()
    $(print "-V" green), $(print "--version" green)              Print version information
EOF
}

declare -Ag rb_args

# defaults:
rb_args[headless]=false
rb_args[silent]=false
rb_args[debug_cpu]=false
rb_args[debug_gpu]=false
rb_args[debug_apu]=false
rb_args[debug_ram]=false
rb_args[profile]=0
rb_args[turbo]=false

function parse_args() {
    local positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;

            -v|--version)
                println "rosettaboy-bash ${rosettaboy_version-"0.0.0"}"
                exit 0
                ;;

            -a|--debug_apu) rb_args[debug_apu]=true ;;
            -c|--debug_cpu) rb_args[debug_cpu]=true ;;
            -g|--debug_gpu) rb_args[debug_gpu]=true ;;
            -H|--headless)  rb_args[headless]=true  ;;
            -r|--debug_ram) rb_args[debug_ram]=true ;;
            -S|--silent)    rb_args[silent]=true    ;;
            -t|--turbo)     rb_args[turbo]=true     ;;

            -p|--profile)
                local flag=$1
                shift
                if [[ $# = 0 ]]; then
                    usage; println
                    error "$flag requires an argument; see usage (above)"
                fi
                rb_args[profile]=$1

                if ! [[ ${rb_args[profile]} =~ ^[0-9]+$ ]] ; then
                    usage; println
                    error "$flag takes a number but '$1' is not a number; see usage (above)"
                fi
            ;;

            -*)
                usage; println; error "unrecognized option: '$1'" 8 ;;

            *) positional+=("$1") ;;
        esac
        shift
    done

    case ${#positional[@]} in
        1)
            rb_args[rom]="${positional[0]}"
            if ! [[ -f "${rb_args[rom]}" ]]; then
                error "rom path '${rb_args[rom]}' does not seem to exist!" 6
            fi
            ;;
        0) usage; println; error "missing path to the ROM (.gb file); see usage (above)" 4 ;;
        *) usage; println; error "too many positional arguments; see usage (above)" 5 ;;
    esac
}

# $1: arg name
function arg() {
    if ! [[ -v rb_args["$1"] ]]; then
        error "arg '$1' is not present" 7
    else
        echo "${rb_args[$1]}"
    fi
}

###############################################################################

v=$rosettaboy_version
test.args.version() { parse_args "--version" | assert.matches "${v}"; }
test.args.version-short() { parse_args "-v" | assert.matches "${v}"; }

test.args.unknown-arg.xpanic() { parse_args "--huh" |& assert.matches "unrecognized option"; }
test.args.missing-rom.xpanic() { parse_args |& assert.matches "missing path to the ROM"; }
test.args.multiple-rom-paths.xpanic() { parse_args one two |& assert.matches "too many positional arguments"; }
test.args.rom-path-does-not-exist.xpanic() {
    parse_args "/oops/not/a/real/file.gb" |&
        assert.matches "rom path '/oops/not/a/real/file.gb' does not seem to exist"
}
test.args.normal-rom-path() {
    parse_args "${BASH_SOURCE[0]}"

    assert.eq "$(arg rom)" "${BASH_SOURCE[0]}"
}

test.args.query-unknown-arg.xpanic() {
    arg "huh" |& assert.matches "arg 'huh' is not present"
}

test.args.boolean-flags() {
    # Test short and long flags:
    parse_args -a "${BASH_SOURCE[0]}" -H -S -c

    assert.t "$(arg headless)"
    assert.t "$(arg silent)"
    assert.t "$(arg debug_cpu)"
    assert.f "$(arg debug_gpu)"
    assert.t "$(arg debug_apu)"
    assert.f "$(arg debug_ram)"
    assert.f "$(arg turbo)"
    assert.eq "$(arg profile)" 0
}

test.args.repeated-boolean-flags() {
    parse_args -a -g -t -g -a --debug_apu -r "${BASH_SOURCE[0]}" -t

    assert.f "$(arg headless)"
    assert.f "$(arg silent)"
    assert.f "$(arg debug_cpu)"
    assert.t "$(arg debug_gpu)"
    assert.t "$(arg debug_apu)"
    assert.t "$(arg debug_ram)"
    assert.t "$(arg turbo)"
    assert.eq "$(arg profile)" 0
}

test.args.profile() {
    parse_args -p 100 "${BASH_SOURCE[0]}"
    assert.eq "$(arg profile)" 100
}
test.args.profile-set-multiple-times() {
    parse_args -p 100 "${BASH_SOURCE[0]}" --profile 300
    assert.eq "$(arg profile)" 300
}
test.args.profile-missing-arg.xpanic() {
    parse_args -a --profile |& assert.matches "\--profile requires an argument"
}
test.args.profile-non-numeric.xpanic() {
    parse_args -a -p big |& assert.matches "'big' is not a number"
}
