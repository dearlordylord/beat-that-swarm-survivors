# Co-op population v1 — independent implementation review

## Final native evidence — population change accepted conditionally

**Verdict:** the reviewed evidence supports the preselected extra25 policy as a deliberate reduction of two-player ordinary population. No remaining blocker was found in the policy, native runner, final receipt comparison or completed browser regression evidence. This is **acceptance of the population change for release preparation**, subject to the normal fresh-source packaging/publication gate. It is not a finding that human enjoyment, every seed's survival, or all late-game outcomes improve.

Independently inspected all four completed V2 campaigns and their raw JSONL receipts: `/tmp/coop-pop-v2-final-{fresh,advanced}{100,25}`. All saved sources and native binaries match their manifests; all four bind the unchanged criteria SHA `5661dd428f784a2ecad0aaa5b087e49448520eadfd4f5f553e86e14faed56ff0`, normalized game context and policy identity recorded below. Within each profile the only runtime-source difference is the25/100 literal; all use V2 runner hash `98c43b18b080f1d3d2998702103fe847104bafa84376fcd9cbba773efd865fa6`. The report hashes bind the actual manifests, JSONL files and current analyzer. The declared final profiles, seeds and36000-tick horizon agree with the contract.

The selection file is byte-identical to commit `01b1258` (15:39:02 UTC); the first final campaign starts at15:49:22 UTC. `/tmp/coop-pop-v1-ledger.json` contains both final usage IDs from the reports, with the same frozen evaluation group and distinct profile scopes, and no earlier listed use of these seeds. This checks declared exposure and chronology, not undisclosed inspection. The candidate was not selected from these final outcomes; any future patch based on them consumes this cohort's independence.

### Observed outcomes, including the regression

| Profile / seed | Extra100 outcome | Extra25 outcome | Mean total population on common observed prefix,100→25 |
| --- | --- | --- | --- |
| Fresh /982451653 | Defeat at29386 | **Defeat at22280:7106 ticks (118.4s) earlier** |430.52→304.96 |
| Fresh /961748941 | Defeat at29528 | Horizon36000; **player0 dead, player1 HP84** |434.95→312.28 |
| Advanced /982451653 | Horizon36000 | Horizon36000 |443.44→322.36 |
| Advanced /961748941 | Horizon36000 | Horizon36000 |450.23→327.51 |

All horizon rows have phase0; **none is victory**. Both advanced players remain alive in each advanced endpoint. These are four paired contexts from **two seeds crossed with two presets**, not four independent seed draws. The finite cohort supplies no statistical confidence claim about a player population.

The population integrals were independently recomputed from raw samples using left-held values and exactly common coverage; all four agree with the analyzer. Their endpoints are22260,29520 and35940 ticks, without extending the last sample or filling time after death. The roughly27–29% reduction concerns measured total living enemies on those prefixes, including changes in living-player count; it is not a fixed-party causal estimate or a guarantee of the same reduction every instant. Source/law review separately establishes that the changed parameter controls ordinary admissions.

The earlier fresh defeat is a real regression and must remain visible in the results/release explanation. At the last common sample22260 both arms are level8; the remaining player's HP is52 in baseline and1 in candidate. Those facts do not identify a causal explanation. A deterministic omniscient controller, changed encounters and subsequent trajectories do not establish human difficulty or prove that progression caused the loss. No compensating XP/game change was introduced after seeing it. The frozen contract requires review of outcomes and expressly treats full-horizon runs as finite regressions; it does not require per-seed survival dominance. Thus this adverse seed does not negate the requested population reduction, but **any claim of universally better survival or no late regression would be contradicted by the evidence**.

### Gates and remaining release conditions

Inspected `/tmp/coop-pop-final-check-v2.log`: it records52/52 proof files,380/380 semantic mutants,1,267,245 emitted policy checks, the actual18-case native counter fixture, capability/geometry/replay checks,24 analyzer tests and16 supervisor tests. Independently reran the24 analyzer tests successfully and reviewed the guards for arm roles, canonical setup, runner/policy/context identities, criteria binding, declared cohort and required final exposure ledger. “Observations complete” is receipt completeness, not an automatic balance verdict.

Independently rechecked both V1/V2 seed100 replays:121 rows per arm,242 total, equal except the three disclosed metadata/time fields, with matching stored receipt hashes. The real solo control reaches7200 in phase0 with HP64; this is a finite smoke check. Exact solo preservation comes from the unchanged single-player callsite and one-player formula, not from comparing that one solo outcome with co-op.

The browser matrix completed during review. Independently inspected `/tmp/coop-pop-browser-qualification/{summary.json,completion-0.json,completion-200.json,completion-600.json,worker-recovery-touch.json}` and matched all42 expected asset hashes to the current `dist/web` artifact. The0/200ms cases have `sourceStable/sourceExact:true`, no recorded errors, p95 worker-reference lag28 ticks, every reported five-second window at most29 ticks, zero host-motion violations and no recovery entries. The600ms case is explicitly **bounded-overload-only**, not an interactive guarantee. Recovery evidence records the two intentional worker/renderer failures, visible diagnostics, a new run, touch ownership/release, no additional timeline sampling on map toggle, and active phase0 rejoin with fresh seq2 actually applied at world tick38. Intentional injected errors must not be relabelled unexplained crashes, and the network matrix must not be generalized to arbitrary networks. Automated browser/touch checks do not establish physical Safari qualification or human enjoyment. Fresh-source packaging/publication remains root's final gate; no production files were edited by this reviewer.

## V2 follow-up — code correction accepted, final evidence pending

The V1 counter finding below is **resolved in reviewed V2 source**. `offline-coop-control.bend` now defines a boss as a living kind0 body with variant20..30 inclusive; ordinary is its exact complement among living kind0 bodies. The runner's actual `population_go` calls these helpers. Six additional universal laws pin classification, coverage and disjointness; they preserve the total population rather than merely renaming one fixture. Independent execution of the bounded proof gate passed the current control proof, including the kernel/unsafe-refusal controls. The13-mutant manifest includes the original finale-only error and both range boundaries; its reported success still belongs to the full gate evidence to be reviewed.

The retained native fixture calls **`Batch.population_go` itself** on18 cases, including dead and non-enemy rows, plus `G.boss_variant(False,7200,0)` yielding21. Initially this fixture was not in the normal gate. Root corrected that during review: `check.sh` now calls `check-native-coop-metrics.sh`, which uses the existing shared heavy-work lock and bounded native compile/run. Thus proving helpers while bypassing them in the runner is also covered by a consuming runtime check. Source wiring is verified; execution of the newly integrated full gate is pending.

Independent V2 replay verification used only `/tmp/coop-pop-v2-replay25` versus V1 development extra25, seed100. All121 JSON rows are identical after excluding **only** `ordinaryPopulation`, `bossPopulation`, and `wallMs`. The sole split change is at tick7200: ordinary288/boss0 becomes ordinary287/boss1. This is finite observed-field equivalence, not universal full-ECS refinement; the source diff is limited to the counter and its pure control helpers. No game/policy transition source changed.

Every retained V2 source hash and native binary hash matches its manifest; its local runtime sources match `/tmp/coop-population-v2-L3WjgC`. Game context and policy identities remain the V1 values recorded below. V2 runner hash is `98c43b18b080f1d3d2998702103fe847104bafa84376fcd9cbba773efd865fa6`; replay extra25 binary is `22360acec6d0c7c5990276f981b1d97ec09160c9c6e0fe681b6a7e9db249aa52`. The new manifest correctly describes boss variants20..30. The selection receipt frozen in commit `01b1258` explicitly retains the V1 telemetry erratum rather than silently repairing old evidence.

**Current disposition:** no remaining code blocker found in this reviewed V2 scope. Extra100 replay was still preparing at the last inspection. Full gate execution, final-cohort results and release integration remain pending; no final trajectory was read and this is not publication approval. Historical V1 findings and evidence follow unchanged.

### Mutation preflight adjustment

Independently reviewed the later change in `scripts/check-bend-mutants.py` from emitting an unused `mutant.mjs` to `--check-only`. It preserves the exact declared `compile_target` (or source fallback), mutated snapshot,10-second CPU/60-second wall limits, proof invocation, and the requirement for exit1 with the expected named-law failure. New positive/negative compiler controls ensure the selected mode accepts a valid Nat body and refuses a Bool body declared as Nat.

Four independent tiny probes through the gate's own bounded `run` wrapper confirmed current compiler behavior: a valid imported consumer passes; an ill-typed imported body fails; an **unused** ill-typed imported definition also fails; a well-typed Bool provider used by a Nat consumer fails at the consumer. No semantic type-correctness or declared-import/consumer coverage weakening was found. The intentionally removed check is **JS code-generation success for every mutant**, not typing or proof rejection. Backend artifact generation/execution remains covered by its separate gates and must not be inferred from `--check-only`. The full mutation suite still requires a successful rerun; this review did not duplicate that heavy run.

## Initial V1 audit

Date: 2026-10-25. Status: **initial code/provenance audit; release qualification pending**. This reviewer did not author the population policy, runner, supervisor or analyzer. Scope is the current `party-difficulty.bend` integration, `offline-coop-batch.bend`, termination control and native supervisor. Only development extra100/extra25 receipts were inspected. Validation results and the final cohort were not read.

## Finding requiring disposition

**P1 for telemetry correctness: ordinary/boss counts misclassify timed bosses.** In `offline-coop-batch.bend:population_go`, only variant30 is counted as a boss. However, `game.bend:boss_variant(False,tick,stage)` returns `20 + stage*2 + ((tick/7200)%2)`; regular encounter rosters use variants0..19. The stage0 boss created at tick7200 has variant21 and is counted as ordinary. The manifest repeats the same erroneous distinction in `populationDefinition`.

Use the actual game's boss classification, covering variants20..30, and retain a control for ordinary0/19, timed20/21/29, final30, zero HP and non-enemy kinds. A source review already establishes this mismatch; a passing arithmetic policy test cannot detect it. The finding was sent to root before final qualification.

This does **not** change the total `population` value, the game simulation, or the primary comparison of total population on a common observed prefix. Existing receipts must nevertheless be labelled as containing the old, incorrect ordinary/boss split; do not silently rewrite their provenance or present that split as correct. A corrected runner needs its own hash. Keep both arms of each comparison on the same runner version, and disclose any diagnostic-runner change across cohorts. No conclusion about unchanged bosses should be inferred from the defective counter.

## Verified implementation behavior

- The production diff is confined to the population policy. Its public entry uses extra25. The exact specification floors `min(base,500) * (100 + (boundedPlayers-1)*boundedExtra) / 100`, then caps at500, with explicit zero/one branches. Largest intermediate is25,000,000; malformed U32 factors cannot overflow it. For one player the result is the previous `min(base,500)`. Extra100 recovers the old capped product, including zero players. The laws pin both the configurable helper and the real default entry; default25 literal laws are not a claim about experimental binaries whose default literal is100/50/0.
- The consuming callsite is `game.bend:dormant_scheduled_for`: the policy controls admission of dormant ordinary slots after the existing time/Curse/mode calculation. Solo calls it with1. Co-op `party_spawn_players` counts positive-HP views; disconnected records become zero-HP views in `Core.player_view`. Seed0's scheduled boss branch remains separate. Existing live enemies are not removed, healed or rescaled when party size changes. Per-slot Curse selection and personal XP formulas are unchanged.
- `offline-coop-batch.start` creates one genuine Core world, configures stage0/standard, joins player1 before stepping, then applies the fresh profile's existing weapon mask to both records. Advanced character/meta/Arcana defaults match the declared preset. `observe` reads player records through `load_players` and reconstructs the state with the **returned same World**, refs, snapshots and pending rewards. It does not create a shadow simulation.
- Each player owns a separate `Policy.Memory`. Both observe personal projections and the same shared body snapshot. The loop passes two directions to one `Core.core_step`. During rewards it takes an actual required id, current round and that player's actual offers; `Policy.upgrade` selects an offer index and `Core.core_choose` validates it. Rejection/failure ends execution with an error. This is a source-level integration check, not a universal proof that every full run terminates or every possible policy action succeeds.
- The loop retains the public Core path, including its JSON/journal work, and discards its frame output. There is no new quiet transition to qualify. Claims about faster execution or a rendering-free internal cost would be unsupported; the existing receipt limitation accurately discloses frame construction.
- `offline-coop-control` distinguishes defeat3, victory4, abort5 and horizon, with terminal phases taking precedence at the horizon. Safety-fuel exhaustion and supervisor timeouts remain infrastructure failures. Independent rerun of the supervisor tests passed **16/16**; those tests validate process/receipt controls, not balance.

## Frozen development provenance independently checked

Reviewed directories: `/tmp/coop-pop-v1-dev100` and `/tmp/coop-pop-v1-dev25`. Their declared four seeds100..103 completed at tick7200 as **horizon**, not victory. This audit does not use those short episodes to qualify late balance, performance or human enjoyment.

The frozen source is `/tmp/coop-population-v1-SKWbfz`: commit `18f9e09b75b9cc31238a1e2011efe49f86802c8c` plus the seven explicitly hashed Bend overlays. All seven match `/tmp/coop-population-v1-snapshot.json` and the reviewed working files. The snapshot is correctly marked dirty. The criteria file matches SHA-256 `5661dd428f784a2ecad0aaa5b087e49448520eadfd4f5f553e86e14faed56ff0`; Git history retains the original freeze and setup amendments.

An independent import walk found exactly the46 local runtime sources declared by both manifests. Every saved source and each retained native binary matches its recorded hash. The two source closures differ only in the `extra_per_player_percent` literal100 versus25. After normalizing that literal their policy source is byte-identical. Their actual tick-zero player records agree: character0, Arcana0, meta0, HP70, identical starter weapons/passives and banned-weapon masks.

| Identity | Verified value |
| --- | --- |
| Normalized game context, both arms | `5b528a6b2dab0ceaf100d5210d4df0fef273632fdfaf2a107c086ce239f754d4` |
| Policy, both arms | `9b63e95df0d72d6e60786995671e97c08aae52c91a41031753e46b4046a91279` |
| Runner, both arms | `5fcb63648d4e02b4ad9ea0ed363c3d14e5fb369a24e87c01be445d11b70c7c12` |
| Native extra100 binary | `68343fbb6d1f46b60c66fcd6cd1e31aa6e0d88e14fbcd0d538ad0a93e1070355` |
| Native extra25 binary | `e35b05913157a721863a9024fc5276e5a08e85a53e4549704fa7c137a669d80b` |
| Supervisor, matches reviewed file | `7c2043e9eb9d0fe5308ab10a154c21a4d9cb3bc09fb0785b51f9241392eeb804` |

The local closure excludes `Base` and the external BendHub package, as intended. Receipts bind the dependency manifest and compiler **version** (`bend 2.0.38`), not a compiler-executable digest or an independent copy/hash of every resolved external module. Therefore this audit verifies the retained executable/source receipts and declared dependency pin; it is not proof of a byte-reproducible rebuild under arbitrary installations. The normal dependency/release gates remain applicable.

## Acceptance boundary

No gameplay-policy or shared-world runner blocker was found in this initial audit. The ordinary/boss telemetry defect above needs correction or explicit evidence-scope disposition before those fields are used. Release remains pending the declared correctness gates, candidate freeze, new-seed checks, complete-horizon regression disposition and fresh browser/mobile release checks. If a full-horizon episode dies early it supplies an early terminal result, not observation of the unplayed late game. The immutable contract, exposure ledger and identical-arm setup must carry forward; this document does not open or qualify the final cohort.
