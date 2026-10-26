#!/bin/bash
# Portable integration test: isolated checkout and fake Bend, no real game build.
set -euo pipefail
source_dir="$(cd "$(dirname "$0")" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/nightfall-launcher-XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/examples/survivors" "$fixture/data with spaces"
cp "$source_dir/run.command" "$fixture/repo/examples/survivors/run.command"
repo="$(cd "$source_dir/../.." && pwd)"
mkdir -p "$fixture/repo/tools" "$fixture/repo/toolchains" "$fixture/repo/scripts"
cp "$repo/tools/clang" "$fixture/repo/tools/clang"
cp "$repo/toolchains/clang.env" "$fixture/repo/toolchains/clang.env"
cp "$repo/scripts/native-toolchain.sh" "$fixture/repo/scripts/native-toolchain.sh"
cat > "$fixture/fake-clang" <<'CLANG'
#!/bin/sh
[ "$1" = --version ] || exit 1
printf '%s\n' 'clang version 19.1.7'
CLANG
chmod +x "$fixture/fake-clang"
export BENDVY_CLANG="$fixture/fake-clang"
touch "$fixture/repo/examples/survivors/native.bend"
cat > "$fixture/fake-bend" <<'COMPILER'
#!/bin/bash
set -euo pipefail
[ "$CC" = "$FIXTURE/repo/tools/clang" ]
[ "$PWD" = "$FIXTURE/repo" ]
[ "$1" = "$FIXTURE/repo/examples/survivors/native.bend" ]
[ "$2" = '-o' ]
echo compile >> "$FIXTURE/compile.log"
if [ "${FAIL_BUILD:-0}" = 1 ]; then
  echo 'partial executable' > "$3"
  exit 42
fi
cat > "$3" <<'BINARY'
#!/bin/bash
set -euo pipefail
[ "$PWD" = "$NIGHTFALL_DATA_DIR" ]
echo run >> launch-count.txt
BINARY
COMPILER
chmod +x "$fixture/fake-bend" "$fixture/repo/examples/survivors/run.command"
export FIXTURE="$fixture" BEND="$fixture/fake-bend" NIGHTFALL_DATA_DIR="$fixture/data with spaces" NODE='/does/not/exist'
launcher="$fixture/repo/examples/survivors/run.command"
cd /
"$launcher"
[ "$(wc -l < "$NIGHTFALL_DATA_DIR/launch-count.txt" | tr -d ' ')" = 1 ]
"$launcher"
[ "$(wc -l < "$NIGHTFALL_DATA_DIR/launch-count.txt" | tr -d ' ')" = 2 ]
"$launcher" --build-only
[ "$(wc -l < "$NIGHTFALL_DATA_DIR/launch-count.txt" | tr -d ' ')" = 2 ]
[ -x "$fixture/repo/examples/survivors/dist/nightfall" ]
cp "$fixture/repo/examples/survivors/dist/nightfall" "$fixture/previous"
if FAIL_BUILD=1 "$launcher" --build-only; then echo 'failed compiler was accepted' >&2; exit 1; fi
cmp "$fixture/previous" "$fixture/repo/examples/survivors/dist/nightfall"
[ "$(wc -l < "$fixture/compile.log" | tr -d ' ')" = 4 ]
if "$launcher" --invalid; then echo 'invalid argument was accepted' >&2; exit 1; fi
if "$launcher" --build-only extra; then echo 'extra argument was accepted' >&2; exit 1; fi
[ "$(wc -l < "$fixture/compile.log" | tr -d ' ')" = 4 ]
"$launcher" --help
[ "$(find "$fixture/repo/examples/survivors/dist" -name '.native-*' | wc -l | tr -d ' ')" = 0 ]
echo 'NATIVE LAUNCHER PASS: rebuild, repo cwd, data cwd, repeat launch, no Node, build-only, failure preservation, arguments, cleanup'
