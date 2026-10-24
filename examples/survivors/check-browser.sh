#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
bash examples/survivors/build-web.sh
example_node examples/survivors/web-smoke.mjs
example_node examples/survivors/browser-smoke.mjs
