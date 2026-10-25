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

The host advances the admission clock during reward pauses and acknowledges
input only after an actual game step. A movement command's intended tick is its
exact target world tick: a late command is rejected rather than shifted forward.
Transport sequence numbers and world ticks are different clocks. The
[worker](coop-worker.mjs) connects these boundaries.

A guest transport departure suspends the shared run without disconnecting the
stored player record or discarding its reward choice. The host keeps its Iroh
endpoint and invitation open. A new connection resets only the guest command
lane, receipt and queued inputs; the host lane, session ID and simulation state
remain intact. Setup creates and configures the guest only on the first join.
Rejoining returns the existing character, health, equipment and reward state,
regardless of the setup selected on the reloaded page. The snapshot rebuilds the
guest's prediction from current authority instead of replaying old local input.

The invitation is a bearer capability for the single guest slot, not a durable
account identity: whoever holds it may fill that slot once its connection is
free. A connected guest cannot be replaced concurrently. Closing or reloading
the host destroys the in-memory world and endpoint; an old invitation cannot
restore that run. An ended admission session cannot be revived by reconnect.

The reconnect laws pin the complete session transition. The generic
[attachment dispatcher laws](coop-attach-LAWS.bend) prove that a two-player
attachment sends the original affine state directly to its resume adapter,
ignoring new setup. Production wires that adapter to `Core.quiet`, which returns
the unchanged state; the full core wiring is checked by source review and
executed state equality. This is not a kernel proof of all game/core functions
or of browser/Iroh lifecycle behavior.

The [session laws](coop-session-LAWS.bend), [reward laws](coop-reward-policy-LAWS.bend),
[protocol laws](coop-protocol-LAWS.bend) and [pickup laws](pickup-selection-LAWS.bend)
state their precise guarantees. The shared [proof gate](../../scripts/check-bend-laws.py)
checks them with BendTT; the [mutation gate](../../scripts/check-bend-mutants.py)
requires type-correct semantic faults to be rejected.

Run `bash examples/survivors/check.sh` from the repository root. Universal wire
encode/decode roundtrip and cross-platform floating point determinism are outside
the current proofs.
