# Optional Survivors classifier bot

A headless controller for the real Bend simulation. It can ask the TypeSafe `jev-latest` classifier to select an offered upgrade or a movement goal. Bend still owns combat, movement, rewards and legal state transitions. This tool does not control the native game window; the native game remains Node-free and uses the same BendHub dependency.

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

Movement candidates come from the Bend action catalog: four cardinal targets and up to four nearby chests, relics, inactive wards or inactive wisps, for at most eight candidates. Distances and target geometry do not establish a safe route. Selected goals become plans lasting at most 120 ticks, revalidated while moving; ordinary steering, local avoidance and Bend `advance` perform movement. There is no teleport or direct reward grant. The classifier cannot invent an action or select reroll, skip or banish through this tool.

Every run uses Bend's fixed seed `12345`; there is no multi-seed evaluation here. Receipts in ignored `examples/survivors/dist/bot-runs/*.jsonl` retain decision contexts, candidates, sanitized responses, outcomes and source/artifact SHA-256 hashes. They omit credentials and raw provider errors. `jev-latest` is a mutable alias; receipts do not identify immutable model weights or measure actual monetary cost.

Further decision points already have game APIs but are not classifier candidates yet: reroll/skip/banish need phase and resource predicates; camp purchases need unlocks, prices and remaining gold; hero/Arcana/stage selection needs an explicit allowed loadout list. Each addition should expose concrete current legal alternatives and consequences, rather than accept free-form commands.

## Checks and evidence

```sh
bash tools/survivors-bot/check.sh
```

Checks include offline provider/context/controller tests, a real Bend action-catalog fixture and an actual simulation integration with a fake classifier. [VALIDATION.md](VALIDATION.md) separately records the two successful live classifications and a matched heuristic observation. That short advanced-profile comparison does not demonstrate better decisions or better play.
