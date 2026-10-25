#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
example_timeout 30 "$NODE" --test examples/survivors/survivor-art.test.mts examples/survivors/expedition-menu.test.mts
example_timeout 30 "$NODE" scripts/generate-native-survivor-art.mts --check
consumer_dir="$(mktemp -d "${TMPDIR:-/tmp}/bendvy-actor-consumers.XXXXXX")"
trap 'rm -rf "$consumer_dir"; example_cleanup_lock' EXIT
example_emit examples/survivors/bot-actions.bend "$consumer_dir/bot-actions.mjs"
BOT_ACTIONS_MODULE="$consumer_dir/bot-actions.mjs" example_timeout 30 "$NODE" --test tools/survivors-bot/actor-consumers.test.mts tools/survivors-bot/planner-objective.test.mts tools/survivors-bot/coop-motion-oracle.test.mts
python3 -B scripts/check-bend-laws.py
bash examples/survivors/check-coop-reliability.sh
bash examples/survivors/check-geometry.sh
bash examples/survivors/check-native-coop-metrics.sh
example_timeout 60 python3 -B examples/survivors/capability-controls.test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_measure_test.py
example_timeout 30 python3 -B tools/survivors-bot/balance_report_test.py
example_timeout 30 python3 -B tools/survivors-bot/native-coop-batch.test.py
