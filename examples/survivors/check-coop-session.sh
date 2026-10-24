#!/usr/bin/env bash
set -euo pipefail
app_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(cd -- "$app_dir/../.." && pwd)"
BEND="${BEND:-bend}"
NODE="${NODE:-node}"
coop_test_dist="$(mktemp -d /tmp/bendvy-coop-session-XXXXXX)"
trap 'rm -rf "$coop_test_dist"' EXIT
check() { "$NODE" "$repo_dir/examples/run-bounded.mjs" 60 bash -c 'ulimit -t 10; exec "$@"' coop-session "$@"; }
check "$BEND" "$app_dir/coop-session-PROOF.bend" --verdict
for module in coop-session coop-protocol coop-network-emulator; do check "$BEND" "$app_dir/$module.bend" -o "$coop_test_dist/$module.mjs"; done
COOP_TEST_DIST="$coop_test_dist" "$NODE" "$repo_dir/examples/run-bounded.mjs" 60 "$NODE" --test "$app_dir/coop-session.test.mjs"
COOP_TEST_DIST="$coop_test_dist" "$NODE" "$repo_dir/examples/run-bounded.mjs" 60 "$NODE" "$app_dir/coop-session-mutations.mjs"
