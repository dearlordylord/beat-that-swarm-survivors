# Personal ability icon studies

This lab compares fourteen proposed personal icons in two vector treatments.
The proposed trinkets express innate themes; they are not existing inventory
items. Production gameplay, names and glyphs remain unchanged during this study.

Run from the repository root with a fresh external output directory:

```sh
/tmp/nightfall-art-venv/bin/python tools/icon-lab/build.py --output /workspace/survivors-icon-lab/iteration-01 --iteration 1
```

Alternatively, provide Pillow and CairoSVG through the local Python environment.
The build also needs Bend and a C compiler. Bend owns every shape, coordinate,
palette and treatment in `artwork.bend`. Python compiles that module, rasterizes
the emitted SVG, verifies finite bounds, and presents comparisons. No raster
tracing or image-generation edit supplies the vector geometry.

Both treatments share a 32-unit canvas, two-unit safe area and two-unit strokes.
Treatment A uses bright flat bodies and dark contours. Treatment B uses a dark
body with colored etched contours. Compare silhouettes and semantic clarity
before selecting a treatment. The visual family should not depend on color
alone.

Inspect 16, 20, 24 and 32 pixel renders. The interface mock uses a 20 pixel icon
inside a 34 pixel HUD slot and a 24 pixel icon inside a 38 by 36 starter slot.
Compare isolated images and the dark interface, then give the unlabelled sheet
to an independent reviewer before revealing the intended object and mechanic.
Record concrete mistakes, revise the smallest geometry, and retain both
iterations until the comparison is recorded.

Finite checks establish nonempty output and safe bounds. They do not prove
recognition, aesthetic quality, accessible contrast or reference fidelity.
Original object drawings avoid official logos and mascot faces; this does not
establish legal clearance of wording or imagery.

## Current candidate

Iteration03 is the independent reviewer's recommendation. Filled treatment A is
stronger than etched treatment B at the actual 20 and 24 pixel interface sizes.
The final footprint separates its heel and forefoot and tilts over a horizontal
pulse. At 16 pixels those parts reduce to two marks, so exact object recognition
is still unestablished. The V trinket reads as a canted frame rather than a
camera. Do not convert these findings into universal recognition claims.

`reviews.json` preserves the three-iteration decision trail and exact comparison
image hashes. These are candidate recommendations, not user selection or
production integration. The actual full-interface HUD and rank overlay still
need final contextual review.
