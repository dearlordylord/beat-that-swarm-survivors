#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
example_emit examples/survivors/bot-actions.bend examples/survivors/dist/bot-actions.mjs
example_node --test tools/survivors-bot/provider.test.mjs tools/survivors-bot/context.test.mjs tools/survivors-bot/runner.test.mjs tools/survivors-bot/visible-controller.test.mjs tools/survivors-bot/visible-process.test.mjs tools/survivors-bot/planner.test.mjs tools/survivors-bot/batch.test.mjs tools/survivors-bot/seed-cli.test.mjs
example_node tools/survivors-bot/actions.test.mjs
example_timeout 60 "${example_cpu[@]}" "$NODE" tools/survivors-bot/integration.test.mjs
