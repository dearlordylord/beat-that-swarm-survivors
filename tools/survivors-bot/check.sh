#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
python3 scripts/generate-bend-types.py
"$NODE" scripts/generate-bend-codecs.mts
mkdir -p examples/survivors/dist
example_emit examples/survivors/bot-actions.bend examples/survivors/dist/bot-actions.mjs

example_node "$example_repo/tools/survivors-bot/observations-check.mts"
