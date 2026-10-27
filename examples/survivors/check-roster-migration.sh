#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/../.."
limit=timeout
if ! command -v "$limit" >/dev/null 2>&1; then
  limit=gtimeout
fi
if ! command -v "$limit" >/dev/null 2>&1; then
  echo 'Roster migration checks require timeout or gtimeout.' >&2
  exit 127
fi
"$limit" --kill-after=5s 60s "${BEND:-bend}" examples/survivors/seven-roster-migration-test.bend
