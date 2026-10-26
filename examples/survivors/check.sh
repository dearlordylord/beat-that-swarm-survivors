#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  '') ;;
  --runtime-only) ;;
  *) echo 'Usage: check.sh [--runtime-only]' >&2; exit 2 ;;
esac
if (( $# > 1 )); then
  echo 'Usage: check.sh [--runtime-only]' >&2
  exit 2
fi
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
if [[ ${1:-} != --runtime-only ]]; then
  bash examples/survivors/check-proofs.sh
fi
example_timeout 30 "$NODE" --test examples/survivors/survivor-art.test.mts examples/survivors/expedition-menu.test.mts
example_timeout 30 "$NODE" scripts/generate-native-survivor-art.mts --check
