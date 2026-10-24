# Multiplayer work split

Recorded 2026-10-24. This is a work map for the discussion, not an implemented
multiplayer feature or approval of new co-op mechanics. The current game remains
single-player. Evidence and upstream references are in
[survivors-multiplayer-feasibility.md](survivors-multiplayer-feasibility.md).

## Preserve the intent

- Keep game rules, validation, progression and authoritative simulation in Bend.
- Keep the native executable path; transport glue may use Rust/C/JavaScript for IO.
- Investigate one player's native application hosting one shared Bendvy ECS world.
  A dedicated game server is an optional deployment of that role, not a prerequisite.
- Joining should use an invitation without a VPN or manual router configuration.
- Iroh is the connectivity candidate: native peers can use direct connections with
  relay fallback. Current browser Iroh connections always use a relay.
- An Iroh transport Wasm module does not require a Bend Wasm port.
- Two players are the first useful shared-world case; 2–4 players is an initial
  exploration target, not a measured capacity guarantee.
- Full rollback and host migration are separate follow-up questions. Neither is
  required to investigate authoritative host/client play.

## What to trust and what to test

Trust the documented upstream capability unless there is a concrete compatibility
question. Do not spend an experiment rediscovering that Iroh can exchange bytes,
implement QUIC, encrypt traffic or attempt NAT traversal. A standalone upstream echo
example is justified only to diagnose installation or establish a test fixture.

Our uncertainty is whether the selected Iroh interface can be integrated into our
actual Bend executable and frame loop, on the required platforms, without moving
game decisions into the transport or blocking the simulation. Native direct-path
claims need observations from different real networks; two localhost processes do
not establish NAT traversal. Relay-path success is a valid outcome to record, not
proof of a direct path.

## Two independent tracks

| Track | Question it owns | Deliverable | Completion evidence |
| --- | --- | --- | --- |
| A: Bend ↔ Iroh adapter | Can our native build establish a session and exchange our framed messages through the chosen C ABI or IO sidecar? | A transport-only executable outside the game. Bind/connect/accept, invitation handling, bounded send/receive, peer/connection events and close. | An actual Bend process sends and receives exact payloads; handles partial framing, connection failure and queue pressure; stays responsive while no packet arrives; reports direct/relay path when the chosen API exposes it. macOS arm64 is checked on the host. No damage, XP, enemies or game refactor. |
| B: shared game model | Can one actual Bendvy world correctly advance multiple player actors? | A local two-player harness using a fake transport, with a shared clock/world and per-player input, equipment, health and reward state. | Independent inputs affect the intended player; projectile ownership is preserved; damage/XP/rewards follow the selected co-op rules; duplicate/stale inputs cannot repeat effects; controlled delay/disconnect does not corrupt the world. No Iroh dependency. |

The tracks share a small versioned message contract, not each other's internals.
A minimal proposed boundary is a player command with session, player, sequence,
intended tick and payload, and an observation with server tick, acknowledged input,
player/entity observations and events. The host maps an authenticated connection
to the player it may control; a client-supplied player ID is not authority.
Transport owns bytes and delivery events; Bend owns command meaning and acceptance.
Specify framing, maximum sizes, stream/datagram choice and queue policy before
implementing the adapter. Do not assume every Rust Iroh feature exists in its C API.

Track A does not prove multiplayer gameplay. Track B does not prove internet
connectivity. They can progress independently once the shared boundary is settled.

## Integration after both tracks

Connect the same game harness to the adapter: two real applications, one shared
world, the host executing the authoritative Bend step. First confirm correct input
ownership and observation delivery; then exercise latency, disconnection and
reconnection. Measure step time, queue growth, snapshot size and correction behavior.
Do not send a complete internal world merely because a frame JSON encoder exists.

Browser participation is a separate compatibility step: wire the same message
contract through Iroh's browser transport and confirm relay behavior, loading,
identity and presentation. This must not silently introduce browser-owned game rules.

Full rollback is a later decision. The upstream Bend demo needs `State: Data`,
whereas our affine ECS world is `State: Type`. It also uses a newer UDP API than
our installed 2.0.38. Any rollback work first needs a complete snapshot/restore and
lifecycle-identity contract plus determinism qualification on the chosen backends.

## Gameplay decisions still open

These need explicit design choices before Track B claims correct co-op behavior:

- XP and loot credit: shared or personal; attribution when two players can collect.
- Upgrade selection: individual choice while others play, or a shared pause.
- Death, revival, joining/leaving, and behavior when the host exits.
- Enemy targeting and difficulty scaling; per-player projectile sharing/budgets.
- Camera separation and which player views participate in offscreen-spawn admission.
- Session loadout/progression admission and where persistent rewards are committed.

Do not choose these accidentally while implementing sockets.

## Current state and next step

- Research complete: source/API feasibility, existing Bevy study found, Iroh
  connectivity roles and native/browser differences documented.
- Not started: transport adapter, shared-world refactor, network gameplay tests.
- Next useful step: settle the small transport/game message boundary and answer the
  minimal two-player gameplay questions. Then give A and B separate ownership and
  acceptance checks. An upstream-only Iroh smoke test is not the project milestone.
