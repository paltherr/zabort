#!/bin/zsh
################################################################################

# SYNOPSIS

# test-runner.zsh [^<prelude>…] [<command> [<argument>…]]

# DESCRIPTION

# Sources "zabort.zsh" and then runs the command with the provided
# arguments. If the command is preceded by arguments starting with the
# caret (^) symbol, then the "eval" builtin is first invoked once with
# each of them minus the caret symbol.

# EXAMPLES

# Call "abort" with the message "Something went wrong":
#
#   $ test-runner.zsh abort "Something went wrong"

# Call "abort" in three nested "eval" calls:
#
#  $ test-runner.zsh eval eval eval abort

# Call "abort" after initializing "ZABORT_SIGNAL" with "USR1":
#
#  $ test-runner.zsh ^ZABORT_SIGNAL=USR1 abort

################################################################################

path[1,0]=(${0:h}/../src/bin);
fpath[1,0]=(${0:h}/../src/functions);

. zabort.zsh;

################################################################################
# Helper Functions

function banner() { echo "Lvl${(l:2::0:)$(($#funcstack - 2))} $1 $funcstack[3]" >&2; }
function e() { banner "Enter"; }
function l() { banner "Leave"; }

################################################################################
# Error Functions

function error-unknown-command() { unknown; }
function error-undefinded-variable() { : $undefined; }

################################################################################
# Test functions

# The test functions defined below accept the same kind of arguments
# as the main script:
#
# <test-function> [^<prelude>…] [<command> [<argument>…]]

# The test functions first print an "Enter" banner, then process their
# arguments in the same manner as the main script, and finally print a
# "Leave" banner. The functions only differ in the context in which
# they process their arguments.

# Alias to process the arguments of the test functions and of the main
# script.
alias process-args='while [[ ${1:-} = ^* ]]; do eval ${1#^}; shift 1; done; "$@"';

# The following functions process their arguments at the top-level of
# their body. Their purpose is to add variety to call stacks.

function f1() { e; process-args; l; }
function f2() { e; process-args; l; }
function f3() { e; process-args; l; }

# The "ctx_*" functions process their arguments in diverse contexts.
# The "@" annotations, which must be in a comment on the same line as
# the function declaration, describe properties of the context.

# Annotations:
# - @subshell: the command is executed in a subshell.
# - @ignored: the command's exit status is ignored.
# - @condition: the command is evaluated as a condition.

function ctx_brace()   { e; { process-args; }; l; }
function ctx_paren()   { e; ( process-args; ); l; } # @subshell
function ctx_subst()   { e; : $(process-args); l; } # @subshell @ignored
function ctx_eval()    { e; eval process-args; l; }
function ctx_set_glb() { e; foo=$(process-args); l; } # @subshell
function ctx_set_lcl() { e; local foo=$(process-args); l; } # @subshell @ignored
function ctx_pipe_lf() { e; { seq 1 10; process-args; } | cat | cat > /dev/null; l; } # @subshell
function ctx_pipe_md() { e; seq 1 10 | { cat; process-args; } | cat > /dev/null; l; } # @subshell
function ctx_pipe_rg() { e; seq 1 10 | cat | { cat > /dev/null; process-args; }; l; }
function ctx_if_cond() { e; if process-args; then true; fi; l; } # @condition
function ctx_and_rg()  { e; true && process-args; l; }
function ctx_and_lf()  { e; process-args && true; l; } # @condition
function ctx_or_rg()   { e; false || process-args; l; }
function ctx_or_lf()   { e; process-args || true; l; } # @condition

################################################################################
# Main Body

process-args;

################################################################################
