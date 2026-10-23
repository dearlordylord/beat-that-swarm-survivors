# Bend 2.0.38 compatibility update

The active toolchain and CI now use Bend 2.0.38, the latest official release checked on 2026-10-23. The published `bendvy-ecs-core@0.1.0.1` package and manifest hash are unchanged. Earlier benchmark reports retain their original 2.0.37 toolchain and results; this upgrade does not requalify those performance numbers.

[Official release notes](https://github.com/bendlang/bend/releases/tag/v2.0.38) describe two relevant breaking changes:

- Native runtime flags now belong inside `+RTS … -RTS`. Native batch, replay and measurement launchers have been updated. Controlled experiments clear `BENDRTS` so ambient settings cannot change the declared run. The launchers' own user-facing `--threads` option is unchanged.
- Generated JavaScript constructors use their declaring-module names. Adapters and fixtures now use those tags directly, including exact cross-module comparisons. Imported function export keys use `module:function` rather than the old dot separator.

The Metal experiment now requires 2.0.38 and checks its actual generated runtime: lowercase `FID_solve`, the four-field `Fid` table, a zero-pending marked task, forced GPU routing, indirect Metal dispatch, command-buffer completion and error propagation. It does not accept the old three-field runtime layout. Actual macOS compilation and Metal execution still require the user's host run.

The Linux installation was updated using `bend update`; `bend version` reports `bend 2.0.38`. The old versioned 2.0.37 installation was preserved. CI downloads the official Linux x64 release archive and verifies SHA256 `f19d088b079c9e1a8834ecd153b7d58c11a5f8f9ab1bdb78dbc96a6bf49aaa81`.

For the Mac, update its local installation once, then run the same experiment from the examples repository:

```sh
bend update
bend version
bash tools/survivors-bot/metal-experiment.sh
```

The expected version is `bend 2.0.38`. Send the final experiment block and `Report:` path. No GPU performance result is claimed by this migration.

## Validation

Passed on Linux aarch64 with Bend 2.0.38 and Clang 19:

- Published dependency audit, including registry verification; browser bundle generation; full `examples/survivors/check.sh` gameplay checks.
- Full `check-native.sh`: persistence, native UI/event handling, batch failure/fuel fixtures and native application compilation. No interactive window was opened.
- Actual generated-JS adapter checks, including 98,304 dormant-state comparisons, 55,585 shot-spawn comparisons, 1,300 quiet-step comparisons and 3,600 risk-grid cells; runner/visible-process checks also passed.
- Native launcher/comparator/replay controls and 14 Metal-supervisor tests, including version acceptance/rejection and runtime-argument boundaries.
- Actual 2.0.38 GPU-entry CPU execution matched the two 1200-tick summaries from 2.0.37 exactly. Forced GPU execution on the CPU-only binary correctly failed with no summaries.
- The scheduler proof passed `--verdict` with `ELAN_TOOLCHAIN=leanprover/lean4:v4.34.0`. The first attempt with default Lean 4.35.0 failed the kernel's toolchain requirement; selecting the required version resolved that infrastructure failure.

The installed runtime and generated C were independently reviewed. Logs and the GPU runtime audit are retained in `/workspace/formal-proofs/bend-games/research/bend-2.0.38-upgrade/`. Actual Mac/Metal build, correctness and timing remain pending the host experiment.
