#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../../common.sh"
cd "$example_repo/examples/survivors"
# A pure proof gate gets 10 CPU seconds, rather than a loose compiler timeout.
example_timeout 60 bash -c 'ulimit -t 10; exec "$@"' bend-menu-proof "$BEND" menu-progression/PROOF.bend --verdict
example_emit "$PWD/menu-progression.bend" "$PWD/dist/menu-progression.mjs"
example_node --test menu-progression/contract.test.mjs menu-progression/mutants.test.mjs
