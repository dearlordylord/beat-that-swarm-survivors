# Acceptance scenarios

Select scenarios that exercise the changed contract. Set distances, tick budgets and timing thresholds from the game's speeds, collision geometry and supported network conditions before evaluating the candidate. The examples below describe failures, not universal numeric defaults.

## Clock and input history

| Scenario | Evidence to capture | Required distinction |
| --- | --- | --- |
| New processing-time sample, then older rAF/event sample | Samples, origins, accumulator before/after, emitted ticks | Source-clock monotonicity versus sample-consumption order |
| Host and client have different callback phase and packet cadence | Command ID/duration, local tick, host execution and ACK | Same command execution versus time between packet events |
| Several accumulated observations arrive together | Host tick delta, local elapsed time, movement and animation age | Knowledge advancing versus a second local simulation step |
| Duplicate/stale ACK, delayed command or coalesced snapshot | Admitted/executed prefix, retained suffix, observation generation | Receipt, execution and presentation freshness |
| Pause/resume, death, tab suspension or reconnect | Epoch, timers, pending history and authority state | New epoch versus replayable history from the old one |

A useful clock counterexample is processing sample 140 after sample 130, then consuming an older frame sample 128. A common `lastTime = sample` assignment rewinds the accumulator's base even though the underlying clock is monotonic. Assert elapsed-time conservation and declared suspend behavior; clamping one delta alone is insufficient if the stored base still moves backwards.

An executable clock case starts with base `0`, remainder `0` and a fixed step of `10`. Consume samples `25, 18, 33`. Expected cumulative `(steps, remainder)` values are `(2, 5), (2, 5), (3, 3)`: the stale sample advances neither time nor base. The faulty variant that clamps negative elapsed time but rewinds the base to `18` emits four total steps at `33`; reject it.

A useful input counterexample holds one direction throughout. Client heartbeat segments contain `[3,3]` simulated steps while server delivery partitions the same two held-state packets into `[4,1]`. An ACK that subtracts one partition from the other is not an ACK of a common input history. Test packet batching and independent tick phase without changing the user's direction.

A world-time counterexample starts at tick 38, x=1000. The host runs neutral ticks 39–41 and fires on 41, then executes three rightward inputs assigned to 42–44. A replay that compacts those inputs into 39–41 reaches the same final x=1007.5 but fires from another position and leaves the projectile three ticks younger. Require replay of every world tick, explicit neutral gaps and an explicit policy for an input targeting an already committed tick. Packet sequence and world tick are different identities.

## Contact and correction

For each affected entity, log logical lifetime ID, physical slot, authority tick, prediction tick and displayed coordinates. For a contact, also log shot and target geometry, swept paths or collision-world query, resolver result and hit-event identity.

| Scenario | Gate |
| --- | --- |
| Moving owner emits a new projectile | The birth follows the weapon's intended origin rule in the owner's chosen timeline; targeted areas and orbiting weapons need their own geometry |
| Owner reverses with a detached projectile already in flight | New input does not drag the existing ballistic path; intended homing/return behavior still uses its declared inputs |
| New observation changes an existing shot's target | Correction has bounded discontinuity and a convergence rule; the shot is not silently recreated from another past aim |
| Canonical updates continue while an existing trajectory is offset | The stated convergence metric decreases or meets its deadline under the law's assumptions |
| Projectile and target interact during prediction/reconciliation | Their collision states belong to one interaction model; visual impact and confirmed damage are attributed to the correct target lifetime |
| Target or projectile slot is reused | Old trajectory, HP, heading, impact and effect caches do not attach to the new lifetime |
| Several bullets share type and spawn tick | Matching distinguishes volley slots or another stable logical identity |
| Replay repeats a hit-producing command | Persistent damage/rewards remain authoritative; transient sound/particles/hit markers follow explicit first-play or event deduplication rules |

A convergence counterexample starts a canonical ballistic shot at x=7300 and its displayed estimate at x=7400, with identical velocity and lifetime ID. Accept fresh canonical observations every tick. A policy that always chooses the previous trajectory can leave the error exactly 100 after 1, 10 and 20 ticks while producing perfectly smooth motion. A continuity-only test admits this defect.

Define convergence over the error metric and lifetime being corrected. State what happens if the entity despawns before the correction budget expires, and whether a discontinuous new canonical target resets or supersedes that budget. Require convergence under declared observation and target-stability assumptions; do not require zero error against an unknown future state.

A contact counterexample displays a predicted projectile at tick 140, an interpolated target at tick 117, and confirmed damage from tick 120. Compare states using the design's explicit world/time mapping; geometric proximity of arbitrarily mixed endpoints is not evidence for or against the authoritative collision.

Predicted contact witnesses can all be internally valid while the real host hits another target. Require nonzero confirmed host contacts matched to actual displayed shot and target lifetimes and the declared time mapping. Do not label a probe with zero confirmed contacts as closure of an authoritative-hit bug. Include future known actors and weapon births in the prediction-dependency review; omitting remote fire can keep a target alive that authority already killed.

A successful contact report names the selected interaction policy and maps authority, simulation, collision and displayed ticks for the tested contact. Include any interpolation, prediction or rewind mapping so the claimed agreement can be checked.

If hit events are introduced, their identity must distinguish legitimate repeated hits from duplicates. An aura can damage the same target more than once; deduplicating only by `(shot, target)` would erase valid damage. Include the collision tick or an explicit event sequence and the relevant entity generations.

## End-to-end and measurement controls

Capture the chain `input → send → host execution → ACK → reconciliation → actual draw`. Check a sustained traversal and release, not just first response and final endpoint. Include startup packet bursts and a mid-run pause if either is part of the product.

Controlled delay/jitter fixtures need:

- Explicit ordering, loss, duplication and coalescing semantics matching the tested transport.
- Actual send-to-delivery distributions in both directions, maximum payload size, queue age and stalled-frame counts.
- Exact binary roundtrip controls including boundary sizes when the encoding or test bridge changes.
- A comparison exposing observer overhead: for example, transporting each byte as an individual debugger-protocol number can create queueing absent from the production byte path.

Retain failing artifacts and the tested revision. Use real peers or browser contexts for the delivery path when available, and say which physical/browser/network conditions were actually exercised. A fake delay value is not measured RTT, and a visible headless tab is not proof that a minimized desktop tab will keep running.
