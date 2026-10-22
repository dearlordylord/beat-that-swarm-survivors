#!/usr/bin/env bash
# Fresh input-only kiting observation; reports outcomes without requiring survival.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
pacing_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-pacing-XXXXXX")"
trap 'rm -rf "$pacing_dir"; example_cleanup_lock' EXIT
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-pacing-run.bend -o "$pacing_dir/native-pacing-run"
mkdir "$pacing_dir/data"
(cd "$pacing_dir/data"; example_timeout 120 "${example_cpu[@]}" "$pacing_dir/native-pacing-run")
