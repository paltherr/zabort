#!/usr/bin/env bats

. $BATS_TEST_DIRNAME/test-support.bash;

################################################################################
# Error handling tests

function check-error() {
  local expected_stack_trace=${expected_stack_trace-$(stack-trace ${callees[@]} abort)};
  check "$@";
}

function unexpected-error-message() {
  local exit_status=$1;
  echo "Command unexpectedly exited with the non-zero status $exit_status.";
}

function command-not-found-message() {
  local caller=${callees[$((${#callees[@]} - 1))]};
  [[ $caller != ctx_eval ]] || caller="(eval):1";
  echo "$caller: command not found: $UNKNOWN_COMMAND";
}

@test "error: External command triggers abort" {
  expected_message=$(unexpected-error-message 1);
  check-error grep foo /dev/null;
}

@test "error: Builtin false triggers abort" {
  expected_message=$(unexpected-error-message 1);
  check-error false;
}

@test "error: Builtin return triggers abort" {
  expected_message=$(unexpected-error-message 42);
  check-error return 42;
}

@test "error: Command not found triggers abort" {
  expected_message=$(command-not-found-message; unexpected-error-message 127);
  check-error $UNKNOWN_COMMAND;
}

@test "error: Abort is triggered in all non-condition contexts" {
  for context in $CONTEXTS; do
    ! context_command_is_condition $context || continue;
    callees=($context);

    expected_message=$(unexpected-error-message 1);
    check-error grep foo /dev/null;
    check-error false;

    expected_message=$(unexpected-error-message 42);
    check-error return 42;

    expected_message=$(command-not-found-message; unexpected-error-message 127);
    check-error $UNKNOWN_COMMAND;
  done;
}

@test "error: Abort isn't triggered in any condition contexts" {
  expected_status=0;
  expected_stack_trace="";
  for context in $CONTEXTS; do
    context_command_is_condition $context || continue;
    callees=($context);
    check-error grep foo /dev/null;
    check-error false;
  done;
}

@test "error: Abort is triggered in all non-condition context combinations" {
  expected_message=$(unexpected-error-message 1);
  for context1 in $CONTEXTS; do
    ! context_command_is_condition $context1 || continue;
    for context2 in $CONTEXTS; do
      ! context_command_is_condition $context2 || continue;
      callees=($context1 $context2);
      check-error false;
    done;
  done;
}

@test "error: Abort isn't ignored in any condition context combinations" {
  expected_status=0;
  expected_stack_trace="";
  for context1 in $CONTEXTS; do
    for context2 in $CONTEXTS; do
      context_command_is_condition $context1 || context_command_is_condition $context2 || continue;
      callees=($context1 $context2);
      check-error false;
    done;
  done;
}

@test "error: Builtin exit doesn't tigger abort" {
  expected_status=42;
  expected_stack_trace="";
  check-error exit 42;
}

@test "error: Builtin exit in subshell sometimes triggers abort in parent shell" {
  for context in $CONTEXTS; do (
    callees=($context);
    if ! context_starts_subshell $context; then
      # The shell exits with the specified status.
      expected_status=42;
      expected_stack_trace="";
    elif ! context_status_is_ignored $context; then
      # The parent shell triggers abort.
      expected_status=1;
      expected_message=$(unexpected-error-message 42);
    else
      # The parent shell ignores the error.
      expected_status=0;
      expected_stack_trace="";
    fi;
    check-error exit 42;
  ) done;
}

@test "error: Undefined variable doesn't tigger abort" {
  # TODO: Fix zsh to trigger the ZERR trap on undefined variable
  # reads.
  expected_status=1;
  expected_message="error-undefinded-variable: undefined: parameter not set";
  expected_stack_trace="";
  check-error error-undefinded-variable;
}

@test "error: Undefined variable in subshell sometimes tiggers abort in parent shell" {
  for context in $CONTEXTS; do (
    callees=($context);
    expected_message="error-undefinded-variable: undefined: parameter not set";
    if [[ $context = ctx_eval ]]; then
      # The shell prints an error but fails to exit.
      #
      # TODO: Fix zsh to always exit on undefined variable reads.
      expected_status=0;
      expected_stack_trace="";
    elif ! context_starts_subshell $context; then
      # The shell exits with status 1.
      expected_status=1;
      expected_stack_trace="";
    elif ! context_status_is_ignored $context; then
      # The parent shell triggers abort.
      expected_status=1;
      expected_message+=$(echo; unexpected-error-message 1);
    else
      # The parent shell ignores the error.
      expected_status=0;
      expected_stack_trace="";
    fi;
    check-error error-undefinded-variable;
  ) done;
}

################################################################################
