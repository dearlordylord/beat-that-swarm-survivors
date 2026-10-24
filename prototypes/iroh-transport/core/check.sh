#!/usr/bin/env bash
set -euo pipefail
core_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(cd -- "$core_dir/../../.." && pwd)"
BEND="${BEND:-bend}"
NODE="${NODE:-node}"
export BEND
mkdir -p "$core_dir/../dist"
# Bound every source/proof compilation to10 CPU seconds and60 wall seconds.
check() {
  "$NODE" "$repo_dir/examples/run-bounded.mjs" 60 bash -c 'ulimit -t 10; exec "$@"' bend-protocol "$@"
}
check "$BEND" "$core_dir/protocol.bend" --check-only
check "$BEND" "$core_dir/PROOF.bend" --verdict
check "$BEND" "$core_dir/protocol.bend" -o "$core_dir/../dist/core.mjs"
check "$BEND" "$core_dir/native-cli.bend" -o "$core_dir/../dist/protocol-native"
"$NODE" "$repo_dir/examples/run-bounded.mjs" 30 "$NODE" --test "$core_dir/core.test.mjs"
