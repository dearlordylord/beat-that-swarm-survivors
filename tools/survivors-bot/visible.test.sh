#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/nightfall-visible-test-XXXXXX")
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/tools/survivors-bot" "$fixture/repo/examples/survivors" "$fixture/repo/scripts" "$fixture/repo/toolchains"
cp "$repo/tools/survivors-bot/visible.sh" "$fixture/repo/tools/survivors-bot/"
cp "$repo/tools/clang" "$fixture/repo/tools/clang"
cp "$repo/scripts/native-toolchain.sh" "$fixture/repo/scripts/native-toolchain.sh"
cp "$repo/toolchains/clang.env" "$fixture/repo/toolchains/clang.env"
cat > "$fixture/compiler" <<'COMPILER'
#!/usr/bin/env bash
set -euo pipefail
[[ $CC == "$FIXTURE/repo/tools/clang" ]]
[[ $1 == "$FIXTURE/repo/examples/survivors/native-bot.bend" && $2 == -o ]]
[[ ${FAIL_BUILD:-0} == 0 ]] || exit 42
printf 'build\n' >> "$FIXTURE/builds"
cat > "$3" <<'BINARY'
#!/usr/bin/env bash
set -euo pipefail
[[ ${BENDRTS+x} != x ]]
printf '%s %s %s %s\n' "$NIGHTFALL_BOT_PROFILE" "$NIGHTFALL_BOT_SEED" "$NIGHTFALL_BOT_TICKS" "$NIGHTFALL_BOT_SECONDS"
exit "${NATIVE_EXIT:-0}"
BINARY
COMPILER
cat > "$fixture/clang" <<'CLANG'
#!/bin/sh
[ "$1" = --version ] || exit 1
printf '%s\n' 'clang version 19.1.7'
CLANG
chmod +x "$fixture/compiler" "$fixture/clang"
export FIXTURE="$fixture" BEND="$fixture/compiler" BENDVY_CLANG="$fixture/clang" NODE=/nonexistent/node PYTHON=/nonexistent/python
export BENDRTS='--gpu on --threads 99'
runner="$fixture/repo/tools/survivors-bot/visible.sh"
bash "$runner" --profile advanced --seed 4294967295 --ticks 1800 --seconds 45 > "$fixture/actual"
[[ $(cat "$fixture/actual") == 'advanced 4294967295 1800 45' ]]
[[ $(wc -l < "$fixture/builds") == 1 ]]
BENDVY_CLANG=/nonexistent/clang bash "$runner" --no-build --seed 0 > "$fixture/reuse"
[[ $(cat "$fixture/reuse") == 'fresh 0 0 0' ]]
[[ $(wc -l < "$fixture/builds") == 1 ]]
bash "$runner" --build-only > "$fixture/build-only"
[[ $(cat "$fixture/build-only") == "Built: $fixture/repo/examples/survivors/dist/nightfall-bot" ]]
[[ $(wc -l < "$fixture/builds") == 2 ]]
for invalid in '--seed 01' '--seed -1' '--seed 4294967296' '--ticks 1.5' '--seconds 4294968' '--profile both' '--no-build --build-only' '--mode heuristic' '--bogus'; do
  if bash "$runner" $invalid >/dev/null 2>&1; then echo "Accepted invalid: $invalid" >&2; exit 1; fi
done
status=0
FAIL_BUILD=1 bash "$runner" > "$fixture/failed" 2>/dev/null || status=$?
[[ $status == 42 && ! -s "$fixture/failed" ]]
status=0
NATIVE_EXIT=23 bash "$runner" --no-build >/dev/null || status=$?
[[ $status == 23 ]]
for obsolete in run.mts runner.mts planner.mts provider.mts context.mts visible.mts visible-controller.mts batch.mts batch-worker.mts batch-wall.mts; do
  [[ ! -e "$repo/tools/survivors-bot/$obsolete" ]] || { echo "Obsolete external bot controller: $obsolete" >&2; exit 1; }
done
if rg -n '(python[0-9]*|node|observation\.json|command-)' "$repo/tools/survivors-bot/visible.sh"; then
  echo 'Native visible launcher reintroduced an external controller dependency.' >&2
  exit 1
fi
echo 'NATIVE VISIBLE WRAPPER PASS'
