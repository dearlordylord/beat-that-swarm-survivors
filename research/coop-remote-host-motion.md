# Remote host motion and the speculative clock

A guest forecast advanced `Session.clock` on every speculative world tick.
That clock expires held movement after 18 ticks. The guest does not receive the
host's future input heartbeats inside that replay, so a larger prediction lead
expired a still-moving host's direction. The avatar stopped between snapshots
and jumped forward on each new anchor. This is latency-sensitive, not specific
to a particular touchscreen or transport.

`Scene` now contains sampled `Directions`, not a session/admission clock.
`receive` captures the authority's current directions; speculative advancement
cannot age that input lease. The next authoritative sample replaces the hint,
including a stop. Host admission expiry remains unchanged. Existing prediction
horizon guards bound the browser's extrapolation; future changes of direction
remain unknown until observed. All players, enemies and projectiles still share
one combat tick. No avatar-only offset or second combat timeline was added.

Two Bend laws pin capture of axes and connection/end masks. Three typed mutants
(clock-before-capture, dropped movement, swapped player lanes) are rejected.
These are boundary laws, not a proof of the entire game or browser scheduler.
The changed Scene type removes the admission-clock capability from advancement.
The frame compatibility marker is now `world-input-combat-v3`.

Temporary emitted-module checks covered 20 combinations of lead (4,12,18,24,54)
and observed input age (0,2,5,17). All now advance 2.5 pixels each world tick and
rebase without the former 7.5-pixel jump for continuous movement. A newly observed
stop takes effect. Another 120 full combat ticks matched the old simulation with
continued host heartbeat renewal, including bodies, players, contacts and births.
The actual host's 18-tick timeout still expires normally.

A real-Iroh browser diagnostic used a mobile touch context, one continuously held
pointer and 300 ms added guest-observation delay. Before: lead29, host frozen on
130/171 advancing-cohort intervals. After: lead30, 0/150, and every displacement
equaled 2.5 times the cohort-tick delta. Same-tick display frames were counted
separately. This does not establish 60 Hz under arbitrary device load or qualify
a physical iPhone/Safari; browser errors were absent and source hashes stable.

A separate reproduced input bug allowed a second finger's release to clear the
first finger's joystick direction. The pad now has one pointer owner; other
pointers are ignored. Owner release/cancel, blur and reward opening clear capture
and input. Direction quantization is unchanged.

The guest lobby initially says “Your place is ready?”; only receipt of an actual
host frame changes it to “Your place is ready!”. Failed connection shows “Could
not connect”. Opening an invitation alone does not establish host availability.
