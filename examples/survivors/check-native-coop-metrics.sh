#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
metrics_dir="$(mktemp -d "${TMPDIR:-/tmp}/bendvy-coop-metrics-XXXXXX")"
trap 'rm -rf "$metrics_dir"; example_cleanup_lock' EXIT
example_timeout 180 "$BEND" "$example_repo/examples/survivors/offline-coop-metrics-check.bend" -o "$metrics_dir/check"
example_timeout 30 "$metrics_dir/check" +RTS --threads 1 --gpu off -RTS
