# Existing weapon vector icon study

This study provides one Bend-authored vector icon for each of the 24 existing
base weapons. Stable IDs, mechanics, recipes and production glyphs remain
unchanged. Display names are provisional wording from `study-matrix.json`,
not cleared trademarks.

Run from the repository root with a fresh external output directory:

```sh
/tmp/nightfall-art-venv/bin/python tools/icon-lab/weapon-build.py --output /workspace/survivors-weapon-icons/iteration-01
```

The build needs Bend, a C compiler, Pillow and CairoSVG. `weapon-artwork.bend`
owns the additional geometry. Starter IDs 20, 21, 14, 22, 8, 23 and 1 directly
import `Art.icon(hero, 1, 0)` from the personal icon module. Their geometry
therefore follows the same revision instead of drifting into duplicate drawings.
Other weapons express their actual trajectory, object and timing family through
large shapes, rather than letters or generic glyphs.

Output includes true SVG, 16/20/24/32 pixel PNG previews, shuffled unlabelled
objects, an old/new contact sheet and a 34-pixel HUD with a rank overlay. The
finite checks cover nonempty output and the two-unit safe area. They do not
prove semantic recognition or aesthetic quality. An independent visual reviewer
must inspect both the blind sheet and actual-size previews before selection.

Source hashes include both the weapon module and imported personal geometry.
A source snapshot accompanies each external iteration. Preserve findings and
selected artifacts before pruning rejected iterations. No production integration
occurs in this lab.

Add `--check` with a fresh output directory to compare current Bend source hashes
and all 24 vector hashes with the recorded manifest. The check does not overwrite
the recorded manifest.
