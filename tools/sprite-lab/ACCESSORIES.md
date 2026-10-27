# Recognizable accessory study

The previous thematic portraits used abstract rectangles and tiny chest badges. Static family consistency passed review, but those accessories did not resemble the required BT21 motifs. This study treats accessory identity as a separate visual gate.

## References and authority

The user requested KOYA, RJ, SHOOKY, masked MANG, CHIMMY, TATA and COOKY motifs in the accepted Nightfall character family. Official assets come from https://www.bt21.com/character and `https://cdn-bt21.line-scdn.net/img/character/bt21/{name}.gif`. The legacy `mang.gif` is the masked design requested in the brief. Exact input URLs and SHA256 hashes are in `accessory-references.json`. Reference GIFs and previews live outside tracked source at `/workspace/survivors-accessory-lab`.

## Method

1. Draw two alternatives in Bend: head emblem and small plush. Compare them against the actual reference, not its written description.
2. Mount the accessories on the shared body. Compare compact and larger placements without changing the hero's face or proportions.
3. Render 32x40 native pixels and 24x30 gameplay pixels using the production 0.75 scale. Include exact-size figures separately from nearest-neighbor enlargements.
4. Shuffle the seven heroes and remove identity labels for independent identification. Record initial guesses before showing references. Then judge resemblance against those references.
5. Revise the failed identity anchors. If fractional scaling damages features, author on the final native pixel grid.
6. Record reviewed hashes, reviewer, remaining defects and the chosen prototype scope. Keep acceptance partial when a mascot only works enlarged. Do not claim a recognition rate from a model review as if it were a human test.

## Source ownership

`accessories.bend` owns the 12x14 variants. `accessories-native.bend` owns direct native-grid revisions. `accessories-integrated.bend` mounts the prototypes on the accepted shared body. `accessories-build.py` compiles Bend, rasterizes SVG, applies the production palette exporter and produces the comparison and shuffled sheets. Python defines presentation layout, not accessory coordinates.

Run from the repository root with a fresh external directory:

```sh
uv run --no-project --with pillow==13.0.0 --with cairosvg==2.9.1 python tools/sprite-lab/accessories-build.py --output /workspace/survivors-accessory-lab/new-iteration
```

The builder expects pinned reference GIFs under `/workspace/survivors-accessory-lab/references`. Source snapshots accompany each generated iteration. The study does not change attack mechanics or the walking rig. The user subsequently selected variant D for production adoption; `theme-selection.json` pins the chosen images, and `theme-artwork.bend` now uses that construction. Historical review limitations remain recorded.
