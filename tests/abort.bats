#!/usr/bin/env bats

. $BATS_TEST_DIRNAME/test-support.bash;

################################################################################
# Function "abort" tests

function check-abort() {
  local expected_stack_trace=${expected_stack_trace-$(stack-trace ${callees[@]} abort)};
  check abort "$@";
}

@test "abort: No arguments" {
  check-abort;
}

@test "abort: Messages" {
  expected_message="single-word-message";
  check-abort "single-word-message";

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
  expected_stack_trace=$(stack-trace tic tac toe abort);
  check-abort -0;

  expected_stack_trace=$(stack-trace tic tac toe);
  check-abort -1;

  expected_stack_trace=$(stack-trace tic tac);
  check-abort -2;

  expected_stack_trace=$(stack-trace tic);
  check-abort -3;

  expected_stack_trace=$(stack-trace);
  check-abort -4;

  expected_stack_trace=$(stack-trace tic tac toe abort);
  expected_message="abort: Valid skip count range from 0 to 4, found: \"5\".";
  check-abort -5;

  expected_stack_trace=$(stack-trace tic tac toe abort);
  expected_message="abort: Valid skip count range from 0 to 4, found: \"42\".";
  check-abort -42;
}

@test "abort: No stack trace" {
  expected_stack_trace="";
  check-abort -q;
  check-abort --quiet;
}

@test "abort: Explicit signal" {
  expected_status=1;
  prelude='ZABORT_SIGNAL=HUP' check-abort;
  prelude='ZABORT_SIGNAL=HuP' check-abort;
  prelude='ZABORT_SIGNAL=hup' check-abort;
  prelude='ZABORT_SIGNAL=1' check-abort;

  expected_status=130;
  prelude='ZABORT_SIGNAL=INT' check-abort;
  prelude='ZABORT_SIGNAL=2' check-abort;

  expected_status=137;
  prelude='ZABORT_SIGNAL=KILL' check-abort;
  prelude='ZABORT_SIGNAL=9' check-abort;
}

@test "abort: Invalid signal" {
  local signal;
  for signal in FOO EXIT ERR ZERR DEBUG 0 32 -1 1234567890987654321; do
    expected_message=$(
      echo "abort: ZABORT_SIGNAL contains unrecognized signal: \"$signal\"";
      echo "Abort");
    prelude='ZABORT_SIGNAL='$signal check-abort;
  done;

  expected_message=$(
    echo "abort: ZABORT_SIGNAL contains unrecognized signal: \"\"";
    echo "Abort");
  prelude='ZABORT_SIGNAL=""' check-abort;
  prelude='ZABORT_SIGNAL=()' check-abort;

  expected_message=$(
    echo "abort: ZABORT_SIGNAL contains unrecognized signal: \"HUP HUP\"";
    echo "Abort");
  prelude='ZABORT_SIGNAL=(HUP HUP)' check-abort;
}

@test "abort: Invalid options" {
  expected_message="abort: Unrecognised option: \"-x\"";
  check-abort -x;
  check-abort -x "ignored message";

  expected_message="abort: Unrecognised option: \"--invalid\"";
  check-abort --invalid;
  check-abort --invalid "ignored message";
}

@test "abort: Alternate contexts" {
  for context in $CONTEXTS; do
    callees=($context);
    check-abort;
  done;
}

################################################################################
