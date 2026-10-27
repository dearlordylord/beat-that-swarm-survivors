# Original versus mod: local performance comparison

## Conclusion

The severe sustained slowdown reported on the player's device remains unresolved.
The earlier report measured a mod optimization, not the original game. This
comparison freshly builds the original fork point and measures both products.
It does not reproduce a mod-only slowdown in the tested Linux browsers.

Original source: `963cc82ca313f9f0697ad99972dd539edf458a4f`.
Mod gameplay source: `74a57c5`; later checkpoint-tool commits do not change the game.
Both builds use Bend 2.0.39 and the same pinned dependency manifest.
Generated modules are identified by SHA-256 in the checkpoint reports.

## Short simulation replay

Use [the checkpoint tool](../tools/survivors-performance/README.md) to capture
a world once and restore it before each short replay. Prefix simulation and
JSON restoration are excluded from the simulation timer. The tool checks actual
tick advancement, final phase and the recorded observation digest on every run.

Five alternating repetitions, Node 24.20.0, Linux arm64, seed 12345, tick
600 through 720, continuous rightward input, no meta progression:

| Measurement | Original | Mod |
| --- | ---: | ---: |
| Advance plus observe, median | 690.5 ms | 608.8 ms |
| Advance plus observe, range | 674.1–704.8 ms | 601.6–618.3 ms |
| Restore, median, outside timer | 11.9 ms | 12.0 ms |
| Initial enemies / projectiles / pickups | 107 / 2 / 1 | 107 / 2 / 1 |
| Final enemies / projectiles / pickups | 110 / 1 / 1 | 110 / 1 / 1 |

Original character 3 and mod character 4 both start with weapon 8, HP 100 and
armor +1, without other stat bonuses. The mod adds a personal fan mechanic:
these are comparable workloads, not identical game semantics. Each variant
matches its own expected digest. This narrow result does not establish late-game
performance or browser smoothness.

## Browser comparison

Actual frontends, fresh muted profiles, 390×844 viewport, DPR 2, thirty warmup
ticks, then approximately 3.5 seconds of rightward movement. Five alternating
repetitions per variant and scenario; no page errors. The scenarios compare
shipped default characters and the matched fan loadouts described above.

Chromium 1243, headless Linux arm64:

| Scenario / metric, median across repetitions | Original | Mod |
| --- | ---: | ---: |
| Default: median animation callback | 4.7 ms | 4.6 ms |
| Default: p95 animation callback | 9.9 ms | 6.6 ms |
| Matched fan: median animation callback | 4.7 ms | 4.7 ms |
| Matched fan: p95 animation callback | 9.8 ms | 6.5 ms |
| p95 animation timestamp interval, both scenarios | 16.7 ms | 16.7 ms |

No recorded interval exceeded 33.4 ms. This environment is display limited at
about 60 Hz. Callback time excludes deferred compositor/GPU work. A mobile
viewport does not reproduce mobile hardware or Safari.

Linux WebKit 2359 with software Mesa also ran five alternating default-character
repetitions. Both versions were slow: median callbacks approximately 26–30 ms
and frequent intervals above 33 ms. This is a software-rendered WPE environment,
not an iPhone measurement, and does not isolate a mod regression.

## Sprite raster diagnostic

New sprites have roughly ten times as many path commands as the originals.
A throwaway cached-bitmap prototype exactly matched all 63 current poses at
normal opacity. In five alternating software readback tests of 2,000 draws,
medians were 34.3 ms for the original sprite, 73.8 ms for current vector drawing,
and 12.2 ms for the cached prototype. Each iteration clears, draws and reads
pixels, so this is a forced-raster diagnostic, not a game-frame benchmark.
The current-vector versus cached difference is about 0.031 ms per draw in this
environment. No production rendering change was adopted from this result.

## Evidence and next diagnostic boundary

Raw reports, fixtures and scripts are kept outside tracked source in the shared
workspace directory `survivors-performance-report`. The original was built in
an isolated worktree; its local comparison preview has a separate save key.
The comparison preview is private/local only and must never replace the public
Survivors site.

The next useful evidence is original and mod behavior on the same affected
device/browser. If only the mod is slow there, measure presented-frame intervals
and rendering on that device rather than extrapolating these CPU timings.
