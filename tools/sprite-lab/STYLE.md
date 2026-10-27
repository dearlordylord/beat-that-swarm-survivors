# Nightfall geometry contract

This is the first mathematical redraw study. Its pilot is the orange-haired third reference character. Iteration 03 is structurally improved but rejected by the user for style and color drift; its current geometry and colors are not an approved replacement target. The user selected the middle Nightfall direction of the earlier concept board. The other six recipes demonstrate reuse and have not passed individual visual review.

## Reference fidelity

`reference-contract.json` fixes the reference hierarchy and review axes. Original character identity takes precedence; the user-approved middle Nightfall direction defines the intended adaptation. The generated seven-character sheet supports comparison and does not replace either source.

| Required visual check | Reject when |
| --- | --- |
| Silhouette | Hair volume, face outline, pose, or clothing outline loses recognizable source shapes |
| Proportions | Head/body ratio, limb thickness, stance, or facial spacing changes without an accepted design reason |
| Palette | Hue, saturation, lightness, contrast, or relative color areas drift, even if selected hex colors match |
| Garment identity | Jacket becomes a tunic, sweatshirt becomes an open coat, or accessories and characteristic color blocks disappear |
| Face and expression | Clean equal eyes produce a different face, expression, or perceived character |
| Rendering style | Pixel clusters, contour thickness, shading density, or angularity become an unrelated clean-vector style |
| Motion identity | Animation changes the established body, hair, face, palette, clothing, or silhouette instead of preserving the character |

Every axis needs pass/fail/unreviewed and concrete visual evidence against fixed references at both enlarged and game size. A failed or unreviewed axis blocks visual acceptance. Do not average failures away. Motion review includes the GIF; if timing cannot be observed, mark that aspect unreviewed.

These are visual judgments with explicit evidence, not mathematical theorems about beauty. Check and record them independently of geometric validity. A structural improvement must survive this comparison before it becomes the new shared baseline.

## Shared construction

All seven use the same `model.bend` primitives and `artwork.bend` renderer. Geometry is authored in Bend. The Python host runs Bend, renders its SVG, checks output, and builds review pages. It does not trace PNGs or invent shape coordinates.

| Property | Current pilot |
| --- | --- |
| Authoring viewport | 64 × 80 integer coordinates |
| Game-size review | 32 × 40, nearest-neighbor sampling |
| Neutral eye origins | (25, 27) and (37, 27) |
| Neutral eye size | One shared 3 × 8 record |
| Hip lanes | x=27 and x=38 |
| Boot bounds | Left x=22..30, right x=35..43, stepped toe polygons |
| Boot baseline | y=74 at contact |
| Full front walk catalog | Eight indexed poses |
| Foot lift | 0..2 authoring units |
| Body bob | 0..1 authoring unit |
| Outline | #101729, four-unit geometric expansion, all body parts painted dark before any colored fill |
| Limb attachment | One polyline through root, shared knee, and tip |
| Face skin | #f4d7b2, blush #e99695 |
| Trousers | #18334c |
| Pilot jacket | #1e828a with #429da2 lapels, pale opening four units wide |
| Pilot hair | #e87333, highlight #ffc078, shade #bd512b |

Grid polygons define head and hair silhouettes. Limbs use joined vector polylines. The dark underpass expands the shared body geometry before color fills cover internal overlaps. This is a construction technique, not a general proof of the union contour's topology.

## Character variation

`roster.json` records the seven identities and outstanding details. `artwork.bend` owns the actual palette and hair polygons. Character data may change hair shape, clothing colors, garment details, and footwear. Keep the face, rig, outline method, viewport, and export path shared. If one identity needs a new garment shape, add an explicit garment variant to the shared renderer rather than creating a second renderer.

Do not mark the family previews complete merely because they share the pilot's model. In particular, the second character still needs green glasses, and the fifth needs its graphic top and brown straps.

## Evidence boundaries

`LAWS.bend` and `PROOF.bend` establish six small claims about shared eye dimensions, dimension preservation, the shared knee, and one literal SVG serialization. They do not prove that the drawing is attractive, that the eyes share a baseline for every possible model value, or that every rendered outline is continuous.

`validation.bend` checks the authored pose bounds, positive eye dimensions, boot gap, and ordinary-walk support rule before SVG output. `validation-tests.bend` checks this finite catalog and rejection examples.

`build.py` independently reads emitted SVG, checks both visible eye rectangles, the central foot gap, and four-neighbor opaque connectivity at both resolutions. These finite checks do not prove a closed dark outline or continuous-time gait. Aesthetic quality and contour readability still require visual review.

The current animation is a front-facing foot-lift study. It has no profile views, forward travel coordinate, world-space planted-foot constraint, or velocity synchronization. Add those to the shared pose model before calling it a locomotion cycle. Do not mirror the front view and label that a side view.

Iteration 04 tests narrower body and hands, a narrower pale shirt, muted teal, a swept orange fringe, and smaller highlight clusters against the fixed references. The jacket colors use observed reference swatches as a starting point; a sampled swatch is not evidence that the whole palette or its area balance matches. These edits remain subject to visual fidelity review.

Iteration 05 compacts the lower silhouette with knee height 64 and ankle height 69 at contact, stepped boot polygons, and shared garment/hair shadow clusters. It preserves the narrower jacket, muted pilot palette, equal full eyes, and fixed foot lanes from iteration 04. Visual acceptance still requires the complete reference-fidelity review.

Iteration 06 responds to the fully enlarged fidelity comparison: taller orange hair and deeper side locks, broader chin, shorter exposed neck, taller shared eyes, pink facial accents, near-white shirt, a small red chest mark, and shorter lapel highlight blocks. These are source-fidelity hypotheses under review, not automatic approvals.

The independent iteration-06 review passes principal palette relationships and garment identity, but keeps silhouette, proportions, expression, and rendering style below acceptance. Temporal motion identity is unreviewed. Partial visual improvement is recorded as `fail` until the agreed reference is met; there is no partial-pass state in the gate.

## Selected baseline

The user subsequently accepted iteration 06's static appearance. `selection.json` binds that decision to the retained image and SVG hashes. Preserve that accepted style during future redraws; the prior model findings remain historical evidence and do not override the user's taste decision. The walking animation still needs improvement. Character-specific missing accessories in `roster.json` remain outstanding.
