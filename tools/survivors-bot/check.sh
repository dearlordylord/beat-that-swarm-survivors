#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
example_emit examples/survivors/bot-actions.bend examples/survivors/dist/bot-actions.mjs
example_node --test tools/survivors-bot/provider.test.mjs tools/survivors-bot/context.test.mjs tools/survivors-bot/runner.test.mjs
example_node tools/survivors-bot/actions.test.mjs
example_node tools/survivors-bot/integration.test.mjs
