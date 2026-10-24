# Bend × Iroh connection prototype

An isolated, reusable transport boundary; it does not import or change Survivors.
The prototype answers whether a browser-hosted Bend protocol can exchange actual
messages over Iroh with a second endpoint. It does not implement multiplayer game
mechanics, rollback, native Bend/Iroh FFI or host migration.

## Try it

Open `/labs/iroh/` on two devices. On the first choose **Create invitation**, copy
the link and send it to the other participant. On the second open the invitation
and choose **Connect** (or paste it into Join). Send messages in either direction;
check the other participant's **Received** journal. Keep the host page open.
The invitation is address information, not a single-use admission token.

Browsers use real public Iroh relays, with end-to-end encryption. This demonstrates
relay connectivity, not native direct NAT traversal. Two browser contexts on the
same test machine also do not qualify two different physical networks. The public
relays are development infrastructure with upstream rate limits and no SLA.
No game save, user account or localStorage is used; endpoint keys/messages are in memory.

## Reusable pieces

- `transport/`: Iroh1.4.1 Rust byte transport, wasm-bindgen0.2.122, connection identity,
  bounded payloads/operations and optional native byte echo diagnostic.
- `core/`: Bend framing/decoding, message-size/sequence admission and session counters.
- `core-adapter.mjs`: generated-runtime representation adapter.
- `channel.mjs`: `BendIrohChannel.create(callback)`, `endpointId()`, `invitation()`,
  `join(invite)`, `send(text)`, `snapshot()`, `close()`. Serializes sends, resets the
  Bend protocol per authenticated connection and prevents old queued sends crossing
  a reconnect. Events: ready/connecting/connected/received/sent/rejected/disconnected/error/closed.
- `app.mjs`: DOM and browser IO only; user-facing host/join/message test.

`Prepared` counts messages accepted locally by Bend. `SENT` is completion of the
Iroh stream write, not an application delivery acknowledgment. `Received` records
Bend acceptance on that endpoint. The other participant's journal is the visible
end-to-end check. There is no delivery-ACK protocol in this version.

Each connection accepts one remote participant. `send` has a bounded queue and
rejects when disconnected/full. Receive uses reliable per-message streams with
pinned Noq acceptance ordering; see transport/README.md for the exact dependency.
Future game messages should be a separate Bend protocol over the byte boundary,
not gameplay logic added to Rust or JavaScript.

## Build

Install Bend2.0.38, Rust1.94+, the wasm32 target and the matching bindgen CLI:

```sh
rustup target add wasm32-unknown-unknown
cargo install wasm-bindgen-cli --version 0.2.122 --locked
bash prototypes/iroh-transport/build.sh
python3 -m http.server 8797 --directory prototypes/iroh-transport/dist/web
```

Open http://127.0.0.1:8797. Public deployment must use HTTPS. The Wasm is Iroh's
transport, not a Bend Wasm port. The build consumes pinned Cargo.lock and emits
`build.json` with source fingerprint and revision. Source remains on the prototype
branch until the boundary is accepted; it is not merged into `master`.

## Site extension

After committing and pushing the prototype branch, build again and use
`node prototypes/iroh-transport/receipt.mjs verify prototypes/iroh-transport/dist/web`.
The build captures source before compilation, checks it again after compilation,
and records both source and output hashes. Publication refuses dirty or stale input.

Open the existing Site with its source helper, then run
`node prototypes/iroh-transport/site-extension.mjs prepare SITE_CHECKOUT` from this
worktree. Package with `site-extension.mjs verify SITE_CHECKOUT` as a required helper
command. This extension preserves every game asset and its original source receipt;
it adds only `/labs/iroh/` and records the separate prototype branch/source snapshot.
It does not publish a new Survivors build. A future full game publication must
explicitly restage a retained lab; do not silently assume extension files survive
replacement of the complete game build tree.

## Verification

```sh
bash prototypes/iroh-transport/core/check.sh
CARGO_TARGET_DIR=/tmp/bendvy-iroh-cargo-target cargo test --locked --features native-probe --manifest-path prototypes/iroh-transport/transport/Cargo.toml --jobs 2
IROH_LAB_URL=http://127.0.0.1:8797/ node prototypes/iroh-transport/browser-smoke.mjs
```

The browser check needs Playwright (`PLAYWRIGHT_MODULE` may name an installed module).
It uses actual Iroh public relays and isolated contexts, checks Unicode/bidirectional
messages, a burst, source/size refusal, reconnect with sequence reset, mobile layout,
no main-game load and no localStorage writes. It creates no mock network server.
Core native-C/JS agreement and narrow law/mutation coverage are documented in core/README.md.
