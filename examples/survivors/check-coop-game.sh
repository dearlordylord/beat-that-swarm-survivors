#!/usr/bin/env bash
# Compile and exercise the real shared Bend world under deterministic delivery.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
app_dir="$example_repo/examples/survivors"
coop_game_dist="$(mktemp -d /tmp/bendvy-coop-game-XXXXXX)"
cleanup(){ rm -rf "$coop_game_dist"; example_cleanup_lock; }
trap cleanup EXIT
for module in coop-core coop-session coop-protocol; do
  example_emit "$app_dir/$module.bend" "$coop_game_dist/$module.mjs"
done
COOP_GAME_TEST_DIST="$coop_game_dist" example_timeout 120 "$NODE" --test "$app_dir/coop-game-replay.test.mjs"
