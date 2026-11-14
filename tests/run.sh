#!/usr/bin/env bash
# Builds the binding and runs haxe/Main.hx on one runtime, then compares the
# lines it prints with tests/expected.txt.
#   run.sh hl [vm]    vm is a HashLink-compatible command, default `hl`, with
#                     any options: "ash --mode jit"
#   run.sh cpp
#   run.sh cppia
# Needs `hxn` on PATH, or HXN naming it.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
hxn="${HXN:-hxn}"
runtime="${1:?usage: run.sh hl [vm] | cpp | cppia}"
case "$runtime" in
	hl) arguments=(hl --vm "${2:-hl}") ;;
	cpp | cppia) arguments=("$runtime") ;;
	*)
		echo "unknown runtime: $runtime" >&2
		exit 2
		;;
esac

cd "$root"
out="$(mktemp)"
trap 'rm -f "$out"' EXIT
"$hxn" run "${arguments[@]}" | tr -d '\r' | tee "$out"
expected="$here/expected.txt"
if [ "$(grep -E '^(opened|title|events|closed)' "$out")" != "$(cat "$expected")" ]; then
	echo "FAILED: the program did not print what tests/expected.txt lists" >&2
	exit 1
fi
echo "PASS: $runtime"
