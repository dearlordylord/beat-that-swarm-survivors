#!/usr/bin/env bash
# Shared bounded checks. Playing the native game does not require Node.js.
example_repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
BEND=${BEND:-bend}
NODE=${NODE:-node}
CLANG=${CLANG:-clang}
example_cpu=()
if [[ -n ${BENDVY_EXAMPLE_CPU:-} ]]; then
  command -v taskset >/dev/null || { echo 'CPU affinity requires taskset.' >&2; exit 1; }
  example_cpu=(taskset -c "$BENDVY_EXAMPLE_CPU")
fi
example_cleanup_lock() {
  if [[ -n ${example_lock_dir:-} ]]; then rmdir "$example_lock_dir" 2>/dev/null || true; fi
}
if [[ ${BENDVY_EXAMPLE_LOCK_HELD:-0} != 1 ]]; then
  if command -v flock >/dev/null 2>&1; then
    exec 9>/tmp/bendvy-parity-heavy.lock
    flock -n 9 || { echo 'Backend checks are already running; retry later.' >&2; exit 75; }
  else
    example_lock_dir="${TMPDIR:-/tmp}/bendvy-examples-heavy.lock.d"
    mkdir "$example_lock_dir" 2>/dev/null || { echo "Backend checks are running, or a stale lock remains: $example_lock_dir" >&2; exit 75; }
    trap example_cleanup_lock EXIT
  fi
  export BENDVY_EXAMPLE_LOCK_HELD=1
fi
example_timeout() {
  "$NODE" "$example_repo/examples/run-bounded.mjs" "$@"
}
example_emit() {
  example_timeout 30 "${example_cpu[@]}" "$BEND" "$1" -o "$2"
}
example_node() {
  example_timeout 30 "${example_cpu[@]}" "$NODE" "$@"
}
