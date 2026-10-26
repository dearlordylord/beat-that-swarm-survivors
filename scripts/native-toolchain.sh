#!/usr/bin/env bash

native_toolchain_repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
native_toolchain_wrapper="$native_toolchain_repo/tools/clang"
if [[ -z ${BENDVY_CLANG:-} ]]; then
  if [[ -n ${CC:-} && $CC != "$native_toolchain_wrapper" ]]; then
    export BENDVY_CLANG=$CC
  elif [[ -n ${CLANG:-} && $CLANG != "$native_toolchain_wrapper" ]]; then
    export BENDVY_CLANG=$CLANG
  fi
fi
export CC="$native_toolchain_wrapper"
export CLANG="$native_toolchain_wrapper"

native_toolchain_require() {
  CLANG=$("$CC" --bendvy-compiler-path) || return
  export CLANG
  if command -v sha256sum >/dev/null 2>&1; then
    BEND_NATIVE_TOOLCHAIN_FINGERPRINT=$(sha256sum "$native_toolchain_repo/toolchains/clang.env" "$native_toolchain_repo/scripts/native-toolchain.sh" "$native_toolchain_wrapper") || return
  elif command -v shasum >/dev/null 2>&1; then
    BEND_NATIVE_TOOLCHAIN_FINGERPRINT=$(shasum -a 256 "$native_toolchain_repo/toolchains/clang.env" "$native_toolchain_repo/scripts/native-toolchain.sh" "$native_toolchain_wrapper") || return
  else
    echo 'Native toolchain verification requires sha256sum or shasum.' >&2
    return 1
  fi
  export BEND_NATIVE_TOOLCHAIN_FINGERPRINT
}
