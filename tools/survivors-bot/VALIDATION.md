# Optional bot validation — 22 October 2026

These observations qualify the optional headless controller and its decision plumbing. They do not qualify a native-window bot, full-run balance, human enjoyment, classifier superiority, multi-seed robustness or monetary cost.

| Check | Observed result | Scope |
| --- | --- | --- |
| Offline tests | 27 passed: provider 10, context 11, runner 6 | Pure/injected service tests; no live HTTP evidence |
| Bend action catalog | `/tmp/nightfall-bot-actions-final.log` passed an actual 13-tick fixture | Real engine targets and observations; not a play-quality test |
| Simulation integration | `/tmp/nightfall-bot-integration.log` passed 600 advanced-profile ticks with a fake classifier | Actual public `choose` agrees with the engine's immediate upgrade preview; fake classification is not live-provider evidence |
| Clean committed game dependency | A separate temporary copy of game sources at `5d3497e`, plus the new facade, compiled and completed 600 actual ticks with a fake classifier: two accepted upgrade decisions and one accepted goal | Confirms the optional tool does not require concurrent uncommitted game edits; temporary copy removed after execution |
| Live movement decision | Run `4e1ea718-969e-40fa-a70a-48a047b64861`: eight candidates at tick 1; selected `move_east`; latency 233.865 ms; reported usage 10,246 input / 269 output | Successful live selection, validated and applied by ordinary movement |
| Live upgrade decision | Same run: three candidates at tick 427; selected Wormwood Charm rank 1 → 2; latency 206.055 ms; reported usage 11,657 input / 129 output | Successful live selection, applied through the public simulation command |

The live run used the advanced preset, `--decisions both`, request ceilings of two upgrades and one goal, and a 5-second per-request timeout. It attempted one upgrade request and one goal request; both succeeded. A later goal decision at tick 301 used the budget fallback because its one-request goal budget was exhausted; there was **no error fallback**. All classifier waiting paused simulation. At tick 600 (10 simulated seconds), the character was alive with HP 187, level 2, 69 kills and 87 gold.

## Matched heuristic observation

Heuristic run `60e2ce71-7565-4c49-abed-f7b2af1693e8` used the same source and artifact hashes, advanced preset and 600-tick horizon, with no HTTP requests. It ended alive with HP 187, level 2, 89 kills and 90 gold. Its first upgrade occurred at tick 251; the live run's first upgrade occurred at tick 427.

Both runs hit the short observation horizon at full HP on an advanced purchased profile. The live run had fewer kills and gold; these two fixed-seed trajectories provide no evidence of improved decision quality or survival. They are not a repeated or statistically controlled evaluation.

## Provenance and limits

The matching compiled bot-module SHA-256 was:

```text
29bf03fff9cdcfb4c4a327670acf40f3d18e8158ee9be9dba12f4b5849c8d4db
```

Each ignored JSONL receipt records the relevant game, facade, catalog, controller, provider, dependency-lock and compiled-module hashes. The evidence is bound to those hashes: other game work was in progress, and subsequent source changes require new matching observations. Receipt paths above identify local ignored development artifacts, not files distributed with the repository.

The model was the mutable provider alias `jev-latest`. Usage is provider-reported; actual price was not measured. Engine-derived previews are immediate pure upgrade calculations, not combat rollouts. Movement targets have unassessed safety, and the selected goal remains subject to ordinary steering and revalidation. The fixed simulation seed is `12345`; no multi-seed claim is made.
