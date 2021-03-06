###################################################-*- mode: shell-script -*-###

set -eu

################################################################################
# Test setup

function setup_file() {
    export MESSAGE="a-simple-test-message";
    export UNKNOWN_COMMAND="unknown-command";
    export TEST_FILE=tests/test-runner.zsh;
    export CONTEXTS=$(grep -o 'ctx[_0-9A-Za-z]\+' $TEST_FILE);

    export TRACE_top=$($TEST_FILE eval echo '$funcfiletrace[1]');
    local f;
    for f in tic tac toe $CONTEXTS; do
        export TRACE_$f=$($TEST_FILE eval "exec 3>&1; $f eval echo '\$funcfiletrace[1]' '1>&3'");
    done;
}

function setup() {
    load '/usr/local/lib/bats-support/load.bash';
    load '/usr/local/lib/bats-assert/load.bash';
    callers=(tic tac toe);
}

################################################################################
# Helper functions

function context_starts_subshell() {
    local context=$1; shift 1;
    grep -q "$context.*@subshell" $TEST_FILE;
}

function context_status_is_ignored() {
    local context=$1; shift 1;
    grep -q "$context.*@ignored" $TEST_FILE;
}

function context_command_is_condition() {
    local context=$1; shift 1;
    grep -q "$context.*@condition" $TEST_FILE;
}

function enter-trace() {
    function rec() {
        local lvl=$1; shift 1;
        local fun=$1; shift 1;
        printf "Lvl%02i Enter %s\n" $lvl $fun;
        if [[ $# -gt 0 ]]; then
            if [[ $fun = ctx_eval ]]; then
                rec $(($lvl + 2)) "$@";
            else
                rec $(($lvl + 1)) "$@";
            fi;
        fi;
    }
    if [[ $# -gt 0 ]]; then
        rec 1 "$@";
    fi;
}

function leave-trace() {
    function rec() {
        local lvl=$1; shift 1;
        local fun=$1; shift 1;
        if [[ $# -gt 0 ]]; then
            if [[ $fun = ctx_eval ]]; then
                rec $(($lvl + 2)) "$@";
            else
                rec $(($lvl + 1)) "$@";
            fi;
        fi;
        printf "Lvl%02i Leave %s\n" $lvl $fun;
    }
    if [[ $# -gt 0 ]]; then
        rec 1 "$@";
    fi;
}

function stack-trace() {
    function rec() {
        local ctx=$1; shift 1;
        local fun=$1; shift 1;
        [[ $# -gt 0 ]] && rec "$fun" "$@";
        eval echo "\"at \$TRACE_$ctx($fun)\"";
        # The builtin "eval" adds an extra stack frame.
        if [[ $ctx = ctx_eval ]]; then
            eval echo "\"at \$TRACE_$ctx((eval))\"";
        fi;
    }
    if [[ $# -gt 0 ]]; then
        rec "top" "$@";
    fi;
}

function check() {
    local command=( "${callers[@]}" "$@" );
    echo "# Testing: $TEST_FILE ${command[@]}";

    if [ -z ${expected_failure+x} ]; then
        local expected_failure=1;
    fi;

    if [ -z ${expected_enter_trace+x} ]; then
        local expected_enter_trace=$(enter-trace ${callers[@]});
    fi;

    if [ -z ${expected_leave_trace+x} ]; then
     if [ $expected_failure -eq 0 ]; then
         local expected_leave_trace=$(leave-trace ${callers[@]});
     else
         local expected_leave_trace="";
     fi;
    fi;

    if [ -z ${expected_stack_trace+x} ]; then
        case $BATS_TEST_NAME in
            test_abort-* ) local expected_stack_trace=$(stack-trace ${callers[@]} abort);;
            test_usage-* ) local expected_stack_trace=$(stack-trace ${callers[@]});;
            test_error-* ) local expected_stack_trace=$(stack-trace ${callers[@]} abort);;
            *            ) echo "Unrecognised test: $BATS_TEST_NAME" >&2; exit 1;;
        esac
    fi;

    run --separate-stderr $TEST_FILE "${command[@]}";
    if [ $expected_failure -eq 0 ]; then
        assert_success;
    else
        assert_failure $expected_failure;
    fi;
    assert_output "";

    run $TEST_FILE "${command[@]}";
    if [ $expected_failure -eq 0 ]; then
        assert_success;
    else
        assert_failure $expected_failure;
    fi;
    assert_output - <<< $(
        {
            [ -z "$expected_enter_trace" ] || echo "$expected_enter_trace";
            [ -z "${expected_message+x}" ] || echo "$expected_message";
            [ -z "$expected_stack_trace" ] || echo "$expected_stack_trace";
            [ -z "$expected_leave_trace" ] || echo "$expected_leave_trace";
        });

}

################################################################################
