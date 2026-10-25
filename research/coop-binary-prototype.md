# Historical binary snapshot prototype

The throwaway experiment is preserved at commit `46d5863` on this branch. Those
measurements used independently owned fixture worlds after fixing the aliasing
bug found in the first review. They did not integrate the browser and did not
measure network latency or FPS.

On Apple M2 Max, macOS arm64, Node v25.6.1, 100 samples, the 512-body fixture's
p50 was 7.555 ms for the old pipeline, 1.740 ms for a typed observation with one
JSON encode and transferred bytes, and 2.397 ms for the schema-interpreted binary
codec. JSON+gzip was 17,118 bytes versus 10,604 bytes for binary+gzip. The binary
codec saved bytes but did not win CPU in most fixtures. No universal speedup
claim follows from that experiment.

That prototype's separate typed observation implementation and unused binary
codec have been removed from active source. Its complete source, instructions
and tables remain in Git at `46d5863`.

The active branch now uses typed observations in the actual game, co-op worker,
projectile presentation and bot frame consumers. Its current benchmark is:

```sh
BEND="$HOME/.bend/bin/bend" SAMPLES=100 \
  RESULTS=/tmp/bendvy-observation-results.json npm run benchmark:observations
```

It compiles the current **production** `coop-core.bend`, and separately compiles
`master` commit `01b4164612cd6e37d39aa75b16fab2dd253ebb0d` from `git archive` as the
baseline. There is no second observation implementation in the benchmark. The
production measurement includes network admission validation, which the frozen
baseline did not have. Gzip roundtrip is checked outside the timed region.

The current selected wire path is one JSON/UTF-8 encode in the worker, an owned
buffer transfer, and bounded gzip/transport. It removes Bend text formatting,
local parsing and the remote frame's deep structured clone. This is distinct
from claiming a binary protocol, zero-copy WASM or an end-to-end FPS improvement.
