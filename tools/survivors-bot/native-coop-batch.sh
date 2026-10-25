#!/usr/bin/env bash
# Python supervises processes and receipts; simulation/controllers run as native C.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
exec python3 -B tools/survivors-bot/native-coop-batch.py "$@"
