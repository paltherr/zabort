#!/usr/bin/env bats

. $BATS_TEST_DIRNAME/test-support.bash;

################################################################################
# Function "abort" tests

function check-abort() {
  check abort "$@";
}

@test "abort: No arguments" {
  expected_message="Abort";
  check-abort;
}

@test "abort: Messages" {
  expected_message=$MESSAGE;
  check-abort $MESSAGE;

  expected_message="message   with   spaces";
  check-abort "message   with   spaces";

  expected_message="message with multiple   parts";
  check-abort "message"   "with"   "multiple   parts";

  expected_message="formatted message with placeholders: \"foo  \" 042";
  check-abort -f "formatted message with placeholders: \"%-5s\" %03i\n" foo 42;

  expected_message="formatted message with placeholders: \"     \"  +42";
  check-abort --printf "formatted message with placeholders: \"%5s\" %+4i\n" "" 42;

  expected_message="message line 1\nmessage line 2";
  check-abort -E "message line 1\nmessage line 2";
  check-abort -- -E "message line 1\nmessage line 2";

  expected_message=$(echo "message line 1"; echo "message line 2");
  check-abort "message line 1\nmessage line 2";
  check-abort -E -e "message line 1\nmessage line 2";
  check-abort -- -E -e "message line 1\nmessage line 2";
  check-abort -f "message line 1\nmessage line 2\n";

  expected_message="-a --message --with --leading --dashes";
  check-abort -- -a --message --with --leading --dashes;
}

@test "abort: Skip stack elements" {
  expected_message=$MESSAGE;

  expected_stack_trace=$(stack-trace tic tac toe abort);
  check-abort -0 $MESSAGE

  expected_stack_trace=$(stack-trace tic tac toe);
  check-abort -1 $MESSAGE

  expected_stack_trace=$(stack-trace tic tac);
  check-abort -2 $MESSAGE

  expected_stack_trace=$(stack-trace tic);
  check-abort -3 $MESSAGE

  expected_stack_trace=$(stack-trace);
  check-abort -4 $MESSAGE

  expected_stack_trace=$(stack-trace tic tac toe abort);
  expected_message="abort: Valid skip count range from 0 to 4, found: \"5\".";
  check-abort -5 $MESSAGE

  expected_stack_trace=$(stack-trace tic tac toe abort);
  expected_message="abort: Valid skip count range from 0 to 4, found: \"42\".";
  check-abort -42 $MESSAGE
}

@test "abort: No stack trace" {
  expected_message=$MESSAGE;
  expected_stack_trace=$(stack-trace);
  check-abort -q $MESSAGE
  check-abort --quiet $MESSAGE
}

@test "abort: Explicit signal" {
  expected_message=$MESSAGE;

  expected_failure=1
  env=(ZABORT_SIGNAL=HUP); check-abort $MESSAGE
  env=(ZABORT_SIGNAL=HuP); check-abort $MESSAGE
  env=(ZABORT_SIGNAL=hup); check-abort $MESSAGE
  env=(ZABORT_SIGNAL=1); check-abort $MESSAGE

  expected_failure=130
  env=(ZABORT_SIGNAL=INT); check-abort $MESSAGE
  env=(ZABORT_SIGNAL=2); check-abort $MESSAGE

  expected_failure=137
  env=(ZABORT_SIGNAL=KILL); check-abort $MESSAGE
  env=(ZABORT_SIGNAL=9); check-abort $MESSAGE
}

@test "abort: Invalid signal" {
  local signal;
  for signal in FOO EXIT ERR ZERR DEBUG 0 32 -1 1234567890987654321; do
    expected_message=$(
      echo "abort: ZABORT_SIGNAL contains unrecognized signal: \"$signal\"";
      echo $MESSAGE);
    env=("ZABORT_SIGNAL=$signal"); check-abort $MESSAGE;
  done;

  expected_message=$(
    echo "abort: ZABORT_SIGNAL contains unrecognized signal: \"\"";
    echo $MESSAGE);
  env=("ZABORT_SIGNAL=\"\""); check-abort $MESSAGE;
  env=("ZABORT_SIGNAL=()"); check-abort $MESSAGE;

  expected_message=$(
    echo "abort: ZABORT_SIGNAL contains unrecognized signal: \"HUP HUP\"";
    echo $MESSAGE);
  env=("ZABORT_SIGNAL=(HUP HUP)"); check-abort $MESSAGE;
}

@test "abort: Invalid options" {
  expected_stack_trace=$(stack-trace tic tac toe abort);

  expected_message="abort: Unrecognised option: \"-x\"";
  check-abort -x $MESSAGE

  expected_message="abort: Unrecognised option: \"--invalid\"";
  check-abort --invalid $MESSAGE
}

@test "abort: Alternate contexts" {
  expected_message=$MESSAGE;
  for context in $CONTEXTS; do
    callers=($context);
    check-abort $MESSAGE;
  done;
}

################################################################################
