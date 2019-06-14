#!/bin/sh

set -eu

# find root of the "workspace"
find_repo_workspace_root() {
	if [ -d "$1/.repo" ]; then
		echo "$1"
	elif [ "${1:-/}" != / ]; then
		find_repo_workspace_root "${1%/*}"
	fi
}

case "${0##*/}" in
ltrace.sh)   MODE=-l ;;
strace.sh)   MODE=-s ;;
gdb.sh)      MODE=-g ;;
valgrind.sh) MODE=-m ;;
*)           MODE=   ;;
esac

ARG0="$(readlink -f "$0")"
SCRIPTS_DIR="$(dirname "$ARG0")"
WS="$(find_repo_workspace_root "$SCRIPTS_DIR")"

set -- "$SCRIPTS_DIR/run.sh" $MODE "$@"
if [ -x "$(which docker)" ]; then
	exec "$WS/docker-run.sh" "$@"
else
	exec "$@"
fi
