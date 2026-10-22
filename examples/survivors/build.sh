#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
mkdir -p examples/survivors/dist
example_emit examples/survivors/game.bend examples/survivors/dist/game.mjs
