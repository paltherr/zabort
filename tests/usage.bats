#!/usr/bin/env bats

. $BATS_TEST_DIRNAME/test-support.bash;

################################################################################
# Function "usage" tests

function check-usage() {
  check usage "$@";
}

@test "Single argument" {
  expected_message="f3: $TEST_MESSAGE";
  check-usage $TEST_MESSAGE;
}

@test "Top-level call" {
  callees=();
  expected_message="$TEST_FILE: $TEST_MESSAGE";
  check-usage $TEST_MESSAGE;
}

@test "Explicit misused command" {
  expected_stack_trace=$(stack-trace f1 f2 f3);
  expected_message="f3: $TEST_MESSAGE";
  check-usage -0 $TEST_MESSAGE;

  expected_stack_trace=$(stack-trace f1 f2);
  expected_message="f2: $TEST_MESSAGE";
  check-usage -1 $TEST_MESSAGE;

  expected_stack_trace=$(stack-trace f1);
  expected_message="f1: $TEST_MESSAGE";
  check-usage -2 $TEST_MESSAGE;

  expected_stack_trace="";
  expected_message="$TEST_FILE: $TEST_MESSAGE";
  check-usage -3 $TEST_MESSAGE;

  expected_stack_trace=$(stack-trace f1 f2 f3 usage);
  expected_message="usage: Valid command indexes range from 0 to 3, found \"4\".";
  check-usage -4 $TEST_MESSAGE;
  expected_message="usage: Valid command indexes range from 0 to 3, found \"42\".";
  check-usage -42 $TEST_MESSAGE;
}

@test "Miscellaneous argument combinations" {
  expected_message="f3: message   with   spaces";
  check-usage "message   with   spaces";

  expected_message="f3: --message starting with a dash";
  check-usage -- "--message starting with a dash";

  expected_message="f1: --message starting with a dash";
  expected_stack_trace=$(stack-trace f1);
  check-usage -2 -- "--message starting with a dash";
}

@test "Invalid options" {
  expected_stack_trace=$(stack-trace f1 f2 f3 usage);

  expected_message="usage: Unrecognised option: \"-x\"";
  check-usage -x $TEST_MESSAGE;

  expected_message="usage: Unrecognised option: \"--invalid-option\"";
  check-usage --invalid-option $TEST_MESSAGE;
}

@test "Invalid messages" {
  expected_stack_trace=$(stack-trace f1 f2 f3 usage);

  expected_message="usage: An error message is required.";
  check-usage;

  expected_message="usage: Multiple error messages aren't allowed, found: \"foo\" \"bar\".";
  check-usage foo bar;
  expected_message="usage: Multiple error messages aren't allowed, found: \"\" \"\".";
  check-usage "" "";

  expected_message="usage: The error message may not be empty.";
  check-usage "";
  check-usage $' \t\n ';
}

################################################################################
