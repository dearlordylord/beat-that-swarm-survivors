# Network clocks, prediction and reconciliation: established patterns

Checked October 25, 2026. Research using primary documentation and source code; game code was not changed. Library documentation on `latest`/`main` changes over time: this is an architecture survey, not a proposal to install unverified versions.

## Answer

Yes. Most of our errors fall under long-established patterns: **fixed timestep**, **client-side prediction + server reconciliation**, **input history with acknowledgments of executed input**, **predicted spawning / spawn matching**, and **separate simulation and presentation timelines**. Existing networking stacks implement much of this, but require the game to adopt their time and identity model. Transport alone does not define these rules.

A direct match: Gambetta shows a character jumping backward and forward after server responses. The solution is a sequence number for each request, the last **processed** input number in the response, and replay of the unprocessed remainder. This is the contract our original heartbeat-duration counter lacked. [Gambetta's original chapter](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html).

> Implementation status: the description below records the cause before the fix. Old `coop-weapon-*` modules have been removed; the current `coop-combat-prediction.bend` candidate predicts known enemies and projectiles together and recomputes them from fresh authoritative state. Check results are recorded in `coop-projectile-visibility.md`.

## Priority addition: projectiles hit beside monsters

After the previous fix, the user observes another error class: their projectile looks smooth, but the impact does not match the visible monster. A smoothness check cannot close this issue.

In the original faulty `coop-browser.mjs`, the player's weapon is predicted forward while monsters remain in received/interpolated observations. `coop-weapon-reconcile.bend` preserves the old visible trajectory of an already known shot. Thus the visible projectile, visible monster and authoritative hit decision can refer to different world states. This is an inference from the implementation; diagnosing a specific frame requires matching shot ID, target ID, server tick and displayed coordinates.

Unity NFE documents this problem class: if resimulation updates some objects while interacting objects remain frozen at another time, collisions diverge. Its documentation proposes grouping interacting ghosts, consistent simulation, anticipation and subsequent correction. [Prediction edge cases / partial snapshots](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction-details.html#possible-mitigations).

Distinguish **prediction correction** from preserving a pleasant-looking history. Unity smoothing reduces the error between recomputed and previously predicted state; preserving an old trajectory forever does not ensure convergence. [Prediction smoothing](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction-smoothing.html). For interactions across temporal representations, Unity also maintains collision-world history for server-side lag compensation; this is an additional mechanism, not an automatic consequence of interpolation. [Physics / lag compensation](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/physics.html#using-lag-compensation-predicted-collision-worlds).

**Architectural recommendation for us:** choose a consistent contact model first. There are two practical directions:

1. Predict the relevant interaction group in Bend: projectiles and enemy states affecting flight/hits must be evaluated at the same predicted tick. Then match and correct the prediction against the host. Unknown future input from another player can still cause misprediction; a correction path is required.
2. Show physical combat on a consistent authoritative playback timeline, with immediate player response explicitly treated as cosmetic anticipation. This simplifies hit truth, but requires a product decision about visible weapon delay.

Authoritative hit events identifying shot, target, tick and contact are useful in both approaches: they can display confirmed damage on the correct target exactly once. **Events alone will not fix a trajectory** visibly flying beside the target. Full rollback of the entire ECS is a possible extension, but not the only way to define a consistent local collision world.

### Laws needed for this error

These are proposed contracts for a future design, not claims of existing proofs:

- **Shared interaction time:** contact computation receives projectile and target from the same collision world/tick. Predicted future and interpolated past must not be mixed silently.
- **Authoritative event linkage:** confirmed damage/impact refers to a specific shot/target lifetime, a specific tick and the result of the same collision resolver; redelivery does not duplicate presentation. Repeated aura damage needs distinguishable hit events, not deduplication only by shot/target pair.
- **Correction convergence:** after sufficient fresh snapshots and without new divergence, prediction approaches authoritative state at the chosen shared presentation tick. “A known shot always keeps its old path” permits persistent error and fails this requirement.
- **Truthful visible geometry:** in the consistent visual world, collision/hit feedback uses the same radii and positions as the displayed target; cosmetic prediction is not presented as a confirmed hit.

A failing contact test is needed: moving targets, crossing trajectories, homing target changes, delayed/batched delivery, slot reuse and piercing/periodic damage. It must link the host event to the same target and check shared-state geometry, not merely bullet speed and proximity of its spawn to the character. Laws can enforce this contract; they do not recover missing future information or choose the time model for us.

## Mapping to our failures

| Our failure | Established pattern | What to adopt |
| --- | --- | --- |
| Client counted ticks between sends, host between receives; even constant direction caused jitter | Numbered input commands + authoritative reconciliation | ACK must identify the executed prefix of the same history. Delivery durations are not execution durations. [Gambetta](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html) |
| Mixing rAF timestamps with a newer `performance.now()` rewound the accumulator | Monotonic time source + one owner of the fixed-step accumulator | Separate game ticks from measurement time and frame time. Source monotonicity does not establish monotonicity of arbitrary mixing of already sampled values. [High Resolution Time](https://www.w3.org/TR/hr-time-3/#now-method), [HTML animation callbacks](https://html.spec.whatwg.org/multipage/imagebitmap-and-animations.html#run-the-animation-frame-callbacks) |
| Character is predicted, weapon remains in the server's past | Predicted spawning, shared firing logic | Predict local shots from the same input and match them with server objects. [Unity NFE: spawning](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#implement-predicted-spawning-for-player-spawned-objects) |
| Reusing a physical slot mixed different projectile lifetimes | Stable predicted-spawn identity / classification | Identify a logical shot separately from its storage slot; type and tick alone may be insufficient. [Unity: classification](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching), [Lightyear PreSpawned](https://docs.rs/lightyear_replication/latest/lightyear_replication/#pre-spawning) |
| A new snapshot selected a new target for an old shot and aged the visible bullet again | Simulation history and presentation history; replay-safe effects | Object matching, resimulation and visible time progression need separate contracts. Source distinguishes re-executing a command from first playing its sound/effect. [Valve HL `HUD_PostRunCmd`](https://github.com/ValveSoftware/halflife/blob/master/cl_dll/hl/hl_weapons.cpp#L983-L1001) |

The last row compares architectures; it does not claim Source uses our particular visible-trajectory preservation policy. Our `WeaponReconcile.rebase` is bounded visual prediction, not full rollback of all interacting objects.

## What to read: a short sequence

1. **Glenn Fiedler, Fix Your Timestep!** — fixed steps, accumulators, separating rendering from simulation, catch-up limits and the “spiral of death.” The direct foundation of our 60 Hz loop. It is not an ACK or projectile-identity guide. [Original](https://gafferongames.com/post/fix_your_timestep/).
2. **Gabriel Gambetta, Fast-Paced Multiplayer**, especially part II — a minimal, clear prediction/reconciliation model. It directly illustrates our original jitter and the required input history. Read entity interpolation and lag compensation afterward as separate problems. [Series](https://www.gabrielgambetta.com/client-server-game-architecture.html), [part II](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html).
3. **Unity Netcode for Entities: prediction and ghost spawning** — the closest reference for our ECS example: owner-predicted objects, spawning, matching, smoothing and known edge cases. Classification is particularly important: the documentation warns that multiple bullets of the same type in one tick cannot reliably be distinguished by spawn tick alone; tick batching can also shift input application. [Prediction overview](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction.html), [spawning/classification](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching).
4. **Lightyear book + API/reference + examples** — a modern open implementation for Bevy. The author labels the book an incomplete set of notes; check it against current APIs and source for actual behavior. [Book](https://cbournhonesque.github.io/lightyear/book/), [source and examples](https://github.com/cBournhonesque/lightyear), [replication / PreSpawned API](https://docs.rs/lightyear_replication/latest/lightyear_replication/).
5. **Valve Half-Life / Source SDK** — useful source code from working implementations: weapon prediction, command history and distinguishing first playback of effects. This is reading material for architecture comparison; copying code requires a separate license review. [HL weapon prediction](https://github.com/ValveSoftware/halflife/blob/master/cl_dll/hl/hl_weapons.cpp), [Source prediction](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/prediction.cpp).

## What libraries provide

| Tool | What it actually handles | What remains our responsibility |
| --- | --- | --- |
| **Lightyear** | Buffers input by tick, synchronizes the input timeline, provides prediction/rollback, interpolation and predicted-spawn matching. Its README explicitly promises to apply tick N input on server tick N. [README](https://github.com/cBournhonesque/lightyear#features), [PreSpawned](https://docs.rs/lightyear_replication/latest/lightyear_replication/#pre-spawning) | Integration of Bevy systems, predicted components, identity and identical simulation rules. This is a Bevy/Rust stack, not a function to plug into our Bend World. |
| **Bevy Replicon** | Server-authoritative ECS replication, events, visibility and serialization. I/O is intentionally absent; prediction/interpolation/rollback are listed as ecosystem extensions. [README](https://github.com/simgine/bevy_replicon#features), [ecosystem](https://github.com/simgine/bevy_replicon#ecosystem) | Choosing a prediction layer and game-clock rules. Installing Replicon alone does not prevent our errors. |
| **Unity Netcode for Entities** | Schedules predicted simulation, authoritative snapshots and predicted spawning/classification. Default matching exists, with explicitly documented limits. [Prediction](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction.html), [classification](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching) | The game must run in Unity ECS and use the required groups/components. Not drop-in for Bend; valuable as a handbook and architecture reference. |
| **GGPO / GGRS** | P2P rollback: remote input prediction, scheduling, resimulation; GGRS requires saving, loading and advancing the game by one frame. [GGPO](https://github.com/pond3r/ggpo), [GGRS API](https://docs.rs/ggrs/latest/ggrs/#how-it-works) | Deterministic, replayable game simulation, correct save/load and replay-safe effects. A different integration scope from our authoritative host plus local prediction. |
| **Iroh** | Encrypted QUIC connections; the application protocol defines behavior above them. Documentation explicitly separates connection pools from application protocols. [Iroh protocols](https://docs.iroh.computer/concepts/protocols) | Input sequence numbers, execution ACKs, game ticks, prediction, spawn identity and rendering timeline. These errors give no reason to replace Iroh. |

**Conclusion for this project (architectural assessment):** adopt established concepts, invariants and verification scenarios now. Integrating all of Lightyear/NFE would require a separate integration layer or moving execution to another ECS, contrary to the current goal of demonstrating Bend/Bendvy. GGPO/GGRS is worth evaluating when full rollback/save-load and a deterministic world become requirements, not as a way to fix one time accumulator.

## Clocks: an important subtlety

Our failure was not an NTP adjustment of system time. `performance.now()` already uses a monotonic clock. An rAF callback receives the timestamp passed by the frame-start algorithm; the callback may execute after another handler has sampled a newer `performance.now()`. Assigning shared `lastTime` from both sources without an ordering contract can therefore decrease `lastTime`. This follows from specifications and our code, not a browser violation of HR Time. Window and Worker also have distinct time origins; comparing relative values without conversion does not create a shared timeline. [HR Time `now`](https://www.w3.org/TR/hr-time-3/#now-method), [time origins](https://www.w3.org/TR/hr-time-3/#sec-time-origin), [HTML rAF](https://html.spec.whatwg.org/multipage/imagebitmap-and-animations.html#run-the-animation-frame-callbacks).

## What to enforce in our implementation

These are recommendations for our implementation, not guarantees of the listed libraries:

- Extract one small clock/accumulator contract: sampled moments, game ticks, acknowledged input and visual age are different values. Conversions are explicit; the accumulator has one owner. Check an old rAF timestamp arriving after a newer network callback and batched updates after a pause.
- Keep the chosen numbered-input ledger: one local input tick, one authoritative consumption, exact cumulative ACK, replay of the suffix only. Never infer execution duration from send/delivery time.
- Describe each entity type as predicted, interpolated or authoritative-only. The player and their weapon must use a consistent temporal model; damage/XP remain host decisions.
- Keep logical ShotId separate from physical pool slot and animation age. Effect playback must be tied to an event/first presentation, not replay count.
- Record real playback checks in the handbook: long holds, turns, release, loss/batched delivery, pause/resume, slot reuse, a new snapshot with a different target, and an ACK with a large world-tick jump. Check trajectories and events, not just initial response and final endpoint.
- Measure actual latency in both directions. Test transport/serialization overhead is not intentionally injected network delay; a prediction library cannot fix an incorrect measuring instrument.

Mapping to candidate files: `coop-browser.mjs` owns the monotonic accumulator and browser IO; `coop-input-queue.bend` defines execution and ACK; `coop-prediction-replay.bend` defines replay/guards/identity; `coop-combat-prediction.bend` recomputes known combat participants from a fresh anchor. Old trajectory preservation has been removed. These are separate mechanisms in the example; correct temporal input assignment and transitions between anchors need independent checks. Further generalization into a reusable Bend core should follow these contracts and laws, keeping game logic in Bend and Iroh as transport.
