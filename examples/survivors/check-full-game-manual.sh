#!/usr/bin/env bash
# One input-only native complete-run consumer; no window or profile files.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
full_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-full-XXXXXX")"
trap 'rm -rf "$full_dir"; example_cleanup_lock' EXIT
native_toolchain_require
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-full-run.bend -o "$full_dir/native-full-run"
mkdir "$full_dir/data"
(cd "$full_dir/data"; example_timeout 900 "${example_cpu[@]}" "$full_dir/native-full-run")
