# Experimental Metal bot batches

This prepares a real GPU experiment for a macOS Apple Silicon host. **Metal compilation, GPU correctness and GPU performance have not been tested in the Linux development environment.** A successful CPU fallback check is not GPU evidence.

## Run on the Mac

From the `bendvy-ecs-examples` repository root:

```sh
bash tools/survivors-bot/metal-experiment.sh
```

The command needs Python 3 for orchestration, Bend 2.0.38 and Apple clang 17 or newer. The simulations themselves are native Bend, with no Node or classifier. `BEND` and `CC` can select tool paths. The version is intentionally pinned because the forced-dispatch check audits that runtime version; the script does not install or update tools.

Each invocation emits C from current sources, compiles the native executable, and builds the adjacent `.gpu` program in separately reported stages, then uses the same binary with `+RTS --gpu off -RTS` and `+RTS --gpu on -RTS`. It first compares two 60-tick smoke jobs. By default, measurement uses eight jobs of 120 ticks, three paired repetitions in alternating CPU/GPU order, and up to eight CPU threads. These small jobs establish feasibility and a short-run comparison, not late-game performance or optimal GPU occupancy. Compilation and smoke time are excluded from the timing medians.

The supervisor bounds C emission and native compilation to 300 seconds each. Metal compilation has its own 1200-second default budget (`--metal-build-seconds`, maximum 1800). Each simulation remains capped at 180 seconds; the overall default is 2400 seconds (`--total-seconds`, maximum 3600). It stops on compiler/runtime errors, timeout, changed inputs/artifacts or differing gameplay summary fields. It keeps the failure report and logs. The GPU is explicitly required for GPU cases; an unavailable Metal backend cannot silently run the experiment on CPU.

Copy the final console block, including PASS/FAIL, host/tool information, parity and dispatch status, timing and the `Report:` path. The report and raw logs are under ignored `examples/survivors/dist/metal-experiments/`; they remain on the shared filesystem. A failure is useful evidence: send the final error and report path rather than retrying a larger workload.

After the small run succeeds, workload size can be selected explicitly, for example `--count 32 --ticks 600`. Higher counts do not guarantee speed: this initial design parallelizes whole independent worlds, while each world's step remains sequential.

## Implementation and dispatch contract

`offline-gpu.bend` wraps the existing pure job scheduler with a marked `solve!(context, plan)` call. The host constructs a serial job plan, the marked call runs the independent worlds, and the host emits detached summaries after joining. Job policy, game mechanics and published BendHub ECS dependency are unchanged. The generic scheduler equivalence law continues to apply to its pure semantics; it does not prove Metal execution or floating-point parity.

The generated Bend 2.0.38 C was audited again after upgrading from 2.0.37; the check does not reuse the old runtime layout. Its function table is now a four-field `Fid` structure and Metal uses indirect dispatch with queued command buffers. It contains `BANGS=1`, a bang-flagged `FID_solve`, and a host task constructed with zero pending children. The host returns this task before the scheduler forks its jobs. With the explicit GPU requirement, the runtime routes this task through `cube_run(..., true)` to Metal dispatch, commit, wait and error checking. This matters because a generic binary with no bang calls, or a CPU frontier reached before the bang, would not establish GPU execution merely by accepting `+RTS --gpu on -RTS`.

The launcher checks the version-specific generated-code contract and requires the nonempty GPU sidecar. A completed positive-count run under the forced-Metal contract supplies execution evidence; this is not a GPU utilization-counter measurement. Source/tool/artifact hashes and the exact commands are retained. CPU and GPU results must match all gameplay summary fields exactly; timing is explicitly `wallMs: null` for both joined batches. Summary equality is narrower than full-world-state equivalence.

## Local validation

Initial Linux aarch64 validation used Bend 2.0.37: it successfully typechecked the entry and emitted C. The generated C was compiled with Clang 19 without a GPU backend, then run with that version's `--gpu off` syntax. Three wrapped-seed jobs at 60 ticks and two jobs at 1200 ticks exactly matched the original native batch summaries. The latter included upgrade decisions. Forcing that version's `--gpu on` on this CPU-only binary exited nonzero with `this binary has no CUDA or Metal GPU support` and no summary output.

The scheduler proof passes kernel verification, and the dependency audit confirms the published BendHub package remains the only ECS dependency. Actual Mac build and run results remain pending until the user executes the command above.

The 2.0.38 upgrade repeated C emission and compilation, matched the two 1200-tick summaries exactly against 2.0.37, and verified GPU refusal using the new `+RTS --gpu on -RTS` syntax. See [the compatibility update](bend-2.0.38-upgrade.md).

## First M2 Max host attempt and build-stage correction

The first host run (Mac14,6, Apple M2 Max, macOS 27.0, Apple clang 21.0.0, Bend 2.0.38) completed C emission in 12.13 seconds, then exceeded the combined 300-second build cap. A 6.78 MB arm64 Mach-O executable was present, but no `.gpu` archive, and build logs were empty. No simulations ran and no parity or performance result exists for that attempt.

The [official 2.0.38 builder](https://github.com/bendlang/bend/blob/v2.0.38/bend2/main.ts) performs native compilation followed by the executable's `+RTS --gpu-build` step. The artifacts therefore point to Metal preparation exceeding the shared budget; they do not establish whether the Metal compiler was making progress or stuck. The supervisor now runs those same two steps separately, using the official Apple clang flags and the already emitted C. It records the C and executable hashes before Metal compilation, provides a dedicated Metal budget, and reports exactly which stage fails. The original failed report is retained unchanged. A new Mac run is required to establish whether the longer Metal stage succeeds.
