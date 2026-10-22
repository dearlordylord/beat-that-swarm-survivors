#!/usr/bin/env bash
# Spawn admission, health display, and XP control regressions. No HTTP requests.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
example_timeout 30 "$BEND" examples/survivors/spawn-policy/PROOF.bend
example_emit examples/survivors/game.bend examples/survivors/dist/game.mjs
example_node examples/survivors/spawn-policy.test.mjs
example_node --test examples/survivors/renderer-healthbars.test.mjs
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-healthbars-test.bend -o examples/survivors/dist/native-healthbars-test
(cd examples/survivors/dist; example_timeout 30 "${example_cpu[@]}" "$example_repo/examples/survivors/dist/native-healthbars-test")
