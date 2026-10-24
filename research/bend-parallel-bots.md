# Native bot parallelism inside Bend

The new opt-in `--execution bend` mode executes independent Survivors worlds in one native process using Bend's explicit parallel calls. The existing process mode remains the default. Game mechanics, the offline resource-memory policy and published BendHub ECS dependency are unchanged.

## Implementation

The process and Bend entries are
[offline-batch.bend](../examples/survivors/offline-batch.bend) and
[offline-parallel.bend](../examples/survivors/offline-parallel.bend), with the
[scheduler](../examples/survivors/parallel/scheduler.bend) owning plan construction
and parallel traversal. Their algorithms, record layouts and argument defaults
are not duplicated here.

The design separates independent simulation owners from detached batch results.
Batch time and individual-job time are different measurements; a pure job does
not gain an individual IO clock merely by executing inside a parallel batch.
The scheduler/compiler source reference inspected was
`a950fd683c0d76f09794078e6174fe98a1492876`, older than the installed compiler.
Actual emitted C was inspected separately; neither inspection alone establishes
scaling or game equivalence.

## Prototype and correctness

A disposable eight-leaf numeric prototype, each leaf owning a 64-element array, confirmed native parallel execution. At 100 million iterations per leaf, elapsed times for 1/2/4/8 threads were 2.535/1.287/0.989/0.749 seconds, with identical checksums. Eight-thread CPU user time was 2.717 seconds, exceeding elapsed time. A shorter version matched an independent scalar oracle. These single samples demonstrate feasibility only. Prototype source, executable, emitted C and scripts were deleted before the game implementation, as requested.

The scheduler's generic equivalence law passes Bend's kernel verification: for every finite plan and pure job function, parallel mapping produces the same result tree as serial mapping. This does not prove whole-game equivalence or speed. Four finite fixtures check empty/singleton plans, odd counts with nonzero stride, and U32 wrapping indices.

Actual native smoke comparisons match every gameplay summary field against the unmodified baseline: one job, three jobs across seed wrap, and two 1200-tick jobs at one/four threads. The latter exercised one and three upgrade decisions. A native failure fixture verifies engine errors, safety-fuel exhaustion and completed-horizon precedence. Launcher and comparator tests cover mode separation, validation, failure cleanup, semantic divergence and the explicit timing contract.

## Measurement method

The baseline is examples commit `7ba26b54738fdbda0d46b878e146dbdb2dc2d41a`, with its original batch executable frozen before edits. Both binaries use installed Bend 2.0.37, Clang 19, and published BendHub `bendvy-ecs-core@0.1.0.1` (manifest SHA256 `f435da9e535b3846d643dad16580e35fb9ae485317226d9d0325ad1dcaa1fdb0`). These are current-balance runs; earlier optimization-campaign measurements are not comparison inputs.

Host: Linux aarch64, 12 available logical CPUs, no cgroup CPU quota. Eight jobs use seeds 100–107 and alternating fresh/advanced profiles, each for 1200 simulation ticks. For CPU budget B, the control uses B native processes with one thread each; the candidate uses one native process with B Bend threads. Both use the same first B CPUs. Three paired repetitions alternate execution order. Compilation is excluded; a shared heavy lock isolates execution. All summary fields except the documented timing field must match across every mode, budget and repetition.

The finite comparison has a 360-second cap per cell and 1800-second overall cap, with cleanup of owned native children on failure. Binary and runner hashes are checked before/after. Raw output, CPU/elapsed times and completion status are retained. The first attempted comparison was interrupted and excluded because an outstanding C emission overlapped its start; its incomplete receipt is preserved. The admitted clean series starts only after compilation and native checks have finished.

## Results

All 24 timed cells completed: 192 summary records (eight distinct jobs repeated across modes, CPU budgets and repetitions), with exact equality of every gameplay summary field. The clean measurement series took 618.9 seconds overall. Times below are medians of three repetitions for the **entire group of eight games**, not one game:

| CPU budget | Native processes, seconds | One process with Bend threads, seconds |
|---:|---:|---:|
| 1 | 55.290 | 53.621 |
| 2 | 28.045 | 26.786 |
| 4 | 13.639 | 13.262 |
| 8 | 6.919 | 8.094 |

The ratio of Bend's one-thread and eight-thread median elapsed times is **6.62×**. Each job reached 1200 ticks (20 game seconds); the group represents 160 aggregate game seconds. At eight threads this is about 19.8 aggregate game-seconds per wall-second, not a 19.8× acceleration of one world.

There is no established throughput advantage over the existing process mode. Eight-thread Bend samples ranged from 6.129 to 8.298 seconds; eight-process samples ranged from 6.904 to 7.381 seconds. The first two paired comparisons favored processes and the third favored Bend. The median of paired process/Bend time ratios at eight CPUs is 0.912; this is a different statistic from the ratio of column medians. Small apparent gains at two/four CPUs are descriptive and do not establish a robust improvement. Keep process mode as the default.

[Machine-readable timings and all 192 summary records](bend-parallel-bots-results.json) retain the clean measurements, binary/runner hashes and raw-output hashes. Shared-filesystem research, including the excluded incomplete attempt, prototype results, source/tool bindings and original raw logs, is at `/workspace/formal-proofs/bend-games/research/bend-parallel-bots-20261023/`.

Final validation also exercised the real shell launcher in Bend mode with three wrapped seeds and four threads. This passed the explicit null-timing result checker. All Bend source hashes still match the pre-measurement inventory.

## Scope

These are eight short seeded jobs, not full campaigns or a macOS benchmark. Increasing thread count cannot guarantee linear scaling: scheduling imbalance, memory costs and host CPU behavior remain relevant. The change parallelizes independent games; it does not parallelize systems inside one game step or alter the ECS library.

Run from the examples repository root:

```sh
bash tools/survivors-bot/native-batch.sh --execution bend --count 100 --ticks 1800 --threads 8 --seed 100 --profile both
```

The launcher rebuilds current source, including on macOS Apple Silicon. It requires Bend and a native compiler, with no Node runtime. Linux measurement commands and timing details are in [the bot documentation](../tools/survivors-bot/README.md#native-offline-batches).
