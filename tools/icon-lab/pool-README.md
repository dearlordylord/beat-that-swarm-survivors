# Shared relic vector icon study

This study draws the existing eighteen `PASSIVES` entries as physical objects.
Stable passive IDs, current catalog names, and effect wording are copied into
`pool-manifest.json`. Proposed names are descriptive candidates with unknown
trademark status. The study does not create new inventory items or change any
production gameplay, glyph, recipe, or displayed name.

Run with Bend, a C compiler, Pillow and CairoSVG:

```sh
/tmp/nightfall-art-venv/bin/python tools/icon-lab/pool-build.py --output /workspace/survivors-relic-icons/iteration-01
```

Use a fresh external directory for each iteration. The build compiles
`pool-artwork.bend`, captures its authored SVG, and renders each icon at 16, 20,
24 and 32 pixels. It produces a comparison sheet, an unlabelled shuffled sheet,
a ranked 34-pixel HUD comparison, an HTML size selector, and a source snapshot.
Bend owns all geometry and colors; Python renders and presents the output.

The family follows treatment A of the personal icon lab. Broad colored bodies
have dark two-unit contours on a 32-unit canvas with two-unit safe padding.
Objects should remain distinct without relying on their colors. Inspect small
icons, negative spaces, and the rank overlay before adding decorative detail.

Finite checks establish nonempty output and the safe area for this catalog.
They do not establish semantic recognition, aesthetics, accessible contrast or
legal clearance. Give the unlabelled sheet to an independent reviewer before
revealing the manifest. Record concrete shape errors and render the smallest
revision that addresses them.

Iteration 02 addresses the independent review in `pool-review.json`. Weight ends are stepped plates; the record has a dark label and spindle; the open spring box uses the working name Restless Box. Split Fork, Travel Mug and Steam Bowl describe the objects actually drawn. Labelled 20/24px readability and family consistency passed review. At16px the record can still read as a coin, and the spring compresses at20px. No unaided recognition rate is claimed.
