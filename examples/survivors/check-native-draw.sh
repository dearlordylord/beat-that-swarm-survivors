#!/usr/bin/env bash
# Pixel oracle for the native Bend renderer; Node is a development dependency only.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-draw-check-XXXXXX")"
trap 'rm -rf "$check_dir"; example_cleanup_lock' EXIT
example_emit examples/survivors/native_draw.bend "$check_dir/native_draw.mjs"
example_emit examples/survivors/native_art.bend "$check_dir/native_art.mjs"
NATIVE_DRAW_MODULE="$check_dir/native_draw.mjs" \
NATIVE_ART_MODULE="$check_dir/native_art.mjs" \
  example_timeout 90 "${example_cpu[@]}" "$NODE" examples/survivors/native-draw.test.mjs
