#!/usr/bin/env bash
# Offline protocol/journal checks; real window tested separately after native build.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
example_node --test tools/survivors-bot/visible-controller.test.mjs tools/survivors-bot/journal.test.mjs tools/survivors-bot/visible-process.test.mjs
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-bot-test.bend -o examples/survivors/dist/native-bot-test
example_timeout 30 "${example_cpu[@]}" examples/survivors/dist/native-bot-test
