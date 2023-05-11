#!/bin/zsh

path[1,0]=(${0:h}/../src/bin);
fpath[1,0]=(${0:h}/../src/functions);

. zabort.zsh;

function banner() { echo "Lvl${(l:2::0:)$(($#funcstack - 2))} $1 $funcstack[3]" >&2; }
function e() { banner "Enter"; }
function l() { banner "Leave"; }

function error-unknown-command() { unknown; }
function error-undefinded-variable() { : $undefined; }

alias process-args='while [[ ${1:-} = ^* ]]; do eval ${1#^}; shift 1; done; "$@"';

function tic() { e; "$@"; l; }
function tac() { e; "$@"; l; }
function toe() { e; "$@"; l; }

# Flags:
# - @subshell: the command is executed in a subshell.
# - @ignored: the command's exit status is ignored.
# - @condition: the command is evaluated as a condition.

function ctx_brace()   { e; { "$@"; }; l; }
function ctx_paren()   { e; ( "$@"; ); l; } # @subshell
function ctx_subst()   { e; : $("$@"); l; } # @subshell @ignored
function ctx_eval()    { e; eval "$@"; l; }
function ctx_set_glb() { e; foo=$("$@"); l; } # @subshell
function ctx_set_lcl() { e; local foo=$("$@"); l; } # @subshell @ignored
function ctx_pipe_lf() { e; { seq 1 10; "$@"; } | cat | cat > /dev/null; l; } # @subshell
function ctx_pipe_md() { e; seq 1 10 | { cat; "$@"; } | cat > /dev/null; l; } # @subshell
function ctx_pipe_rg() { e; seq 1 10 | cat | { cat > /dev/null; "$@"; }; l; }
function ctx_if_cond() { e; if "$@"; then true; fi; l; } # @condition
function ctx_and_rg()  { e; true && "$@"; l; }
function ctx_and_lf()  { e; "$@" && true; l; } # @condition
function ctx_or_rg()   { e; false || "$@"; l; }
function ctx_or_lf()   { e; "$@" || true; l; } # @condition

process-args;
