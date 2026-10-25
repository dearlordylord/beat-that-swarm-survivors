# Co-op command boundary

[Session admission](coop-session.bend) owns authenticated player binding,
sequence checks, movement expiration and acknowledgements.
[The protocol](coop-protocol.bend) owns command framing and canonical numeric
encoding. Their data declarations and functions are the authority for wire
shape, limits and timing policy.

The transport host supplies the authenticated identity; it must not trust an
identity from the message payload. Admission and game application are separate:
[the game core](coop-core.bend) validates actual setup and reward eligibility.
[Reward policy](coop-reward-policy.bend) supplies the admission decision and
remaining obligations used by that core.

The host advances the admission clock during gameplay pauses and acknowledges
input only after an actual game step. Intended tick is diagnostic. Disconnect
and terminal behavior belong to the session transition, while character death
belongs to gameplay. The [worker](coop-worker.mjs) connects these boundaries.

The [session laws](coop-session-LAWS.bend), [reward laws](coop-reward-policy-LAWS.bend),
[protocol laws](coop-protocol-LAWS.bend) and [pickup laws](pickup-selection-LAWS.bend)
state their precise guarantees. The shared [proof gate](../../scripts/check-bend-laws.py)
checks them with BendTT; the [mutation gate](../../scripts/check-bend-mutants.py)
requires type-correct semantic faults to be rejected.

Run `bash examples/survivors/check.sh` from the repository root. Universal wire
encode/decode roundtrip and cross-platform floating point determinism are outside
the current proofs.
