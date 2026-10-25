#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
app_dir="$example_repo/examples/survivors"
geometry_dir="$(mktemp -d "${TMPDIR:-/tmp}/bendvy-geometry-check-XXXXXX")"
trap 'rm -rf "$geometry_dir"; example_cleanup_lock' EXIT
example_timeout 60 "$BEND" "$app_dir/geometry-spawn-check.bend" -o "$geometry_dir/spawn"
example_timeout 60 "$geometry_dir/spawn" +RTS --threads 1 --gpu off -RTS
example_timeout 180 "$BEND" "$app_dir/geometry-game-check.bend" -o "$geometry_dir/game"
example_timeout 60 "$geometry_dir/game" +RTS --threads 1 --gpu off -RTS
