#!/bin/sh

set -eu
cd "$(dirname "$0")"

if [ -t 1 ]; then
	COLOUR=true
else
	COLOUR=
fi

case "$0" in
*/status.sh)
	f=do_git_status
	;;
*/grep.sh)
	f=do_git_grep
	;;
*)
	f=cat
	;;
esac

do_git_status() {
	local x=
	while read x; do
		cd "$x"
		git status -s | sed -e "s|^\(...\)\(.*\)|\x1b[31m\1\x1b[m$x/\2|"
		cd - > /dev/null
	done
}

do_git_grep() {
	local x=
	while read x; do
		cd "$x"
		git grep ${COLOUR:+--color=always} "$@" | sed -e "s|^|$x/|"
		cd - > /dev/null
	done
}

do_repo_list() {
	cat
}

if [ -s .repo/manifest.xml -a -x "$(which repo 2> /dev/null)" ]; then
	repo list -p
else
	ls -1d */.git/.. | cut -d/ -f1 2> /dev/null
fi | sort -V | $f "$@"
