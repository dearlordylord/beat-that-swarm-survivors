# Connection readiness before simulation

The reported start-then-disconnect was reproduced with host b9a1364 (combat
model v2) and guest d0fca34 (v3). The old host started as soon as it received
Setup; the guest rejected the first incompatible snapshot without ever drawing
a frame. The host then showed its rejoin message. Two d0fca34 clients connected
normally in the comparison. This establishes the mixed-version failure mode;
the original device's complete diagnostic message was not captured.

The separate “Could not connect” heading concealed the useful error in another
part of the panel, while its explanatory paragraph still asserted that the
friend was hosting. The error reason now appears directly below the heading.

The application handshake and short control codec now live in Bend:

1. Authenticated Iroh connection begins Hello/HelloAck version negotiation.
2. An admitted Setup prepares the initial or retained world, without stepping.
3. The guest validates and applies the initial snapshot, then echoes its exact
   connection token and observation number.
4. Only that ReadyAck moves the host into Running and emits Started.
5. The guest enters Running after Started; its prediction/input also waits.

The actual worker scheduler reads the Bend Running predicate. Laws pin both
start actions and the entry into a Running state, so a mutant that enters
HostRunning while returning Nothing is rejected. Other laws cover stale epochs,
duplicate acknowledgments, nonfatal obsolete deadlines, retries, immutable first
failure reasons, compatible frame admission and the allowed wire control forms.
Neither received bytes nor transport connection alone imply guest readiness.

Browser IO still owns timers, worker delivery, transport handles and rendering.
It reports their results to Bend. The main thread observes worker Bend states and
can apply the deadline without a response from a crashed/unresponsive worker.
Rust can close one peer without closing the listening endpoint. Only the final
rejection send waits for a transport receipt; game traffic is not serialized
behind a new per-message round trip.

Temporary real-Iroh diagnostics verified normal join/rejoin/reward selection;
withheld ReadyAck kept host simulation at tick zero and its game view hidden;
a deliberately wrong Hello version displayed the full reason and did not start
the host; another guest subsequently joined through the same retained invitation.
These execution checks qualify the IO adapters, not a proof of browsers or Iroh.

The connection module has 38 checked laws and six rejected semantic mutants.
Independent projections pin the epoch, role and waiting predicates, rather than
using the implementation's own projection as its specification. The existing
full example check passed before those final three projection laws; their
proofs and all six connection mutants then passed the focused check.

Fault injection also covered a worker throwing during module startup and a
worker that never replies. Both produce a visible failure and release the busy
UI without starting the world or leaving an invitation. The final adapter build
repeated the withheld-ack and rejected-peer/same-invitation retry checks.

This extraction covers connection policy, not all browser orchestration.
Animation scheduling, DOM rendering, snapshot transfer and worker delivery
remain adapters. Prediction's elapsed-time accumulator and reset orchestration
still live in JavaScript; movement, reconciliation and combat forecasting call
Bend modules. Do not describe the whole browser layer as proved or logic-free.
