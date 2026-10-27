#!/bin/bash
# Rebuild the native Bend game from this checkout, then open its own window.
set -euo pipefail
cd "$(dirname "$0")"
app_dir="$PWD"
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if [ "${1:-}" = '--help' ]; then
  echo 'run.command [--build-only]'
  echo 'Rebuilds local Bend sources and runs the native game. Requires Bend and a C compiler.'
  exit 0
fi
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != '--build-only' ]; }; then
  echo 'Usage: run.command [--build-only]' >&2
  exit 2
fi
if ! command -v "${BEND:-bend}" >/dev/null 2>&1; then
  echo 'Bend is required. Add it to PATH or set BEND=/absolute/path/to/bend.' >&2
  exit 1
fi
if [ "$(uname -s)" = Darwin ] && ! xcrun --find clang >/dev/null 2>&1; then
  echo 'Apple Command Line Tools are required. Install with: xcode-select --install' >&2
  exit 1
fi
source "$app_dir/../../scripts/native-toolchain.sh"
native_toolchain_require
mkdir -p dist
staging_dir="$(mktemp -d "$app_dir/dist/.native-XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cd ../..
echo 'Building B.T.S: Beat That Swarm - Survivors from current Bend sources…'
"${BEND:-bend}" "$app_dir/native.bend" -o "$staging_dir/nightfall"
chmod +x "$staging_dir/nightfall"
mv -f "$staging_dir/nightfall" "$app_dir/dist/nightfall"
if [ "${1:-}" = '--build-only' ]; then
  echo "Built: $app_dir/dist/nightfall"
  exit 0
fi
if [ -n "${NIGHTFALL_DATA_DIR:-}" ]; then
  save_dir="$NIGHTFALL_DATA_DIR"
elif [ "$(uname -s)" = Darwin ]; then
  save_dir="$HOME/Library/Application Support/Nightfall Survivors"
else
  save_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nightfall-survivors"
fi
mkdir -p "$save_dir"
cd "$save_dir"
echo "Save directory: $save_dir"
rm -rf "$staging_dir"
trap - EXIT INT TERM
exec "$app_dir/dist/nightfall"
