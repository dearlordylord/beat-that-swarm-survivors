#!/usr/bin/env bash
set -euo pipefail
unset BENDRTS
cd "$(dirname -- "$0")/../.."
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
profile=${NIGHTFALL_BOT_PROFILE:-fresh}
seed=${NIGHTFALL_BOT_SEED:-12345}
ticks=${NIGHTFALL_BOT_TICKS:-0}
seconds=${NIGHTFALL_BOT_SECONDS:-0}
pacing=${NIGHTFALL_BOT_PACING:-realtime}
build=1
build_only=0
force_build=0
usage() { echo 'visible.sh [--profile fresh|advanced] [--seed U32] [--ticks U32] [--seconds N] [--unlimited] [--no-build|--build-only|--rebuild]'; }
while (($#)); do
  case "$1" in
    --help) usage; exit 0 ;;
    --no-build) build=0; shift ;;
    --build-only) build_only=1; shift ;;
    --rebuild) force_build=1; shift ;;
    --unlimited) pacing=unlimited; shift ;;
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
[[ $pacing == realtime || $pacing == unlimited ]] || { echo 'Invalid pacing' >&2; exit 2; }
((seconds <= 4294967)) || { echo 'Seconds must be at most 4294967.' >&2; exit 2; }
((build || (!build_only && !force_build))) || { echo '--no-build cannot be combined with --build-only or --rebuild.' >&2; exit 2; }
app_dir="$PWD/examples/survivors"
binary="$app_dir/dist/nightfall-bot"
if ((build)); then
  source "$PWD/scripts/native-toolchain.sh"
  native_toolchain_require
  mkdir -p "$app_dir/dist"
  if command -v sha256sum >/dev/null 2>&1; then hash_command=(sha256sum); else hash_command=(shasum -a 256); fi
  bend_executable=$(command -v "${BEND:-bend}")
  while [[ -L $bend_executable ]]; do
    link=$(readlink "$bend_executable")
    if [[ $link == /* ]]; then bend_executable=$link; else bend_executable="$(dirname "$bend_executable")/$link"; fi
  done
  bend_executable="$(cd "$(dirname "$bend_executable")" && pwd -P)/$(basename "$bend_executable")"
  bend_runtime="$(dirname "$bend_executable")/../bend2"
  bend_library=${BEND_LIB:-$HOME/.bend/lib}
  if [[ ! -d $bend_library ]]; then "${BEND:-bend}" "$app_dir/native-bot.bend" --check-only; fi
  build_inputs() {
    printf '%s\n' native-bot-cache-v1 "$bend_executable" "$CLANG" "$bend_runtime" "$bend_library"
    "${BEND:-bend}" version || return
    "$CLANG" --version || return
    uname -srm || return
    "${hash_command[@]}" "$bend_executable" "$CLANG" "$CC" "$PWD/tools/survivors-bot/visible.sh" scripts/native-toolchain.sh toolchains/clang.env bendhub-dependencies.json || return
    find "$app_dir" -path "$app_dir/dist" -prune -o -type f -name '*.bend' -print | LC_ALL=C sort | while IFS= read -r file; do
      "${hash_command[@]}" "$file" || exit
    done || return
    for directory in "$bend_runtime" "$bend_library"; do
      [[ -d $directory ]] || { echo "Cannot locate Bend build inputs: $directory" >&2; return 1; }
      find -L "$directory" -type f -print | LC_ALL=C sort | while IFS= read -r file; do
        "${hash_command[@]}" "$file" || exit
      done || return
    done
    if [[ -n ${SDKROOT:-} ]]; then
      for file in SDKSettings.json SDKSettings.plist usr/include/module.modulemap usr/include/math.h; do
        if [[ -f $SDKROOT/$file ]]; then "${hash_command[@]}" "$SDKROOT/$file" || return; fi
      done
    fi
    env | LC_ALL=C sort | while IFS= read -r entry; do
      case "$entry" in
        BEND_*=*|SDKROOT=*|DEVELOPER_DIR=*|MACOSX_DEPLOYMENT_TARGET=*|CPATH=*|C_INCLUDE_PATH=*|CPLUS_INCLUDE_PATH=*|OBJC_INCLUDE_PATH=*|LIBRARY_PATH=*|COMPILER_PATH=*) printf '%s\n' "$entry" ;;
      esac
    done
  }
  build_key() { build_inputs | "${hash_command[@]}" | awk '{print $1}'; }
  binary_hash() { "${hash_command[@]}" "$1" | awk '{print $1}'; }
  input_key=$(build_key)
  receipt="$binary.build-key"
  cached=0
  if (( !force_build )) && [[ -x $binary && -f $receipt ]]; then
    [[ $(cat "$receipt") != "$input_key $(binary_hash "$binary")" ]] || cached=1
  fi
  if ((cached)); then
    echo 'Native bot is up to date.' >&2
  else
    staging=$(mktemp -d "$app_dir/dist/.native-bot-XXXXXX")
    trap 'rm -rf "$staging"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    echo 'Building native bot…' >&2
    "${BEND:-bend}" "$app_dir/native-bot.bend" -o "$staging/nightfall-bot"
    [[ $(build_key) == "$input_key" ]] || { echo 'Build inputs changed during compilation; rerun the launcher.' >&2; exit 75; }
    chmod +x "$staging/nightfall-bot"
    printf '%s %s\n' "$input_key" "$(binary_hash "$staging/nightfall-bot")" > "$staging/build-key"
    mv -f "$staging/nightfall-bot" "$binary"
    mv -f "$staging/build-key" "$receipt"
    rm -rf "$staging"
    trap - EXIT INT TERM
  fi
fi
[[ -x $binary ]] || { echo 'Missing native bot; run without --no-build first.' >&2; exit 1; }
if ((build_only)); then
  echo "Ready: $binary"
  exit 0
fi
export NIGHTFALL_BOT_PROFILE=$profile NIGHTFALL_BOT_SEED=$seed NIGHTFALL_BOT_TICKS=$ticks NIGHTFALL_BOT_SECONDS=$seconds NIGHTFALL_BOT_PACING=$pacing
exec "$binary"
