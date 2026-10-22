#!/usr/bin/env bash
# Optional native window bot. Compile300s; session wall horizon plus cleanup bound.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
source examples/common.sh
mkdir -p examples/survivors/dist
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-bot.bend -o examples/survivors/dist/nightfall-bot
example_timeout 920 "$NODE" tools/survivors-bot/visible.mjs "$@"
