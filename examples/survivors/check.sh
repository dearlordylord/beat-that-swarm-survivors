#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
python3 -B scripts/check-bend-laws.py
python3 -B scripts/check-bend-mutants.py
bash examples/survivors/check-coop-reliability.sh
bash examples/survivors/check-geometry.sh
example_timeout 60 python3 -B examples/survivors/capability-controls.test.py
example_timeout 30 python3 -B tools/survivors-bot/ecs_migration_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_measure_test.py
