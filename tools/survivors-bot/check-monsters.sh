#!/usr/bin/env bash
# Spawn admission, health display, and XP control regressions. No HTTP requests.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
python3 -B scripts/check-bend-laws.py examples/survivors/spawn-policy/PROOF.bend
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-healthbars-test.bend -o examples/survivors/dist/native-healthbars-test
(cd examples/survivors/dist; example_timeout 30 "${example_cpu[@]}" "$example_repo/examples/survivors/dist/native-healthbars-test")
