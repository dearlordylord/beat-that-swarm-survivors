# Snapshot serialization prototype

2026-10-25. Throwaway branch `prototype/binary-snapshots`, based on clean `master`
commit `01b4164612cd6e37d39aa75b16fab2dd253ebb0d`. The original checkout's dirty
`pools.bend` and uncommitted research notes are not inputs to this experiment.
Production entrypoints, native launch and Iroh transport are unchanged.

## Run

From this worktree, with the pinned Bend compiler and Node installed:

```sh
BEND="$HOME/.bend/bin/bend" SAMPLES=100 \
  RESULTS=/tmp/bendvy-binary-prototype-results.json \
  node examples/survivors/prototype-binary-benchmark.mjs
```

Compilation happens freshly in a temporary directory, removed on completion.
The raw measurement JSON stays outside tracked source. No npm installation,
browser build or Rust build is required for this serialization experiment.

## What was built

- [Typed Bend projection](../examples/survivors/prototype-binary-observation.bend):
  an additive observation API that calls the existing player selection,
  visibility, prediction eligibility and combat-scene functions. It returns the
  authoritative state and data directly, without formatting numbers as text.
  The original `core_observe` is exposed alongside it for comparison.
- [Binary codec](../examples/survivors/prototype-binary-codec.mjs): a fixed-schema
  interpreter using explicit little-endian `u32`/`f32`, tagged constructors known
  from the schema, counted lists, booleans and bounded UTF-8 strings. Linked
  lists are flattened on the wire, then reconstructed where the existing Bend
  prediction API expects them. The birth index tree is preserved structurally
  with byte constructor discriminants. No quantization or integer narrowing.
- [Executable comparison](../examples/survivors/prototype-binary-benchmark.mjs):
  real emitted Bend, exact round trips, normalized-F32 parity with the original
  observation, transfer ownership and malformed-frame rejection checks.

The complete visual frame and detached combat prediction scene are included.
So are representative delivery-envelope fields: admission state, receipt,
input timing/rejection, observation sequence, token, UUID run ID and a contact
journal. The populated fixtures preserve visited targets, slow/burn, projectile
owner/slot and birth-index data. The dense journal case has 512 events with
string identities. This is not a visual-bodies-only benchmark.

The baseline pipeline measures Bend JSON creation + parsing, object structured
clone, JSON stringify + UTF-8 encode, UTF-8 decode + JSON parse. The binary path
measures typed observation + mechanical presentation reshaping, binary encode,
buffer transfer and binary decode. A third control measures typed observation,
one JSON encode in the worker, buffer transfer and JSON decode. Both candidate
paths avoid the baseline's deep object clone.

The transfer timing uses Node `structuredClone` with a transfer list; a real
Node `MessageChannel` additionally verifies delivery, detached sender ownership
and exact decode for each fixture. No browser or inter-thread scheduling latency
is included in the reported synchronous timings. Both candidate paths use the
same existing presentation shape after decode; neither renderer was rewritten.

## Results

Apple M2 Max, macOS arm64, Node v25.6.1, pinned Bend 2.0.38. Final run was made
after fixing fixture isolation, without running another check alongside it.
These measurements supersede the original run in commit `0a090b8`, whose
initial/live scenarios shared mutable ECS storage. Eight warmups and 100 samples
per fixture; baseline/binary order alternates.
The JSON-transfer control always runs third, so this is an exploratory local
comparison rather than a statistically controlled benchmark study. Times below
are p50 milliseconds, excluding compression and any Iroh/WASM/network work.

| Fixture | Existing pipeline | Typed + JSON transfer | Typed + binary transfer | Existing → binary |
| --- | ---: | ---: | ---: | ---: |
| Initial | 0.093 | 0.031 | 0.059 | 1.58× |
| Actual core after 60 ticks, 125 visible bodies | 2.055 | 0.451 | 0.661 | 3.11× |
| Controlled 128 bodies | 1.934 | 0.443 | 0.631 | 3.06× |
| Controlled 512 bodies | 7.555 | 1.740 | 2.397 | 3.15× |
| Controlled 1,000 bodies | 14.669 | 3.265 | 4.646 | 3.16× |
| 512 bodies with statuses + 512 journal events | 10.797 | 4.240 | 3.962 | 2.73× |
| Choice metadata fixture | 2.050 | 0.450 | 0.651 | 3.15× |
| Disconnected core observation | 2.047 | 0.452 | 0.649 | 3.16× |

For 512 bodies, p95 was 8.661 ms existing, 2.347 ms typed+JSON and 3.024 ms
typed+binary. For 1,000 bodies: 16.277 / 3.608 / 5.255 ms respectively.

| Fixture | JSON bytes | Binary bytes | JSON+gzip bytes | Binary+gzip bytes |
| --- | ---: | ---: | ---: | ---: |
| Actual core after 60 ticks | 55,405 | 16,805 | 6,042 | 3,095 |
| 128 bodies | 58,640 | 17,273 | 5,355 | 2,800 |
| 512 bodies | 221,779 | 65,657 | 17,118 | 10,604 |
| 1,000 bodies | 429,116 | 127,145 | 32,061 | 23,757 |
| 512 bodies + dense journal | 452,145 | 121,649 | 24,926 | 17,428 |

Gzip uses browser-compatible `CompressionStream`/`DecompressionStream` executed
in Node. Both compressed sizes include four envelope bytes, and binary sizes
already include the prototype's 12-byte header. The third control's typed JSON
can have different decimal spellings from Bend's `F32.show`; the table reports
the original JSON and binary sizes, not an assertion about that control's size.

Stage measurements for 512 bodies explain the result:

| Stage | p50 ms |
| --- | ---: |
| Bend JSON creation + parse | 4.001 |
| Typed Bend observation + presentation reshaping | 0.205 |
| Deep clone of envelope objects | 2.152 |
| Transfer of prepared binary buffer | 0.011 |
| Native JSON stringify/UTF-8/parse roundtrip | 1.422 |
| Prototype binary encode/decode roundtrip | 2.158 |

Stage medians are independent measurements and should not be added as an exact
prediction of pipeline latency. The codec is a simple generic schema interpreter
with a sizing pass, validation and object reconstruction, so native JSON can
outperform this codec by itself. The measured improvement comes primarily from
removing Bend text formatting and deep cloning. A specialized/generated binary
codec or packed renderer may improve CPU further, but that remains unmeasured.

Compression was also measured separately over precomputed payloads (10 samples,
gzip + gunzip + parse/decode, excluding observation creation and transfer). For
512 bodies p50 was 3.726 ms JSON versus 3.120 ms binary; for 1,000 bodies it was
6.272 versus 5.970 ms. Smaller bytes alone do not guarantee less compression CPU.

## Checks and interpretation

Every fixture now starts from its own freshly created world; the live factory
creates and joins a new game and advances that world alone. The disconnected
fixture disconnects its own world. Setup stays outside all timed regions.

A regression check runs after all fixtures are prepared, before each measurement
batch and after repeated observations. It independently pins world ticks, player
positions and connected flags, plus the choice fixture's round/required players.
The check was first run against the old setup and failed with initial X=7350
instead of 7200. After the fix it passes for all eight fixtures, including live
guest connected=true and disconnected guest connected=false.

All eight fixtures passed typed-vs-original observation parity, binary exact
roundtrip, gzip roundtrip, transferred-buffer ownership/delivery and observation
parity after repeated measurements. The float comparison preserves original
Bend F32 semantics: decimal JSON values are rounded back to F32 before comparing
to direct binary F32 values. This is not bitwise JS-double equivalence with the
old decimal spelling.

Malformed checks reject short/truncated frames, unsupported versions, trailing
bytes, oversized list counts, invalid booleans, non-finite floats and oversized
frames. These are prototype checks, not a complete adversarial codec audit.
No partial decoded observation escapes a failed read.

Also passed:

```sh
python3 scripts/check-dependencies.py
BEND="$HOME/.bend/bin/bend" NODE=node bash examples/survivors/check-coop-reliability.sh
```

The dependency audit covered 197 Bend modules with the pinned theorem-library
submodule initialized. The existing reliability suite, run before this
fixture-only fix, compiled its own fresh modules and passed, including dense
contact geometry, codecs, journal, playback,
input flow and client clock. This checks coexistence with the prototype; it does
not establish production-browser integration of the new codec.

The experiment supports adopting the typed Bend observation boundary and
transferring bytes. This particular binary codec improves bandwidth further,
while the typed+JSON control is faster on CPU in most measured cases. Choosing
the final wire representation should include actual browser/device and relay
measurements. Keep binary+gzip as a candidate, and specialize the codec only if
its CPU cost matters in those measurements.

The browser worker, compression queue, negotiated protocol version, receipt
gating and Iroh calls have not been rewired. Native checks and actual-Iroh
browser checks were not run: production code is unchanged, and the prototype
does not claim end-to-end latency, FPS, allocation/GC or zero-copy WASM results.
