#!/usr/bin/env bash
set -euo pipefail
app_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source "$app_dir/../common.sh"
coop_effects_dist="$(mktemp -d /tmp/bendvy-coop-effects-XXXXXX)"
trap 'rm -rf "$coop_effects_dist"; example_cleanup_lock' EXIT
example_emit "$app_dir/game.bend" "$coop_effects_dist/game.mjs"
example_emit "$app_dir/coop-effects.bend" "$coop_effects_dist/coop-effects.mjs"
COOP_EFFECTS_MODULE="$coop_effects_dist/coop-effects.mjs" COOP_EFFECTS_GAME_MODULE="$coop_effects_dist/game.mjs" example_node "$app_dir/coop-effects.test.mjs"
