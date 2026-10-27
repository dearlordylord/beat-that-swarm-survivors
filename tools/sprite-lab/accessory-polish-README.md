# Accessory polish prototypes

This study preserves the selected variant D. It compares two reversible identity
refinements, E and F, for MANG, KOYA and CHIMMY. It does not replace production
art or update `theme-selection.json`.

Run from the repository root with a fresh external output directory:

```sh
uv run --no-project --with pillow==13.0.0 --with cairosvg==2.9.1 python tools/sprite-lab/accessory-polish-build.py --output /workspace/survivors-accessory-polish
```

`accessory-polish-art.bend` owns all new geometry. The generator mounts it on
`Theme.body` at the selected transform. Python compiles Bend, rasterizes its SVG,
applies the production palette exporter, and lays out the comparison.

The output includes official reference images, 16x18 isolated icons, 32x40 native
heroes, and actual 24x30 gameplay heroes. The builder verifies pinned reference
hashes, the 16x18 footprint, unchanged pixels outside the accessory mount, and an
exact match between D and the selected production native images. These finite
checks do not establish reference fidelity or gameplay recognition.

The hypothesis for MANG is that a pink heart on the turquoise mask and a purple
lower muzzle preserve the official masked identity better than a protruding pink
beak. KOYA tests rounder ear steps and an outlined purple nose. CHIMMY tests
stronger black ear masses and restrained mouth/tongue marks. Independent review
must judge the exact output before any production replacement.
