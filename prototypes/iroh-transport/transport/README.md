# Iroh transport adapter prototype

Pinned: Iroh 1.4.1, Noq/Noq-proto 1.4.0, wasm-bindgen 0.2.122. This crate only
transports bytes. Bend decides the meaning and acceptance of application messages.

## Browser API

```js
import init, { Transport } from './iroh_transport.js';
await init();
const endpoint = await Transport.create(event => {
  // type: ready, connecting, connected, message, disconnected, error, closed
  // peerId: authenticated Iroh endpoint ID when present
  // bytes: Uint8Array for message; message: diagnostic text when present
  // path: "relay" is the documented browser constraint, not a measured native path
});
const invite = endpoint.invitation();
// On the other endpoint:
await endpoint.join(invite);
await endpoint.send(new Uint8Array([1, 2, 3]));
endpoint.close();
```

Each endpoint automatically accepts one remote peer. Recreate a closed endpoint;
it cannot be rebound. Another peer is refused while connected/connecting. A peer
disconnect leaves a still-open endpoint available for another connection. The
invitation serializes the endpoint ID and addressing information, not a private
key or a game authorization grant. Application admission belongs to the Bend
protocol layer. Keys and state exist only in memory.

One message uses one reliable QUIC unidirectional stream terminated by EOF, with
at most 1048576 bytes (1 MiB). The receiver reads one stream to completion before accepting
the next. **Callers must serialize sends** to preserve their application enqueue
order. The locked Noq-proto 1.4.0 `Streams::accept` returns monotonically increasing
remote stream indexes (`src/connection/streams/mod.rs:65`), including implicitly
opened lower indexes (`streams/state.rs:845–873`); the receiver consequently waits
for lower streams even when higher stream packets arrive first. The native probe
exercises a delayed first stream followed by 49 already-finished streams. This is
a pinned implementation dependency, not a general claim of cross-stream ordering
for every QUIC library. Review it when upgrading Noq or use a persistent framed
stream instead.

The adapter rejects sends above 1048576 bytes (1 MiB) and more than 16 concurrent sends.
Creating/connecting and incomplete incoming/outgoing frames have 20-second limits;
an idle healthy connection is not timed out by the application. Oversized or
stalled receive streams close that connection. Browser endpoints use Iroh's public
development relays and are relay-only; no NAT traversal/direct-connect result is
claimed. Production relay capacity is a separate deployment choice.

## Build

From the worktree root, with Rust wasm32 target and wasm-bindgen-cli 0.2.122:

```sh
CARGO_TARGET_DIR=/tmp/bendvy-iroh-cargo-target CARGO_BUILD_JOBS=2 cargo build --locked --release --target wasm32-unknown-unknown --manifest-path prototypes/iroh-transport/transport/Cargo.toml
wasm-bindgen --target web --out-name iroh_transport --out-dir prototypes/iroh-transport/transport/dist/pkg /tmp/bendvy-iroh-cargo-target/wasm32-unknown-unknown/release/bendvy_iroh_transport.wasm
```

The optional native byte echo peer uses the same ALPN and invitation/frame format:

```sh
CARGO_TARGET_DIR=/tmp/bendvy-iroh-cargo-target cargo run --locked --release --features native-probe --manifest-path prototypes/iroh-transport/transport/Cargo.toml --bin iroh-native-probe
```

It prints its invitation and echoes received byte frames. It is an IO diagnostic,
not a Bend game server. Native Linux arm64 compilation here does not qualify
macOS or cross-network NAT traversal. `cargo test --features native-probe` checks
real native loopback ordering and the receive-size bound.

Primary basis: [official browser example](https://github.com/n0-computer/iroh-examples/tree/main/browser-echo),
[browser limitations](https://docs.iroh.computer/languages/wasm-browser), and the
pinned crate source/lockfile. No Bend runtime or primary game code is imported.

## Game integration

`examples/survivors/coop-transport.mjs` is the game IO adapter. It passes raw
`Uint8Array` messages to the Bend game protocol rather than using the lab's chat
framing. It copies payloads when queued, serializes writes, binds received events
to the authenticated peer, and invalidates pending sends on connection changes.
It bounds its queue to 16 messages and 4 MiB total; individual frames are bounded
to 1 MiB in both JS and Rust. These are transport resource limits, not gameplay
pool limits. A completed send is not an application acknowledgment.

Build only the reusable Wasm module with:

```sh
bash prototypes/iroh-transport/build-transport.sh OUTPUT_DIRECTORY
```

Place its generated files at the game adapter's `./iroh/` URL or provide
`CoopTransport.create(callback, { moduleUrl })`. Transport callbacks carry raw
`message.bytes`, authenticated `peerId`, and a local `connectionEpoch`. Bend must
still decide the session/player assignment and application acceptance. A new
transport connection is not permission to join an existing run.
