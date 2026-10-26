#!/usr/bin/env bash
set -euo pipefail
unset BENDRTS
cd "$(dirname -- "$0")/../.."
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
profile=${NIGHTFALL_BOT_PROFILE:-fresh}
seed=${NIGHTFALL_BOT_SEED:-12345}
ticks=${NIGHTFALL_BOT_TICKS:-0}
seconds=${NIGHTFALL_BOT_SECONDS:-0}
build=1
build_only=0
usage() { echo 'visible.sh [--profile fresh|advanced] [--seed U32] [--ticks U32] [--seconds N] [--no-build|--build-only]'; }
while (($#)); do
  case "$1" in
    --help) usage; exit 0 ;;
    --no-build) build=0; shift ;;
    --build-only) build_only=1; shift ;;
    --profile|--seed|--ticks|--seconds)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      key=${1#--}; printf -v "$key" '%s' "$2"; shift 2 ;;
    *) usage >&2; exit 2 ;;
  esac
done
unsigned() { [[ $1 =~ ^(0|[1-9][0-9]{0,9})$ ]] && ((10#$1 <= 4294967295)); }
for key in seed ticks seconds; do
  unsigned "${!key}" || { echo "Invalid $key (expected U32)" >&2; exit 2; }
done
[[ $profile == fresh || $profile == advanced ]] || { echo 'Invalid profile' >&2; exit 2; }
((seconds <= 4294967)) || { echo 'Seconds must be at most 4294967.' >&2; exit 2; }
((build || !build_only)) || { echo '--no-build and --build-only cannot be combined.' >&2; exit 2; }
app_dir="$PWD/examples/survivors"
binary="$app_dir/dist/nightfall-bot"
if ((build)); then
  source "$PWD/scripts/native-toolchain.sh"
  native_toolchain_require
  mkdir -p "$app_dir/dist"
  staging=$(mktemp -d "$app_dir/dist/.native-bot-XXXXXX")
  trap 'rm -rf "$staging"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  "${BEND:-bend}" "$app_dir/native-bot.bend" -o "$staging/nightfall-bot"
  chmod +x "$staging/nightfall-bot"
  mv -f "$staging/nightfall-bot" "$binary"
  rm -rf "$staging"
  trap - EXIT INT TERM
fi
[[ -x $binary ]] || { echo 'Missing native bot; run without --no-build first.' >&2; exit 1; }
if ((build_only)); then
  echo "Built: $binary"
  exit 0
fi
export NIGHTFALL_BOT_PROFILE=$profile NIGHTFALL_BOT_SEED=$seed NIGHTFALL_BOT_TICKS=$ticks NIGHTFALL_BOT_SECONDS=$seconds
exec "$binary"
