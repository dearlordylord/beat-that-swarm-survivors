# Standards review — cycle 2

Scope: dirty changes and new co-op sources relative to
`5aff25371637f14dca5bfa879968b630344edd22`, reviewed on 2026-10-25.
The parallel menu commits `afc4546` and `3ef7bdc` are outside this review.
Standards source: repository `AGENTS.md`; no repository
`CODING_STANDARDS.md` was found. Applied the code-review skill's Fowler smell
baseline as judgement calls. The reviewer authored Core/HitJournal changes;
those files and their tests/proofs are **excluded**, not independently reviewed.

## Documented rules

No additional hard violation found in the inspected browser/worker/presentation,
renderer, InputFlow, Playback, ClientClock, ContactPlayback and LocalProjectiles
sources. Game-state decisions remain in Bend; browser code dispatches IO and
formats renderer records. Native entry points were not modified by this change.
No unsafe/foreign proof shortcut was found in these new Bend modules. Actual
BendHub import and proof gates remain required; this review is not their result.

## Correctness finding forwarded to the implementation owner

**Blocking: overflow accounting reports no eviction.**
`coop-local-projectiles.bend`, `overflow_added(before,after)`, computes
`Bool.to_u32(Nat.is_gt(after,before))`, while callers pass the pre-cap length
followed by the post-cap length. The emitted function returns `0` for
`overflow_added(513,512)`. Consequently both dropped counters miss real capacity
losses. Public-path laws reuse the same helper, leaving this error unconstrained.
Pin the intended independent overflow count, fix the helper, and test a capped
public transition plus a mutant. This finding concerns the acceptance plan's
explicitly counted cosmetic overflow rather than an invented coding rule.

## Possible smells

**Mysterious name (nonblocking):** browser `lastRoundTripMs` is measured from
command enqueue until a snapshot's admission acknowledgement. It includes queue
residence, host processing and snapshot delay. Rename it to `inputAckDelayMs` or
state that meaning at its declaration/diagnostic output. Treating it as pure
network RTT would mislead later tuning and performance reports.

No recommendation to move renderer styling or browser scheduling IO into Bend.
A follow-up readback should verify the counter fix and any material changes
made after this review.

## Cycle 3 — independent follow-up

Core, HitJournal and SnapshotFlow remain excluded because this reviewer authored
them. HitEffects was reviewed independently at implementation SHA-256
`a6552eb308e2228298fe425b591760244dbd37b4df1beb754e78beb0b75a52a4`,
laws `a11b4d6d7e9df85b5cc337794597b5337a82fefb4d3277ee26ba6f33e35aa0ba`,
proof `914b555b73d213468f7853c4fd1c7df78c6a7a9ef27c88fc86c9f3f4807bba6a`.
Fresh emission passed 23 runtime checks under `--stack_size=192`, including
successive 500-hit batches and target indexing across 12,000 actors. The laws
pin public add/advance/render paths and their selection, expiry, mapping and
capacity helpers. A constant-empty public result contradicts those equations.
This is not proof of the browser adapter or QUIC behavior.

The LocalProjectiles overflow helper now counts `before-after`; this closes the
cycle-2 source error. Final law/readback qualification is pending its owner's
freeze. A new gap was forwarded: the string-rendering law delegates to opaque
`native_render_frame`, and no current law pins that serializer or its row
serializers. A constant-empty encoder could therefore preserve the typed
render-pipeline laws. A mutation experiment during the owner's ongoing edits
was **inconclusive**, because the baseline failed an unrelated in-progress
endpoint proof. Do not report that run as a surviving or rejected mutant.

The cycle-2 diagnostic naming concern is also closed in source:
`inputAckDelayMs` now names enqueue-to-admission acknowledgement latency.

### Final policy readback after extraction

The earlier pending LocalProjectiles conclusion is superseded by this narrower
review. The former 152 Game-importing claims were removed after exceeding the
fixed verifier CPU limit; they are **not** carried forward as proved guarantees.

Blind readback first inspected only the 52 formulas in policy laws SHA-256
`43c70ab4b630673789189b25ef7ddd6e220431ab1485f414fe28dbefdd050e89`.
They pin overflow subtraction, terminal kind/outcome, a symmetric past/future
64-tick receipt window, first live exact seed/generation lookup, contact offset
or canonical fallback, complete visibility selection, and every serializer
field plus empty/singleton/cons/frame paths. No constant-empty or opaque-helper
gap was found within those policy contracts. `contact_found` alone checks only
generation; its public caller's pinned lookup supplies seed/alive validation.
Serialization equations describe raw concatenation, not JSON well-formedness
for arbitrary quoted strings; runtime-generated numeric/colon IDs are the
current input domain.

Only after readback, inspected runtime delegation at adapter SHA-256
`573842bd69835a431e1d967ececc47b4a14cfd1698f25557eb048e5af2f1dd6a`
and policy source SHA-256
`168b072a6aa4e527b19af07533eaed037bc90b705fefdc63bd64d1624f1c2db6`.
DTO mappings preserve the relevant fields. Contact mapping, guided/shown
endpoints, terminal classification, overflow counters, prepared visibility and
render encoding call the policy; it is not an unused proof copy. Browser
filtering prepares visibility once per frame.

This closes the earlier serializer-law gap **for the extracted policy**.
Game planning, bootstrap/replay transitions, muzzle capture, main adapter input
construction and its state capacity remain integration/runtime evidence, not
universal proofs. See `coop-local-projectiles-proof-boundary.md`.

Nonblocking cleanup suggestion forwarded: the adapter retains unused local
`current_target_life` and `fallback_impact` implementations after delegation.
They are not the active contact path; removing them avoids future ambiguity.

### Composite browser/worker integration readback

Inspected browser SHA-256
`70d5e0a6eea8be6eecfffd4a6896061f9507dcb0e95bfc8b2d9d310fc4bf22da`
and worker
`8ba287b505460532f72b22e8bc44159ec9fb72b93fa814965653e5ebf1f89754`.
This is independent IO review; the reviewer authored the composite Bend model,
which is excluded here.

No new blocking wiring defect found. Guest input reserves admission before
sequence allocation and prediction. The input timer and immediate Choice flush
call only the shared composite preparer; successful callbacks finish the stored
packet and both epoch/generation guards fence old callbacks. Failure fences the
composite state and reports a visible connection error. Connection creation and
cleanup reset delivery state; guest input and receipt identities remain distinct.

A receipt is offered only after successful reconciliation and `ui.present`.
Host byte admission uses the composite frame budget, then parses the entire
payload before handling ACK or forwarding commands. The worker independently
decodes the same original packet and applies commands in order through existing
Session/InputQueue admission. A malformed sibling cannot escape the pure parser
as a partial ACK. Semantic command admission is still per command, not an atomic
multi-command game transaction. Host inbox refusal reports failure and closes
the connection rather than silently discarding queued movement. Worker guest
messages remain connection-epoch fenced; host-local commands use the legacy
single-command fallback.

Handshake/error controls still use the transport control path; the shared
composite writer covers steady input and snapshot ACK traffic. This readback
does not prove scheduling, relay progress, browser suspension or all reconnect
interleavings. The actual-Iroh harness and final source hashes remain separate
release evidence.

### Final playback clock readback and IO wiring

Formula-first readback used the new Mode laws before inspecting implementation.
Final hashes: Playback source
`7188f8ce0c6cf2ea9a6325acbc2b49a6b9c85b79f66996e6152cda5a4be60b0f`,
laws `6472fd82418e5205868badf7b276b49fcf92ac71cf4c215b64f4f107a1022ef4`,
proof `ff147bd2011ddb88aa1e086d2421c211d20ceea54f1e4d72c1172ad06837ca19`.
No hidden policy weakening found: initial/history/new-stream state is Priming;
initial refill is D=6 guest/3 host, while post-underrun Holding refills at one
new authority tick. Boost enters above D+4 and remains only above D+1. Ordinary
rates are 60/66, emergency 84; independent enum specifications pin every branch.
Ready resumes discard the old latch, clamp fractional credit, and spend only the
last monotonic sample interval up to 33,334 microseconds. A waiting callback
updates its timestamp without accumulating silence as debt. Existing authority
clipping, saturating tick arithmetic, bounded history and lifetime matching remain.
The old nominal-rate comment was corrected to avoid implying an overall66 cap.

Separate source inspection confirms every Cursor mode dispatches through the
proved waiting/movement path. Both active paths select the actual mode/rate and
pass it to `running_units`; all modes then use the same sample cursor. Fresh,
first-frame and history-recovery constructors reset Priming, while underrun
resets Holding. The browser adapter calls `Playback.advance` and projects
`Playback.is_buffering(state)`; it does not make Mode decisions in JavaScript.
Presentation adapter hash:
`a046df4a74edb617a1280f6495df342f860481f514919a02146ec957f85c381c`.
Sample/State arity remains unchanged; ContactPlayback and hit consumers share
the resulting sample rather than introducing another remote clock.

After this freeze, independently reran Journal's strict84-law gate and36 semantic
mutants against the final Playback imports: PASS. No application or Playback
source edits were made by this review. End-to-end timing still requires the
separate fingerprinted browser run; policy proofs do not establish network QoS.
