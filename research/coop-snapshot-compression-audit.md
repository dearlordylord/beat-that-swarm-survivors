# Snapshot compression: compatibility and asynchronous delivery audit

Reviewed 2026-10-25. This is a focused primary-source review of the proposed `BSZ1`-framed, per-snapshot gzip codec using browser Compression Streams. The source review and focused Node evidence below qualify only the inspected boundary; they do not establish relay/network performance or browser-device reliability. The supplied observation was 34.5 MB across 361 frames in roughly 32 seconds, with native write completion near 1 ms and persistent snapshot age. Relay throughput is a hypothesis until queue, codec and delivery costs are measured separately.

## Browser compatibility

WebKit introduced the Compression Streams API in Safari 16.4. Apple's release notes confirm that release on macOS Big Sur, Monterey and Ventura, and on iOS/iPadOS 16.4. `gzip` is an appropriate supported format for this boundary; do not assume that newer compression formats have the same compatibility. Check both constructors and creation with `gzip` at runtime, and report unsupported or failed encoding/decoding through the existing visible failure diagnostic. API availability is not a measurement of codec speed on a target device. Sources: [WebKit Safari 16.4 feature announcement](https://webkit.org/blog/13966/webkit-features-in-safari-16-4/), [Apple Safari 16.4 release notes](https://developer.apple.com/documentation/safari-release-notes/safari-16_4-release-notes).

## Decode and integrity boundary

Use an independent gzip stream for each snapshot. The Compression Standard requires gzip CRC32 and ISIZE validation, permits only one member, and rejects trailing input after that member. A decoder can expose output chunks before encountering the trailer error; neither JSON admission nor application ACK may occur until the stream finishes successfully. Check decompressed byte count while reading, before retaining each output chunk, and reject results exceeding 1 MiB. Enforce the existing compressed transport-frame limit separately, including framing bytes. Source: [WHATWG Compression Standard](https://compression.spec.whatwg.org/).

The 1 MiB output limit bounds accepted JSON; it is **not a strict peak-memory bound for the browser's internal decoder**. WebKit documents that it buffers a complete input chunk's decompression output before returning it and grows internal allocations during decompression. Smaller input chunks may reduce allocation bursts, but the application must not claim its output counter bounds every native allocation. Source: [WebKit Compression Streams implementation notes](https://docs.webkit.org/Deep%20Dive/Modules/CompressionStreams.html).

Use streaming consumption concurrently with any manual writable-side production; waiting for a backpressured write/close before beginning to read can stall a TransformStream pipeline. A `ReadableStream.pipeThrough(...)` pipeline avoids that particular sequencing mistake. Every rejected read/write/close must be handled, including cancellation during connection replacement. A malformed compressed frame must not be retried as ordinary JSON merely because decompression failed.

## Asynchronous delivery and bounds

An application window of eight snapshots does not itself bound concurrent asynchronous decoders when cumulative ACKs are allowed. Counterexample: snapshot 8 finishes before 1–7; ACK8 releases all eight host slots; snapshots 9–16 start while the old decoders are still running. Repetition can accumulate unfinished jobs despite the bounded sender window.

The chosen implementation direction is therefore one active snapshot decode/admit operation and an explicitly bounded serial queue of eight jobs. Control, handshake and ACK messages remain outside this queue. The Iroh adapter already delivers complete frames in order, so preserving that order also avoids introducing additional application-level reordering. The queue must reject/diagnose overflow rather than append indefinitely. Its stated count must make clear whether the active job is included.

Fence each job using the captured connection identity:

1. Reject a stale event epoch before starting a decode.
2. After the await, check the captured generation and connection epoch before publishing or acknowledging its result.
3. Apply the same check in the rejection path: failure of an old decode must not fail a replacement connection.
4. Reset to a new independent queue on reconnect; an unresolved old job must not keep the new party waiting behind its promise.

These are architectural requirements, not claims that the current adapter has passed them. The parent implementation owner reports that intake is being changed to a bounded serial decoder and that generation/epoch checks surround the asynchronous boundary; source review and executed tests must confirm that wiring.

## Required focused evidence

- Valid snapshots round-trip exactly; compressed bytes and decompressed bytes are recorded independently.
- Truncated gzip, invalid trailer/checksum, trailing data and oversized decompressed output fail before admission or ACK.
- Eight deliberately slow jobs exercise the active-plus-pending bound and FIFO admission; a ninth job exercises the stated overflow policy.
- Disconnect/reconnect during both successful and rejected decode leaves the new connection unchanged and able to process its first snapshot.
- Missing constructors and constructor failures produce the existing visible diagnostic without an unhandled rejection.
- Chrome and WebKit execution test the same codec boundary. A Playwright WebKit pass should not be described as testing physical iOS devices.
- Measure compression, queue waiting, decompression and admission separately, alongside snapshot age and byte rate. Native write completion is local send progress, not proof of receiver delivery. Compression benefit and relay saturation remain runtime questions.

## Independent implementation review

Inspected `examples/survivors/coop-snapshot-codec.mjs`, SHA-256 `02002325f2d91771e5eff0c42bd8943556603d6d3d391d9fb7b63e429232442a`, and its browser call sites. No blocking defect was found in this frozen codec module. Its eight-job limit includes the active job; one active decode runs at a time. It bounds compressed framing before admission, counts decompressed output while reading, waits for full stream completion, and additionally checks final CRC32/ISIZE. Input is submitted in 1 KiB chunks. Close rejects pending jobs and deliberately lets the active bounded decode finish, which requires the adapter's post-await epoch fence. Ordinary text bypasses the compressed FIFO; production snapshots must consistently use the compressed envelope to retain snapshot FIFO ordering.

The focused Node check passed **128 assertions**: the synthetic 155,713-byte scene became 15,638 compressed bytes (ratio 0.100). This is a fixture result, not a live-game throughput measurement. Additional independent runtime probes rejected trailing zero, copied trailing trailer, empty-plus-real concatenated gzip members, and two real gzip members. A 1,048,576-byte repetitive payload round-tripped at the inclusive limit. Missing and throwing compression/decompression constructors rejected as expected. A failed decompression constructor is normalized to the generic invalid/truncated message; the first probe expected the original text and failed, then the corrected rejection-contract probe passed. These constructor probes check codec rejection, not UI diagnostics or absence of browser unhandled rejections.

**Integration finding sent to the owner:** at inspection, `coop-browser.mjs` created its decoder once per outer `connect()`, while transport `connected`/`disconnected` events could change `connectionEpoch` within that call. Old queued work would therefore remain ahead of a replacement transport connection's frames. Close and replace the decoder on transport epoch transitions, capture the selected decoder for each message, and add the pre-decode event-epoch guard. The existing post-await success and rejection guards correctly prevented old results/errors from mutating a new epoch. An explicit new outer `connect()` already closed and replaced the queue. Verification scenario: hold one old decode unresolved, queue another, change the transport epoch without replacing the outer callback, and verify that the new initial frame completes independently; then settle the old promise both successfully and with rejection and verify no new-state change.

This finding is an adapter lifecycle obligation, not a request to migrate the engine. The source fix is reviewed below; browser/device evidence remains separately qualified. No Chrome, WebKit or physical-iOS codec run was executed by this independent reviewer. The primary-source compatibility claim above does not substitute for those runs.


### Queue lifecycle finding: resolved in source readback

Re-inspected `coop-browser.mjs` (SHA-256 `1f8c09bf4c78dded5534868373031cbc869a7c8f7c4ca371067cc5c55d2e81eb`) after the owner’s fix. Every `connected` event closes the prior decoder and creates a new independent decoder; `disconnected` closes its current decoder, and `cleanup()` closes the active decoder. Message intake rejects a mismatched event epoch before decode and captures `messageDecoder` before awaiting it. Both the success continuation and catch path check outer generation and event connection epoch. Because closing a pending job rejects its promise asynchronously, the synchronous disconnect epoch update precedes that catch continuation. Old active jobs may finish, but their results cannot be admitted into the replacement epoch. This resolves the reported source-level queue reuse/fencing defect; no further blocker was found in this focused readback.

The parent reports candidate 7’s 300 ms observation-delay run at p95/max lag 26 ticks and 1,004 host-motion pairs with zero violations. This reviewer has not independently inspected that frozen runtime artifact. The 200/600 ms cases and mobile worker-failure evidence were still pending at this readback; this update makes no full browser-pass claim.
