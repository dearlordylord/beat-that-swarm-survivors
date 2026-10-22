#!/usr/bin/env bash
set -euo pipefail
export BEND=/home/node/.bend/bin/bend
export NODE=/home/node/.local/share/mise/installs/node/24.20.0/bin/node
export BEND_LIB=/tmp/bendvy-ecs-examples-cold-hub
source examples/common.sh
example_timeout 480 "$NODE" tools/survivors-bot/autoresearch/benchmark.mjs
