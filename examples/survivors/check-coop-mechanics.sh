#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
app_dir="$example_repo/examples/survivors"
coop_mechanics_dist="$(mktemp -d /tmp/bendvy-coop-mechanics-XXXXXX)"
trap 'rm -rf "$coop_mechanics_dist"; example_cleanup_lock' EXIT
for module in game coop-core; do example_emit "$app_dir/$module.bend" "$coop_mechanics_dist/$module.mjs"; done
COOP_MECHANICS_TEST_DIST="$coop_mechanics_dist" example_timeout 120 "$NODE" --test "$app_dir/coop-mechanics.test.mjs"
