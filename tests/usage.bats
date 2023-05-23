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
  expected_message="usage: Command index out of range 0..3: \"4\"";
  check-usage -4 $TEST_MESSAGE;
  expected_message="usage: Command index out of range 0..3: \"42\"";
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

  expected_message="usage: Unrecognized option: \"-x\"";
  check-usage -x $TEST_MESSAGE;

  expected_message="usage: Unrecognized option: \"--invalid-option\"";
  check-usage --invalid-option $TEST_MESSAGE;
}

@test "Invalid messages" {
  expected_stack_trace=$(stack-trace f1 f2 f3 usage);

  expected_message="usage: A non-empty error message is required.";
  check-usage;
  check-usage "";

  expected_message="usage: A single error message is allowed, found: \"foo\" \"bar\"";
  check-usage foo bar;
  expected_message="usage: A single error message is allowed, found: \"foo\" \"foo bar\" \"bar\"";
  check-usage foo "foo bar" bar;
  expected_message="usage: A single error message is allowed, found: \"\" \"\"";
  check-usage "" "";

  expected_message="usage: The error message cannot be whitespace only, found: \" \"";
  check-usage " ";
  expected_message="usage: The error message cannot be whitespace only, found: \" "$'\t\n'" \"";
  check-usage $' \t\n ';
}

################################################################################
