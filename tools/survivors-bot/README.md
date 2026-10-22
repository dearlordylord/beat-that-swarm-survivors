# Optional Survivors classifier bot

A headless controller for the real Bend simulation. It can ask the TypeSafe `jev-latest` classifier to select an offered upgrade or a movement goal. Bend still owns combat, movement, rewards and legal state transitions. The headless entry is described below; the optional visible native entry is described at the end. The ordinary native game remains Node-free and uses the same BendHub dependency.

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

The two request ceilings must sum to at most 50. Requests are not retried. Timeout, missing credentials, provider failure, invalid/stale answers and exhausted budgets use the heuristic fallback and are identified in the receipt. Simulation pauses during **all** classifier calls, including movement-goal calls; provider latency is not simulated danger. `run.sh` bounds compilation to 30 seconds and execution to 120 seconds overall, so a requested simulation horizon is not a completion guarantee.

## Context and actions

Upgrade requests include the current build, hero, Arcana, stage, mode, slots, progression prerequisites, nearby threats, sampled health history and actual offered rewards. Bend supplies current mechanical values and an immediate preview of each offer using the pure `G.upgrade` function. These previews predict the immediate stat change, not future combat, DPS or survival. Additional JavaScript arithmetic estimates are explicitly labeled non-authoritative fallbacks.

Movement candidates come from the Bend action catalog: four cardinal targets and up to four nearby entity targets: fresh experience drops, chests, relics, inactive wards or inactive wisps, for at most eight candidates. One entity slot is reserved for nearby reachable XP when available. Both controllers also collect nearby fresh XP between classifier decisions, using local enemy/projectile avoidance and rejecting blocked routes or drops that will auto-claim before arrival. Ordinary XP still auto-claims after 120 ticks; approaching it can grant earlier upgrades. Local collection does not spend classifier requests, and consumed or expired targets are discarded. Distances and target geometry do not establish a safe route. Selected goals become plans lasting at most 120 ticks, revalidated while moving; ordinary steering, local avoidance and Bend `advance` perform movement. For builds equipped only with unevolved self-centered fields, steering approaches enemies within the field radius reported by the actual Bend projectile constructor, while retaining contact and hostile-projectile avoidance. Ranged and mixed builds retain kiting. There is no teleport or direct reward grant. The classifier cannot invent an action or select reroll, skip or banish through this tool.

Every run uses Bend's fixed seed `12345`; there is no multi-seed evaluation here. Receipts in ignored `examples/survivors/dist/bot-runs/*.jsonl` retain decision contexts, candidates, sanitized responses, outcomes and source/artifact SHA-256 hashes. They omit credentials and raw provider errors. `jev-latest` is a mutable alias; receipts do not identify immutable model weights or measure actual monetary cost.

Further decision points already have game APIs but are not classifier candidates yet: reroll/skip/banish need phase and resource predicates; camp purchases need unlocks, prices and remaining gold; hero/Arcana/stage selection needs an explicit allowed loadout list. Each addition should expose concrete current legal alternatives and consequences, rather than accept free-form commands.

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

This first visible bridge is **lockstep**: simulation waits during inference, while the window keeps processing events. Movement commands cover six normal simulation ticks before another observation, ending early for a reward. Goals are revalidated between batches and last at most 120 ticks. Short batches still leave a delay before reacting to a changing target. A session-private sequence filename binds each command to one stationary observation; classifier answers additionally pass the existing run/sequence/frame/candidate checks. Malformed native commands leave the game waiting, and the session wall limit still applies. Bot profiles are isolated; no human save is read or written. Audio is disabled in this experiment window.

```sh
bash tools/survivors-bot/check-visible.sh
# Linux diagnostic only, after building the bot binary and providing Xvfb/xdotool:
NIGHTFALL_X11_SYSROOT=/path/to/sysroot bash tools/survivors-bot/visible-window-smoke.sh
```

The next mechanics step is to select one evidenced issue from a run, state a measurable hypothesis, and compare one change. See [the observation loop](../../research/mechanics-improvement-loop.md).

The local controller also reads the actual radius of self-centered field weapons from Bend's `Shots.spawn`. A build containing only such weapons approaches enemies into attack range while retaining contact/projectile avoidance; ranged or mixed builds retain ordinary kiting. This corrects the previous fixed retreat distance that could prevent an aura starter from producing XP at all. It is a heuristic, not a survival guarantee. The journal lists local XP movement intents separately from classifier choices.

Monster spawn/HP regressions can be checked without HTTP using `bash tools/survivors-bot/check-monsters.sh`. Its native capture is written under ignored `examples/survivors/dist/`.
