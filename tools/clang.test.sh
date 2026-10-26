#!/bin/sh
# Isolated compiler-wrapper contract; no game build or scripting runtime needed.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/bendvy-clang-test-XXXXXX")
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/repo/tools" "$fixture/repo/toolchains" "$fixture/compiler with spaces"
cp "$repo/tools/clang" "$fixture/repo/tools/clang"
cp "$repo/toolchains/clang.env" "$fixture/repo/toolchains/clang.env"
wrapper=$fixture/repo/tools/clang
compiler=$fixture/compiler\ with\ spaces/clang
cat > "$compiler" <<'COMPILER'
#!/bin/sh
if [ "$1" = --version ]; then
  printf '%s\n' "$TEST_CLANG_VERSION"
  exit "${TEST_VERSION_STATUS:-0}"
fi
printf '%s\n' "$@" > "$TEST_CLANG_ARGUMENTS"
exit "${TEST_COMPILE_STATUS:-0}"
COMPILER
chmod +x "$compiler"
unset CC CLANG BENDVY_CLANG
export TEST_CLANG_VERSION='clang version 19.1.7'
export TEST_CLANG_ARGUMENTS="$fixture/arguments"
export NODE=/nonexistent/node PYTHON=/nonexistent/python
expect_failure() {
  if "$@" > "$fixture/stdout" 2> "$fixture/stderr"; then
    echo "Expected failure: $*" >&2
    exit 1
  fi
}
[ "$(BENDVY_CLANG="$compiler" "$wrapper" --bendvy-compiler-path)" = "$compiler" ]
BENDVY_CLANG="$compiler" "$wrapper" 'source with spaces.c' -o 'output with spaces' '-DVALUE=$literal'
printf '%s\n' 'source with spaces.c' -o 'output with spaces' '-DVALUE=$literal' > "$fixture/expected"
cmp "$fixture/expected" "$fixture/arguments"
status=0
BENDVY_CLANG="$compiler" TEST_COMPILE_STATUS=23 "$wrapper" -c file.c || status=$?
[ "$status" = 23 ]
for version in 'clang version 14.0.0' 'clang version 19.1.6' 'clang version 21.0.0' 'Apple clang version 19.1.7' 'clang version 19.1.70' 'clang version 19.1.7git' 'clang version 19.1.7-rc1'; do
  expect_failure env BENDVY_CLANG="$compiler" TEST_CLANG_VERSION="$version" "$wrapper" --bendvy-compiler-path
done
expect_failure env BENDVY_CLANG="$compiler" TEST_VERSION_STATUS=42 "$wrapper" --bendvy-compiler-path
expect_failure env BENDVY_CLANG=/nonexistent/clang "$wrapper" --bendvy-compiler-path
expect_failure env CC="$compiler" TEST_CLANG_VERSION='clang version 19.1.6' "$wrapper" --bendvy-compiler-path
expect_failure env CLANG="$compiler" TEST_CLANG_VERSION='clang version 21.0.0' "$wrapper" --bendvy-compiler-path
expect_failure env CC="$wrapper" "$wrapper" --bendvy-compiler-path
"$wrapper" --select "$compiler"
[ "$("$wrapper" --bendvy-compiler-path)" = "$compiler" ]
cp "$compiler" "$fixture/original-compiler"
sed 's/"$TEST_CLANG_VERSION"/"clang version 19.1.6"/' "$fixture/original-compiler" > "$compiler"
expect_failure "$wrapper" --bendvy-compiler-path
cp "$fixture/original-compiler" "$compiler"
sed 's/19\.1\.7/19.1.8/g' "$fixture/repo/toolchains/clang.env" > "$fixture/pin"
mv "$fixture/pin" "$fixture/repo/toolchains/clang.env"
expect_failure "$wrapper" --bendvy-compiler-path
printf '%s\n' 'CLANG WRAPPER PASS: exact version, overrides, selection, revalidation, argument forwarding'
