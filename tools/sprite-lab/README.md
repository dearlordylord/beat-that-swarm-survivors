# Iterate on a Nightfall character

Generate the seven-character family sheet and orange pilot from Bend, then refine the pilot through visual review. Keep generated artifacts outside this checkout.

Requires Bend, Clang, Python 3, Pillow 13.0.0, and CairoSVG 2.9.1. Node.js is not used.

## Generate a review iteration

1. Read [the shared style contract](STYLE.md) and [the roster](roster.json).
2. Choose a fresh output directory for the next iteration.
3. Run from the repository root:

```sh
uv run --with pillow==13.0.0 --with cairosvg==2.9.1 python tools/sprite-lab/build.py \
  --output /workspace/survivors-nightfall-art/bend-pilot/next-review \
  --reference-root /workspace
```

4. Open the output's `index.html`. Inspect the large image, game-size figures, eight-frame strip, and GIF.
5. Give the output and the original reference sheet to an independent visual model. Compare the pinned original, selected Nightfall middle row, and supporting generated sheet against the result. Review silhouette, proportions, palette relationships, garment identity, face and expression, rendering style, and identity throughout motion. Structural checks are a separate assessment. Require defects and concrete revision targets rather than an overall approval.
6. Record pass, fail, or unreviewed with concrete evidence for every axis in the output's `style-review.json`. Record the reviewer. Run `python3 tools/sprite-lab/check_review.py OUTPUT_DIRECTORY`. Any failed or unreviewed axis blocks visual acceptance. Record the critique in [the review log](reviews.json). Change the smallest shared geometry responsible for the named defect.
7. Generate a fresh directory and compare it with the previous iteration. Keep the previous output until the comparison and decisions are recorded. Then delete rejected generated previews unless they remain an active reference.
8. Repeat until the pilot passes both structural checks and reference-fidelity review. A cleaner drawing that loses the source style is a failed iteration. Then review each remaining character against its `roster.json` identity, using the same renderer and checks.

The build checks Bend proofs and finite validators, compiles the native SVG generator into a temporary directory, and renders the actual output. Each retained output includes `source/`, source hashes, validation results, the proof checker output, SVG files, PNG files, a GIF, and a local HTML page. The selected output retains its build-time source snapshot. Rejected iteration images and source snapshots were pruned at the user's request; their decisions remain in the review log.

Use the source snapshot to repeat an older iteration. `build.py` resolves modules beside itself. An older snapshot retains that iteration's validation rules.

## Keep the visual loop consistent

Preserve these references outside tracked source:

- `/workspace/tumblr_o3pqt9wwOf1r8ugkco3_r2_640.webp` is the original seven-character sheet.
- `/workspace/survivors-sprite-concepts-abc.png` supplies the selected middle Nightfall direction.
- `/workspace/survivors-nightfall-art/01-generated-roster.png` is the full generated interpretation.

Use this review brief with every iteration:

> Compare the actual Bend neutral pose, native-size preview, frame strip, and GIF with ALL pinned references side by side. The original supplies identity, the middle Nightfall row supplies the selected style, and the generated roster is supporting material. For silhouette, proportions, palette, garment identity, face/expression, rendering style, and motion identity, return pass/fail/unreviewed with concrete visible evidence. Compare hair volume, head/body ratio, pose, hue/saturation/lightness, relative areas of each color, outfit cut, accessories, expression, contour weight, pixel-cluster size, and shading density. Distinguish approved Nightfall adaptation from unrequested simplification. Name at most five correction priorities. Check improvements against the original as well as the previous iteration. A uniform family of drawings can still fail fidelity. Do not infer style acceptance from proofs, connectivity, equal eyes, a numeric similarity score, or merely using the same hex colors.

The reference images guide the redraw. They are not production geometry inputs. Record a source revision, review outcome, and actual edit for each iteration. If a visual defect can recur, add an observable artifact check or a shared constructor constraint, then verify that a deliberately broken example is rejected.

## Validate without drawing

```sh
bend tools/sprite-lab/PROOF.bend --verdict
bend tools/sprite-lab/validation-tests.bend --verdict
python3 tools/sprite-lab/check_mutations.py
```

The build applies a 10-second CPU and 60-second wall limit to subprocesses. See [evidence boundaries](STYLE.md#evidence-boundaries) before reporting what these checks establish.

`check_mutations.py` requires proof rejection when one eye width changes or a segment uses the wrong joint. It also compiles a catalog with excessive foot lift and requires the generator to exit with an error without emitting SVG.

## Keep the reference fixed

`reference-contract.json` pins the three source images by content hash and declares their precedence and review axes. `--reference-root` locates those files. Missing or changed files stop generation; changing the target reference requires an explicit contract edit. Every output copies the references beside the result and records their hashes. The selected-style preview crops only the approved middle row. `fidelity-comparison.png` places the orange character from each pinned reference next to the Bend result; crop rectangles live in the contract and do not change source geometry.

A fresh render starts with an unreviewed fidelity report. `check_review.py` checks completeness and binds the verdict to the comparison pixels, fidelity sheet, pilot SVG, GIF, and reference hashes. It cannot decide whether a model's visual judgment is correct. Do not copy a prior pass onto new pixels. Source snapshots retain the review brief and contract used for that iteration.

User feedback rejected iteration 03's reference fidelity despite its structural improvements. Restore the original's style, proportions, palette balance, and clothing character before propagating that pilot to the other six.

The review image enlarges small references as well as reducing large ones, using nearest-neighbor scaling. Keep the same crop coordinates and reference precedence through the loop. When an expanded reference comparison exposes a previously missed mismatch, retain the earlier critique in the log and record the new failure rather than treating previous passes as permanent.

## Retain the selected result

The user selected the latest static drawing in `selection.json`; walking animation remains a prototype. This explicit taste decision sets the accepted visual baseline despite the earlier model reservations. Keep those reservations in the log rather than rewriting them as passes. Compare future revisions against this accepted baseline as well as the original identity references.

Keep the selected output, its original source snapshot, pinned input references, validation evidence, and the decision log. Delete rejected output folders and obsolete comparison pages after their findings are recorded. Do not preserve every intermediate image as methodology. Remove links to deleted artifacts and rebuild the shared ZIP so it does not retain discarded previews. A fresh output directory is still required to prevent accidental overwrites of retained results.

The selected output lives at `/workspace/survivors-nightfall-art/bend-pilot/review-06-fidelity`. Previous iteration paths in `reviews.json` identify historical artifacts that have been pruned. Their decisions remain available; those paths are not promises that files still exist.
