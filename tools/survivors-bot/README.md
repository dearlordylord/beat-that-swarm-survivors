# Optional Survivors classifier bot

A deterministic controller with spatial memory and bounded route planning for the real Bend simulation. An optional advisory layer can ask the TypeSafe `jev-latest` classifier to select an offered upgrade or a movement goal. Bend still owns combat, movement, rewards and legal state transitions. The headless entry is described below; the optional visible native entry is described at the end. The ordinary native game remains Node-free and uses the same BendHub dependency.

## Run

From the repository root, install the optional tool's pinned dependencies with Node.js 24+:

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
| `--max-upgrade-requests 6` | Upgrade request ceiling; default 6 |
| `--max-goal-requests 2` | Movement-goal request ceiling; default 2 |
| `--timeout-ms 2000` | Per-request timeout; default 2 seconds |
| `--ticks 1800` | Simulation horizon; default 30 simulated seconds |
| `--seed 12345` | Explicit U32 simulation seed; headless, visible and batch entry points |

The two request ceilings must sum to at most 50. Requests are not retried. Timeout, missing credentials, provider failure, invalid/stale answers and exhausted budgets use the heuristic fallback and are identified in the receipt. Simulation pauses during **all** classifier calls, including movement-goal calls; provider latency is not simulated danger. `run.sh` bounds compilation to 30 seconds and execution to 120 seconds overall, so a requested simulation horizon is not a completion guarantee.

## Context and actions

Upgrade requests include the current build, hero, Arcana, stage, mode, slots, progression prerequisites, nearby threats, sampled health history and actual offered rewards. Bend supplies current mechanical values and an immediate preview of each offer using the pure `G.upgrade` function. These previews predict the immediate stat change, not future combat, DPS or survival. Additional JavaScript arithmetic estimates are explicitly labeled non-authoritative fallbacks.

XP remains on the ground until collected; elapsed time never credits it automatically. A separate resource pool and value-preserving merging prevent abandoned XP from occupying enemy spawn slots. Returning to an earlier drop can therefore matter.

Both modes share a deterministic spatial planner. It tracks currently available XP identities, groups drops into spatial clusters, and scores reward against route time and threat exposure. The current engine observation exposes the complete resource catalog, so this is explicit planning state over an omniscient observation, not a simulated limited-visibility human memory. Disappeared resources are removed immediately. Bounded A* routes around enemy/contact cells and hostile projectiles on a coarse grid. Planning has a fixed expansion budget and a bounded candidate count; it can fail to find an existing route, and its risk estimate is not a safety guarantee. A retained objective receives switching hysteresis, while damage, disappearance, stuck movement and periodic replanning can change it. There is no fixed 120-tick expiry that makes the bot forget distant XP.

The classifier sits above these abstractions: when enabled it receives prepared route alternatives, cluster rewards, distance/risk estimates and the deterministic baseline choice. Its validated answer advises the same planner; it does not implement routing or movement. Without a classifier, after exhausted budgets, or on provider failure, the baseline continues with the same spatial state. Neither mode needs HTTP for local collection, route following, avoidance or ordinary combat. Direction targets, chests, relics and persistent XP are possible objectives. Removed map wisps and sentinels are neither engine goals nor classifier choices; weapon 19 remains a separate player weapon. For builds equipped only with unevolved self-centered fields, steering uses the field radius reported by Bend; ranged and mixed builds kite. The classifier cannot invent an action or select reroll, skip or banish through this tool.

Headless runs accept an explicit U32 seed (default `12345`). Receipts in ignored `examples/survivors/dist/bot-runs/*.jsonl` retain decision contexts, candidates, sanitized responses, outcomes and selected source/artifact SHA-256 hashes. They omit credentials and raw provider errors. `jev-latest` is a mutable alias; receipts do not identify immutable model weights or measure actual monetary cost. Equal seeds and configuration support repeatable heuristic comparisons; classifier replies are external inputs and are not deterministic.

## Offline batches

Run from the repository root with Bend and Node.js 24+. The batch entry never imports the classifier provider, accepts no classifier mode and sends no classifier requests:

```sh
./tools/survivors-bot/batch.sh --count 1000 --ticks 1800 --workers 1 --seed 12345 --profile fresh --wall-seconds 300
# Small smoke run:
./tools/survivors-bot/batch.sh --count 2 --ticks 60 --workers 1 --wall-seconds 60
```

The wrapper builds the facade once under the shared build lock, then releases that lock. User batches can therefore contend for CPU with native play or compilation; choose the worker count accordingly. Comparative evidence checks acquire an outer `examples/common.sh` lock to serialize their workload, while ordinary user batches do not hold the compiler lock throughout a long simulation. Each batch freezes the compiled module before launching workers so subsequent builds cannot change queued runs. Workers use the same planner and upgrade baseline as ordinary heuristic runs. Consecutive seeds wrap within U32 without duplicates within a batch; `--profile both` alternates fresh and advanced presets.

Limits are `--count` 1–10000, `--ticks` 1–37000, `--workers` 1–min(8, available CPUs), and `--wall-seconds` 1–86400. Defaults are 1000 runs, 1800 ticks, one worker and 300 wall seconds. Compilation has its own 30-second limit; execution has a wall-budget fail-safe. These are requested workloads and bounds, **not a promise that 1000 runs finish within five minutes**. Increase the budget or reduce the workload based on measured runtime. Timeout or interruption terminates workers; there is no automatic resume.

Ignored `examples/survivors/dist/bot-batches/<batch-id>/` contains `manifest.json`, compact `runs.jsonl` and the frozen `simulation.mjs`. The manifest records options, selected source hashes, exact bundle hash and final status/counts. Each run records seed/profile/horizon, elapsed time, outcome and summary metrics; full frame/decision journals are omitted. Completed, exception, timeout, interrupted and unstarted work are distinguished. A terminal death and a bounded surviving observation are different simulation outcomes; an exhausted wall budget never claims that the batch completed. Non-complete batch status exits nonzero.

Further decision points already have game APIs but are not classifier candidates yet: reroll/skip/banish need phase and resource predicates; camp purchases need unlocks, prices and remaining gold; hero/Arcana/stage selection needs an explicit allowed loadout list. Each addition should expose concrete current legal alternatives and consequences, rather than accept free-form commands.

## Native offline batches

The free headless controller also has a Bend-to-C entry. From the repository root:

```sh
bash tools/survivors-bot/native-batch.sh --count 100 --ticks 1800 --workers 2 --seed 100 --profile both
```

It rebuilds current sources and runs native Bend without Node, graphics, HTTP or classifier calls. `--execution processes` is the default: each process owns its own world. `--threads` defaults to one Bend runtime thread per process, so multiple processes do not each reserve the full host CPU count. The wrapper translates its `--threads` option to Bend 2.0.38 runtime arguments `+RTS --threads N -RTS` and clears ambient `BENDRTS` for repeatable runs. `--ticks` is the actual simulation horizon; upgrade choices do not consume that horizon. Death and reaching the horizon are distinct outcomes. A bounded safety-fuel failure exits nonzero.

To let Bend schedule independent runs inside one process instead, use:

```sh
bash tools/survivors-bot/native-batch.sh --execution bend --count 100 --ticks 1800 --workers 1 --threads 8 --seed 100 --profile both
```

Bend execution compiles `offline-parallel.bend` to `dist/nightfall-parallel-batch`; process execution keeps `offline-batch.bend` and `dist/nightfall-batch`. These are separate artifacts, including when using `--no-build`. Bend execution requires one worker (the default); an explicit or environment-supplied worker count above one is rejected. `--threads` selects its Bend runtime pool. The entry forks independent pure runs and joins the batch before printing summaries, so this mode has no live per-run progress or individual timers: `wallMs` is `null`. Measure elapsed time around the whole batch; do not interpret that as one game's time. Increasing threads is a scheduling request, not a measured scaling guarantee.

The controller reads typed game state. `advance_quiet` shares the ordinary combat and progression implementation but omits per-tick frame serialization. XP is physically collected; the controller retains a resource objective and uses bounded routes and upgrade preferences. Native F32 arithmetic and route tie ordering may differ from the JavaScript controller; this is not a promise of identical cross-backend run traces. Behavioral parity fixtures check the supported operations separately.

`--output-dir DIR` selects persistent receipts; the default is under ignored `examples/survivors/dist/native-batches/`. Worker JSONL, stderr, source/binary hashes, manifest and completion counts survive worker failure. In process mode, each completed summary is flushed with a stderr progress message before the next run. Bend mode emits only after its joined batch completes. `manifest.json` records the selected execution mode. `--no-build` explicitly reuses the existing binary. The shell returns nonzero if any worker fails. The native batch wrapper has no simulation wall timeout; use a bounded external process supervisor for automated campaigns.

Compilation and runtime are separate costs. Backend speed and native scaling need actual measurements; merely compiling to C does not establish a speedup. The browser and optional visible classifier bridge keep their existing Node tools.

For a bounded Linux comparison of already-built binaries (Python is only the measurement supervisor):

```sh
flock /tmp/bendvy-parity-heavy.lock python3 -B tools/survivors-bot/compare-native-parallel.py \
  --serial-binary examples/survivors/dist/nightfall-batch \
  --parallel-binary examples/survivors/dist/nightfall-parallel-batch \
  --output-dir /tmp/nightfall-parallel-comparison
```

This fixes eight seeds, 1200 ticks, three paired repetitions and CPU budgets 1/2/4/8. Each pair compares B native processes with one B-thread Bend process on the same CPUs. It rejects any difference in gameplay summary fields and retains raw records and completion receipts. It has a 360-second cell cap and 1800-second overall cap. It requires Linux `taskset`; the game launcher itself supports macOS. Use a fresh output directory and budgets supported by the host. These short runs do not establish late-game scaling.

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

`visible.sh` rebuilds the current Bend sources before each launch, including on macOS Apple Silicon. It needs Bend, a C compiler and Node.js 24+ for the optional controller. It consumes the same pinned BendHub package as the game. Compilation is bounded to 300 seconds; `--seconds` bounds the session in wall seconds (1–900), rather than guaranteeing a simulation horizon. Escape or closing the window stops the session. The ordinary native game still launches without Node.

In a second terminal, open the journal:

```sh
node tools/survivors-bot/journal.mjs --host 0.0.0.0 --port 8714
```

Visit `http://localhost:8714/` on that machine, or its host address on port 8714. The viewer reads the newest run by default; use the printed `--receipt` command to fix a particular run. The read-only viewer exposes the selected journal to hosts that can reach its listening address; use default `127.0.0.1` for local-only access.

The journal shows real alternatives and input context while inference is pending, the validated selection actually sent to the engine, classifier/fallback identity, measured response time, source/binary hashes, and observed HP/kills/gold/level changes after 0.5, 2 and 5 simulation seconds. These are observational intervals, not causal credit. No model reasoning is invented. The map is actual snapshot telemetry; the native window supplies the game rendering.

This first visible bridge is **lockstep**: simulation waits during inference, while the window keeps processing events. Movement commands cover six normal simulation ticks before another observation, ending early for a reward. The shared planner revalidates resources and routes between observation batches, retaining objectives until a replanning or invalidation condition applies. Short batches still leave a delay before reacting to a changing target. A session-private sequence filename binds each command to one stationary observation; classifier answers additionally pass the existing run/sequence/frame/candidate checks. Malformed native commands leave the game waiting, and the session wall limit still applies. Bot profiles are isolated; no human save is read or written. Audio is disabled in this experiment window.

```sh
bash tools/survivors-bot/check-visible.sh
# Linux diagnostic only, after building the bot binary and providing Xvfb/xdotool:
NIGHTFALL_X11_SYSROOT=/path/to/sysroot bash tools/survivors-bot/visible-window-smoke.sh
```

The next mechanics step is to select one evidenced issue from a run, state a measurable hypothesis, and compare one change. See [the observation loop](../../research/mechanics-improvement-loop.md).

The local controller also reads the actual radius of self-centered field weapons from Bend's `Shots.spawn`. A build containing only such weapons approaches enemies into attack range while retaining contact/projectile avoidance; ranged or mixed builds retain ordinary kiting. This corrects the previous fixed retreat distance that could prevent an aura starter from producing XP at all. It is a heuristic, not a survival guarantee. The journal lists local XP movement intents separately from classifier choices.

Monster spawn/HP regressions can be checked without HTTP using `bash tools/survivors-bot/check-monsters.sh`. Its native capture is written under ignored `examples/survivors/dist/`.

## Persistent XP verification

`examples/survivors/persistent-xp.test.mjs` checks actual Bend functions for physical pickup, no age expiry, immediate enemy-slot release, nearest-pile overflow, 400-drop base-value conservation and seeded replay. `persistent-xp/PROOF.bend` proves only the small accounting helpers, not the entire ECS lifecycle or physical collision geometry. Pool conservation here concerns base XP; character/passive bonuses are applied on pickup by the ordinary game rules.

Planner tests cover retained resource generations, disappearance, blocked nearest piles, available cluster alternatives, chest/retreat diversity, route lengths, ETA and bounded search. Controller tests cover advisory failure without losing memory. The real-engine integration uses an explicitly fake classifier and natural rewards; it does not measure live classifier quality. The short two-seed batch smoke qualifies execution and receipts, not thousand-run throughput or gameplay balance.

The ordinary balance fixture has a separate 90-second wall limit. The current pool layout contains 1456 entities, including 400 XP entries and 512 shared player-projectile slots. The fixture still checks all three finales, Endless, the dense horde and reward queues; the longer bound changes no oracle. Other ordinary Node checks retain 30 seconds, natural bot integration 60 seconds and public API progression 180 seconds. This is a correctness-run bound, not a performance qualification.

The headless controller consumes each returned `Packet` through `observed_packet`, reusing the exact existing frame string. It parses the frame, actions and mechanics once per transition. The legacy `observe(state)` fallback is used only when a facade lacks that helper; observation failures never retry a consumed owner. This removes duplicate frame generation, without claiming a measured speedup.

## Experimental Metal batches on macOS

Use native CPU batches for practical runs. Metal is retained only to reproduce the research results. The initial full-game Metal build timed out after 1200 seconds on M2 Max. Small controls can be reproduced with `bash tools/survivors-bot/metal-diagnose.sh`: two small controls, at most 90 seconds of Metal compilation each. See [diagnostic instructions](../../research/metal-diagnostics.md). Those controls pass on M2 Max. The full-game command below now tests a [smaller GPU presentation closure](../../research/metal-game-boundary.md), with Metal compilation capped at 120 seconds and CPU smoke checked first.

From the repository root on an Apple Silicon Mac:

```sh
bash tools/survivors-bot/metal-experiment.sh --metal-noinline-spins --metal-segment-functions --metal-stage-trace --smoke-ticks 1 --count 2 --ticks 5
```

This rebuilds a GPU entry and compares the same native binary on CPU and forced Metal. This command reproduces the successful short test: two one-tick smoke jobs, then two five-tick worlds in three paired repetitions. The unchanged default horizons are larger and remain unqualified. It prints parity, dispatch, timing and the persistent report path. Send that final block for analysis; if it fails, include the error and `Report:` path. Python 3 supervises the experiment; the bots execute Bend/C. See [requirements, limits and validation status](../../research/metal-bots.md). On M2 Max this command passed summary parity and required-GPU dispatch, but GPU was approximately 561 times slower than CPU. Complete game runs and GPU full-state equivalence remain unqualified.
