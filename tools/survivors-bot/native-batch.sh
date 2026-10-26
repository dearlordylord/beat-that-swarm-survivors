#!/usr/bin/env bash
# Rebuild Bend -> C -> native executable; no Node runtime or graphics.
set -euo pipefail
# Controlled batch settings come from explicit options, not ambient runtime flags.
unset BENDRTS
cd "$(dirname -- "$0")/../.."
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
source "$PWD/scripts/native-toolchain.sh"
count=${NIGHTFALL_BATCH_COUNT:-100}
ticks=${NIGHTFALL_BATCH_TICKS:-1800}
seed=${NIGHTFALL_BATCH_SEED:-12345}
profile=${NIGHTFALL_BATCH_PROFILE:-both}
workers=${NIGHTFALL_BATCH_WORKERS:-1}
threads=${NIGHTFALL_BATCH_THREADS:-1}
execution=${NIGHTFALL_BATCH_EXECUTION:-processes}
build=1
output_dir=${NIGHTFALL_BATCH_OUTPUT_DIR:-}
usage() { echo 'native-batch.sh [--count N] [--ticks N] [--seed U32] [--profile fresh|advanced|both] [--execution processes|bend] [--workers N] [--threads N] [--no-build] [--output-dir PATH]'; }
while (($#)); do
  case "$1" in
    --help) usage; exit 0 ;;
    --output-dir) [[ $# -ge 2 ]] || exit 2; output_dir=$2; shift 2 ;;
    --no-build) build=0; shift ;;
    --count|--ticks|--seed|--profile|--workers|--threads|--execution)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      key=${1#--}; printf -v "$key" '%s' "$2"; shift 2 ;;
    *) usage >&2; exit 2 ;;
  esac
done
unsigned() { [[ $1 =~ ^(0|[1-9][0-9]{0,9})$ ]] && ((10#$1 <= 4294967295)); }
for key in count ticks seed workers threads; do
  unsigned "${!key}" || { echo "Invalid $key (expected U32)" >&2; exit 2; }
done
((count > 0 && count <= 10000 && ticks > 0 && ticks <= 37000 && workers > 0 && workers <= 256 && threads > 0 && threads <= 128)) || { echo 'Invalid bounds: count 1..10000; ticks 1..37000; workers 1..256; threads 1..128' >&2; exit 2; }
[[ $profile == fresh || $profile == advanced || $profile == both ]] || { echo 'Invalid profile' >&2; exit 2; }
[[ $execution == processes || $execution == bend ]] || { echo 'Invalid execution (expected processes or bend)' >&2; exit 2; }
if [[ $execution == bend && $workers != 1 ]]; then
  echo 'Bend execution requires --workers 1; use --threads for its runtime pool.' >&2
  exit 2
fi
((workers <= count)) || workers=$count
entry=offline-batch.bend
binary_name=nightfall-batch
if [[ $execution == bend ]]; then
  entry=offline-parallel.bend
  binary_name=nightfall-parallel-batch
fi
app_dir="$PWD/examples/survivors"
mkdir -p "$app_dir/dist"
staging=$(mktemp -d "$app_dir/dist/.native-batch-XXXXXX")
pids=()
output_dir=${output_dir:-$app_dir/dist/native-batches/$(date -u +%Y%m%dT%H%M%SZ)-$$}
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
printf '{"backend":"native","execution":"%s","count":%s,"ticks":%s,"seed":%s,"profile":"%s","workers":%s,"threadsPerWorker":%s,"buildOnLaunch":%s}\n' "$execution" "$count" "$ticks" "$seed" "$profile" "$workers" "$threads" "$build" > "$output_dir/manifest.json"
echo "Native batch receipts: $output_dir" >&2
find "$app_dir" -path "$app_dir/dist" -prune -o -type f -name '*.bend' -print | LC_ALL=C sort > "$output_dir/source-files.txt"
if command -v sha256sum >/dev/null 2>&1; then
  while IFS= read -r source_file; do sha256sum "$source_file"; done < "$output_dir/source-files.txt" > "$output_dir/source-sha256.txt"
elif command -v shasum >/dev/null 2>&1; then
  while IFS= read -r source_file; do shasum -a 256 "$source_file"; done < "$output_dir/source-files.txt" > "$output_dir/source-sha256.txt"
fi
cleanup() {
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  for pid in "${pids[@]}"; do wait "$pid" 2>/dev/null || true; done
  rm -rf "$staging"
  if [[ -n ${lock_dir:-} ]]; then rmdir "$lock_dir" 2>/dev/null || true; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ ${BENDVY_EXAMPLE_LOCK_HELD:-0} != 1 ]]; then
  if command -v flock >/dev/null 2>&1; then
    exec 9>/tmp/bendvy-parity-heavy.lock
    flock -n 9 || { echo 'Backend checks are already running; retry later.' >&2; exit 75; }
  else
    lock_dir="${TMPDIR:-/tmp}/bendvy-examples-heavy.lock.d"
    mkdir "$lock_dir" 2>/dev/null || { echo "Backend checks running or stale lock: $lock_dir" >&2; exit 75; }
  fi
fi
if ((build)); then
  native_toolchain_require
  echo 'Compiling native Bend batch runner…' >&2
  "${BEND:-bend}" "$app_dir/$entry" -o "$staging/$binary_name" >&2
  chmod +x "$staging/$binary_name"
  mv -f "$staging/$binary_name" "$app_dir/dist/$binary_name"
fi
[[ -x "$app_dir/dist/$binary_name" ]] || { echo 'Missing native binary; run without --no-build first.' >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$app_dir/dist/$binary_name" > "$output_dir/binary-sha256.txt"
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$app_dir/dist/$binary_name" > "$output_dir/binary-sha256.txt"
fi
# Process mode distributes worlds across processes. Bend mode sends every world
# to one process; its Bend entry forks pure runs onto the runtime thread pool.
# Each process owns an independent game world. Global index controls seed/profile;
# round-robin assignment remains deterministic across worker counts.
for ((worker=0; worker<workers; worker++)); do
  jobs=$(((count - 1 - worker) / workers + 1))
  NIGHTFALL_BATCH_COUNT=$jobs NIGHTFALL_BATCH_TICKS=$ticks NIGHTFALL_BATCH_SEED=$seed \
  NIGHTFALL_BATCH_PROFILE=$profile NIGHTFALL_BATCH_INDEX=$worker NIGHTFALL_BATCH_STRIDE=$workers \
    "$app_dir/dist/$binary_name" +RTS --threads "$threads" -RTS >"$output_dir/worker-$worker.jsonl" 2>"$output_dir/worker-$worker.stderr" &
  pids+=("$!")
done
status=0
: > "$output_dir/worker-statuses"
worker=0
for pid in "${pids[@]}"; do
  worker_status=0
  wait "$pid" || worker_status=$?
  printf '%s %s\n' "$pid" "$worker_status" >> "$output_dir/worker-statuses"
  if ((worker_status != 0)); then
    printf 'Native batch worker %s (pid %s) failed: exit=%s; stdout=%s/worker-%s.jsonl stderr=%s/worker-%s.stderr\n' "$worker" "$pid" "$worker_status" "$output_dir" "$worker" "$output_dir" "$worker" >&2
    status=1
  fi
  worker=$((worker + 1))
done
pids=()
for ((worker=0; worker<workers; worker++)); do cat "$output_dir/worker-$worker.jsonl"; done
records=0
for ((worker=0; worker<workers; worker++)); do
  lines=$(wc -l < "$output_dir/worker-$worker.jsonl")
  records=$((records + lines))
done
if ((records != count)); then
  printf 'Native batch summary count mismatch: expected=%s actual=%s; inspect %s/worker-*.jsonl and worker-*.stderr\n' "$count" "$records" "$output_dir" >&2
  status=1
fi
printf '{"exitStatus":%d,"requestedCount":%d,"summaryLines":%d}\n' "$status" "$count" "$records" > "$output_dir/completion.json"
printf '%s\n' "$status" > "$output_dir/exit-status"
exit "$status"
