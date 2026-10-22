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

## Visible native decision journal — 2026-10-22

The optional native app now renders and advances one native-owned Bend world. The external Node controller receives engine observations and submits bounded movement or an exact offered upgrade. Ordinary game sources and the pinned BendHub dependency remain authoritative. Native audio and human profile persistence are excluded from this experiment entry; no macOS execution was available here.

Validation on Linux AArch64 with Bend 2.0.37 and the existing Clang 19 setup:

- 36 offline provider/context/controller/viewer/process tests passed (`/tmp/nightfall-visible-unit-final.log`). Process stubs test cleanup and exit reporting, not game behavior, and store their receipts in isolated temporary directories.
- New Bend sources passed the source checker. The actual native protocol fixture executed against fresh initialization and passed malformed/range/horizon rejection, invalid upgrade rejection, 16 ms pacing, horizon completion, sequence advancement and paused waiting (`/tmp/nightfall-visible-fixture.log`).
- Actual X11/Xvfb window smoke passed: native 1024×768 window, changing captured pixels, advancing tick/sequence, Escape, controller termination, no remaining game window, and `window-closed` receipt (`/tmp/nightfall-visible-window.log`, diagnostic directory `/tmp/nightfall-visible-window-b51jIS`).
- The live browser journal rendered actual native telemetry, selected candidates and outcome intervals without JavaScript errors; screenshot `/tmp/nightfall-visible-journal-live.png`. The telemetry map is not native rendering.
- Dependency audit passed: one example, 18 Bend modules, no source-checkout ECS imports. No added npm dependencies.

### Successful live native observation

Receipt: ignored local `examples/survivors/dist/bot-runs/af180082-b4f0-488c-bf28-49ec1de7470a.jsonl`.

Fresh profile, engine-fixed seed12345, 60 wall seconds, at most one goal and one upgrade classifier request, 5000 ms timeout, no retries. Simulation waited during inference; normal window/IPC pacing also contributes wall time. This is not an FPS result.

| Actual classification | Simulation tick | Selection | Provider latency |
| --- | ---: | --- | ---: |
| Movement goal | 6 | Move north | 265.95 ms |
| Upgrade | 416 | Spark Wand rank 1 → 2 | 206.35 ms |

Both responses passed context/candidate validation and were submitted to the native world. The immediate post-choice native frame matched the selected Bend upgrade preview for HP, max HP, gold, weapons and passives. Usage reported by the provider was 10057 input/270 output tokens for the goal and 11590 input/125 output for the upgrade; no monetary price is inferred. Later decisions explicitly used budget fallback.

Final observation: tick2096 (34.93 simulation seconds), phase0, HP70/70, level3, kills138, gold116. The run stopped at its wall limit, not by death or completion. Receipt records `outcome: wall-limit` and native `SIGTERM` with `expected: true`. There were no error fallbacks; exhausted-budget fallback is separate. Native binary SHA-256: `16da00bc72d0dede7d512519cb023c83ca3d95663acd88139f6e69f2196d8e93`.

An earlier 90-wall-second observation (`7d2517f6-5a30-40ad-92e2-24bd0174a5c9`) supplied two successful real classifications, but its summary incorrectly labeled deliberate wall-limit termination as `native-error`. The cleanup reporting bug was fixed, regression-tested, and the successful run above repeated the ordinary entry. The campaign made four live classifier requests total. The earlier journal was retained unchanged as evidence of that reporting bug.

Source and binary hashes are recorded at run start. These bind the observed working-tree build, including concurrent uncommitted game changes; selected file hashes are not a complete import closure, and these numerical results are not claimed for a different checkout. The frozen `check-visible.sh` entry also passed end to end (`/tmp/nightfall-visible-check-final.log`). CI is configured to execute this fixture; its outcome is separate from local observations. The classifier alias remains mutable. None of these short observations establishes improved play, desired difficulty, causality or enjoyment.
