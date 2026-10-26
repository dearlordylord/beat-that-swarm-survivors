#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-audio-bench-XXXXXX")"
trap 'rm -rf "$check_dir"; example_cleanup_lock' EXIT
cd "$example_repo"
native_toolchain_require
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-audio-bench.bend -o "$check_dir/audio-bench"
example_timeout 30 "${example_cpu[@]}" "$check_dir/audio-bench"
