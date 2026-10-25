#!/usr/bin/env bash
# Offline protocol/journal checks; real window tested separately after native build.
set -euo pipefail
cd "$(dirname -- "$0")/../.."
source examples/common.sh
mkdir -p examples/survivors/dist
example_node --test tools/survivors-bot/visible-controller.test.mjs tools/survivors-bot/journal.test.mjs tools/survivors-bot/visible-process.test.mjs
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-bot-build-XXXXXX")"
trap 'rm -rf "$check_dir"; example_cleanup_lock' EXIT
# Compile the real native endpoint; business decisions belong to Bend laws.
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-bot.bend -o "$check_dir/native-bot"
[[ -x "$check_dir/native-bot" ]]
