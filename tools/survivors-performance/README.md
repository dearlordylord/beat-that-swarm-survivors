# Short solo performance checks

## iPhone Safari: use HTTPS

Do not assume a plain HTTP preview measures the same execution mode as the
public HTTPS game. WebKit developers [confirmed an iOS 27 Enhanced Security
policy](https://bugs.webkit.org/show_bug.cgi?id=324968#c3) that can disable JIT
for plaintext HTTP. Slow simulation on that origin can affect both the mod and
the original, even after all files have loaded.

On the Mac hosting the shared workspace, with Tailscale running:

```sh
bash tools/survivors-performance/serve-private-macos.sh
```

Keep the terminal open and use the HTTPS hostname printed by Tailscale, including
port 9443. The script serves the local build through a loopback Python backend
and Tailscale Serve, restricted to the tailnet. It does not use Funnel or publish
to the public Survivors site. First-time HTTPS/Serve enablement may require
following the link printed by Tailscale. Stop with Ctrl+C.
The HTTPS port can be changed with `SURVIVORS_HTTPS_PORT` if another Serve
listener already owns it. The launcher does not reset existing Serve mappings.

An HTTP-versus-HTTPS performance comparison must use the same device and build.
On 2026-10-27 the affected player confirmed that the same mod runs without lag
on iPhone Safari through private HTTPS on port 9443. Both mod and original had
been severely slow over the HTTP preview. Disabling simulation restored FPS;
advance dominated the diagnostic timings. This confirms the origin-dependent
execution slowdown in this incident. JIT suppression is the explanation supported
by WebKit's policy and local JIT-disabled reproduction, rather than a directly
observed JIT status on the phone. Use HTTPS for subsequent iPhone comparisons.

## Simulation checkpoints

Capture a world once, then measure short replay windows from that saved state.
Measurements do not replay the entire prefix each time. This development tool
uses the compiled Bend simulation; it does not implement game rules or require
Node.js for native play.

Keep captures and reports outside tracked source. Build each version's
`game.mjs` from its own source before capturing. Do not load an original-game
checkpoint directly into the mod: their state schemas differ.

## Capture

From the repository root:

```sh
node tools/survivors-performance/checkpoints.mts capture \
  examples/survivors/dist/web/dist/game.mjs \
  /tmp/survivors-performance/mod-t600.json.gz \
  --character 4 --seed 12345 --tick 600 --steps 120
```

The scenario starts with meta code zero and seed 12345, moves right on each
simulation tick, and saves the world at tick 600. It also records the expected
result after another 120 ticks. Capture once at several useful ticks, such as
0, 600 and 1800. A capture fails if rewards or a terminal state prevent the
requested active-game ticks. It does not silently time paused or rejected work.

The gzip envelope records the full state, compiled-module hash, Git revision and
tracked-diff fingerprint where available, Bend version, dependency-manifest
hash, input scenario, loadout, actor counts and observation checksums. The
`provenance.revision` field is the checkout HEAD at capture time, not proof of
the module's build commit. The compiled-module SHA-256 is the authoritative
identity of the code measured. Keep source/build provenance separately when
comparing a module built before later commits. Raw state
must contain only ordinary JSON values; functions, hidden/accessor fields,
nonfinite numbers and other opaque values are rejected.

## Compare

Capture each version independently, then alternate measurements:

```sh
node tools/survivors-performance/checkpoints.mts compare \
  /tmp/survivors-performance/original-t600.json.gz /tmp/original-game.mjs \
  /tmp/survivors-performance/mod-t600.json.gz examples/survivors/dist/web/dist/game.mjs \
  --runs 5 > /tmp/survivors-performance/comparison.json
```

Both fixtures must share seed, checkpoint tick, window length and input. Their
characters may differ for an explicitly matched-loadout comparison.

Each module gets one untimed replay window for warmup. Each measured repetition
restores a fresh world outside the simulation timer. The report separates JSON
restore, `advance_live` and `observe` costs, with median/minimum/maximum per
variant and every raw repetition. It verifies the initial observation, actual
tick advancement, final phase and exact recorded final-observation digest.
Any failure stops the command with a nonzero exit status instead of producing
a misleading fast result.

These are simulation/observation timings. They exclude browser frame projection,
rendering, compositor work, display waits and network loading. Run browser
measurements separately before claiming smoother displayed gameplay. Actor
counts and loadouts are in each report to make different workloads visible.

## Reuse a capture after a code optimization

A changed compiled-module hash is rejected by default. For an intentional
behavior-preserving candidate:

```sh
node tools/survivors-performance/checkpoints.mts compare \
  /tmp/survivors-performance/mod-t600.json.gz /tmp/before-game.mjs \
  /tmp/survivors-performance/mod-t600.json.gz /tmp/candidate-game.mjs \
  --runs 5 --compatible-candidate
```

The candidate still must decode the saved state and match both the initial
observation and recorded replay result. If schema or gameplay behavior changes,
refresh the capture. A successful short window establishes compatibility for
that fixture, not every possible game state.

## Original versus mod

Numeric character IDs no longer imply the same weapon. Original character 0
uses weapon 0; mod character 0 uses weapon 20. Label a default-start comparison
as the experience shipped by each version.

For a closer matched-loadout comparison, original character 3 and mod character
4 both start with weapon 8, armor +1 and HP 100, without a speed, damage, pickup
or regeneration bonus. The mod adds the personal fan mechanic, so later combat
and actor counts can still differ. Compare the recorded workloads rather than
claiming identical gameplay between the two products.

## Checks

Use a freshly built local engine:

```sh
node --test tools/survivors-performance/checkpoints.test.mts
```

Set `SURVIVORS_PERF_TEST_MODULE` when the compiled current-mod module is elsewhere. The test
uses real Bend advancement over a three-tick window and verifies restore,
module-hash rejection, explicit candidate compatibility and checksum failures.
