#!/usr/bin/env bash

src="$(dirname "$0")/src/gameboy.bash"
readonly src

# shellcheck disable=SC1090
source "${src}"

# $1: test function name
function run_test() {
    local testname="$1"
    local ignored=false
    local should_panic=false

    ## Parse test name and options:
    if [[ "${testname}" =~ ^.*\.ignore$ ]]; then
        testname=$(rev <<<"${testname}"| cut -d'.' -f2- | rev)
        ignored=true
    fi

    if [[ "${testname}" =~ ^.*\.xpanic$ ]]; then
        testname=$(rev <<<"${testname}"| cut -d'.' -f2- | rev)
        should_panic=true
    fi


    printf "    %-${max_test_name_len}s ... " "$testname"
    if [[ $ignored = true ]]; then
        println "ignored" brown
        return 0
    fi

    ## Run in a subprocess:
    prelude=":"
    if [[ -n $DEBUG ]]; then
        prelude="set -x"
    fi

    output=$(bash -c "source \"${src}\"; $prelude; $1" 2>&1)
    ec=$?

    if [[ $ec == "${ASSERTION_FAILED_EXIT_CODE}" ]] ||
       [[ $should_panic == false && $ec != 0 ]] ||
       [[ $should_panic == true && $ec == 0 ]];
    then
        print "failed" red
        print " (";
            if [[ $ec == "${ASSERTION_FAILED_EXIT_CODE}" ]]; then
                print "assertion failed" purple
            elif [[ $should_panic == true ]]; then
                print "expected non-zero exit" purple
            else
                print "$ec" red;
            fi
        println ")"
        println

        print "      Output" bold
        println ":"
        while IFS= read -r line; do
            print "      | "
            echo "$line"
        done <<<"$output"
        println

        ec=1
    else
        print "passed" green
        if [[ $should_panic == true ]]; then
            print " ("
            print "panicked as expected" purple
            print ": "
            print "$ec" bold
            print ")"
        fi
        println

        ec=0
    fi

    return $ec
}

declare max_test_name_len=0
function update_name_len() {
    local testname=$2
    local len=${#2}

    if [[ $len -gt $max_test_name_len ]]; then max_test_name_len=$len; fi
}

mapfile -t -c 1 -C update_name_len tests <<<"$(
    declare -F \
        | cut -d' ' -f3 \
        | grep '^test.*'
)"
num_tests=${#tests[@]}
if [[ $num_tests = 1 ]] && [[ "${tests[0]}" == $'\n' ]]; then
    num_tests=0
fi

println "Running $(print ${num_tests} purple) test$([ ${num_tests} != 1 ] && echo -n "s"):"
if [[ $num_tests = 0 ]]; then exit 0; fi

failure_count=0
start=$(date +%s)
for testname in "${tests[@]}"; do
    run_test "${testname}" || { ((failure_count += 1)); }
done
end=$(date +%s)

if [[ $failure_count != 0 ]]; then
    println
    print "$failure_count" red
    print " out of " bold
    print "$num_tests" cyan
    print " failed; see above." bold
    println ""
    exit 3
else
    println
    print "All tests passed in $((end - start)) seconds." bold
    println
fi

# Note: we could actually measure line based test coverage by setting a `DEBUG`
# trap that records line num and source.

# TODO: running tests in parallel. Need to have a lock for printing outputs so
# that they are not interleaved.

# TODO: allow specifying a test filter
