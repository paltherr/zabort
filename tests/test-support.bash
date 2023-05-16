###################################################-*- mode: shell-script -*-###

set -eu;

################################################################################
# Test setup

function setup_file() {
  bats_require_minimum_version 1.5.0;
  export DEFAULT_MESSAGE="Abort";
  export TEST_MESSAGE="a-simple-test-message";
  export UNKNOWN_COMMAND="unknown-command";
  export NON_EXISTENT_FILE="non-existent-file.txt";
  export UNDEFINED_VARIABLE="undefined_variable";
  export TEST_FILE=tests/test-runner.zsh;
  export CONTEXTS=$(grep -o 'ctx_\w\+' $TEST_FILE);
  export CONTEXTS_AT_SUBSHELL=$(grep -o 'ctx_\w\+.*@subshell' $TEST_FILE | grep -o 'ctx_\w\+');
  export CONTEXTS_AT_IGNORED=$(grep -o 'ctx_\w\+.*@ignored' $TEST_FILE | grep -o 'ctx_\w\+');
  export CONTEXTS_AT_CONDITION=$(grep -o 'ctx_\w\+.*@condition' $TEST_FILE | grep -o 'ctx_\w\+');
  export TRACE_script=$($TEST_FILE '^echo $funcfiletrace[1]');
  export TRACE_prelude_function=$($TEST_FILE '^() { echo $funcsourcetrace[1]; }');
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

function context-starts-subshell() {
  [[ $CONTEXTS_AT_SUBSHELL = *$1* ]];
}

function context-ignores-exit-status() {
  [[ $CONTEXTS_AT_IGNORED = *$1* ]];
}

function context-is-condition() {
  [[ $CONTEXTS_AT_CONDITION = *$1* ]];
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
  local -a args=(); local -i index=2*$# level=1; local caller=script;
  while (($# > 0)); do
    local trace=TRACE_$caller;
    [[ -v $trace ]] || trace=TRACE_prelude_function;
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
