###################################################-*- mode: shell-script -*-###

set -eu;

################################################################################
# Test setup

function setup_file() {
  bats_require_minimum_version 1.5.0;
  export DEFAULT_MESSAGE="Abort";
  export TEST_MESSAGE="a-simple-test-message";
  export UNKNOWN_COMMAND="unknown-command";
  export TEST_FILE=tests/test-runner.zsh;
  export CONTEXTS=$(grep -o 'ctx_\w\+' $TEST_FILE);
  export TRACE_top=$($TEST_FILE '^echo $funcfiletrace[1]');
  local f;
  for f in f{1..3} $CONTEXTS; do
    export TRACE_$f=$($TEST_FILE '^exec 3>&1' $f '^echo $funcfiletrace[1] 1>&3');
  done;
}

function setup() {
  load '/usr/local/lib/bats-support/load.bash';
  load '/usr/local/lib/bats-assert/load.bash';
  callees=(f1 f2 f3);
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
  local -a args=(); local -i index=0 level=1;
  while (($# > 0)); do
    args[index++]=$level; args[index++]=$1;
    [[ $1 != ctx_eval ]] || level+=1;
    level+=1; shift 1;
  done;
  ((${#args[@]} == 0)) || printf "Lvl%02i Enter %s\n" "${args[@]}";
}

function leave-trace() {
  local -a args=(); local -i index=2*$# level=1;
  while (($# > 0)); do
    args[--index]=$1; args[--index]=$level;
    [[ $1 != ctx_eval ]] || level+=1;
    level+=1; shift 1;
  done;
  ((${#args[@]} == 0)) || printf "Lvl%02i Leave %s\n" "${args[@]}";
}

function stack-trace() {
  local -a args=(); local -i index=2*$# level=1; local caller=top;
  while (($# > 0)); do
    local trace=TRACE_$caller;
    [[ $caller != ctx_eval ]] || args[--index]="${!trace}((eval))";
    args[--index]="${!trace}($1)";
    caller=$1; shift 1;
  done;
  ((${#args[@]} == 0)) || printf "at %s\n" "${args[@]}";
}

function assert_status() {
  local expected_status="$1";
  if (( status != expected_status )); then
    {
      local width=8;
      batslib_print_kv_single $width "expected" "$expected_status" "actual" "$status";
      [[ -z "$output" ]] || batslib_print_kv_single_or_multi $width "stdout" "$output";
      [[ -z "$stderr" ]] || batslib_print_kv_single_or_multi $width "stderr" "$stderr";
    } |
      batslib_decorate "exit status differs" | fail;
  fi;
}

function assert_separate_outputs() {
  local expected_stdout="$1" expected_stderr="$2";
  if [[ "$output" != "$expected_stdout" ]]; then
    {
      local width=8;
      batslib_print_kv_single_or_multi $width "expected" "$expected_stdout" "actual" "$output";
      [[ -z "$stderr" ]] || batslib_print_kv_single_or_multi $width "stderr" "$stderr";
    } |
      batslib_decorate 'stdout differs' | fail;
  elif [[ "$stderr" != "$expected_stderr" ]]; then
    {
      local width=8;
      batslib_print_kv_single_or_multi $width "expected" "$expected_stderr" "actual" "$stderr";
      [[ -z "$output" ]] || batslib_print_kv_single_or_multi $width "stdout" "$output";
    } |
      batslib_decorate 'stderr differs' | fail;
  fi;
}

function check() {
  local command=("${prelude[@]/#/^}");
  local callee;
  for callee in "${callees[@]}"; do
    command+=("$callee");
    [[ ! -v "${callee}_prelude" ]] || eval "command+=(\"\${${callee}_prelude[@]/#/^}\")";
  done;
  command+=("$@");
  echo "# Testing: $TEST_FILE ${command[@]@Q}";

  local expected_abort=${expected_abort-true};
  local expected_enter_trace=${expected_enter_trace-$(enter-trace ${callees[@]})};
  if $expected_abort; then
    local expected_message=${expected_message-$DEFAULT_MESSAGE};
    local expected_stack_trace=${expected_stack_trace-$(stack-trace ${callees[@]})};
    local expected_leave_trace=${expected_leave_trace-};
    local expected_status=${expected_status-1};
  else
    local expected_message=${expected_message-};
    local expected_stack_trace=${expected_stack_trace-};
    local expected_leave_trace=${expected_leave_trace-$(leave-trace ${callees[@]})};
    local expected_status=${expected_status-0};
  fi;

  local expected_stdout=${expected_stdout-};
  local expected_stderr=${expected_stderr-$(\
      [[ -z "$expected_enter_trace" ]] || echo "$expected_enter_trace";
      [[ -z "$expected_message"     ]] || echo "$expected_message";
      [[ -z "$expected_stack_trace" ]] || echo "$expected_stack_trace";
      [[ -z "$expected_leave_trace" ]] || echo "$expected_leave_trace")};

  run --separate-stderr $TEST_FILE "${command[@]}";
  assert_status $expected_status;
  assert_separate_outputs "$expected_stdout" "$expected_stderr";
}

################################################################################
