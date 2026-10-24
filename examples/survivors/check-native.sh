#!/usr/bin/env bash
# Shared heavy lock; every build and runtime is bounded separately.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
app_dir="$example_repo/examples/survivors"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-check-XXXXXX")"
trap 'rm -rf "$check_dir"; example_cleanup_lock' EXIT
# This test uses fake Bend in an isolated checkout and does not build game code.
example_timeout 30 bash "$app_dir/native-launcher.test.sh"
for source in native-audio-test native-profile-test native-test offline-parallel-test native-fps-test native-loot-test spawn-lifecycle-test; do
  if [[ ! -f "$app_dir/$source.bend" ]]; then
    echo "Missing required native test: $source.bend" >&2
    exit 1
  fi
  example_timeout 300 "${example_cpu[@]}" "$BEND" "$app_dir/$source.bend" -o "$check_dir/$source"
  mkdir "$check_dir/$source-data"
  (cd "$check_dir/$source-data"; example_timeout 30 "${example_cpu[@]}" "$check_dir/$source")
done
capture_dir="${NIGHTFALL_CAPTURE_DIR:-$app_dir/dist/native-captures}"
mkdir -p "$capture_dir"
for frame in menu gameplay upgrade map; do
  cp "$check_dir/native-test-data/$frame.ppm" "$capture_dir/$frame.ppm"
done
cp "$check_dir/native-loot-test-data/experience-piles.ppm" "$capture_dir/experience-piles.ppm"
echo "Native captures: $capture_dir"
example_timeout 300 "${example_cpu[@]}" "$BEND" "$app_dir/native.bend" -o "$check_dir/nightfall"
[[ -x "$check_dir/nightfall" ]]
echo 'NATIVE BUILD PASS (window not opened by this headless check)'
