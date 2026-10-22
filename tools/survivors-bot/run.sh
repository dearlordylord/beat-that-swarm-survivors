#!/usr/bin/env bash
# Optional bot experiment: serialized build30s and bounded execution120s.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
example_emit examples/survivors/bot-actions.bend examples/survivors/dist/bot-actions.mjs
example_timeout 120 "$NODE" tools/survivors-bot/run.mjs "$@"
