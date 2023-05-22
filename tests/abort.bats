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

  expected_message=$'message line 1\\nmessage line 2';
  check-abort -E "message line 1\nmessage line 2";
  check-abort -- -E "message line 1\nmessage line 2";

  expected_message=$'message line 1\nmessage line 2';
  check-abort "message line 1\nmessage line 2";
  check-abort -E -e "message line 1\nmessage line 2";
  check-abort -- -E -e "message line 1\nmessage line 2";
  check-abort -f "message line 1\nmessage line 2\n";

  expected_message="-a --message --with --leading --dashes";
  check-abort -- -a --message --with --leading --dashes;
}

@test "abort: Skip stack elements" {
  expected_stack_trace=$(stack-trace f1 f2 f3 abort);
  check-abort -0;

  expected_stack_trace=$(stack-trace f1 f2 f3);
  check-abort -1;

  expected_stack_trace=$(stack-trace f1 f2);
  check-abort -2;

  expected_stack_trace=$(stack-trace f1);
  check-abort -3;

  expected_stack_trace="";
  check-abort -4;

  expected_stack_trace=$(stack-trace f1 f2 f3 abort);
  expected_message="abort: Valid skip count range from 0 to 4, found: \"5\".";
  check-abort -5;
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
  message_pattern=$'abort: ZABORT_SIGNAL contains unrecognized signal: "%s"\n'$DEFAULT_MESSAGE;
  local signal;
  for signal in FOO EXIT ERR ZERR DEBUG 0 32 -1 1234567890987654321; do
    printf -v expected_message "$message_pattern" "$signal";
    prelude='ZABORT_SIGNAL='$signal check-abort;
  done;

  printf -v expected_message "$message_pattern" "";
  prelude='ZABORT_SIGNAL=""' check-abort;
  prelude='ZABORT_SIGNAL=()' check-abort;

  printf -v expected_message "$message_pattern" "HUP HUP";
  prelude='ZABORT_SIGNAL=(HUP HUP)' check-abort;
}

@test "abort: Stop PID" {
  prelude='zmodload zsh/system';
  f4_prelude='ZABORT_STOP_PID=$sysparams[pid]';
  for context in $CONTEXTS; do
    context-starts-subshell $context || continue;
    unset ${!expected_*};
    callees=(f1 ctx_paren f2 ctx_paren f3 $context f4 ctx_paren f5 ctx_paren f6);
    if context-ignores-exit-status $context; then
      # The non-zero exit status of the stopped abort is ignored and
      # the calling functions execute normally to their end.
      expected_status=0;
      expected_leave_trace=$(leave-trace f1 ctx_paren f2 ctx_paren f3 $context);
    else
      # The non-zero exit status of the stopped abort triggers the
      # ZERR trap.
      expected_status=1;
      expected_leave_trace=$( \
          echo "Command unexpectedly exited with the non-zero status 1.";
          stack-trace f1 ctx_paren f2 ctx_paren f3 $context TRAPZERR);
    fi;
    check-abort;
  done;
}

@test "abort: Redundant or invalid stop PID" {
  callees=(f1 ctx_paren f2 ctx_paren f3 ctx_paren f4 ctx_paren f5 ctx_paren f6);
  f3_prelude='ZABORT_STOP_PID=$$' check-abort;
  f3_prelude='ZABORT_STOP_PID=1' check-abort;
  f3_prelude='ZABORT_STOP_PID=42' check-abort;
  f3_prelude='ZABORT_STOP_PID=-42' check-abort;
  f3_prelude='ZABORT_STOP_PID=foobar' check-abort;
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
