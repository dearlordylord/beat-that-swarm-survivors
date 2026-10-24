#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
example_timeout 60 bash -c 'ulimit -t 10; exec "$@"' bend-role-proof "$BEND" examples/survivors/entity-role/PROOF.bend --verdict
example_timeout 60 bash -c 'ulimit -t 10; exec "$@"' bend-movement-proof "$BEND" examples/survivors/movement-selection/PROOF.bend --verdict
example_timeout 60 python3 -B examples/survivors/capability-controls.test.py
example_timeout 30 python3 -B tools/survivors-bot/ecs_migration_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_compare_test.py
example_timeout 30 python3 -B tools/survivors-bot/replay_measure_test.py
example_node examples/survivors/spawn-lifecycle.test.mjs
example_node examples/survivors/live-quiet.test.mjs
example_node examples/survivors/pickup-component.test.mjs
example_timeout 180 "${example_cpu[@]}" "$NODE" examples/survivors/movement-selection.test.mjs
example_node examples/survivors/spawn-policy.test.mjs
example_node examples/survivors/arena.test.mjs
example_node examples/survivors/music.test.mjs
example_node --test examples/survivors/audio.test.mjs
example_node --test examples/survivors/renderer-map.test.mjs
example_node examples/survivors/pools.test.mjs
example_node examples/survivors/loot-visual.test.mjs
example_node examples/survivors/projectile-pool/allocator.test.mjs
example_node examples/survivors/shared-pools.test.mjs
example_node examples/survivors/persistent-xp.test.mjs
example_node examples/survivors/progression.test.mjs
bash examples/survivors/menu-progression/test.sh
example_node --test examples/survivors/catalog.test.mjs
example_node examples/survivors/projectiles.test.mjs
example_node examples/survivors/builds.test.mjs
# Seven natural level-ups need a longer bounded integration horizon.
example_timeout 180 "${example_cpu[@]}" "$NODE" examples/survivors/api.test.mjs
# Distant relics now require up to 1800 real movement ticks per stage.
example_timeout 90 "${example_cpu[@]}" "$NODE" examples/survivors/objectives.test.mjs
# The 1456-entity fixture covers three finales, Endless, actor absence and horde capacity.
example_timeout 90 "${example_cpu[@]}" "$NODE" examples/survivors/balance.test.mjs
example_node examples/survivors/defeat.test.mjs
example_node examples/survivors/smoke.mjs
