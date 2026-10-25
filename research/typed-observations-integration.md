# Typed observations integrated with TypeScript

2026-10-25. Work is on `prototype/binary-snapshots`; `refactor/typescript` at
`0e16a6e` was merged in `203996e`. No merge into master or publication was done.
The unrelated original checkout edits were not inputs to this implementation.

## Production path

`Game.Packet.frame` is now `Maybe<Observation>`. `CorePacket.frame` is
`Maybe<Observation>` with distinct `Display` and `Clock` constructors. No
observation is `None`, not an empty string. The DTO contains presentation data;
JavaScript does not walk the ECS world to create a frame. The same API is used
by normal browser gameplay, the co-op worker and bot frame consumers.

`observations.mts` reshapes trusted Bend lists/records for the renderer. It does
not parse JSON or repeat full validation. `LocalProjectiles.render_frame` also
returns typed presentation data directly. Menu/profile JSON-value conversion and
bot action/mechanics catalogs are separate paths and were not redesigned.

The worker serializes a remote envelope once with native JSON/UTF-8, transfers
ownership of its buffer, and the main thread compresses those bytes. There is no
remote display-object structured clone followed by another stringify. Local
host display still uses ordinary worker object delivery. JS/WASM still copies
bytes through the existing wasm-bindgen API; this is not a zero-copy claim.

The guest checks bounded decompression/integrity, decodes UTF-8/JSON, and calls
one network admission validator before the existing connection/prediction/
receipt flow. Its schema is generated from Bend Data declarations by
`scripts/generate-observation-schema.py`; the generated ABI supplies local TS
types. Constructor/field/numeric/list/depth checks apply only at this untrusted
boundary. No snapshot is admitted partially. Unused local worker/Core parsers
and the old parallel snapshot parser were removed after integration.

Both directions of internal worker traffic are typed at the sender and receiver.
The generated schema is included in build/codegen, and its generator is an input
to the existing publication snapshot procedure. Native launch remains without
Node.js. Protocol version, gzip envelope, application window, epoch/rejoin and
receipt policies were not changed.

## Measured production comparison

The benchmark freshly compiles actual `coop-core.bend`, then separately compiles
master `01b4164612cd6e37d39aa75b16fab2dd253ebb0d` from `git archive`. It contains no
alternate observation implementation. Eight independently owned fixture worlds
are checked for lifecycle/position isolation and F32-normalized field parity.
The historical binary experiment remains at `46d5863`, not in production.

Run:

```sh
BEND="$HOME/.bend/bin/bend" SAMPLES=100 \
  RESULTS=/tmp/bendvy-observation-results.json npm run benchmark:observations
```

The command respects the existing heavy-check lock. The recorded run used Node
v24.20.0 in Linux arm64 Docker on the same Apple M2 Max host; the container's CPU
model was reported as unknown. Eight warmups and 100 alternating samples per
fixture. Production includes incoming network admission; the old baseline did
not have that additional validation. Compression is round-trip checked and
sized outside the timed region. No browser scheduling, network latency or FPS is
included. Raw results are outside tracked source at
`/tmp/bendvy-final-observation-benchmark.json` in the container.

| Fixture | Frozen master p50 ms | Production p50 ms | Ratio | Master gzip bytes | Production gzip bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| initial | 0.093 | 0.062 | 1.49× | 827 | 831 |
| live-60-ticks | 2.231 | 0.871 | 2.56× | 5,971 | 6,547 |
| population-128 | 2.019 | 0.872 | 2.31× | 5,343 | 5,650 |
| population-512 | 8.098 | 3.545 | 2.28× | 17,024 | 17,925 |
| population-1000 | 16.711 | 7.383 | 2.26× | 31,852 | 32,986 |
| status-512-journal-512 | 11.763 | 5.832 | 2.02× | 24,756 | 25,448 |
| choice | 2.228 | 0.898 | 2.48× | 6,004 | 6,581 |
| disconnected | 2.212 | 0.884 | 2.50× | 5,981 | 6,558 |

For 512 bodies, p95 was 9.769 ms baseline and 4.767 ms production; network
admission itself had p50 0.936 ms. For 1,000 bodies, p95 was 23.718 and 12.185 ms.
These are local exploratory measurements, not universal speed guarantees.

Wire size increases somewhat: native JSON prints direct F32 host numbers with
longer decimal spellings than Bend's shortest-F32 formatter. The 512-body frame
is 221,779 -> 266,199 raw bytes and 17,024 -> 17,925 gzip bytes. This implementation
wins CPU and removes redundant boundaries; it does not claim a bandwidth win.
A future binary format must be measured against this integrated path.

## Verification and limits

- `npm run check:typescript`: passed, including strict browser/Node/ABI builds,
  type-aware lint, formatting, source/import boundaries and ABI tests.
- `python3 scripts/check-dependencies.py`: passed, 196 Bend modules; package pins
  unchanged.
- Full `examples/survivors/check.sh`: passed on macOS with canonical
  `TMPDIR=/private/tmp`, including 52/52 kernel proof files, 380/380 semantic
  mutants, emitted co-op checks, geometry, native metrics and Python controls.
  An initial macOS run exposed the existing temporary-path alias problem; a
  Linux attempt passed proofs/mutants/co-op but lacked clang on PATH. Those
  environment failures are not reported as successful full runs.
- `check-native.sh`: passed on macOS with `TMPDIR=/private/tmp`; launcher explicitly
  ran with invalid NODE, profile/UI/loot checks passed, native executable built.
  Captures are `/tmp/bendvy-merged-native-captures`, outside tracked source.
- Bot facade/observations checks and seeded 60-tick heuristic run: passed; no
  classifier requests. Bot action/mechanics parsing remains unchanged.
- Fresh merged Bend + TS + Astro + Rust/WASM web build: passed.
- Actual-Iroh Chromium matrix on the merged artifact: 0/200 ms interactive cases,
  600 ms bounded-overload case, worker/renderer failure recovery, mobile touch,
  map sampling and active rejoin passed with exact-source checks. Artifact/logs
  are `/tmp/bendvy-merged-network` in the container. The 600 ms case does not
  qualify interactive latency.
- Independent Standards and Spec reviews of `master...203996e`: no substantive
  findings. The later cleanup removes unused parsers and renames the benchmark.

Before the TS merge, two serialization-candidate runs each hit one motion-bound
violation (one at 200 ms and one at 0 ms), with no worker/decoder errors. A similar
uncertainty was already recorded in the TypeScript handoff. The merged candidate
subsequently passed the full seeded matrix once. This does not establish that
the timing instability is fixed; thresholds were not weakened. Physical mobile
and WebKit were not qualified here.
