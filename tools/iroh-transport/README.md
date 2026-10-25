# Survivors Iroh transport

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
  // relayUrl: configured self-hosted relay URL
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
stalled receive streams close that connection. Browser endpoints use only our
self-hosted relay at `https://quint-graph.fly.dev` (Iroh 1.4.1, Fly region `yyz`).
The custom relay map replaces the public development relay list; there is no
silent public-relay fallback. Browser endpoints remain relay-only; no NAT
traversal/direct-connect result is claimed. Existing invitation links from hosts
using public relays must be replaced after both browsers reload.

## Build and checks

The browser co-op mode uses this adapter directly. Rust transports encrypted bytes;
Bend owns game admission and simulation. There is no separate lab or chat UI.

Developer prerequisites: Rust 1.94+, the Wasm target and matching bindgen CLI:

```sh
rustup target add wasm32-unknown-unknown
cargo install wasm-bindgen-cli --version 0.2.122 --locked
bash tools/iroh-transport/build.sh /tmp/survivors-iroh
```

The regular Survivors web build invokes the script and packages its output at
`./iroh/`. Hosted players install nothing. Native solo does not need this toolchain.

From the repository root:

```sh
CARGO_TARGET_DIR=/tmp/bendvy-iroh-cargo-target cargo test --locked --features native-probe --manifest-path tools/iroh-transport/Cargo.toml --jobs 2
```

The optional `iroh-native-probe` binary is a byte echo diagnostic, not a game
server or native Bend/Iroh FFI. Its loopback checks cover ordering and frame bounds;
they do not qualify macOS or cross-network direct connectivity.

## Game boundary

`examples/survivors/coop-transport.mjs` copies queued payloads, serializes writes,
binds incoming events to the authenticated peer and invalidates stale sends.
Its queue is bounded to 16 messages / 4 MiB, with a 1 MiB frame limit in JS and
Rust. A completed send is not an application acknowledgment. Bend validates
commands and maps the authenticated connection to an allowed player.

Primary references: [browser example](https://github.com/n0-computer/iroh-examples/tree/main/browser-echo)
and [browser limitations](https://docs.iroh.computer/languages/wasm-browser).
