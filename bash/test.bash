#!/usr/bin/env bash

src="$(dirname "$0")/src/gameboy.bash"
readonly src

# shellcheck disable=SC1090
source "${src}"

# $1: test function name
function run_test() {
    local testname="$1"
    local ignored=false
    local xfail=false

    ## Parse test name and options:
    if [[ "${testname}" =~ ^.*\.ignore$ ]]; then
        testname=$(rev <<<"${testname}"| cut -d'.' -f2- | rev)
        ignored=true
    fi

    if [[ "${testname}" =~ ^.*\.xfail$ ]]; then
        testname=$(rev <<<"${testname}"| cut -d'.' -f2- | rev)
        xfail=true
    fi


    printf "    %-${max_test_name_len}s ... " "$testname"
    if [[ $ignored = true ]]; then
        println "ignored" brown
        return 0
    fi

    ## Run in a subprocess:
    output=$(bash -c "source \"${src}\"; $1" 2>&1)
    ec=$?

    if [[ $xfail == false && $ec != 0 ]] || [[ $xfail == true && $ec == 0 ]]; then
        print "failed" red
        print " (";
            if [[ $xfail == true ]]; then
                print "expected failure" purple
            else
                print "$ec" red;
            fi
        println ")"
        println

        print "      Output" bold
        println ":"
        while read -r line; do
            print "      | "
            echo "$line"
        done <<<"$output"
        println

        ec=1
    else
        print "passed" green
        if [[ $xfail == true ]]; then print " (xfail)" purple; fi
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
