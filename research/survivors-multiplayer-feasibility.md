# Multiplayer feasibility for the Bendvy Survivors example

Investigated 2026-10-24 against installed Bend 2.0.38, the current example, the user's existing Rust/Bevy research, and first-party networking documentation. This is a source/API feasibility study. No network server, multiplayer game, transport round trip, cross-platform determinism test or throughput benchmark was run for this note.

Work split and retained decisions: [multiplayer plan](survivors-multiplayer-plan.md).

## Assessment

**A shared 2–4-player world is feasible while keeping all gameplay in Bend.** The recommended first architecture is an authoritative native Bend server (either dedicated or hosted by one player): clients send player inputs; Bend validates and applies them to one shared ECS world; clients display authoritative snapshots and interpolate remote actors. A browser adapter may handle WebSocket bytes, TLS/connection lifecycle and presentation without deciding damage, XP, targeting, purchases or rewards. This is an engineering recommendation, not an already implemented facility.

The substantial work is converting the single-player game model, not obtaining a socket. Bend already supplies TCP and UDP effects. It does not, by their existence, supply matchmaking, room lifecycle, authentication, replication, client prediction, interest management or a ready browser-compatible game networking stack. [B1–B4, G1]

## Existing research found

The likely requested recent document is [Bevy deterministic physics and networking](/workspace/typescript/nanako/docs/research/notes/bevy_deterministic_networking.md), checked on 2026-10-04. Its central distinction transfers directly: authoritative client/server prediction can correct drift; input-only lockstep/rollback requires the complete simulation to agree. Restoring transforms alone does not restore all persistent physics/ECS state. The note explicitly distinguishes released integration from main-only code, and its previous exclusion of GGRS is retained here; this study does not propose adding GGRS.

The crate versions and compatibility matrix in that 4 October note were not re-audited today; they are not a new version-selection recommendation.

For Bend we should borrow those architectural and validation lessons, not expect Rust Bevy plugins to plug into Bendvy. Lightyear supplies timeline/input, replication, interpolation and prediction machinery around Bevy, while Replicon focuses on server-authoritative replication. Their role separation is useful even when implementing a smaller Bend-specific protocol. [R1–R3]

## What Bend currently supplies

| Capability | Source observation | Consequence |
| --- | --- | --- |
| Native TCP | `listen`, `accept`, `connect`, string/byte send and receive, timed `try_*` operations; C implementation creates nonblocking POSIX sockets. | A native Bend process can be designed as a server without moving simulation into Node. API/source existence is confirmed; actual game networking remains untested. |
| Native UDP | Bind, datagram send/receive, byte variants and timed polling operations. | A datagram protocol is possible, but loss, ordering, duplicate handling and peer/session rules remain application work. |
| JS TCP/UDP effect files | Their implementations call `io_sys().socket`, `fcntl`, pointer-based OS calls. The older compiler reference implements `io_sys()` through `bun:ffi`. | These are native-host JS effects, not the browser WebSocket API. Do not assume emitted JS socket effects run in a normal browser. |
| Browser transport | Browser WebSocket is a two-way browser/server interface; WebTransport provides streams and datagrams with a supporting server. | A thin browser/edge transport bridge is a sensible first route. WebSocket is sufficient for a first co-op prototype; measure before choosing a more complex transport. |

Sources: [B1–B4, W1–W2]. No claim of successful transport execution is made here. The installed source's timed receive API must not be casually substituted for a newer `UDP.poll` without checking its timeout/result semantics.

## There is already a Bend rollback demo, but it is not a drop-in

The local Bend source checkout contains [io_rollback_netcode](/workspace/formal-proofs/bend-formatter-upstream-fix/demos/io_rollback_netcode/README.md), inspected at commit `71d2a173efd761eb52a8c974004a6fade846cd41`. It has a UDP relay, predictive clients, replay of ordered inputs, and a headless two-walker example. Its README documents comparison checkpoints, but those instructions were not executed in this study. [B5]

Two exact integration barriers matter:

1. `Net<P,S>` and `Game<P,S>` require `P: Data` and **`S: Data`**. Our `State` is **`Type`**, because it owns an affine ECS `World`. It cannot simply be copied into that history. Full rollback would require a complete snapshot/restore or reconstruction contract covering world identity, allocation/lifecycle state, components and gameplay queues—not merely the existing frame JSON. [B5, G1]
2. The demo calls `UDP.poll`, while installed Bend 2.0.38 Base exposes `UDP.try_recv_from`/byte variants instead and contains no `UDP.poll` declaration. Thus this source checkout must not be described as immediately compatible with the installed distribution. [B1, B5]

The relay orders and timestamps input; it is not the same architecture as a server that authoritatively computes and validates Survivors combat. The demo shows a relevant design direction, not evidence that our ECS world already supports deterministic multiplayer rollback.

## Current game changes required

| Current implementation | Multiplayer model needed |
| --- | --- |
| One `Run` owns `px`, `py`, HP, XP, weapons, passives, revivals and progression. `State` owns one global offer/pending queue. | Separate session-wide state (stage, clock, RNG, waves) from per-player state. Prefer actual player entities/components for identity, position, vitality and equipment; make input/reward ownership explicit. |
| ECS store has Body, Vitals and Motion; the playable character is not currently an ECS entity. | Add a player representation and player ID/ownership mapping. ECS query composition can be reused; this is an application-model extension, not proof that Bendvy needs a new networking primitive. |
| `advance*(state, dx, dy)` accepts one movement vector. | Tick transition accepts a bounded, validated, ordered collection of commands keyed by player and sequence/tick. Connection identity must not allow a client to control another player's actor. |
| `Motion.ownerBase` and projectile requests identify one of 24 weapons, not the firing player. | Carry both player ownership and weapon identity. Make damage attribution, per-player effects and allocator fairness unambiguous. |
| Enemy movement, pickups, hazard damage and spawn admission use one player position. | Decide targeting and pickup credit in Bend, and apply server-side rules over the player collection. |
| Spawn law excludes one camera rectangle. | To retain the user's no-visible-spawn rule, admit a birth only outside every relevant active camera exclusion region. A single-player candidate generator may need bounded retries or deferred spawning when a candidate fails the multi-view gate. |
| Fixed pools contain 512 enemy/relic slots, 512 player projectiles, 32 hostile projectiles and 400 XP piles. | Revisit live budgets and scheduling fairness for several loadouts. Adding players does not automatically multiply those capacities or preserve performance. |
| Upgrade/chest handling and UI pause are effectively single-player. | Choose world-pause versus per-player selection, timeout/default choices, and reconnect behavior. These are game-design decisions, not transport details. |

Sources: [G1–G5]. Stable network entity identity should distinguish a recycled pool slot's generation from its prior occupant. The present frame/seed convention alone should not become an unqualified promise that delayed network events target the current occupant correctly.

## Recommended staged experiment

1. **Local shared-world model, without sockets.** Two scripted players in one Bend ECS world, later four. Commands carry player ID, input sequence and intended tick. A deterministic delivery emulator injects delay, duplication, reordering, loss and disconnects. Define the accepted command log and late-input policy first; compare authoritative replay against that log. This proves neither real transport nor cross-platform agreement, but catches ownership and multiplayer-rule mistakes cheaply.
2. **Native authoritative process.** Compile the same core to C and run a server plus two clients. Keep simulation frequency separate from snapshot frequency. Start with complete bounded snapshots, then measure bytes and CPU before introducing deltas/interest filtering. Existing `advance_quiet` avoids producing a JSON presentation packet on every internal tick, but its single-player input and state model still require refactoring. [G1, G6]
3. **Browser clients.** Keep the Astro site as the static menu/client host. Connect it to a separately running game session service using `wss://`; use a small IO bridge if needed. The current Site is configured only as static assets and cannot by that configuration host a long-lived native Bend server. This is a limitation of the current deployment, not a claim that all possible Sites/Worker configurations are incapable of networking. [H1, W1]
4. **Responsiveness and reconciliation.** Initially interpolate other actors and accept server corrections. If local movement latency is unsatisfactory, add prediction using the same Bend movement rules and bounded input history. Do not start with whole-world rollback of thousands of actors unless measurements and gameplay requirements justify its snapshot/replay cost.
5. **Optional input-only rollback research.** Only after complete snapshot/restore and deterministic ordering are specified. Replay identical command streams on ARM macOS and x86 native targets and emitted JS, hash canonical stable-ID gameplay state each tick, and force rollbacks across spawn/despawn, deaths, pickups, upgrades and RNG consumption. A seed and fixed timestep alone do not establish C/JS or cross-CPU bitwise determinism.

Suggested first laws/tests (not drafted or proved here): input cannot affect a different player's actor; an accepted input sequence is applied at most once; snapshot sequence never regresses the client's confirmed state; XP collection obeys the chosen conservation/credit policy; every admitted enemy is outside all applicable camera regions; recycled IDs cannot accept stale-generation events; recording one player's reward cannot credit it twice.

## Decisions before product implementation

- Co-op or PvP; fixed 2–4-player cohort or mid-run joining.
- Shared versus individual XP, loot, level-ups and persistent rewards.
- Whether upgrade selection pauses the room, only that actor, or nobody.
- Enemy target policy, friendly fire, revival and failure conditions.
- Player separation/camera policy and who is relevant to offscreen spawn admission.
- Server hosting and room lifetime; reconnect versus resume-from-start.
- Server-authoritative profile/loadout admission versus trusting local saved progress.

These choices can remain hypotheses in the first network simulator, but should not silently become shipping mechanics.

## Peer-hosted play without VPN or manual port forwarding: Iroh

**Iroh is a viable connectivity candidate for a player-hosted Bend game.** One player's native application can run the authoritative Bend simulation while Iroh connects the other players to it. The host is still the game's server in the authority sense, but a separate dedicated simulation server is not required. Matchmaking/lobby, transport/relay, and authoritative simulation are three distinct roles; choosing peer connectivity does not itself supply game synchronization or remove those distinctions.

For native endpoints, Iroh coordinates NAT traversal through a relay and attempts a direct connection. If that is unavailable, traffic continues through an end-to-end-encrypted relay. This is the practical route to avoiding a VPN and manual router configuration; it is not a promise that every pair can connect directly or through every blocked network. Some infrastructure remains even when no central machine computes the game. The public development relays are shared and rate-limited, without uptime or performance guarantees, so they are appropriate for a prototype rather than a production availability assumption. [Iroh relays](https://docs.iroh.computer/concepts/relays)

For a first friends-only session, the host can display an `EndpointTicket` to copy, paste or share as an invite. It packages endpoint identity, relay and optional direct-address information; thus our own central lobby database is not necessary for the initial prototype. It does not replace the application's admission, player ownership or room protocol. A ticket is reusable rather than automatically single-use, and its dialing information can become stale. [Iroh tickets](https://docs.iroh.computer/concepts/tickets)

Native integration has two plausible IO-only boundaries: link Iroh's raw C API through Bend foreign-effect glue, or run a small local Rust transport sidecar. In both cases, Bend retains command validation, player state, simulation, XP and rewards. The official C binding is `iroh-c-ffi`, built from source; it is not a prebuilt drop-in library. Its documented platform table lists macOS arm64, Linux x86_64/glibc and Windows x86_64. That covers the user's Apple Silicon host as a documented target, but does not establish Linux arm64 support for our current development container. Build/ABI/lifetime and transport behavior still need an integration prototype. [Iroh C API](https://docs.iroh.computer/languages/c)

**Browser behavior is different:** the current Iroh browser implementation routes every connection through a relay. Browsers cannot use its native UDP hole punching, so a native-to-browser session must not be described as direct P2P. The documentation provides a Rust-to-Wasm route using `wasm-bindgen` and says there is no official bundled npm Wasm package; we would need a small application-specific wrapper. This would compile **Iroh's transport** to Wasm, not port Bend or the game runtime to Wasm. The existing browser Bend output can remain JavaScript. [Iroh browser support](https://docs.iroh.computer/languages/wasm-browser)

The first experiment should separate these risks: two native Iroh endpoints exchange a bounded game-command envelope and report whether the selected route is direct or relayed; then attach the already specified local two-player Bend simulation. Test a browser peer as a separate relay-only case. No such Iroh integration or cross-network test has been performed in this study. Hosting migration, host disconnect/migration, invite admission and malicious-host trust are application decisions that connectivity alone does not settle.

The existing Bend rollback example is also available upstream: [demo directory](https://github.com/bendlang/bend/tree/main/demos/io_rollback_netcode), [README](https://github.com/bendlang/bend/blob/main/demos/io_rollback_netcode/README.md), [netcode library](https://github.com/bendlang/bend/blob/main/demos/io_rollback_netcode/netcode.bend), and [headless walkers test](https://github.com/bendlang/bend/blob/main/demos/io_rollback_netcode/walkers_test.bend). Those are useful design references alongside Iroh, not an alternative connectivity guarantee: the `Data` state bound and installed-API mismatch described above still apply.

## Sources

- **B1:** Installed Bend 2.0.38 [Base TCP/UDP effects](/home/node/.bend/bend2/base.bend:332), byte and timed variants through line 456; [affine socket/listener handles](/home/node/.bend/bend2/base.bend:106).
- **B2:** Installed [C TCP connection](/home/node/.bend/bend2/effs/tcp_connect.c:21), [C UDP bind](/home/node/.bend/bend2/effs/udp_bind.c:4).
- **B3:** Installed [JS TCP connection](/home/node/.bend/bend2/effs/tcp_connect.js:6), [JS UDP bind](/home/node/.bend/bend2/effs/udp_bind.js:4).
- **B4:** Older pinned compiler reference [io_sys / bun:ffi](/workspace/formal-proofs/bendvy/.references/bend2/bend2/comp.ts:6169), commit `a950fd683c0d76f09794078e6174fe98a1492876` per `.references/sources.json`. Used to identify the host dependency, not to claim installed-version execution.
- **B5:** Bend rollback [README](/workspace/formal-proofs/bend-formatter-upstream-fix/demos/io_rollback_netcode/README.md), [`Data` bounds](/workspace/formal-proofs/bend-formatter-upstream-fix/demos/io_rollback_netcode/netcode.bend:53), [`UDP.poll` use](/workspace/formal-proofs/bend-formatter-upstream-fix/demos/io_rollback_netcode/netcode.bend:596), inspected checkout commit above.
- **G1:** [Run/State types](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/game.bend:97), [ECS Store](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/game.bend:24).
- **G2:** [Projectile ownership and allocator](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/projectile-pool.bend:5), [Motion ownership fields](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/game.bend:28).
- **G3:** [Offscreen spawn gate](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/spawn-policy.bend:13).
- **G4:** [Pool capacities](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/pools.bend:4), [XP pickup accounting](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/persistent-xp.bend:3).
- **G5:** [Damage/reward aggregation](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/game.bend:1054), [pending reward queue](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/game.bend:1141).
- **G6:** [Quiet advancement and one-vector interface](/workspace/formal-proofs/bendvy-ecs-examples/examples/survivors/game.bend:1157).
- **H1:** Current static deployment manifest: `/workspace/sites/nightfall-survivors/.openai/hosting.json`, `static.directory = dist`.
- **R1:** Existing user research [Bevy deterministic physics and networking](/workspace/typescript/nanako/docs/research/notes/bevy_deterministic_networking.md), checked 2026-10-04.
- **R2:** First-party [Lightyear docs](https://docs.rs/lightyear/latest/lightyear/), [component prediction/interpolation registration](https://docs.rs/lightyear/latest/lightyear/prelude/struct.ComponentRegistry.html).
- **R3:** First-party [Bevy Replicon project](https://github.com/simgine/bevy_replicon).
- **W1:** [Browser WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API).
- **W2:** [Browser WebTransport API and server requirements](https://developer.mozilla.org/en-US/docs/Web/API/WebTransport_API).
