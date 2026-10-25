#!/usr/bin/env bash
# Optional native window bot. Compile300s; session wall horizon plus cleanup bound.
set -euo pipefail
# The visible-controller options select the runtime; ignore ambient RTS overrides.
unset BENDRTS
cd "$(dirname -- "$0")/../.."
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
source examples/common.sh
python3 scripts/generate-bend-types.py
"$NODE" scripts/generate-bend-codecs.mts
mkdir -p examples/survivors/dist
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-bot.bend -o examples/survivors/dist/nightfall-bot
example_timeout 920 "$NODE" tools/survivors-bot/visible.mts "$@"
