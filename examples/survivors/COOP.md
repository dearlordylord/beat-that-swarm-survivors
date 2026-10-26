# Browser co-op

This two-player mode is part of the Bendvy ECS example. Open `coop.html`, choose
setup and **Host a run**, then share the invitation. The guest chooses a survivor
and arcana and joins in the browser. Players install nothing. Keep the host page
open; browser Iroh uses relays. Move with WASD, arrows or the touch pad. Attacks
are automatic; XP requires physical pickup. Opening the map is local.

Shared XP level-ups pause for each living player's choice; chests pause for their
collector. A fallen player stays out while the teammate continues. The host keeps
the shared world in memory. A guest reload can rejoin through the same invitation;
closing or reloading the host loses that run. There is no host migration.

Ordinary enemy admission uses the solo stage budget plus 25% per additional
living player: two living players use 125%, rather than the previous 200%.
The result rounds down and remains capped at 500. One living player keeps the
solo budget. This changes population admission only; enemy HP, damage, shared
XP and timed bosses retain their existing rules. It does not instantly remove
enemies already present when a player falls.

The native two-bot balance runner, paired seeds, pressure samples and offline
retrospective workflow are documented in
[the bot tools](../../tools/survivors-bot/README.md#balance-comparisons-and-retrospective-evidence).

At a terminal result, Bend progression settles each local player's profile once,
keyed by run and player. Departure or host loss is not a settlement receipt and
does not award an aborted run's accumulated rewards.

## Simulation and display

The host's Bend ECS simulation owns movement, damage, pickups, XP and rewards.
Browser JavaScript handles device input, Iroh bytes, worker scheduling, compression
and drawing. The native solo launch remains independent of Node and Iroh.

The guest predicts its own movement with immutable target world ticks. The host
applies a command only at its assigned tick; missing input is neutral and late
input is rejected. Reconciliation uses the authoritative anchor and retained
local inputs. The lead adapts monotonically on admitted authoritative observations;
existing command targets and sequence numbers remain unchanged. Known pauses
and death disable prediction.

Remote players, enemies and confirmed projectiles use one Bend interpolation
clock over at most eight authoritative snapshots. Startup and underrun have
separate refill rules; bounded emergency catch-up removes excess display lag.
Actors share a bracket and
fraction; recycled lifetimes are not interpolated together. The browser does not
forecast or replay the future world. Local projectile anticipation is cosmetic:
it captures the displayed muzzle, uses stable shot identities, and cannot change
HP, XP or rewards.

Confirmed contact receipts come from the same prepared host resolver used for
combat. Shot and target lifetimes identify the recipient. Bend maps confirmed
shot endpoints and effects to the displayed target trajectory, with a recorded
impact fallback when that lifetime is absent. Recent cosmetic history and effect
storage are bounded; canonical outcomes remain in the host snapshots. The host
emits at most the latest 512 ordered cosmetic receipts per step before network
serialization. Omitted receipts contribute to the cosmetic overflow counter;
damage, kills, XP and rewards are still resolved in full.

## Delivery and timing

Snapshot delivery permits sixteen application-unacknowledged observations, one
native write and one replaceable latest pending observation. A cumulative receipt
must name an actually sent observation from this connection. It is emitted after
guest parsing, admission and presentation. Native write completion and QUIC
acknowledgement do not mean the guest applied a snapshot.

Guest input uses a 64-command journal: at most 62 movement commands and two
reserved control entries. Ordered batches contain at most 32 commands. Admission
happens before prediction; a full journal stops further prediction instead of
inventing unsent movement. One shared client writer sends a `BSC1` packet carrying
an optional `BSB1` input batch and the latest snapshot ACK together. The input
journal and coalesced receipt history retain their separate bounds; they do not
compete through alternating native writes. Host and worker validate the whole
packet before consuming either child. Gzip is a bounded snapshot byte-transport
adapter; it contains no game decisions.

These limits bound pending work, not network latency. The 600 ms per native write
stress case can exceed the supported prediction lead and batch throughput.
That overload case checks bounded degradation and recovery, not playable input
response. A suspended host browser can stall everyone; the UI reports the stall
or failure rather than claiming a worker prevents suspension. Reload both peers
after a protocol update.

## Run and check

From the repository root, use the browser prerequisites in
[README.md](README.md#browser-launch), then run:

```sh
node examples/survivors/launch.mts
```

Open the printed co-op URL. Cross-device invitations require HTTPS. The launcher
builds current source; publication uses the separate
[fresh-build procedure](README.md#publication).

```sh
bash examples/survivors/check-proofs.sh
```

For the scope of the kernel proofs, see the
[local projectile proof boundary](../../research/coop-local-projectiles-proof-boundary.md)
and [reliability plan](../../research/coop-reliability-plan.md).
The [results report](../../research/coop-reliability-results.md) records the
qualified scenarios and remaining limits.

Real Iroh delivery, timing and reconnection require manual browser verification.
The repository does not currently provide an automated two-browser network harness.

The repository-only [netcode skill](../../skills/realtime-netcode/SKILL.md) records
review rules and pitfalls. It is not installed globally. Primary-source reading
is collected in the [industry audit](../../research/coop-reliability-industry-audit.md).

### Typed observations and byte delivery

`Game.Packet` and `CorePacket` carry typed Bend observations. `None` means no
observation; co-op `Clock` carries step/contact receipts and `Display` carries the
presentation projection plus the detached prediction scene. Host adapters only
reshape Bend collections for drawing. Local Bend and worker results are trusted
through generated ABI types; they are not fully parsed again at runtime.

The worker projects `Core.NetworkView` from authoritative state and encodes
`CoopNetwork.Snapshot` as standard CBOR with pinned cborg. Each shared session,
player record and visible actor appears once. Actors retain their original mixed
order, status, trajectory, ownership, visits and lifetime data. Bend reconstructs
the existing observation and prediction scene with the same `view_observation`
function used by the local view. Inactive pool entries and internal indexes do
not cross the wire. Each snapshot is complete, including after reconnect.

The wire uses positional constructor variants and flat bounded sequences. The
existing ABI generator derives field layouts and numeric ranges from Bend.
Finite fractional values round-trip exactly without coordinate quantization.
The `BCB1` frame contains gzip-compressed CBOR and remains within Iroh's 1 MiB
message limit. Gzip CRC and size checks precede CBOR admission. The tokenizer
rejects excessive depth, container lengths, strings and total token counts before
recursive decoding. Maps, tags, indefinite lengths, undefined values, non-finite
numbers, malformed UTF-8 and trailing bytes are rejected.

`commandAck` is the guest command admission sequence used for input timing.
It is distinct from the application receipt for a token and observation. The
unused resolved-input receipt is absent. Rejected-input diagnostics remain in
`inputTiming`. The compressed queue, connection fencing, latest pending snapshot,
application receipt window and snapshot cadence retain their existing behavior.

To compare full JSON, compact JSON and compact CBOR on the same fresh gameplay
snapshots, run `BASELINE_REVISION=241f799 ARTIFACT_DIR=/tmp/snapshot-measurement npm run benchmark:observations`.
The bounded interleaved measurement includes Bend projection, codec work, gzip,
admission, Bend reconstruction and guest-visible projection. The baseline schema
is loaded from the identified pre-migration commit. The report records source
fingerprints, actor counts, byte counts and timing ranges. It measures processing
work rather than Iroh latency or FPS. Captures stay outside tracked source.

After `bash examples/survivors/build-web.sh`, run the existing boundary checks:

```sh
node examples/survivors/observations-check.mts examples/survivors/dist/web/dist
node examples/survivors/coop-snapshot-codec-check.mts examples/survivors/dist/web/dist/coop-connection.mjs
node examples/survivors/coop-playback-wire-check.mts examples/survivors/dist/web/dist/coop-playback-wire.mjs examples/survivors/dist/web/dist
npm run check:typescript
```

The observation check covers phases, admission, reconnect, actor and contact
identities, spectator views, ownership, ordering and input diagnostics through
the production CBOR and gzip boundary. The codec check covers byte and queue
bounds. The playback check uses emitted Bend projections and the browser adapter.
