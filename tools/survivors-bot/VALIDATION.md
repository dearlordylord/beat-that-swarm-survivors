# Bot validation

Current execution uses the Bend policy directly in native window and headless
runners. The old Node planner, classifier controller and file-command bridge have
been removed. Their historical receipts do not validate the current driver.

The native batch launcher's shell contract is checked with:

```sh
bash tools/survivors-bot/visible.test.sh
```

These checks verify launcher arguments and native process invocation. They do not
prove policy quality, balance, graphical output or performance. Run the native
Bend driver checks and actual short simulations separately when changing policy
or stepping behavior. Strict audit comparison work continues in GitHub issue #11.

## Bend-only migration checks

The visible, serial and parallel launchers now use `bot-driver.bend`. Co-op uses
the same `offline-policy.bend` with separate memory for each player.

The migration was checked with Bend 2.0.39 and LLVM Clang 19.1.7:

- Native source checks passed for visible, serial, parallel and GPU entrypoints.
  The GPU check was a source check, not a GPU execution.
- Fresh and advanced native X11 windows ran on a virtual display. Fresh reached
  tick 120 and moved from the starting position. Advanced reached tick 600,
  moved and selected one upgrade. A gameplay frame was inspected.
- Four serial native runs, two profiles and seeds 12345 and 982451653, reached
  tick 120. Every summary field except wall time matched the previous driver.
  This comparison does not establish full physical-state equality.
- Serial and parallel native runs matched summary fields for two worlds of
  120 ticks each, excluding wall time.
- Five phase-routing laws passed the proof kernel. Five type-correct routing
  mutants failed their corresponding laws. These laws cover action routing,
  not the full planner or simulation.
- Launcher fixtures and `npm run check:typescript` passed.

Run the routing proof with a bounded checker:

```sh
timeout 60 sh -c 'ulimit -t 10; exec bend examples/survivors/bot-turn-PROOF.bend --verdict'
```

On macOS, use `gtimeout` from coreutils instead of `timeout`. The persistent
mutation cases are in `scripts/law-mutants/bot-turn.json`.

These checks establish the controller migration. They do not establish a speedup
or a 100× simulation rate. The archived journal viewer receives no live feed
from the new native driver.

## Unlimited window pacing

`visible.sh --unlimited` selects the continuous loop in `bot-window-loop.bend`.
It advances the shared driver between presentation deadlines approximately
100 ms apart. It has no eight millisecond simulation budget. Drawing still
consumes time on the same thread. Realtime mode keeps the original app loop.

The current scheduler was exercised as a native X11 program with an independent
counter fixture. Its 1200 simulated steps produced 26 presentations. A second
run received a real window-close event and stopped at step 121 after four
presentations. The FPS/TPS/SPEED overlay was inspected on this fixture. These
are scheduling checks with a synthetic workload, not game throughput results.

Earlier 600-tick game comparisons belong to the previous eight millisecond
version. They do not establish full-game equivalence or speed for this loop.
The current game entrypoint passes source checking; a macOS game run remains
to be measured on the user's host. The user confirmed that the macOS launch
works and reported visible acceleration after the continuous loop change.
That report is qualitative; it establishes no numeric speedup or 100× result.

Six pacing laws pass the kernel through `bot-pacing-PROOF.bend`. Six
type-correct mutations in `scripts/law-mutants/bot-pacing.json` are rejected at
their corresponding laws. They cover unrestricted simulation readiness, default
realtime deadlines, initial presentation and subsequent presentation deadlines.

## Parallel native grid

The grid owns worlds in a balanced affine tree. `parallel/affine.bend` uses
explicit CPU fork/join calls for pure world steps. Rendering forks independent
tiles. The window and ordered error/completion reports stay on the IO loop.

Run the scheduler proof and native comparison probe from the repository root:

```sh
timeout 60 sh -c 'ulimit -t 10; exec bend examples/survivors/parallel/affine-PROOF.bend --verdict'
CC="$PWD/tools/clang" bend examples/survivors/bot-grid-parallel-probe.bend -o /tmp/nightfall-grid-probe
GRID_PROBE_SERIAL=1 /tmp/nightfall-grid-probe +RTS --threads 1 -RTS > /tmp/grid-serial.jsonl
/tmp/nightfall-grid-probe +RTS --threads 1 -RTS > /tmp/grid-parallel-one.jsonl
/tmp/nightfall-grid-probe +RTS --threads 4 -RTS > /tmp/grid-parallel-four.jsonl
cmp /tmp/grid-serial.jsonl /tmp/grid-parallel-one.jsonl
cmp /tmp/grid-serial.jsonl /tmp/grid-parallel-four.jsonl
```

The probe runs ten advanced worlds for 300 ticks each. It compares complete
Run values, offers, snapshots, pending values, policy memory and choice counts,
including exact F32 bits. It does not capture hidden ECS storage. The generic
scheduler law proves equality of serial and parallel maps for arbitrary Data
inputs and functions. It does not prove whole-game equivalence for affine worlds.
The branch-reversal mutant is recorded in `scripts/law-mutants/affine-tree.json`.

`bot-grid-probe.bend` checks mixed completion bounds. The first world stops at
tick one while nine other worlds reach tick two. The finished world stays in
its cell. Actual window checks also cover ten independent views and explicit
runtime thread counts. These checks establish parallel execution and the tested
results, not a universal speedup or the separate 100× headless target.
