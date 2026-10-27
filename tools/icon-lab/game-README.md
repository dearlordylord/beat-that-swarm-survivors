# Selected game icons

The game uses style A for 24 weapons, 18 shared relics, and seven personal
innate motifs. Stable catalog IDs select artwork in `item-icons.mts`. Catalog
`icon` fields remain plain text fallbacks for categories without reviewed art.
Evolutions reuse their base weapon icon. Unions and arcana retain their existing
symbols.

Regenerate the checked-in browser vectors and native masks from Bend sources:

```sh
python3 -m venv /tmp/nightfall-art-venv
/tmp/nightfall-art-venv/bin/pip install cairosvg Pillow
npm ci
/tmp/nightfall-art-venv/bin/python tools/icon-lab/game-build.py
/tmp/nightfall-art-venv/bin/python tools/icon-lab/game-build.py --check
```

The exporter compiles the three authored Bend sheets, selects filled personal
motifs, and emits `item-icon-shapes.mts` and `native_icons.bend`. Personal motif
labels come from the approved ability matrix. Browser artwork retains the SVG
curves. Native presentation samples the same artwork on a 20-pixel grid, rounds
opaque pixels to source colors, and merges adjacent rectangles. Native launch
uses only the checked-in Bend display lists and requires neither Python nor
Node.js.

Browser consumers share a kind-and-ID registry. Weapon and passive IDs have
separate namespaces. Unsupported reward categories use escaped text symbols.
Starter badges, collection cards, solo and co-op reward cards, and the solo
loadout use the selected artwork. Personal motifs identify innate abilities in
the survivor details and selected-run card. Native collection cards, reward
rows, and paused loadouts use the generated masks.

Run focused presentation checks after regeneration:

```sh
node --test examples/survivors/item-icons.test.mts examples/survivors/expedition-menu.test.mts
bend examples/survivors/native_icons.bend --check-only
bend examples/survivors/native.bend --check-only
npm run typecheck
```
