#!/usr/bin/env bats

. $BATS_TEST_DIRNAME/test-support.bash;

################################################################################
# Error handling tests

function check-error() {
  if ${expected_abort-true}; then
    local expected_stack_trace=${expected_stack_trace-$(stack-trace ${callees[@]} TRAPZERR)};
  fi;
  check "$@";
}

function prepend-caller() {
  local message=$1 caller=${2-${callees[-1]}};
  [[ $caller != ctx_eval ]] || caller="(eval):1";
  echo "$caller: $message";
}

function unexpected-error-message() {
  local exit_status=$1;
  echo "Command unexpectedly exited with the non-zero status $exit_status.";
}

function errmsg-unknown-command() {
  prepend-caller "command not found: $UNKNOWN_COMMAND" "$@";
}

function errmsg-non-existent-file() {
  prepend-caller "no such file or directory: $NON_EXISTENT_FILE" "$@";
}

function errmsg-undefined-variable() {
  prepend-caller "$UNDEFINED_VARIABLE: parameter not set" "$@";
}

function errmsg-bad-substitution() {
  prepend-caller "bad substitution" "$@";
}

function errmsg-bad-flag() {
  prepend-caller "error in flags" "$@";
}

@test "External command triggers ZERR trap" {
  expected_message=$(unexpected-error-message 1);
  check-error grep foo /dev/null;
}

@test "Builtin false triggers ZERR trap" {
  expected_message=$(unexpected-error-message 1);
  check-error false;
}

@test "Builtin return triggers ZERR trap" {
  expected_message=$(unexpected-error-message 42);
  check-error return 42;
}

@test "Unknown command triggers ZERR trap" {
  expected_message=$(errmsg-unknown-command; unexpected-error-message 127);
  check-error $UNKNOWN_COMMAND;
}

@test "Non-existent file triggers ZERR trap" {
  expected_message=$(errmsg-non-existent-file ${callees[-1]}:source; unexpected-error-message 127);
  check-error source $NON_EXISTENT_FILE;

  prelude='read-file() cat <$1';
  expected_message=$(errmsg-non-existent-file read-file; unexpected-error-message 1);
  expected_stack_trace=$(stack-trace ${callees[@]} read-file TRAPZERR);
  check-error read-file $NON_EXISTENT_FILE;
}

@test "ZERR trap is triggered in all non-condition contexts" {
  for context in $CONTEXTS; do
    ! context-is-condition $context || continue;
    callees=(f1 f2 $context f3);

    expected_message=$(unexpected-error-message 1);
    check-error grep foo /dev/null;
    check-error false;

    expected_message=$(unexpected-error-message 42);
    check-error return 42;

    expected_message=$(errmsg-unknown-command; unexpected-error-message 127);
    check-error $UNKNOWN_COMMAND;

    expected_message=$(errmsg-non-existent-file ${callees[-1]}:source; unexpected-error-message 127);
    check-error source $NON_EXISTENT_FILE;
  done;
}

@test "ZERR trap is triggered in all non-condition context combinations" {
  expected_message=$(unexpected-error-message 1);
  for context1 in $CONTEXTS; do
    ! context-is-condition $context1 || continue;
    for context2 in $CONTEXTS; do
      ! context-is-condition $context2 || continue;
      callees=(f1 $context1 f2 $context2 f3);
      check-error false;
    done;
  done;
}

@test "ZERR trap isn't triggered in any condition contexts" {
  expected_abort=false;
  for context in $CONTEXTS; do
    context-is-condition $context || continue;
    callees=(f1 f2 $context f3);
    check-error false;
  done;
}

@test "ZERR trap isn't triggered in any condition context combinations" {
  expected_abort=false;
  for context1 in $CONTEXTS; do
    for context2 in $CONTEXTS; do
      context-is-condition $context1 || context-is-condition $context2 || continue;
      callees=(f1 $context1 f2 $context2 f3);
      check-error false;
    done;
  done;
}

@test "Builtin exit doesn't tigger ZERR trap" {
  expected_abort=false;
  expected_status=42;
  expected_leave_trace="";
  check-error exit 42;
}

@test "Builtin exit triggers ZERR trap in parent shells that listen to subshell exit status" {
  for context in $CONTEXTS; do
    unset ${!expected_*};
    callees=(f1 f2 $context f3);
    if ! context-starts-subshell $context; then
      # The shell exits with the specified status.
      expected_abort=false;
      expected_status=42;
      expected_leave_trace="";
    elif context-ignores-exit-status $context; then
      # The parent shell ignores the non-zero exit status.
      expected_abort=false;
      expected_leave_trace=$(leave-trace f1 f2 $context);
    else
      # The parent shell triggers abort.
      expected_stack_trace=$(stack-trace f1 f2 $context TRAPZERR);
      expected_message=$(unexpected-error-message 42);
    fi;
    check-error exit 42;
  done;
}

@test "Expansion errors trigger shell exit but not ZERR trap" {
  # TODO: Fix zsh to trigger the ZERR trap on expansion errors.
  expected_abort=false;
  expected_status=1;
  expected_leave_trace="";

  prelude='undefined-variable() { : ${'$UNDEFINED_VARIABLE'}; }';
  expected_message="$(errmsg-undefined-variable undefined-variable)";
  check-error undefined-variable;

  prelude='bad-substitution() { : ${]}; }';
  expected_message="$(errmsg-bad-substitution bad-substitution)";
  check-error bad-substitution;

  prelude='bad-flag() { : ${(j)1}; }';
  expected_message="$(errmsg-bad-flag bad-flag)";
  check-error bad-flag;
}

@test "Expansion errors in eval trigger eval exit but not shell exit nor ZERR trap" {
  # TODO: Fix zsh to exit the shell rather than just the eval when an
  # expansion error occurs inside an eval.
  expected_abort=false;

  expected_message="$(errmsg-undefined-variable "(eval):1")";
  check-error eval : '$'$UNDEFINED_VARIABLE;

  expected_message="$(errmsg-bad-substitution "(eval):1")";
  check-error eval : '${]}';

  expected_message="$(errmsg-bad-flag "(eval):1")";
  check-error eval : '${(j)1}';

  callees=(f1 f2 ctx_eval f3);
  expected_leave_trace=$(leave-trace f1 f2 ctx_eval);

  prelude='undefined-variable() { : ${'$UNDEFINED_VARIABLE'}; }';
  expected_message="$(errmsg-undefined-variable undefined-variable)";
  check-error undefined-variable;

  prelude='bad-substitution() { : ${]}; }';
  expected_message="$(errmsg-bad-substitution bad-substitution)";
  check-error bad-substitution;

  prelude='bad-flag() { : ${(j)1}; }';
  expected_message="$(errmsg-bad-flag bad-flag)";
  check-error bad-flag;
}

@test "Undefined variable in printf tiggers ZERR trap" {
  expected_message="$(errmsg-undefined-variable; unexpected-error-message 1)";
  check-error printf -v ignored %d $UNDEFINED_VARIABLE;
}

################################################################################
