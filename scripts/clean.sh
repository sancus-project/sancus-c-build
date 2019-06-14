#!/bin/sh

git_clean() {
	local x="$1" c=

	cd "$x"
	cat <<-EOT
	#
	# $x
	#
	
	EOT
	git clean -dfx
	if [ "$(git status -s configure.ac 2> /dev/null)" = " M configure.ac" ]; then
		c=$(git diff configure.ac | grep -v -e '^.AC_INIT' -e '^+++' -e '^---' | grep -c '^[+-]')
		if [ 0 = "$c" ]; then
			git checkout -- configure.ac
		fi
	fi
	git status -s
       	cd - > /dev/null;
}

if [ $# -eq 0 ]; then
	# git clean

	if [ -s .repo/manifest.xml -a -x "$(which repo 2> /dev/null)" ]; then
		repo list -p
	else
		ls -1d */.git/.. | cut -d/ -f1 2> /dev/null
	fi | while read x; do
		[ -d "$x" ] || continue

		git_clean "$x"
	done

	# uninstall
	cat <<-EOT
	#
	# out/
	#

	EOT
	rm -rvf out/
else
	# git clean
	for x; do
		[ -d "$x" ] || continue
		# uninstall
		if [ -s $x/build/Makefile ]; then
			make -C $x/build uninstall || true
		fi
		git_clean $x
	done
fi
