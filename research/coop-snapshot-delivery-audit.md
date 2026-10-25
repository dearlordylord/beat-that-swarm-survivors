# Snapshot delivery completion audit

Reviewed against the pinned Iroh 1.4.1 / noq 1.4.0 source on 2026-10-25.
This is a source-level explanation; browser performance still needs measurement.

## Three different completions

1. `write_all` plus `finish` means the producer has supplied stream bytes and
   declared end-of-stream. It does not wait for delivery. Dropping the finished
   send stream does not cancel its buffered reliable transmission.
2. `stopped().await` after `finish` waits for the peer's QUIC acknowledgement of
   all stream data or a rejection. It does **not** confirm application processing.
3. An application receipt sent after guest parsing, admission and presentation
   confirms that this observation passed that application boundary.

The pinned source is `noq-1.4.0/src/send_stream.rs`, documentation for `finish`
(lines179–188) and `stopped` (lines242–253), in the Cargo registry selected by
`tools/iroh-transport/Cargo.lock`. The same distinction is documented by upstream
[Quinn SendStream](https://docs.rs/quinn/0.11.12/quinn/struct.SendStream.html#method.stopped).

Our Rust adapter `tools/iroh-transport/src/browser.rs:248` used (1) by default
and (2) only for `confirm_delivery=true`. JavaScript completion-based counters
therefore measured active write futures, not all reliable bytes/streams awaiting
peer processing. A `latestSnapshot` slot in JS cannot coalesce snapshots already
committed to QUIC. This makes a hidden obsolete-snapshot backlog plausible, but
does not establish its contribution to the measured eight-second lag without
an A/B trace.

The receiver accepts and fully reads each unidirectional stream before accepting
the next (`browser.rs:79`). That intentionally restores stream-ID order and can
hold later complete snapshots behind an earlier unfinished stream. QUIC's
independent streams alone do not remove this application-imposed ordering.

## Adopted boundary

`coop-snapshot-flow.bend` now owns at most sixteen application-unacknowledged
observation IDs, one native write, and one replaceable latest pending
observation. Native completion clears only its matching write. An application
receipt must match the connection token and an exact outstanding sent ID; it
cumulatively removes IDs up to that admitted observation. ACK-before-native-
completion preserves the native writer. Future, skipped, duplicate-old and
wrong-token ACKs leave state unchanged.

The original one-application-flight candidate was rejected because stop-and-wait
at 300 ms cannot sustain a 20 Hz snapshot cadence. The earlier twelve-flight candidate
sustained 20 Hz in a 60-second **pure model** simulation at a 300 ms application ACK
delay (1,201 dispatches, maximum six outstanding); actual browser and relay
throughput require a separate run. This change improves the pipeline without
reintroducing an unbounded queue of obsolete snapshots.

The browser retains corresponding payloads as IO data. A snapshot is at most
1 MiB at transport admission, so sixteen unacknowledged snapshots account for at
most 16 MiB of committed snapshot bytes, plus at most 1 MiB pending. Only one
native write executes concurrently; retransmission/library overhead is not part
of that payload accounting. Receipts are sent only after successful guest
parse/admission/presentation. Handshake and running snapshots use the same flow.

The fresh-state invariant and preservation by every public state transition are
kernel-proved: at most sixteen outstanding IDs. Pending and writing are each a
`Maybe`, so each holds at most one identity. These laws establish queue policy,
not an upper bound on elapsed network latency or guaranteed delivery. A stalled
guest can fill the window until the IO timeout; this is bounded work, not
progress. Tests must still measure display cadence, input application,
latest-authority age and recovery. Absence of overflow is insufficient evidence.

The first measured window was eight. Under a 200 ms native write delay and
300 ms added observation delay, its cadence and interpolation age missed the
acceptance bound. The final window is sixteen, matched to the sixteen-job decoder
budget. The native writer remains singular; the playback history remains eight
frames. Resource bounds and packet cadence are different claims.

The later actual-Iroh review increased the final window from twelve to sixteen.
Measured acknowledgement age reached approximately 684 ms at p95; allowing
100 ms of scheduling headroom at 20 Hz requires sixteen slots. The decoder
uses the same sixteen-job budget. This sizing is an empirical operating point,
not a guarantee of progress under arbitrary latency.
