Native builds require upstream Clang **19.1.7**. The pin lives in
`toolchains/clang.env`; `tools/clang` checks the compiler on every invocation.
Apple Clang, other patch releases, and prerelease builds are refused.

On macOS, install the pinned Homebrew formula once:

```sh
brew install llvm@19
./tools/clang --bendvy-compiler-path
```

The wrapper finds Homebrew's `llvm@19` automatically. On Linux, or with a manual
LLVM installation, select the actual executable:

```sh
./tools/clang --select /opt/llvm-19.1.7/bin/clang
```

This records a local, ignored selection under `.toolchains/`. An explicit
`BENDVY_CLANG`, `CC`, or `CLANG` override must also identify upstream 19.1.7;
a wrong override fails instead of silently falling back. Native entrypoints set
`CC` to the repository wrapper so Bend's C compilation uses the same guard.
Native launch and batch execution require neither Docker, Node.js nor Python.

For a direct Bend-to-C build, set the same wrapper explicitly from the repository
root:

```sh
CC="$PWD/tools/clang" bend example.bend -o example
```

A raw `bend ... -o executable` command outside these entrypoints does not read
the repository pin automatically.

The compiler pin does not promise identical artifacts across operating systems:
SDKs, system headers, libraries, and linkers can still differ.
