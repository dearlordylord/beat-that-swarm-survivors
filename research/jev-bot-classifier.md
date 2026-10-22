# Jev-assisted Survivors bot: feasibility research

**Purpose:** Assess delegating selected bot decisions to the external Jev classifier.

**Audience:** Game contributors and experiment reviewers.

**Status:** Research proposal, 2026-10-22; no integration or live request executed.

**Authority:** Source inspection and retained historical evidence; proposals are not game requirements.

**Expected use:** Select a bounded optional prototype and its evaluation criteria.

**Lifecycle:** Review when the classifier API, game decision interface, or dependency versions change; consolidate accepted decisions into the prototype contract.

**Implementation follow-up:** The research below records the initial feasibility inspection. An [optional controller](../tools/survivors-bot/README.md) subsequently implemented both upgrade choice and movement-goal selection, with authoritative Bend-derived immediate previews. See its [validation](../tools/survivors-bot/VALIDATION.md) for offline checks and the bounded live observation; the historical latency figures below remain a separate dataset.

## Finding

**Feasible as an optional low-frequency decision adviser. Start with choosing one legal upgrade.** Keep deterministic Bend movement and authoritative game transitions. Jev need not run Hapsland, inspect code, or control the complete game loop. A small optional TypeScript harness can call the same external classifier through Effect. Classifier confidence is not a calibrated probability that an action maximizes survival.

This report inspected local primary sources without reading credentials, installing packages, running game/classifier tests, or making paid/network classifier calls. Hapsland checkout HEAD: `fe640722dcab4d724a0f95327f4a395c5d5bbbc8`. Game checkout inspected by the coordinating agent: `d0d07b45e5fba3101bb6a32f45c533cad520ff4e`. Installed dependency sources identify both `effect` and `@effect/ai-typesafe` as `4.0.0`; these node_modules files are local installed-package evidence, not files covered by the Hapsland commit hash. The coordinator also verified public npm metadata for [effect@4.0.0](https://registry.npmjs.org/effect/4.0.0) and [@effect/ai-typesafe@4.0.0](https://registry.npmjs.org/@effect%2fai-typesafe/4.0.0) on 2026-10-22; no new installation or classifier call was made.

## Actual API and minimal reuse

| Boundary | Source-inspected fact | Consequence |
| --- | --- | --- |
| Typed decision | `Decision.make({ input: Schema, decisions: { name: Decision... } })`; `DecisionModel.decide(definition, { input })` returns named answers and usage | Define a game snapshot schema and a choice definition directly |
| Categorical | `Decision.classify({ instructions, criteria: { label: description, ... } })` requires at least two labels | Legal upgrade IDs can become the only allowed labels; one legal action needs no request |
| Binary | `Decision.probability` answers probability of true; optional criteria describe both outcomes | Several binary action scores are independent probabilities, not a categorical distribution or utility scores |
| Provider mapping | TypeSafe adapter maps Classify → `choice`, Rate → `score`, Probability → `noul` | The external Jev provider path already supports categorical decisions in installed source |
| Answer | Classify returns `label`, per-label `probabilities`, optional provider-defined `confidence`; chosen label need not equal maximum-probability label | Use and log an explicit label-selection policy; do not silently replace the selected label with argmax |
| Validation | Effect validates finite unit-interval probabilities and distribution sum; TypeSafe declares two-decimal precision and normalizes small rounding drift | Typed output checks do not establish gameplay correctness |
| Transport | `TypeSafeClient.layer({ apiKey, apiUrl? })` + `TypeSafeDecisionModel.model("jev-latest")` + `FetchHttpClient.layer` | Standalone composition, without importing Hapsland packages |

Primary sources:

- Hapsland [Jev bridge](../../../typescript/jev/packages/review-execution/src/jev-decision.ts), lines 17–28 and 35–56: its helper deliberately accepts only probability definitions; importing that product helper would unnecessarily inherit product boundaries.
- Installed [Decision.ts](../../../typescript/jev/node_modules/effect/src/ai/Decision.ts), lines 65–84, 95–107, 178–215, 256–298 and 339 onward.
- Installed [DecisionModel.ts](../../../typescript/jev/node_modules/effect/src/ai/DecisionModel.ts), lines 190–228, 341–365 and 380–420: schema-to-JSON encoding, provider dispatch and validation.
- Installed [TypeSafeDecisionModel.ts](../../../typescript/jev/node_modules/@effect/ai-typesafe/src/TypeSafeDecisionModel.ts), lines 21–33, 44–97 and 110–113.
- Installed [TypeSafeClient.ts](../../../typescript/jev/node_modules/@effect/ai-typesafe/src/TypeSafeClient.ts), lines 54–80, 101–115: Bearer auth, default `https://api.typesafe.ai/v1`, POST `/systemone`, no automatic retries.
- Hapsland [provider declaration](../../../typescript/jev/packages/runtime-environment/src/runtime/backend.ts), lines 69–94: model `jev-latest`, credential reference `TYPESAFE_API_KEY`. This report did not access its value or verify key availability.

Conceptual standalone composition (proposal; not executed/typechecked here): read `Config.Redacted("TYPESAFE_API_KEY")`, supply it to `TypeSafeClient.layer`, supply that client layer to `TypeSafeDecisionModel.model("jev-latest")`, and provide that model to `DecisionModel.decide`. Pin both Effect packages to the same exact compatible release. An optional Node/TypeScript experiment must not become a native game launch prerequisite.

**Clef caveat:** the current Hapsland Cloudflare adapter explicitly rejects non-Probability decisions ([cloudflare.ts](../../../typescript/jev/packages/review-execution/src/review-providers/cloudflare.ts), lines 52–61 and 85–126). It uses `CLOUDFLARE_API_TOKEN` plus account/model identity. Its offline adapter coverage is not evidence of categorical support or live quality/latency. Do not generalize the TypeSafe categorical path to that adapter.

## Snapshot and candidate contract

Suggested input: run ID, monotonically increasing decision sequence, simulation tick, hero/stage/mode, HP ratio, current loadout with ranks, passive/Arcana effects, evolution prerequisites and missing ingredients, reward type, exact legal options with stable IDs and human-readable mechanics, and a compact danger summary. Include the objective explicitly (survive to dawn, not maximize immediate damage).

The existing `Game.packet` serializes a JSON frame exposing HP/max HP, time, level, equipment, mode, offers `{kind,id,level}`, and bodies. Numerical IDs alone are insufficient: use `content.mjs` / `native-content.bend` descriptions to explain actual candidate effects. Do not send every entity when nearest-threat, enemy-count, projectile-pressure, free-space and recent-damage summaries suffice. These game interface observations were supplied by the coordinating agent; the classifier-side source inspection above is independent. Game primary entry points: [game.bend](../examples/survivors/game.bend), `choose_raw` line 720, seeded `started` line 798, `start` line 800 and public `choose` line 884.

Make `criteria` only the current legal upgrade candidates, e.g. `offer_0`, `offer_1`, `offer_2`, with substantive descriptions. Put current build and mechanics in the state, not vague labels such as “good option.” Ask which legal option best supports the stated survival objective. If only one candidate is legal, choose locally. Whether selecting the returned label or applying another explicit policy, record that policy before comparing outcomes.

Proposal protocol: `{runId, decisionSeq, observationTick, rewardRevision, candidatesHash, candidates, snapshot}` → `{runId, decisionSeq, selectedCandidateId, model, latencyMs, usage, probabilities}`. Bend retains legality and effects. Revalidate exact candidate identity, current reward revision and current legal list at application time. Reject late, duplicate, unknown or stale choices. A tick alone is insufficient because queued rewards can share a tick; a human choice invalidates any outstanding request. `Game.choose_raw` currently clamps the choice index, and an unavailable index can reach a synthesized healing offer through `offer_at`; neither behavior is sufficient validation of external decisions.

## Where to put the classifier

| Responsibility | Recommendation | Reason |
| --- | --- | --- |
| Upgrade choice | First prototype | Small legal candidate set, long-term synergies matter, existing choice panel can pause for a bounded decision; initially actual offers only, excluding reroll/skip/banish |
| Macro plan | Later experiment | Choose among “approach this chest,” “activate this ward,” “kite clockwise,” “prioritize escape”; deterministic steering executes the plan |
| Every-frame movement | Defer | Network delay, observation age, cost and nondeterminism overwhelm a fast simulation loop |
| Legality / collision / damage | Keep Bend | Existing game rules remain authoritative |

A practical first harness can import the already-generated `dist/game.mjs`, run the actual Bend-generated simulator and call `Game.choose` / `Game.advance`. This is an optional experiment process, not replacing Bend game logic or its BendHub ECS dependency. There is no existing native RPC bridge; native classifier integration is additional work and is not claimed here.

For paused upgrade decisions: freeze at the choice boundary, one request in flight, proposed two-second timeout, no retry, deterministic existing upgrade policy on failure/timeout. For a live macro planner: keep deterministic movement running, expire plans by simulation ticks and invalidate entity targets on lifecycle/identity change because pool slots can be reused; never await network in the render/tick path. Suggested initial budget: at most 50 requests per run and a declared aggregate call ceiling for the whole experiment. These are proposed operational limits, not measured service performance.

## What latency evidence actually exists

Retained historical primary evidence is accessible from Hapsland Git history, not a newly executed measurement:

- [2026-09-20 report](https://github.com/dearlordylord/hapsland/blob/e0a071afea12c1808f54aefba4ff2d44bc825341/evidence/evaluation/live-report-2026-09-20.json), exact commit `e0a071afea12c1808f54aefba4ff2d44bc825341`, fields `budget`, `timing`, `results`, `acceptance`.
- [Owning interpretation](https://github.com/dearlordylord/hapsland/blob/e0a071afea12c1808f54aefba4ff2d44bc825341/evidence/evaluation/README.md), lines 12–30 and final limitations.
- Current [evaluation guide](../../../typescript/jev/docs/evaluation.md), lines 22–35 and 48–62, routes to those records.

That report records **44 live code-review probability requests, zero retries**, mean **202.5 ms**, p50 **189 ms**, p95 **282 ms**, min **128 ms**, max **383 ms**. Transport and conformance were 44/44. **Semantic release acceptance failed:** one authored positive was outside its expected band, 32 semantic combinations were unchecked and one ambiguous. This is neither categorical-gameplay accuracy evidence nor a present-day latency guarantee. It suggests infrequent decisions are plausible; it does not qualify frame-by-frame control. No actual monetary charge is recorded there, so this report makes no cost-per-run claim. Token usage can be retained and separately priced only against the chosen provider's current billing terms.

## Proposed experiment and stopping rule

1. Offline fixtures first: two/three legal offers, one offer, invalid label, stale reward, timeout, missing key and provider failure. Confirm no illegal transition and deterministic fallback; mocked answers test plumbing only.
2. Small bounded categorical smoke test on authored upgrade snapshots. Record input/prompt identity, model alias, returned label/probabilities, latency, usage, failures and fallback rate. Keep exact action histories for replay. Mutable `jev-latest` is not immutable weights identity.
3. Compare existing heuristic and classifier-assisted upgrades on matched initial conditions. Current game hardcodes seed `12345`; `G.start` argument two is packed persistent upgrades, **not a random seed**. Current evaluation can only claim fixed-seed comparisons. A proper multi-seed API is separate future work.
4. Predeclare survival time, reach-dawn rate, kills, damage taken, upgrade/evolution completion, legal-action rate, request failures, wall-clock wait separately from virtual game time, and call/token budgets. Use the same deterministic movement and profile on both sides. Include fresh and intermediate legal profiles, rather than only a maximally upgraded ceiling profile, when feasible; do not interpret repeated identical deterministic baseline runs as independent map diversity.
5. Retain the integration only if it improves the chosen gameplay outcome with acceptable waiting and bounded spend. No success claim follows from a plausible-looking choice or high returned confidence alone. Macroplanning is a separate follow-up experiment.

Frozen snapshot comparisons can present identical observations and offer sets to both policies, but establish legality and plumbing rather than which choice improves gameplay. End-to-end runs match initial conditions; their worlds and later offers may naturally diverge after different choices. The affine game world has no supported state-fork interface: a counterfactual branch would require replaying a recorded legal action prefix from a fresh start, not copying or editing owned state.

## Reuse classification

- **DEPEND ON (optional):** published Effect and `@effect/ai-typesafe` packages for the experiment, compatible exact pins.
- **BORROW:** typed decision definition, provider-layer composition, sanitized timing/usage and failure accounting patterns.
- **REJECT:** importing Hapsland CLI/resident/review pipeline or vendoring its product code into the game.
- **OPTIONAL INTEGRATION:** external Jev adviser. Base gameplay, native launch and deterministic bot remain usable without credentials or network.
