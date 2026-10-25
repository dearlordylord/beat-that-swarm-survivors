# Survivors: remove JSON from browser snapshots

Research date: 2026-10-25. This is a design recommendation, not an implemented or benchmarked migration. The current package manifest pins Bend 2.0.38; the transport pins wasm-bindgen 0.2.122 and locks js-sys 0.3.99. Local source observations below describe the working tree, not a clean release snapshot.

## Recommendation

Expose a typed presentation snapshot from Bend, pack it once into a versioned binary frame in the simulation worker, and transfer the owned `ArrayBuffer` to the browser transport. Decode into the existing presentation shape initially. Preserve Bend's authority over which fields are observable and all simulation/admission policy. Rust/Iroh should continue treating the payload as opaque bytes.

The desired path is:

```text
Bend typed observation
  -> worker: schema-specific binary writer
  -> Uint8Array / transferable ArrayBuffer
  -> JS transport -> wasm-bindgen Vec<u8> -> Iroh
  -> peer: Uint8Array -> bounded binary reader -> presentation
```

One JS-to-WASM copy is acceptable in this first design. Removing text formatting, JSON parsing/stringifying, and deep object cloning is a separate improvement from eliminating every byte copy. There is no evidence yet that the WASM copy dominates runtime.

## What the current source actually does

`CorePacket.frame` is a `String` in [coop-core.bend](../examples/survivors/coop-core.bend). [coop-worker.mjs](../examples/survivors/coop-worker.mjs) parses that string in `packet()`, then publishes local and remote frame objects with `postMessage` and no transfer list. [coop-browser.mjs](../examples/survivors/coop-browser.mjs) stringifies the remote envelope in `flushSnapshot()`. The guest later decodes UTF-8 and parses JSON again.

[coop-snapshot-codec.mjs](../examples/survivors/coop-snapshot-codec.mjs) currently accepts text, encodes UTF-8, compresses it with browser gzip streams, and adds the `BSZ1` envelope. It enforces compressed/raw limits and validates gzip length/CRC. These checks are relevant requirements for a replacement, not disposable overhead.

[coop-transport.mjs](../examples/survivors/coop-transport.mjs) snapshots mutable input with `slice()` before queuing and copies incoming bytes before emitting them. [browser.rs](../tools/iroh-transport/src/browser.rs) accepts `Vec<u8>`, writes it to an Iroh unidirectional stream, and creates a fresh JS array with `Uint8Array::from(bytes)` on receive. These transport APIs already support arbitrary binary data; JSON is imposed above them.

## Platform facts that matter

| Boundary | Supported mechanism | Consequence |
| --- | --- | --- |
| Worker -> browser | `postMessage({bytes}, [bytes.buffer])` transfers the buffer and detaches it in the sender. The typed-array wrapper is serializable; its buffer is the transferable resource. | Avoids copying the byte payload across threads; the sender must stop using that buffer. |
| JS -> exported Rust `Vec<u8>` | wasm-bindgen numeric sequence conversion copies into WASM linear memory. Exported `&[u8]` inputs also copy. | Replacing `Vec<u8>` with a borrowed slice is not a zero-copy optimization. |
| Rust -> JS `Uint8Array::from(&[u8])` | js-sys creates a new typed array from the slice. | Current callback bytes have independent JS ownership, so they can safely outlive the callback. |
| Rust -> JS `Uint8Array::view` | Unsafe view into WASM memory; allocations/memory growth and the Rust allocation's lifetime can invalidate it. | Do not keep such a view across asynchronous queueing or transfer it as an owned JS buffer. |
| Numeric wire layout | `DataView` reads/writes mixed numeric types with explicit byte order. Typed-array multi-byte elements use platform byte order. | Specify byte order in the protocol and use explicit-endian accessors. |

Sources: [HTML transfer algorithms](https://html.spec.whatwg.org/multipage/structured-data.html#structuredserializewithtransfer), [browser implementer documentation and example](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects), [wasm-bindgen numeric slices](https://wasm-bindgen.github.io/wasm-bindgen/reference/types/number-slices.html), [owned numeric slices](https://wasm-bindgen.github.io/wasm-bindgen/reference/types/boxed-number-slices.html), [js-sys source at the transport's wasm-bindgen tag](https://github.com/wasm-bindgen/wasm-bindgen/blob/0.2.122/crates/js-sys/src/lib.rs), [ECMAScript DataView](https://tc39.es/ecma262/multipage/structured-data.html#sec-dataview-objects).

## Concrete first format

A local probe against the installed pinned Bend compiler returned `Observation{tick:17,x:1.25,rows:[3,...]}` directly as an ordinary JS tagged object, with `List` represented by `Con`/`Nil` objects. Bend `Array` emits a normal JS array, not a typed array. A Node probe packed the returned values into 12 bytes with `DataView`, transferred the backing buffer using `structuredClone(..., {transfer:[buffer]})`, and verified both sender detachment and the receiving float value. This establishes a usable compiler ABI and the Node transfer primitive; it is not a browser/Iroh test or performance measurement. No compiler modification is needed for this seam. The pinned compiler's F32 bit helper allocates typed arrays per call, so avoid building a byte list in Bend by invoking that helper for every numeric field: let a mechanical JS `DataView` writer pack the typed observation instead.

The source audit must extend beyond visible bodies. `packet_extra`, `coop_extra`, and `combat_forecast_extra` build text today; combat prediction's `observe` also exposes a native scene through JSON with recursive collections, maps, player/run state and projectile metadata. Its typed replacement must preserve visited targets, slow/burn effects, owner/slot/birth identity and every prediction input. A body row alone has nine 32-bit fields (36 bytes), but that is not a complete snapshot schema. Use iterative traversal of emitted linked lists to avoid JS recursion depth limits. A JS decoder may perform mechanical structural validation; scene selection and game admission remain in Bend. Never trust a received `$` tag as permission to bypass admission.

Use a schema-specific full snapshot before introducing deltas. Start with a fixed header containing magic, protocol version, message kind, payload byte length, connection token and observation sequence. Encode the existing envelope's other semantic fields too: receipt, admission data, contact journal and input timing must not silently disappear when the visible frame changes format.

Use `u32` for existing U32 identifiers/ticks/counters and explicit `f32` for values whose authoritative source is F32. Do not quantize positions, truncate identifiers to u16, or invent narrower ranges until actual bounds have been checked. Reject non-finite floats where the presentation contract requires finite values. Variable sections have a bounded count followed by fixed-width records, with checked arithmetic before allocation or iteration. Rare strings use bounded UTF-8 lengths; numeric enums stay numeric. A parser must consume the complete declared frame, reject unknown versions/kinds and invalid enum values, and return no partial observation on failure.

The initial guest decoder may build exactly the object the current renderer expects. This retains one object construction pass but removes the text roundtrip and permits migration without rewriting rendering and prediction together. Later, hot render loops can read packed records directly if profiling justifies changing their interface.

On the worker side, produce independent owned buffers for local presentation and remote delivery, or retain a separate local object. Transferring a buffer used by local rendering would detach it. Do not transfer a subarray of a shared/pool backing buffer unless ownership of that entire backing buffer is intentionally relinquished.

Keep the current reliable Iroh delivery and application receipt semantics. Binary encoding does not justify changing ordering, backpressure, the observation window, handshake gating or connection epoch rejection. Use a new negotiated wire version so mixed deployments fail clearly.

## Why not simply add a binary serialization library?

CBOR is a standardized binary representation for numbers, arrays, maps and strings; FlatBuffers has a schema compiler and generated JS accessors over a binary buffer. Both are legitimate options. Neither removes a JSON string that Bend has already constructed: the observation interface must change first. [CBOR RFC 8949](https://www.rfc-editor.org/rfc/rfc8949.html), [FlatBuffers JavaScript documentation](https://flatbuffers.dev/languages/javascript/).

For this closed two-peer presentation protocol, the recommended starting point is a small schema-specific writer/reader with the platform's `DataView`, provided the full schema remains manageable. This is engineering judgment, not a benchmark result or a claim that handwritten codecs are universally faster. Generic MessagePack/CBOR traversal over the emitted Bend ADTs would retain their recursive list/tag/map topology and require adapters; a deliberately flattened observation schema is still needed. FlatBuffers adds a schema compiler and Bend-to-generated-type integration, whose benefit for the present renderer has not been demonstrated. If the schema audit shows that maintaining both sides would be large or error-prone, prefer a generated schema codec over an expanding handwritten protocol. A generic JSON-to-CBOR conversion after `JSON.parse` would only address part of the problem.

Do not initially introduce SharedArrayBuffer, an unsafe WASM pointer interface, an allocator bridge, or a second Rust copy of the game schema. Shared memory requires cross-origin isolation and a separate synchronization/ownership design, while ordinary transfer already handles this worker handoff. [SharedArrayBuffer security and sharing requirements](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer).

## Compression and copy ownership

Change the compression layer to accept bytes rather than text, retaining raw/compressed limits and bounded decompression. Compare raw binary with gzip binary using actual captured frames. Binary is not guaranteed to be smaller than gzip JSON on the wire, and compression CPU may outweigh bandwidth savings for small frames. Keep a versioned compression flag and measure before selecting a default; do not silently remove gzip based only on raw byte counts.

After the representation migration, an explicit owned-buffer send API can remove the transport's defensive `slice()` where the caller relinquishes mutation rights until completion. Preserve the existing copying send API for callers that do not satisfy that contract. Similarly, Rust already supplies independent JS receive buffers; another JS copy may be removable if no consumer mutates those bytes. Audit all consumers before doing either change.

## Implementation and acceptance sequence

1. Audit the complete observation/envelope schema and every renderer/prediction consumer. Add a typed Bend observation export and keep the existing native JSON adapter, derived from the same projection. `G.Packet.frame` and `CorePacket.frame` have multiple existing consumers; changing them wholesale would unnecessarily broaden this migration. Native launch must continue without Node.
2. Turn the compiler ABI probe above into a small reproducible boundary check. A linked Bend list of bytes is not itself a packed byte buffer; avoid assuming that returning `List<U8>` gives `Uint8Array` or efficient zero-copy storage.
3. Add one bounded binary writer/reader for the complete frame, version negotiation, and byte-oriented compression. Convert at the worker boundary and use transferable ownership for remote bytes.
4. Compare the old and new decoded observations field-for-field on real scenarios: initial setup, ordinary combat, max population, choices, pause/map, disconnect/rejoin and terminal states. Pin float semantics explicitly: compare original Bend F32 values or `Math.fround` of the old JSON values, since decimal `F32.show` and subsequent JS parsing may not produce the same double value as decoding the original F32 bits. A blind old/new JS `deepEqual` can fail despite correct preservation of authoritative F32 values.
5. Exercise malformed/truncated frames, oversized section counts/strings, invalid floats/tags, trailing bytes, gzip bombs, stale epochs and queue overflow. Preserve atomic decode and receipts only after successful admission/presentation.
6. Run the README functional checks and actual-Iroh browser harness. Measure encode/decode/compression wall time, allocation/GC, main-thread long tasks, raw/wire size, and guest observation lag at p50/p95 with the same scenarios and populations. Keep captures and profiles outside tracked source.

No speedup factor is claimed. This research did not benchmark or implement a codec, prove a complete snapshot schema, or establish browser-worker feasibility for moving the Iroh endpoint into the simulation worker. Endpoint relocation can be evaluated later if transport scheduling remains material.
