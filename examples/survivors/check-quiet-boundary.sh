#!/usr/bin/env bash
# Exact authoritative-state development check; game/bot binaries use native C.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
quiet_check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-quiet-check-XXXXXX")"
trap 'rm -rf "$quiet_check_dir"; example_cleanup_lock' EXIT
example_timeout 90 "${example_cpu[@]}" "$BEND" examples/survivors/quiet-boundary-test.bend -o "$quiet_check_dir/quiet-boundary-test.js"
example_timeout 180 "${example_cpu[@]}" "$NODE" "$quiet_check_dir/quiet-boundary-test.js"
