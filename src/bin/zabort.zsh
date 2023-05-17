#!/bin/zsh

################################################################################
# Autoload "abort" and "usage"

autoload -Uz abort;
autoload -Uz usage;

################################################################################
# Shell configuration for (more) reliable error handling

# Terminate the current shell script if a command returns a non-zero
# exit status. This is strictly stronger than the ERR_EXIT option,
# which exits a (sub)shell if a command returns with a non-zero exit
# status. With the ERR_EXIT option, a parent shell won't be terminated
# if the subshell was started in a context where its exit status is
# ignored. The trap defined here solves this by explicitly terminating
# all parent shells.

TRAPZERR() {
  abort -1 "Command unexpectedly exited with the non-zero status $?.";
}

# TODO: Are there any cleanups, like killing pending jobs/subshells,
# that should be done in an HUP trap??
#
# TODO: The presence of a HUP trap sometimes seems to lead to
# duplicate triggering of the ZERR trap in parent shells.
#
# trap 'cleanup; return 129' HUP;

# Trigger the ZERR trap also when commands in pipelines return with a
# non-zero exit status.
set -o pipefail;

# Exit the (sub)shell with status 1 when an undefined variable is
# accessed. Unfortunately this doesn't trigger the ZERR trap (nor any
# other trap). If the subshell was started in a context where its exit
# status is ignored, the error is lost. There seems to be no way to
# reliably terminate the current shell script whenever an undefined
# variable is accessed.
# https://monospacedmonologues.com/2020/07/untriggered-traps-in-zsh/
set -u;

# Send the HUP signal to running jobs when the shell exits.
#
# TODO: Investigate whether this is needed. It may be needed to fully
# kill pipelines.
#
# set -o hup;

################################################################################
