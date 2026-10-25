#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/../.."
NODE=${NODE:-node}
# Validate before building, and derive the external fail-safe from the same parser.
batch_wall=$("$NODE" tools/survivors-bot/batch-wall.mts "$@")
python3 scripts/generate-bend-types.py
"$NODE" scripts/generate-bend-codecs.mts
mkdir -p examples/survivors/dist
bash -c 'source examples/common.sh; example_emit examples/survivors/bot-actions.bend examples/survivors/dist/bot-actions.mjs'
"$NODE" examples/run-bounded.mts "$batch_wall" "$NODE" tools/survivors-bot/batch.mts "$@"
