#!/usr/bin/env bats

. $BATS_TEST_DIRNAME/test-support.bash;

################################################################################
# Function "usage" tests

function check-usage() {
    check usage "$@";
}

@test "usage: Single argument" {
    expected_message="toe: $MESSAGE";
    check-usage $MESSAGE;
}

@test "usage: Top-level call" {
    callers=();
    expected_message="$TEST_FILE: $MESSAGE";
    check-usage $MESSAGE;
}

@test "usage: Explicit misused command" {
    expected_message="toe: $MESSAGE";
    expected_stack_trace=$(stack-trace tic tac toe);
    check-usage -0 $MESSAGE;

    expected_message="tac: $MESSAGE";
    expected_stack_trace=$(stack-trace tic tac);
    check-usage -1 $MESSAGE;

    expected_message="tic: $MESSAGE";
    expected_stack_trace=$(stack-trace tic);
    check-usage -2 $MESSAGE;

    expected_message="$TEST_FILE: $MESSAGE";
    expected_stack_trace=$(stack-trace);
    check-usage -3 $MESSAGE;

    expected_message="usage: Valid command indexes range from 0 to 3, found \"4\".";
    expected_stack_trace=$(stack-trace tic tac toe usage);
    check-usage -4 $MESSAGE;

    expected_message="usage: Valid command indexes range from 0 to 3, found \"42\".";
    expected_stack_trace=$(stack-trace tic tac toe usage);
    check-usage -42 $MESSAGE;
}

@test "usage: Miscellaneous argument combinations" {
    expected_message="toe: message   with   spaces";
    check-usage "message   with   spaces";

    expected_message="toe: --message starting with a dash";
    check-usage -- "--message starting with a dash";

    expected_message="tic: --message starting with a dash";
    expected_stack_trace=$(stack-trace tic);
    check-usage -2 -- "--message starting with a dash";
}

@test "usage: Invalid options" {
    expected_stack_trace=$(stack-trace tic tac toe usage);

    expected_message="usage: Unrecognised option: \"-x\"";
    check-usage -x $MESSAGE;

    expected_message="usage: Unrecognised option: \"--invalid-option\"";
    check-usage --invalid-option $MESSAGE;
}

@test "usage: Invalid messages" {
    expected_stack_trace=$(stack-trace tic tac toe usage);

    expected_message="usage: An error message is required.";
    check-usage;

    expected_message="usage: Multiple error messages aren't allowed, found: \"foo\" \"bar\".";
    check-usage foo bar;
    expected_message="usage: Multiple error messages aren't allowed, found: \"\" \"\".";
    check-usage "" "";

    expected_message="usage: The error message may not be empty.";
    check-usage "";
    check-usage "$(printf " \t\n ")";
}

################################################################################
