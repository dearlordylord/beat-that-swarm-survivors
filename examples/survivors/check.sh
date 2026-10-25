#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
example_timeout 30 "$NODE" --test examples/survivors/survivor-art.test.mts examples/survivors/expedition-menu.test.mts
example_timeout 30 "$NODE" scripts/generate-native-survivor-art.mts --check
python3 -B scripts/check-bend-laws.py
bash examples/survivors/check-coop-reliability.sh
bash examples/survivors/check-geometry.sh
bash examples/survivors/check-native-coop-metrics.sh
example_timeout 60 python3 -B examples/survivors/capability-controls.test.py
example_timeout 30 python3 -B tools/survivors-bot/ecs_migration_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_measure_test.py
example_timeout 30 python3 -B tools/survivors-bot/balance_report_test.py
example_timeout 30 python3 -B tools/survivors-bot/native-coop-batch.test.py
