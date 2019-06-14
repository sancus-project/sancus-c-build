#!/bin/sh

set -eu

BOARDS=
#BOARDS="$BOARDS ht2"
#BOARDS="$BOARDS ht5"

APPS=
APPS="$APPS tisd"

LIBS="libhtc-core"
LIBS="$LIBS libhtc-audio"
LIBS="$LIBS libhtc-compat"
LIBS="$LIBS libhtc-bindings"
LIBS="$LIBS libhtc-display"
LIBS="$LIBS libhtc-hcp"

# find root of the "workspace"
find_repo_workspace_root() {
	if [ -d "$1/.repo" ]; then
		echo "$1"
	elif [ "${1:-/}" != / ]; then
		find_repo_workspace_root "${1%/*}"
	fi
}
BASE="$(find_repo_workspace_root "$(dirname "$0")")"
[ -d "$BASE" ] || BASE="$(dirname "$0")"

PREFIX="$BASE/out"
#UPDATE_CONFIG="$(which updateconfig.sh || true)"

[ -n "${RUN_TESTS:-}" ] || RUN_TESTS=true
[ -n "${JOBS:-}" ] || JOBS=$(grep -c ^processor /proc/cpuinfo)

if [ $# -eq 0 ]; then
	if [ -z "$BOARDS" ]; then
		for x in "$BASE"/libhtc-board-*; do
			[ -d "$x" ] || continue
			LIBS="$LIBS ${x#$BASE/}"
		done
	else
		for x in $BOARDS; do
			LIBS="$LIBS libhtc-board-$x"
		done
	fi
	for x in $LIBS $APPS; do
		if [ -d "$BASE/$x" ]; then
			set -- "$@" "$BASE/$x"
		fi
	done
fi

mkdir -p "$PREFIX/lib/pkgconfig" "$PREFIX/share/aclocal" "$PREFIX/bin"
PREFIX=$(cd "$PREFIX" && pwd -P)

for d in /usr/local/lib /usr/local/lib/$(uname -m)-*; do
	[ -d "$d" ] || continue
	LD_LIBRARY_PATH="$d${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
done

export PATH="$PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export "PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export ACLOCAL="aclocal -I $PREFIX/share/aclocal"
export LANG=C


for x; do
	cat <<-EOT
	#
	# $x
	#
	EOT

	if [ -x "${UPDATE_CONFIG:-}" ]; then
		cd "$x"
		$UPDATE_CONFIG
		cd - > /dev/null
	fi

	if [ ! -x "$x/configure" ]; then
		if [ -x "$x/autogen.sh" ]; then
			cd "$x"
			./autogen.sh
			cd - > /dev/null
		elif [ -s "$x/configure.ac" -o -s "$x/configure.in" ]; then
			autoreconf -ivfs "$x"
		else
			echo "$x: 'configure.ac' or 'configure.in' is required" >&2
			continue
		fi
	fi

	builddir="$x/build"
	srcdir=".."

	if [ ! -s "$builddir/Makefile" ]; then
		mkdir -p "$builddir"
		cd "$builddir"
		"$srcdir/configure" --prefix "$PREFIX"
		cd - > /dev/null
	fi

	run_make() {
		make -C "$builddir" ${JOBS:+-j$JOBS} "$@"
	}

	run_make
	[ "${RUN_TESTS:-no}" = no ] || run_make check

	run_make install
done
