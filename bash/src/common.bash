
# Colors:
readonly color_bold='\033[0;1m' #(OR USE 31)
readonly color_cyan='\033[0;36m'
readonly color_purple='\033[0;35m'
readonly color_green='\033[0;32m'
readonly color_brown='\033[0;33m'
readonly color_red='\033[1;31m'
readonly color_nc='\033[0m' # No Color

# $1: string, $2: color (optional)
function print() {
    local color="color_${2-"nc"}"
    printf "${!color}%s${color_nc}" "$1"
}

function println() {
    print "$1" "${2-"nc"}"
    echo ""
}

function err_handler() {
    local errNum=$?
    local cmd="$BASH_COMMAND"

    {
        println ""
        print "Error at " cyan
        print "${BASH_SOURCE[1]}" brown
        print ":" cyan
        print "$1 " green
        print "($errNum)" red
        print ": \`" cyan
        print "$cmd" bold
        println "\`" cyan
        println ""

        backtrace
    } >&2

    exit $errNum
}
trap 'err_handler $LINENO ${BASH_LINENO[@]}' ERR

function print_line_no() {
    print "\`" cyan
    print "$(head "$1" -n "$2" | tail -1 | sed -e 's/^[[:space:]]*//' | tr -d '\n')" bold
    println "\`" cyan
}

function backtrace() {
    println "Backtrace: " cyan
    for ((i=${#FUNCNAME[@]}-1; i>=2; i--)); do
        print " $((${#FUNCNAME[@]}-1-i))" red && print ": " cyan
        print "${BASH_SOURCE[$i]}" brown
        print ":" cyan
        print "${BASH_LINENO[$i-1]}" green
        print " within " cyan
        print "${FUNCNAME[$i]}(" purple && print "..." cyan && println ")" purple
        print "     -> " cyan && print_line_no "${BASH_SOURCE[$i]}" ${BASH_LINENO[$i-1]}
    done
}


function error() {
    {
        print "error" red
        print ": "
        println "$1"
        println
    } >&2

    exit "${2-3}"
}

# $1: message, $2: exit code (optional)
function panic() {
    {
        print "error" red
        print ": "
        println "$1"
        println

        backtrace
    } >&2

    exit "${2-3}"
}

function warn() {
    {
        print "warning" brown
        print ": "
        print "$1"
    } >&2
}

function assert_eq() {
    if [[ "$1" != "$2" ]]; then
        s=""
        if [[ $# -gt 2 ]]; then s=": "; fi
        panic "expected '$1' == '$2'${s}${*:3}" 2
    fi
}

# $1: array variable name; $2: function name
function list.map() {
    panic "unimplemented"
}

function string.len() {
    :
}

# $1: a, $2: b
function cmp.max() {
    :
}

################################################################################

function test.common.map.ignore() {
    list.map
}

function test.common.map2.ignore() {
    echo hooray
}

################################################################################

function test.test-lib.smoke() { :; }
function test.test-lib.ignored.ignore() { ouch; }
function test.test-lib.panics.xfail() { panic "whoops"; }

################################################################################
