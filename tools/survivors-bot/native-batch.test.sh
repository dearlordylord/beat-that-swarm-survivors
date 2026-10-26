#!/usr/bin/env bash
# Wrapper contract with fake compiler/native binary. Node intentionally unavailable.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/nightfall-native-batch-test-XXXXXX")
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/tools/survivors-bot" "$fixture/repo/examples/survivors"
cp "$repo/tools/survivors-bot/native-batch.sh" "$fixture/repo/tools/survivors-bot/"
mkdir -p "$fixture/repo/toolchains" "$fixture/repo/scripts"
cp "$repo/tools/clang" "$fixture/repo/tools/clang"
cp "$repo/toolchains/clang.env" "$fixture/repo/toolchains/clang.env"
cp "$repo/scripts/native-toolchain.sh" "$fixture/repo/scripts/native-toolchain.sh"
cp "$repo/examples/common.sh" "$fixture/repo/examples/common.sh"
# Browser helpers must load without resolving a native compiler.
BENDVY_CLANG=/nonexistent/clang BENDVY_EXAMPLE_LOCK_HELD=1 bash -c 'source "$1"' _ "$fixture/repo/examples/common.sh"
cat > "$fixture/fake-clang" <<'CLANG'
#!/bin/sh
[ "$1" = --version ] || exit 1
printf '%s\n' 'clang version 19.1.7'
CLANG
chmod +x "$fixture/fake-clang"
export BENDVY_CLANG="$fixture/fake-clang"
touch "$fixture/repo/examples/survivors/offline-batch.bend" "$fixture/repo/examples/survivors/offline-parallel.bend"
cat > "$fixture/compiler" <<'COMPILER'
#!/usr/bin/env bash
set -euo pipefail
[[ $CC == "$FIXTURE/repo/tools/clang" ]]
[[ $1 == "$FIXTURE/repo/examples/survivors/${EXPECT_ENTRY:-offline-batch.bend}" && $2 == -o ]]
[[ ${FAIL_BUILD:-0} == 0 ]] || exit 42
echo build >> "$FIXTURE/builds"
cat > "$3" <<'BINARY'
#!/usr/bin/env bash
set -euo pipefail
[[ ${EMPTY_WORKER:-0} != 1 ]] || exit 0
[[ $# == 4 && $1 == +RTS && $2 == --threads && $3 == ${EXPECT_THREADS:-1} && $4 == -RTS ]]
[[ ${BENDRTS+x} != x ]]
for ((n=0; n<NIGHTFALL_BATCH_COUNT; n++)); do
  index=$((NIGHTFALL_BATCH_INDEX + n * NIGHTFALL_BATCH_STRIDE))
  seed=$(((NIGHTFALL_BATCH_SEED + index) % 4294967296))
  profile=$NIGHTFALL_BATCH_PROFILE
  if [[ $profile == both ]]; then
    profile=fresh
    ((index % 2 == 0)) || profile=advanced
  fi
  printf '%s %s %s %s\n' "$index" "$seed" "$profile" "$NIGHTFALL_BATCH_TICKS"
done
if [[ ${FAIL_WORKER:-0} == 1 && $NIGHTFALL_BATCH_INDEX == 0 ]]; then
  echo 'injected native worker failure' >&2
  exit 23
fi
if [[ ${SIGNAL_WRAPPER:-0} == 1 ]]; then
  kill -TERM "$PPID"
fi
BINARY
COMPILER
chmod +x "$fixture/compiler"
export BENDRTS="--threads 99 --gpu on"
export FIXTURE="$fixture" BEND="$fixture/compiler" NODE=/nonexistent/node BENDVY_EXAMPLE_LOCK_HELD=1
runner="$fixture/repo/tools/survivors-bot/native-batch.sh"
bash "$runner" --count 5 --seed 4294967294 --ticks 17 --profile both --workers 2 | sort -n > "$fixture/actual"
cat > "$fixture/expected" <<'EXPECTED'
0 4294967294 fresh 17
1 4294967295 advanced 17
2 0 fresh 17
3 1 advanced 17
4 2 fresh 17
EXPECTED
diff -u "$fixture/expected" "$fixture/actual"
[[ $(wc -l < "$fixture/builds") == 1 ]]
BENDVY_CLANG=/nonexistent/clang bash "$runner" --no-build --count 1 --ticks 1 --seed 0 --profile advanced > "$fixture/reuse"
[[ $(cat "$fixture/reuse") == '0 0 advanced 1' ]]
[[ $(wc -l < "$fixture/builds") == 1 ]]
for invalid in '--count 0' '--count -1' '--seed 4294967296' '--seed 01' '--ticks 0' '--workers 257' '--threads 0' '--threads 129' '--profile invalid' '--execution invalid' '--execution bend --workers 2' '--execution bend --count 1 --workers 2' '--bogus'; do
  if bash "$runner" $invalid > /dev/null 2>&1; then echo "Accepted invalid: $invalid" >&2; exit 1; fi
done
if FAIL_BUILD=1 bash "$runner" --count 1 > "$fixture/failed" 2>/dev/null; then exit 1; fi
[[ ! -s "$fixture/failed" ]]
if FAIL_WORKER=1 bash "$runner" --no-build --count 2 --workers 2 --output-dir "$fixture/failed-worker" > "$fixture/partial" 2>"$fixture/worker-failure.stderr"; then exit 1; fi
[[ -s "$fixture/failed-worker/worker-0.jsonl" && -s "$fixture/failed-worker/worker-1.jsonl" ]]
[[ $(cat "$fixture/failed-worker/worker-0.stderr") == 'injected native worker failure' ]]
[[ $(cat "$fixture/failed-worker/exit-status") == 1 ]]
grep -q 'Native batch worker 0 .*exit=23; stdout=.*worker-0.jsonl stderr=.*worker-0.stderr' "$fixture/worker-failure.stderr"
grep -q 'injected native worker failure' "$fixture/failed-worker/worker-0.stderr"
[[ $(cat "$fixture/failed-worker/completion.json") == '{"exitStatus":1,"requestedCount":2,"summaryLines":2}' ]]
if EMPTY_WORKER=1 bash "$runner" --no-build --count 1 --output-dir "$fixture/empty-worker" > /dev/null 2>"$fixture/empty-failure.stderr"; then exit 1; fi
grep -q 'Native batch summary count mismatch: expected=1 actual=0' "$fixture/empty-failure.stderr"
[[ $(cat "$fixture/empty-worker/completion.json") == '{"exitStatus":1,"requestedCount":1,"summaryLines":0}' ]]
signal_status=0
SIGNAL_WRAPPER=1 bash "$runner" --no-build --count 1 --output-dir "$fixture/interrupted" > /dev/null 2>/dev/null || signal_status=$?
[[ $signal_status == 143 && -s "$fixture/interrupted/worker-0.jsonl" && -s "$fixture/interrupted/manifest.json" ]]
# Native Bend mode has a separate entry/artifact and one runtime pool.
if bash "$runner" --execution bend --no-build --count 1 > /dev/null 2>/dev/null; then echo 'Reused process binary for Bend mode' >&2; exit 1; fi
EXPECT_ENTRY=offline-parallel.bend EXPECT_THREADS=4 bash "$runner" --execution bend --count 5 --seed 4294967294 --ticks 17 --threads 4 --output-dir "$fixture/bend" > "$fixture/bend-actual"
diff -u "$fixture/expected" "$fixture/bend-actual"
[[ -x "$fixture/repo/examples/survivors/dist/nightfall-batch" && -x "$fixture/repo/examples/survivors/dist/nightfall-parallel-batch" ]]
[[ $(wc -l < "$fixture/builds") == 2 ]]
[[ $(cat "$fixture/bend/manifest.json") == *'"execution":"bend"'* ]]
[[ $(cat "$fixture/bend/manifest.json") == *'"workers":1,"threadsPerWorker":4'* ]]
[[ ! -e "$fixture/bend/worker-1.jsonl" ]]
EXPECT_THREADS=4 bash "$runner" --execution bend --no-build --count 1 --threads 4 > "$fixture/bend-reuse"
[[ $(wc -l < "$fixture/builds") == 2 ]]
bash "$runner" --execution processes --no-build --count 1 --output-dir "$fixture/processes" > /dev/null
[[ $(cat "$fixture/processes/manifest.json") == *'"execution":"processes"'* ]]
if NIGHTFALL_BATCH_EXECUTION=bend NIGHTFALL_BATCH_WORKERS=2 bash "$runner" --no-build --count 1 > /dev/null 2>&1; then exit 1; fi
echo 'NATIVE BATCH WRAPPER PASS'
