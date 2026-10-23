# Native renderer performance — 2026-10-23

The reported slowdown reached 16 FPS on the player's Mac. The following Linux
CPU diagnostics explain a plausible source; they do not measure that Mac's FPS,
window presentation, audio or vsync.

## Full-frame baseline

A frozen native O3 fixture uses the real 1004-entity ECS world, 400 enemies near
the camera, 48 projectiles, 32 hit plans and a constructed late-game inventory.
After 90 warmup steps it measures simulation, display-list construction and the
complete 512-square Image separately, with completion barriers. One CPU and one
Bend runtime thread are used. These initial cells have no repeated timing claim.

| Catch-up steps | Simulation ms | Display list ms | Image ms | Total ms |
| --- | ---: | ---: | ---: | ---: |
| 1 | 5 | 1 | 26 | 32 |
| 2 | 13 | 1 | 28 | 42 |
| 4 | 26 | 0 | 34 | 60 |

The 60 ms frame resembles the reported slowdown, but is a separate-host fixture.
Zero in the display-list column means below the millisecond clock resolution.
The direct native view control took 38 ms at 400 enemies; exact state and pixel
checksums matched the split control. Raw sources, generated C, executable,
barrier audit and receipts: `../bend-games/research/native-full-frame-20261023/`.

## Renderer candidates

The original renderer filters the display list repeatedly for each quadtree
branch. The painting candidate traverses shapes back-to-front, replacing only
touched Image branches. It preserves opaque ordering and original leaf-overlap
semantics. A second candidate explicitly forks four CPU quadrants in Bend.

One native O3 binary selects each candidate at runtime. Twelve varying frames
use actual enemy art, health bars and HUD, with three alternating repetitions,
four fixed CPUs and four Bend runtime threads for every candidate. All image
checksums agree. The independent JavaScript development oracle additionally
compares all 262144 pixels in each of 29 scenes, including fractional and
degenerate rectangles, fonts and overlapping sprites.

| Actors | Original median ms / 12 frames | Painted | Four CPU quadrants |
| --- | ---: | ---: | ---: |
| 100 | 79 | 21 | 52 |
| 400 | 240 | 66 | 154 |

These timings include scene construction and complete Image forcing, not a game
step or window presentation. The painting algorithm is approximately 3.6 times
faster in the 400-actor fixture. The less effective quadrant prototype is removed
from production. Frozen candidate sources and every raw result are retained in
`../bend-games/research/native-render-candidates-20261023/`.

## Full-frame acceptance

A second frozen native O3 binary selects the original and painted renderers at
runtime in the full game fixture. Twelve runs comprise three alternating pairs
for each of one and four catch-up steps. CPU0, one runtime thread, the 90-step
warmup, 400 on-camera enemies, 48 projectiles and 32 hit plans are held fixed.
The clock stops before exporting a complete authoritative `O.snapshot` and a
512-square PPM. Every state payload and every PPM byte matches across both
implementations and all repetitions within each catch-up scenario.

| Catch-up steps | Original median Image ms | Painted Image ms | Original total ms | Painted total ms |
| --- | ---: | ---: | ---: | ---: |
| 1 | 31 | 7 | 37 | 14 |
| 4 | 30 | 7 | 55 | 31 |

At four steps, simulation medians remain 24 ms for both implementations. The
renderer change reduces measured full-frame CPU time by about 62% at one step
and 44% at four steps in this fixture. These short, millisecond-clock repeated
measurements qualify this workload, not a general FPS guarantee or the player's
Mac presentation path. Catch-up can still consume substantial time.

The native C audit confirms list traversal uses explicit runtime continuations,
not one C call-stack frame per rectangle. Sequential traversal retains about
48 bytes of continuation payload per pending rectangle, in addition to list and
Image storage. Paint traversal is bounded by nine quadtree levels.

Raw frozen source, generated C, executable, exact state/PPM artifacts, timing
receipts and stack audit: `../bend-games/research/native-full-frame-painted-20261023/`.
The production renderer now uses painting through the existing `image` entry
point; old clipping helpers and the unsuccessful quadrant prototype are removed.
Game rules, ECS state, sprite detail and image dimensions are unchanged.
