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

ARG0="$(readlink -f "$0")"
SCRIPTS_DIR="$(dirname "$ARG0")"
WS="$(find_repo_workspace_root "$SCRIPTS_DIR")"

exec "$WS/docker-run.sh" "$SCRIPTS_DIR/build.sh" "$@"
