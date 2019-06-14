#!/bin/sh

set -eu

git_update() {
	local d="$1" changes=

	cat <<-EOT
	#
	# $d
	#

	EOT
	cd "$d"
	git remote update --prune
	if changes="$(git status -s | grep -v '^?? ')"; then
		changes=true
		git stash
	fi
	git pull -q --rebase
	if [ "$changes" = true ]; then
		git stash pop -q
	fi
	git status -s
	cd - > /dev/null
}

if [ $# -eq 0 ]; then
	for x in */.git/..; do
		git_update "${x%%/*}"
	done
else
	for x; do
		git_update "${x%/}"
	done
fi
