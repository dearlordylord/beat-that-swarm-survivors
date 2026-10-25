---
name: realtime-netcode
description: Diagnose and implement real-time multiplayer game timing, client prediction, reconciliation, predicted spawning and contact consistency. Use for input lag, correction jitter or disagreement between displayed combat and authoritative hits.
---

# Realtime Netcode

Make the authority, input history, entity identity and interaction timeline explicit before changing the symptom. Preserve the project's chosen engine, language and transport unless the requested work and evidence justify a change.

For a read-only research or review request, deliver contracts, evidence and unresolved choices without installing dependencies, migrating libraries or editing implementation code. For implementation, carry the reproduced failure through a regression and verify the resulting behavior. A skill file or design note does not complete an authorized gameplay fix.

## Establish the temporal contract

Trace one input and one affected entity through input sampling, simulation, transport, authoritative execution, reconciliation and rendering. Record these separately:

| Value | Meaning to establish |
| --- | --- |
| Clock sample | Clock source, time origin, units, sample time versus delivery time |
| Simulation tick | Which world advances, fixed duration or explicit command duration |
| Input ID | Which exact command the client predicted and the host consumed |
| Authoritative ACK | Executed prefix, including partial consumption if the protocol permits it |
| Entity lifetime | Stable logical identity, distinct from a recycled storage slot |
| Presentation state | Which tick/world is displayed and how correction converges |

The trace is complete when every displayed or simulated quantity can be assigned to a clock/world and an entity lifetime. Use distinct types or named wrappers where the project supports them; equal numeric values do not establish equal meanings.

## Follow the relevant branch

- **Clock or step-count failure:** inspect the accumulator's owner and all callers. A monotonic clock source can still be consumed in a decreasing order when old frame samples arrive after newer event samples. Make origin conversion, stale samples, suspend time and catch-up limits explicit. See [clock and input scenarios](references/acceptance.md#clock-and-input-history).
- **Prediction or reconciliation:** identify the exact input records and durations replayed on both sides. ACK the executed prefix and replay its suffix. Packet arrival intervals and state heartbeats do not define simulated command duration. The same step function and initial conditions must support the claimed agreement. Exact FIFO execution alone does not assign inputs to world ticks: preserve their intended tick, including neutral gaps, and define how late inputs are rejected, delayed or rolled back. Otherwise movement distance can agree while cooldowns, births and collisions disagree.
- **Spawn or effect failure:** match logical shot/entity lifetimes across prediction and authority. Include enough information to distinguish simultaneous volleys. Store birth identity independently from visual age and current network time. Replay may recompute simulation; presentation effects need explicit first-play or event-deduplication semantics.
- **Missed or displaced impacts:** inspect the projectile and target together. Declare a coherent predicted interaction set, an authoritative combat playback timeline, or an explicit lag-compensated collision-world mapping. Read [contact and correction scenarios](references/acceptance.md#contact-and-correction) before treating smooth motion as a successful fix.
- **Library or handbook selection:** compare the library's required simulation/identity/save-load contract to the existing game. Read [patterns and primary sources](references/patterns-and-sources.md). A transport library does not supply the game's prediction model.

## Separate three obligations

**Continuity** bounds visible corrections. **Convergence** requires the displayed estimate to approach the specified canonical state under stated conditions. **Contact truth** ties a hit to the correct shot, target lifetime, collision tick and resolver.

Test each obligation independently. Keeping an old trajectory forever can satisfy continuity while preserving an error forever. Smoothing must correct a defined error; it cannot make two incompatible collision timelines agree by itself. Authoritative hit events provide attribution and deduplication, but do not make a visually distant projectile touch its target.

Keep canonical simulation state separate from render correction state. Reconciliation may restore and replay canonical state; presentation correction should have its own bounded lifetime or convergence rule. A network update is not an extra local animation tick.

## State the missing property before the fix

Choose laws or properties that connect the two sides of the boundary where the failure occurs. Typical candidates are:

- Given the same deterministic step, command durations and starting state, consuming an input prefix and replaying the remaining suffix preserves the intended path.
- Duplicate or stale ACKs cannot acknowledge another command or consume elapsed time twice.
- Reused pool slots receive new lifetime identities; known lifetimes retain their identities through reconciliation.
- A correction converges within a declared budget when fresh canonical observations continue and the law's stability assumptions hold.
- Contact evaluation uses compatible projectile/target states; confirmed hit effects refer to that contact and are delivered once under the event's identity rules.

Use the project's existing formal or property-testing workflow. Falsify the proposed property on the failing implementation, then check its implementation and meaningful mutants. State assumptions and proof scope explicitly: a proof of replay scheduling does not prove the gameplay adapter, renderer, operating-system scheduler or network latency.

## Qualify the observable behavior

Use [the acceptance scenarios](references/acceptance.md) to select tests for the actual failure. Establish the old failure before accepting the candidate. Retain start/stop responsiveness while checking the complete trajectory, contacts and correction path.

Measure actual delivery delay in both directions, update/render cadence, queue age and instrumentation cost. A delayed-byte fixture must preserve the transport semantics it claims, and its encoding must preserve exact bytes. Compare representative real-transport behavior with controlled scenarios; distinguish injected delay from additional driver backlog.

Complete an implementation only when the symptom's regression passes, neighboring authority/identity/interaction guarantees still hold, and the deployed or launched artifacts are the tested revision when delivery is in scope. Report measured conditions and remaining limits. Preserve acceptance criteria while investigating a failed measurement rather than weakening them to admit the candidate.
