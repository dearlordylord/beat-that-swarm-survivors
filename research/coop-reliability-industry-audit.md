# Co-op combat reliability: architecture audit

Reviewed 25 October 2026 against the existing `research/netcode-*` notes and `skills/realtime-netcode/`. This is a focused delta, not a repeat of their broad survey. The comparison uses primary engine documentation/source; it is an architecture review, not a browser or network proof.

## Failure in baseline `5aff253` (replaced)

This section records the old implementation, not the final browser path.

The guest’s movement replay was tick-addressed: `Prediction` stores local inputs by `targetWorldTick`, but its lead is `ceil(RTT × 60 / 1000) + 4`, capped at 54 ticks ([prediction state](../examples/survivors/coop-prediction.bend#L16), [browser reconciliation](../examples/survivors/coop-browser.mjs#L62)). A reported lead near 47 ticks therefore makes the combat display a long forecast beyond the latest host anchor.

For each accepted snapshot, the browser passes the host’s latest session admission to `CombatForecast.receive`, then rebases the fresh combat anchor through that same guest display tick ([browser](../examples/survivors/coop-browser.mjs#L83), [combat policy](../examples/survivors/coop-combat-prediction-policy.bend#L8)). `receive` keeps only current direction axes; `rebase` discards the old scene as simulation truth and replays the full unconsumed horizon. Each replay tick moves both players, enemies and existing shots, and forecasts team weapon births. The rendered bodies and witnesses share the resulting `Scene.tick`, so they are internally one forecast cohort; they are not evidence that the host followed the forecast. The scene explicitly assumes held remote input and future shots ([future plan](../examples/survivors/coop-combat-prediction.bend#L92), [forecasted volleys](../examples/survivors/coop-combat-prediction.bend#L111), [rendered assumptions](../examples/survivors/coop-combat-prediction.bend#L538)).

The host snapshot does carry admission metadata such as sequence/applied tick, but the combat adapter reduces it to `Session.Directions`; it does not retain an effective-tick input history ([session lane](../examples/survivors/coop-session.bend#L11), [adapter](../examples/survivors/coop-combat-prediction-policy.bend#L10)). A new held direction consequently drives every speculative tick after the new anchor. This matches the reported reverse correction (host 7700 → 7457.5 in one frame, with a 45-unit change for the same enemy lifetime): those are supplied regression observations, not measurements reproduced in this review.

The worker publishes about every 50 ms, while the guest can forecast roughly 47 ticks ahead. The send cadence is one snapshot every three 60 Hz steps; a 50 ms presentation buffer can smooth packet cadence, but it cannot make the remaining remote future known. If the buffer delays the anchor, it adds about three more ticks to the unknown interval ([worker schedule](../examples/survivors/coop-worker.mjs#L104)).

## Industry comparison

| Reference | Relevant contract | What it says about this design |
| --- | --- | --- |
| **Source / Valve** | Predict the locally controlled player; interpolate remote players. Source documents a bounded 250 ms extrapolation window. For hitscan, the server rewinds historical player hitboxes to the command/view time and restores them. The history is players, not a replay of all projectile and combat state ([Source networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking), [Valve lag compensation source](https://github.com/ValveSoftware/source-sdk-2013/blob/be57e3d01ac7d7aa6a2cacbfef187c0b46616db0/src/game/server/player_lagcompensation.cpp#L345-L437), [Bernier paper](https://web.cs.wpi.edu/~claypool/courses/4513-B03/papers/games/bernier.pdf)). | A long remote forecast is not contact truth. Source keeps collision time explicit and limits rewind to a specific hit model; it does not make persistent projectile contacts correct by smoothing their sprites. |
| **Unreal** | Character Movement records owner moves, the server reproduces and ACKs/corrects them, then the client replays saved moves after the acknowledged timestamp. Unreal’s networked projectile example spawns and collides on the server; radial damage is authority-only ([Epic movement guide](https://dev.epicgames.com/documentation/unreal-engine/understanding-networked-movement-in-the-character-movement-component-for-unreal-engine), [networking overview](https://dev.epicgames.com/documentation/unreal-engine/networking-overview-for-unreal-engine), [radial damage API](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Engine/UGameplayStatics/ApplyRadialDamage)). | Preserve the guest’s exact move history and muzzle-at-birth position; confirm damage and recipients on the host. GAS prediction keys identify predicted side effects within a logical ability activation scope; they are not a long-lived shot/contact identity ([Epic FPredictionKey](https://dev.epicgames.com/documentation/unreal-engine/API/Plugins/GameplayAbilities/FPredictionKey)). |
| **Unity Netcode for Entities 1.10** | Full snapshots roll predicted ghosts back and replay them together. Partial snapshots can leave interacting ghosts at different ticks; documented mitigations include grouping, limiting interactions to simulated entities, or anticipation. Predicted spawn classification by type/tick cannot reliably distinguish multiple same-type bullets in its window ([prediction edge cases](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction-details.html), [spawn matching](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching)). | A same-tick tag is necessary, but a coherent rollback also needs the state and history for all interacting actors and births. Bend currently replays one detached combat scene, but does not know future host movement/fire or receive a host collision event. |
| **Lightyear 0.30 / Bevy** | Tick-synced inputs are buffered for their exact server tick. Its spaceships demo predicts a remote bullet only when that remote input arrived early; remote entities can instead be interpolated. For physics, it separates canonical `Position` from render `Transform` so visual correction cannot overwrite the next fixed tick ([Lightyear timeline/input](https://cbournhonesque.github.io/lightyear/book/tutorial/basic_systems.html), [spaceships demo](https://github.com/cBournhonesque/lightyear/blob/0.30.0/demos/spaceships/README.md#predicted-bullet-spawning-and-input-delay), [Avian state/render split](https://cbournhonesque.github.io/lightyear/book/concepts/advanced_replication/avian.html)). | Closest match for per-tick inputs and correction ownership. Its input buffer and rollback histories do not exist in this Bend adapter. Lightyear is a Rust/Bevy stack, not a Bend/Iroh drop-in. Bevy Replicon supplies server-authoritative replication but not transport or a prediction model ([Replicon docs](https://docs.rs/bevy_replicon/latest/bevy_replicon/)). |

Across these systems, visual correction and collision authority are explicit separate responsibilities. Lightyear keeps visual transforms out of canonical physics; Source permits rendered remote hitboxes to differ from server-time hitboxes because its lag-compensation query names the time being tested. Neither source defines independent per-actor render offsets as a guarantee of shot/target contact truth in one displayed cohort.

## Decision after the first measured candidate

The initial capped forecast and shared crossfade recommendation was tested and
rejected. With delayed observations, enemy corrections remained large and the
client accumulated 450 ticks of authority lag. The failed prototype is removed.
See [the acceptance record](coop-reliability-plan.md) for the counterexample.

The replacement follows the interpolation option described by Source and
Lightyear: local movement prediction, a bounded authoritative remote snapshot
timeline, and local cosmetic projectile anticipation. No future whole-world
combat replay runs in the browser's snapshot intake or render path. All remote
players, enemies and confirmed projectiles share one bracket and fraction.
Confirmed contacts come from the host's prepared resolver, with stable shot and
target lifetimes. Terminal shot paths and target-relative effects share the
same target trajectory. Cosmetic anticipation cannot change HP, XP or rewards.

Input delivery uses a bounded FIFO journal, batched commands and one native
write in flight. Admission precedes sequence allocation and prediction. At
capacity, input prediction pauses rather than pretending an unsent command
reached the host. Critical actions reserve capacity. A transport completion
only clears its matching connection epoch and batch.

## Acceptance and proof boundaries

The [acceptance plan](coop-reliability-plan.md) records adversarial obligations
and review cycles. Pure Bend laws, mutation checks, emitted-code diagnostics and
actual Iroh browser runs establish different evidence. None proves arbitrary
network availability, browser scheduling or complete game physics. The old
combat forecast laws are not evidence for the new presentation path.
