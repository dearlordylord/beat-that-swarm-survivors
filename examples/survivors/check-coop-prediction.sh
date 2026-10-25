#!/usr/bin/env bash
set -euo pipefail
app_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source "$app_dir/../common.sh"
prediction_dir="$(mktemp -d /tmp/bendvy-prediction-check-XXXXXX)"
trap 'rm -rf "$prediction_dir"; example_cleanup_lock' EXIT
for module in coop-prediction player-movement coop-session game; do
  example_emit "$app_dir/$module.bend" "$prediction_dir/$module.mjs"
done
COOP_LATENCY_MODULE_DIR="$prediction_dir" example_timeout 60 "$NODE" --test "$app_dir/coop-latency.test.mjs" "$app_dir/coop-orchestration.test.mjs"
