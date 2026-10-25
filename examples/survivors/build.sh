#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
mkdir -p examples/survivors/dist
example_emit examples/survivors/game.bend examples/survivors/dist/game.mjs
example_emit examples/survivors/game-encoder.bend examples/survivors/dist/game-encoder.mjs
example_emit examples/survivors/menu-catalog.bend examples/survivors/dist/menu-catalog.mjs
example_emit examples/survivors/menu-progression.bend examples/survivors/dist/menu-progression.mjs
"$NODE" examples/survivors/generate-menu-content.mjs
