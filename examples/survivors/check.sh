#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
example_node examples/survivors/spawn-lifecycle.test.mjs
example_node examples/survivors/live-quiet.test.mjs
example_node examples/survivors/spawn-policy.test.mjs
example_node examples/survivors/pools.test.mjs
example_node examples/survivors/loot-visual.test.mjs
example_node examples/survivors/projectile-pool/allocator.test.mjs
example_node examples/survivors/shared-pools.test.mjs
example_node examples/survivors/persistent-xp.test.mjs
example_node examples/survivors/progression.test.mjs
example_node --test examples/survivors/catalog.test.mjs
example_node examples/survivors/projectiles.test.mjs
example_node examples/survivors/builds.test.mjs
# Seven natural level-ups need a longer bounded integration horizon.
example_timeout 180 "${example_cpu[@]}" "$NODE" examples/survivors/api.test.mjs
example_node examples/survivors/objectives.test.mjs
# The 1468-entity fixture covers three finales, Endless, actors and horde capacity.
example_timeout 90 "${example_cpu[@]}" "$NODE" examples/survivors/balance.test.mjs
example_node examples/survivors/defeat.test.mjs
example_node examples/survivors/smoke.mjs
