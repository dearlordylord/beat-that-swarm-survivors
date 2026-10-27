# Thematic roster export

The user requested seven BTS-inspired heroes in the accepted Nightfall drawing style. The new brief explicitly changes outfit palettes and motifs. The previous selected orange-haired pilot remains the style reference. These sprites are human chibi interpretations, not verified portrait likenesses.

`theme-artwork.bend` imports the accepted shared face, hair variants, rig and outline construction. It owns the seven themed color recipes and shared body. `accessories-native.bend` and `accessories.bend` supply the user-selected D accessories. `theme-generate.bend` emits the seven static neutral figures after the existing pose validation. The original artwork and selected review snapshot remain unchanged.

| ID | Hero | Palette and motifs |
| --- | --- | --- |
| 0 | RM | Indigo jacket and KOYA held plush |
| 1 | Jin | Cream jacket and RJ held plush |
| 2 | SUGA | Charcoal jacket and frontal SHOOKY cookie |
| 3 | j-hope | Ochre jacket and masked MANG held plush |
| 4 | Jimin | Pearl jacket and CHIMMY held plush |
| 5 | V | Burgundy jacket and TATA held plush |
| 6 | Jung Kook | Gold jacket and COOKY held plush |

The themed boot inner edges move one authoring unit outward. The original single-unit central gap disappeared under 2:1 nearest-neighbor sampling. The wider gap keeps both boots separated on the actual 32x40 game grid. The hip and knee positions remain shared.

Run the exporter from the repository root, using a fresh external output folder:

```sh
uv run --no-project --with pillow==13.0.0 --with cairosvg==2.9.1 python tools/sprite-lab/theme-build.py --output /workspace/survivors-bts-art
node scripts/generate-native-survivor-art.mts
```

Check the committed exports against a fresh render:

```sh
uv run --no-project --with pillow==13.0.0 --with cairosvg==2.9.1 python tools/sprite-lab/theme-build.py --output /tmp/survivors-theme-check --check
node scripts/generate-native-survivor-art.mts --check
node --test examples/survivors/survivor-art.test.mts
```

Bend owns all shape coordinates and authored colors. Python rasterizes the SVG at 64x80, takes nearest-neighbor samples at 32x40, maps anti-aliased pixels to the nearest authored RGB color, discards samples with alpha below 128, and serializes each color into exact orthogonal row runs. The generated `survivor-shapes.mts` is consumed by both browser SVG and Canvas. The existing native generator converts the same pixel masks into Bend rectangles. Native launch does not run Python or Node.

The exporter checks the inherited structural proofs, actual unoccluded equal eyes, one opaque component at both sizes, and the final central boot gap. The native generator checks its mask conversion. These checks do not establish likeness, style acceptance or animation quality. Independent visual review must inspect `contact-sheet.png` and compare the retained accepted pilot. No new walk cycle is authored here; the game keeps its existing presentation.

## Selected accessory integration

The user selected pixel-grid variant D for game adoption. `theme-selection.json` records the exact approved PNG hashes. The production exporter rejects output that differs from those seven selected images. This protects the selected artifact; it does not prove aesthetic fidelity.

The accessory group is mounted at authoring `(32,38)` with scale2. KOYA, MANG and CHIMMY have direct16x17native geometry; the other four retain the selected larger-plush construction. The human face and shared body are the same as the reviewed prototype. Browser portraits, Canvas and generated native rectangles consume the same32x40pixel masks.

The independent findings in `accessory-current-review.json` remain unchanged. User acceptance chooses the construction and size; miniature facial detail and MANG fidelity remain partial. Gameplay uses the seven starter/innate contracts in `examples/survivors/THEMATIC_ROSTER.md`.
