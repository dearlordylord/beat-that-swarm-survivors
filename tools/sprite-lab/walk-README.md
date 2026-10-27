# Shared survivor walk rig

Build all seven eight-frame cycles and update the generated browser/native shape
catalog from the repository root:

```sh
/tmp/nightfall-art-venv/bin/python tools/sprite-lab/walk-build.py /workspace/survivors-walk-game-art
```

Verify that the committed shape catalog matches a fresh Bend compilation:

```sh
/tmp/nightfall-art-venv/bin/python tools/sprite-lab/walk-build.py /tmp/nightfall-walk-check --check
```

The Python environment needs Pillow and CairoSVG. Bend and Clang must be on PATH.
Run `npm ci` at the repository root to install the pinned dprint formatter used
for generated source.
Generated previews stay outside tracked source. The generated source module is
`examples/survivors/survivor-walk-shapes.mts`. Its public surface contains
`survivorWalkLayers(id, frame)`, `survivorWalkFrameCount`, and `survivorWalkCount`.
It returns the same color/path layer format as the accepted static portraits.
Native rendering consumes that same catalog through its generator.

`walk-artwork.bend` owns the shared hips, eight step poses, knee/ankle endpoints,
boots, arm phase, wrist mount and foreground boot depth order. Each character
reuses its selected head, palette and selected accessory D geometry with the direct-grid RJ refinement. Accepted
idle artwork remains a separate, unchanged catalog. Moving accessories use a
wrist mount one authoring unit higher than the preceding prototype, and the boot
fills draw in front to preserve visible feet beside the large held plush.
The walking leg underpass accounts for the enclosing four-unit SVG stroke;
its total width is eight units around a six-unit fill, so raised leg outlines
do not bridge the central foot lane.

The left stance covers frames zero through four; the other foot is offset by
four frames. Under a reference forward advance of one authoring unit per frame,
adding root travel to local sole position leaves the planted sole fixed.
Runtime phase selection follows actual travel distance. This finite reference
check does not establish perfectly planted feet for every camera projection,
turn, speed or quantized subpixel position.

The builder verifies all 56 emitted frames, exact selected top 18 native head
rows, a transparent central lane between the boot soles, bounded sole height,
and reference stance contact. It exports 32x40 sprites plus 24x30 gameplay
renders produced from the same palette paths at the actual 0.75 transform.
It produces per-character GIFs and enlarged strips for independent review.
The quantizer retains each selected static SVG palette as well as moving-frame
colors. Removing an unused garment color can otherwise change the nearest
palette match of antialiased head pixels, even when the head geometry is exact.
These checks do not prove animation aesthetics or temporal smoothness.

This first integrated catalog remains front-facing. It animates legs and arms
for travel in any direction, but it does not pretend to supply side/back profile
artwork. Dedicated directional drawings and stricter projected stance contact
remain later visual refinements.

The builder verifies all seven selected idle PNG hashes against `theme-selection.json` before using them as comparison inputs. A changed reference stops regeneration.
