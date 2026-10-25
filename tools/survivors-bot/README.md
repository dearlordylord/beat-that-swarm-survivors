# Optional Survivors classifier bot

A deterministic controller with spatial memory and bounded route planning for the real Bend simulation. An optional advisory layer can ask the TypeSafe `jev-latest` classifier to select an offered upgrade or a movement goal. Bend still owns combat, movement, rewards and legal state transitions. The headless entry is described below; the optional visible native entry is described at the end. The ordinary native game remains Node-free and uses the same BendHub dependency.

## Run

From the repository root, install the optional tool's pinned dependencies with a Node.js version supported by [package.json](package.json):

```sh
npm ci --prefix tools/survivors-bot --ignore-scripts
./tools/survivors-bot/run.sh --mode heuristic --profile fresh --decisions both --ticks 1800
```

Heuristic mode is the default and makes no HTTP requests. For live classification, set and export `TYPESAFE_API_KEY` locally, then run:

```sh
./tools/survivors-bot/run.sh --mode jev --profile fresh --decisions both --ticks 1800
```

Live mode sends the decision context and candidates to the provider. Keep credentials in your local environment. Neither commands nor receipts need the credential value.

Inspect the engine's actual offers, complete goal catalog and mechanical values after one initialization tick, without inference:

```sh
./tools/survivors-bot/run.sh --inspect-actions
```

| Option | Meaning |
| --- | --- |
| `--profile fresh` | Fresh native-profile initialization, including its actual unlocked starting loadout |
| `--profile advanced` | Fully purchased Agatha/Living Tree preset; not a fresh player |
| `--decisions both` | Classify upgrades and movement goals |
| `--decisions upgrades` | Classify upgrades only; movement uses the heuristic controller |
| `--max-upgrade-requests N` | Upgrade request ceiling |
| `--max-goal-requests N` | Movement-goal request ceiling |
| `--timeout-ms N` | Per-request timeout |
| `--ticks N` | Simulation horizon |
| `--seed N` | Explicit U32 simulation seed; headless, visible and batch entry points |

CLI defaults, validation and request handling belong to [run.mjs](run.mjs),
[runner.mjs](runner.mjs) and [provider.mjs](provider.mjs). Bounds in
[run.sh](run.sh) apply to the whole invocation, so a requested simulation horizon
is not a completion guarantee. Simulation waits during classification; provider
latency is not simulated danger.

## Context and actions

[bot-actions.bend](../../examples/survivors/bot-actions.bend) supplies actual legal
alternatives and immediate engine previews. [context.mjs](context.mjs) packages
them for the provider. Previews do not predict future combat or survival.

[planner.mjs](planner.mjs) owns the deterministic spatial planner, its observation
model, resource retention, routing and steering. The classifier advises that
planner through prepared legal alternatives. It cannot invent engine actions.
The planner uses omniscient engine observations; it is not a model of human
visibility, and bounded route estimates are not safety guarantees.

Receipts retain decision context, sanitized responses, outcomes and selected
source/artifact hashes. Classifier replies are external inputs; equal game seeds
do not make those replies deterministic. The provider alias is mutable and does
not identify immutable model weights or measured monetary cost.

## Offline batches

Run from the repository root with Bend and a Node.js version supported by [package.json](package.json). The batch entry never imports the classifier provider, accepts no classifier mode and sends no classifier requests:

```sh
./tools/survivors-bot/batch.sh --count 1000 --ticks 1800 --workers 1 --seed 12345 --profile fresh --wall-seconds 300
# Small smoke run:
./tools/survivors-bot/batch.sh --count 2 --ticks 60 --workers 1 --wall-seconds 60
```

[batch.mjs](batch.mjs) and [batch-worker.mjs](batch-worker.mjs) define batch
configuration, seed assignment, workload limits and completion status.
[batch.sh](batch.sh) owns compilation. A requested workload is not a throughput
guarantee; choose it from measurements on the host.

Each batch freezes its compiled module and records options, selected source
hashes, artifact identity and per-run outcomes. Completed, failed, timed-out,
interrupted and unstarted work remain distinguishable. See the runner sources
for receipt schema and output locations. Ordinary user batches can contend with
other processes; comparative evidence runners serialize their workloads.

## Native offline batches

The free headless controller also has a Bend-to-C entry. From the repository root:

```sh
bash tools/survivors-bot/native-batch.sh --count 100 --ticks 1800 --workers 2 --seed 100 --profile both
```

[native-batch.sh](native-batch.sh) rebuilds and runs native Bend. The process
entry is [offline-batch.bend](../../examples/survivors/offline-batch.bend); each
process owns its world. The wrapper defines runtime thread arguments, limits,
receipt locations and failure behavior. Native execution does not require Node,
graphics, HTTP or classifier calls.

To let Bend schedule independent runs inside one process instead, use:

```sh
bash tools/survivors-bot/native-batch.sh --execution bend --count 100 --ticks 1800 --workers 1 --threads 8 --seed 100 --profile both
```

The Bend entry is [offline-parallel.bend](../../examples/survivors/offline-parallel.bend).
It joins independent simulations before emitting summaries. Its elapsed batch
time is not an individual game's time. Increasing threads requests scheduling;
it does not establish scaling.

[offline-policy.bend](../../examples/survivors/offline-policy.bend) owns the native
controller. The quiet game API shares the ordinary simulation but omits frame
presentation. Native arithmetic and route ties may differ from JavaScript;
supported behavioral parity is checked separately.

Compilation and runtime are separate costs. Backend speed and native scaling
need actual measurements; merely compiling to C does not establish a speedup.
Use a bounded external supervisor for automated campaigns.

For a bounded Linux comparison of already-built binaries (Python is only the measurement supervisor):

```sh
flock /tmp/bendvy-parity-heavy.lock python3 -B tools/survivors-bot/compare-native-parallel.py \
  --serial-binary examples/survivors/dist/nightfall-batch \
  --parallel-binary examples/survivors/dist/nightfall-parallel-batch \
  --output-dir /tmp/nightfall-parallel-comparison
```

[compare-native-parallel.py](compare-native-parallel.py) defines the frozen
workload, paired process/thread comparison, semantic rejection rules and time
budgets. It requires Linux affinity support; the game launcher itself supports
macOS. Use a fresh output directory and budgets supported by the host. Short
runs do not establish late-game scaling.

Development checks for the new path:

```sh
bash tools/survivors-bot/native-batch.test.sh
python3 -B tools/survivors-bot/compare-native-parallel_test.py
bend examples/survivors/parallel/PROOF.bend --verdict
```

The failure/fuel fixture `offline-parallel-test.bend` is included in `examples/survivors/check-native.sh`.

## Checks and evidence

```sh
bash tools/survivors-bot/check.sh
```

Checks include offline provider/context/controller tests, a real Bend action-catalog fixture and an actual simulation integration with a fake classifier. [VALIDATION.md](VALIDATION.md) separately records the two successful live classifications and a matched heuristic observation. That short advanced-profile comparison does not demonstrate better decisions or better play.

## Visible native run and decision journal

The optional window bot renders the **same native-owned world** it controls. Install the optional dependencies above, then run from the repository root:

```sh
./tools/survivors-bot/visible.sh --mode heuristic --profile fresh --seconds 120
# With TYPESAFE_API_KEY exported locally:
./tools/survivors-bot/visible.sh --mode jev --profile fresh --seconds 120 --max-upgrade-requests 6 --max-goal-requests 2
```

[visible.sh](visible.sh) owns the build and session bounds. This optional entry
uses Node for its controller and the same published ECS dependency as the game.
Its wall-time horizon does not guarantee a simulation horizon. The ordinary
native game still launches without Node.

In a second terminal, open the journal:

```sh
node tools/survivors-bot/journal.mjs --host 0.0.0.0 --port 8714
```

Visit `http://localhost:8714/` on that machine, or its host address on port 8714. The viewer reads the newest run by default; use the printed `--receipt` command to fix a particular run. The read-only viewer exposes the selected journal to hosts that can reach its listening address; use default `127.0.0.1` for local-only access.

[journal.mjs](journal.mjs) and [journal.html](journal.html) present actual
telemetry and classifier decisions. Outcome intervals are observations, not
causal credit; the journal does not invent model reasoning.

[native-bot.bend](../../examples/survivors/native-bot.bend) and
[visible-controller.mjs](visible-controller.mjs) own the lockstep protocol,
observation batches and command validation. The experiment uses an isolated bot
profile and excludes native audio. Short observation batches still leave a
reaction delay; classification cannot bypass engine validation.

```sh
bash tools/survivors-bot/check-visible.sh
# Linux diagnostic only, after building the bot binary and providing Xvfb/xdotool:
NIGHTFALL_X11_SYSROOT=/path/to/sysroot bash tools/survivors-bot/visible-window-smoke.sh
```

The next mechanics step is to select one evidenced issue from a run, state a measurable hypothesis, and compare one change. See [the observation loop](../../research/mechanics-improvement-loop.md).

Monster spawn/HP regressions can be checked without HTTP:

```sh
bash tools/survivors-bot/check-monsters.sh
```

## Persistent XP verification

[The small-core proof](../../examples/survivors/persistent-xp/PROOF.bend) covers accounting helpers, not the entire ECS lifecycle or collision geometry.

Correctness-run budgets belong to the check runners, and current pool values
belong to [pools.bend](../../examples/survivors/pools.bend). Neither supplies a
performance qualification.

## Experimental Metal batches on macOS

Use native CPU batches for practical runs. Metal is retained only to reproduce
the research results. The initial full-game Metal build timed out after 1200
seconds on M2 Max. Small controls can be reproduced with
`bash tools/survivors-bot/metal-diagnose.sh`; see the
[diagnostic instructions](../../research/metal-diagnostics.md). Those controls
pass on M2 Max. The full-game command below tests a
[smaller GPU presentation closure](../../research/metal-game-boundary.md).
Current stage budgets and execution gates belong to
[metal-diagnose.py](metal-diagnose.py) and [metal-experiment.py](metal-experiment.py).

From the repository root on an Apple Silicon Mac:

```sh
bash tools/survivors-bot/metal-experiment.sh --metal-noinline-spins --metal-segment-functions --metal-stage-trace --smoke-ticks 1 --count 2 --ticks 5
```

This rebuilds a GPU entry and compares the same native binary on CPU and forced Metal. This command reproduces the successful short test: two one-tick smoke jobs, then two five-tick worlds in three paired repetitions. The unchanged default horizons are larger and remain unqualified. It prints parity, dispatch, timing and the persistent report path. Send that final block for analysis; if it fails, include the error and `Report:` path. Python 3 supervises the experiment; the bots execute Bend/C. See [requirements, limits and validation status](../../research/metal-bots.md). On M2 Max this command passed summary parity and required-GPU dispatch, but GPU was approximately 561 times slower than CPU. Complete game runs and GPU full-state equivalence remain unqualified.
