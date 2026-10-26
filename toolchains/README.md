Native builds use platform-specific compiler selection. `tools/clang` validates
the compiler on every invocation; requirements live in `toolchains/clang.env`.

On macOS, install Apple's Command Line Tools:

```sh
xcode-select --install
./tools/clang --bendvy-compiler-path
```

The wrapper selects Apple Clang through `xcrun --sdk macosx --find clang` and
requires Apple Clang 17 or newer. It resolves the SDK through
`xcrun --sdk macosx --show-sdk-path`, exports `SDKROOT`, and passes `-isysroot`
explicitly. The selected SDK must contain `usr/include/math.h`. Keep Xcode or
Command Line Tools and its SDK compatible; the minimum compiler version alone
does not establish SDK compatibility.

Homebrew LLVM 19 is not used on macOS because it cannot reliably compile the
new Apple framework module maps. The previous Linux compiler selection file is
ignored on macOS. Mac selections use `.toolchains/clang-apple.path` instead.

Linux requires upstream LLVM Clang **19.1.7**. Other patch releases, prereleases
and Apple Clang are refused. Select a manual installation with:

```sh
./tools/clang --select /opt/llvm-19.1.7/bin/clang
```

This records a local, ignored selection under `.toolchains/`. An explicit
`BENDVY_CLANG`, `CC`, or `CLANG` override must satisfy the current platform's
requirements. A wrong override fails instead of silently falling back. Native entrypoints set
`CC` to the repository wrapper so Bend's C compilation uses the same guard.
Native launch and batch execution require neither Docker, Node.js nor Python.

For a direct Bend-to-C build, set the same wrapper explicitly from the repository
root:

```sh
CC="$PWD/tools/clang" bend example.bend -o example
```

A raw `bend ... -o executable` command outside these entrypoints does not read
the repository pin automatically.

The exact Linux version pin is for reproducible native measurements. macOS
tracks the selected Apple developer tools and SDK. Artifacts and performance
measurements are not interchangeable between these environments.
