#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
# A complete ten-minute simulated run is a functional consumer, not a benchmark.
example_timeout 900 "${example_cpu[@]}" "$NODE" examples/survivors/full-run.mjs
