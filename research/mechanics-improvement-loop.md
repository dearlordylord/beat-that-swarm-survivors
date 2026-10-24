# Survivors mechanics: observation before intervention

The first iteration is a visible run of the real native Bend simulation with a decision journal. No balance change or claim of classifier superiority is part of this iteration.

## First iteration

1. Run the fresh profile with the same source revision, an explicitly recorded engine seed, and explicit request/time budgets. Keep advanced-profile runs separately labeled.
2. Watch the native window and the journal together. The classifier selects actual offered upgrades and occasional engine goals; deterministic steering handles movement between those choices.
3. Inspect a concrete decision: actual alternatives, current engine mechanics and offer previews, selected action, whether the classifier or fallback supplied it, and subsequent observed HP/kills/gold/level changes after approximately 0.5, 2 and 5 simulation seconds. Intervals can overlap and include other choices, healing and combat; they do not establish causation.
4. Record one suspected problem and its evidence: run ID, source/binary hashes, decision sequence, simulation tick, observed behavior and what the player should experience instead. Do not manufacture a model rationale: this categorical API returns a selection, not a faithful explanation of its reasoning.
5. Form a falsifiable change hypothesis. Example: “An activated ward provides so much protection that staying near it dominates movement.” First establish whether the run actually demonstrates that behavior; a selected ward goal is not proof of arrival, activation or dominance.
6. Choose a measurement the engine actually exposes. Missing facts such as ward-attributed damage or rescue outcomes require engine telemetry before measuring them. Net HP loss is not total damage. Kills are not DPS. A short surviving run is not evidence of good difficulty.
7. Change one mechanic and compare the same setup across several controller styles, then inspect it as a human player. Fixed seed and build improve comparability, but live classifier behavior is not deterministic and `jev-latest` does not identify fixed model weights. A multi-seed study must bind its seed inputs through the actual game API.

## Run note

- Observation: run ID, decision sequence/tick, source/binary identity.
- Suspected mechanic and the player experience at stake.
- Concrete evidence and alternative explanations.
- Hypothesis and one proposed change.
- Measurement, horizon, controller styles and regression checks.
- Result: observed effect, limits, and whether to keep/revert the change.

Deterministic scripted scenarios belong to correctness and regression checks; they need no classifier. Different bots provide different play styles, not an automatic judgment of whether the game is enjoyable. Human play remains necessary.

## Current limits

The visible experiment owns one native world, renders that same world, and advances it through ordinary game functions. Simulation waits during classifier requests; the window remains responsive. Its wall-clock pace includes rendering and IPC overhead, so it is not an FPS or real-time classifier benchmark. The optional bot window has no audio and does not load or save the human player's profile. The journal's map is a telemetry view, separate from native rendering.

See [bot instructions](../tools/survivors-bot/README.md) and [validation](../tools/survivors-bot/VALIDATION.md).
