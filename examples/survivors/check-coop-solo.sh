#!/usr/bin/env bash
set -euo pipefail
app_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source "$app_dir/../common.sh"
coop_solo_dist="$(mktemp -d /tmp/bendvy-coop-solo-XXXXXX)"
trap 'rm -rf "$coop_solo_dist"; example_cleanup_lock' EXIT
for module in game coop-solo-oracle; do example_emit "$app_dir/$module.bend" "$coop_solo_dist/$module.mjs"; done
COOP_SOLO_TEST_DIST="$coop_solo_dist" example_timeout 120 "$NODE" "$app_dir/coop-solo-equivalence.test.mjs"
