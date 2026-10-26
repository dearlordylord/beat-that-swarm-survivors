# Parallel native bot grid

The native grid executes independent worlds and renders their tiles with Bend
CPU fork/join calls. A persistent balanced affine tree owns each world's game
state and policy memory. The IO loop reads the round clock, joins pure work,
then checks errors and reports completions in stable bot order. Count one keeps
the existing single-bot path. No ECS package or engine source changed.

Run from the examples repository root:

```sh
bash tools/survivors-bot/visible.sh --count 10 --threads 8 --profile advanced --unlimited
```

Omit `--unlimited` for realtime pacing. `--threads auto` is the default. The grid
prints its actual runtime thread count. Runtime pool size alone did not make
the former IO-sequenced loop parallel. The new pure traversal contains explicit
parallel calls. The emitted C contains separate child tasks and their join for
both world advancement and views.

## Checks

The generic actual-context scheduler law passes kernel verification. Reversing
the result branches is a well-typed mutant and fails that proof. This is a
scheduler law for arbitrary Data inputs and functions, not whole-game refinement
for affine ECS owners.

A native detailed probe compares ten advanced worlds for 300 ticks each using
serial mapping on one thread and parallel mapping on one and four threads.
Their captures match byte for byte. Captures include full Run values, offers,
snapshots, pending values, policy memory, choices and exact F32 bits. Hidden ECS
storage is not captured. The mixed-bound native probe confirms a world stopped
at tick one stays frozen while nine others advance to tick two.

Launcher fixtures pass, including runtime thread flags and invalid arguments.
A real X11 window showed all ten worlds with four runtime threads. Independent
source review found no blocker in ownership, ordering, bounds, completion,
error reporting or thread selection.

## Window timing

Linux aarch64, Bend 2.0.39, pinned LLVM Clang 19.1.7, native `-O3`.
Both configurations were restricted to CPUs 0–3. The workload was ten advanced
worlds, seeds 12345–12354, 300 ticks each, unlimited pacing, one Xvfb window.
Five alternating one-thread/four-thread pairs completed. No run was dropped.
Wall time includes native startup, simulation, tile rendering and presentation.
Compilation is excluded.

| Runtime threads | Median wall seconds | Minimum | Maximum |
|---:|---:|---:|---:|
| 1 | 21.101 | 19.884 | 25.257 |
| 4 | 8.817 | 8.486 | 12.583 |

The ratio of median wall times is 2.39. This compares the new implementation
at one and four threads, not the old sequential implementation against the new
one. Four-thread user CPU time exceeded wall time, confirming simultaneous CPU
work rather than merely creating idle worker threads.

This is an early-game fixture on one Linux host, not a macOS result, a linear
scaling guarantee or the separate 100× headless target. Rendering follows wall
time, so frame counts can differ. Remaining scheduler, reference-counting and
display overhead was not profiled. Reproduce on the target host before using
these timings as a capacity estimate.

[Samples, hashes and comparison scope](native-bot-grid-parallel-results.json)
record the individual times. [Validation commands](../tools/survivors-bot/VALIDATION.md#parallel-native-grid)
rebuild the detailed comparison probe.
