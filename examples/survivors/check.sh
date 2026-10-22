#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
example_node examples/survivors/progression.test.mjs
example_node --test examples/survivors/catalog.test.mjs
example_node examples/survivors/projectiles.test.mjs
example_node examples/survivors/builds.test.mjs
example_node examples/survivors/api.test.mjs
example_node examples/survivors/objectives.test.mjs
example_node examples/survivors/balance.test.mjs
example_node examples/survivors/defeat.test.mjs
example_node examples/survivors/smoke.mjs
