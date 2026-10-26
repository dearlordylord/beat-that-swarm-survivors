#!/usr/bin/env bash
# Native bot build; real window checked separately after compilation.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-bot-build-XXXXXX")"
trap 'rm -rf "$check_dir"; example_cleanup_lock' EXIT
# Compile the real native endpoint; business decisions belong to Bend laws.
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-bot.bend -o "$check_dir/native-bot"
[[ -x "$check_dir/native-bot" ]] || { echo "Native compilation did not produce executable: $check_dir/native-bot" >&2; exit 1; }
