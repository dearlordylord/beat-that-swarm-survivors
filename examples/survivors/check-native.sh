#!/usr/bin/env bash
# Shared heavy lock; every build and runtime is bounded separately.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
app_dir="$example_repo/examples/survivors"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-check-XXXXXX")"
cache_build_dir=""
trap 'rm -rf "$check_dir"; if [[ -n "$cache_build_dir" ]]; then rm -rf "$cache_build_dir"; fi; example_cleanup_lock' EXIT
# This test uses fake Bend in an isolated checkout and does not build game code.
example_timeout 30 bash "$app_dir/native-launcher.test.sh"
sources=(native-profile-io-check native-test native-loot-test)
# Resolve a cold BendHub cache before fingerprinting its contents. These checks
# do not emit executables and still run when compiled artifacts are reused.
for source in "${sources[@]}"; do
  if [[ ! -f "$app_dir/$source.bend" ]]; then
    echo "Missing required native test: $source.bend" >&2
    exit 1
  fi
  example_timeout 30 "${example_cpu[@]}" "$BEND" "$app_dir/$source.bend" --check-only
done
cache_key="$(python3 -B scripts/native-check-cache-key.py "$example_repo" "$BEND" "$CLANG")"
cache_dir="${NIGHTFALL_NATIVE_CHECK_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/bendvy-native-checks}/$cache_key"
mkdir -p "$cache_dir"
unchanged_sources() {
  if [[ "$(python3 -B scripts/native-check-cache-key.py "$example_repo" "$BEND" "$CLANG")" != "$cache_key" ]]; then
    echo 'Native check inputs changed during the run; retry with a stable source snapshot.' >&2
    exit 75
  fi
}
for source in "${sources[@]}"; do
  if [[ ! -x "$cache_dir/$source" ]]; then
    echo "Building $source"
    # Build on the cache filesystem so publication is an atomic rename, including
    # when TMPDIR and XDG_CACHE_HOME live on different mounts.
    cache_build_dir="$(mktemp -d "$cache_dir/.build-$source-XXXXXX")"
    example_timeout 300 "${example_cpu[@]}" "$BEND" "$app_dir/$source.bend" -o "$cache_build_dir/$source"
    [[ -x "$cache_build_dir/$source" ]]
    unchanged_sources
    mv "$cache_build_dir/$source" "$cache_dir/$source"
    rmdir "$cache_build_dir"
    cache_build_dir=""
  else
    echo "Cached $source"
  fi
  mkdir "$check_dir/$source-data"
  (cd "$check_dir/$source-data"; example_timeout 30 "${example_cpu[@]}" "$cache_dir/$source")
done
unchanged_sources
capture_dir="${NIGHTFALL_CAPTURE_DIR:-$app_dir/dist/native-captures}"
mkdir -p "$capture_dir"
for frame in menu gameplay upgrade map; do
  cp "$check_dir/native-test-data/$frame.ppm" "$capture_dir/$frame.ppm"
done
cp "$check_dir/native-loot-test-data/experience-piles.ppm" "$capture_dir/experience-piles.ppm"
echo "Native captures: $capture_dir"
echo 'NATIVE CHECKS PASS (standalone game build is separate)'
