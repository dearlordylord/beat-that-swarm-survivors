---
name: bend-sprite-art
description: Redraw reference characters as mathematical Bend sprite geometry, refine them through visual review, preserve likeness and a consistent character family, and prototype joint-based animation. Use for this repository's sprite artwork workflow and its methodology.
---

# Bend sprite artwork

Build the artwork in Bend, render it, show the actual images to a visual reviewer, and revise the geometry from concrete findings. Maintain two separate judgments: structural consistency and fidelity to the intended appearance. A clean, consistent drawing can still lose the source character.

## Resume from the selected result

Read these files before changing artwork:

- [selection.json](../../tools/sprite-lab/selection.json) records the user's selected appearance and its artifact hashes. This taste decision takes precedence over earlier model reservations within its stated scope.
- [STYLE.md](../../tools/sprite-lab/STYLE.md) defines shared construction and the limits of current checks.
- [roster.json](../../tools/sprite-lab/roster.json) lists every character, its identifying details, and unfinished work.
- [reference-contract.json](../../tools/sprite-lab/reference-contract.json) pins original identity references and the selected concept direction.
- [reviews.json](../../tools/sprite-lab/reviews.json) records defects, edits, and decisions. Historical paths may refer to pruned outputs.

Locate the selected output and pinned references through those records. In this workspace, generated assets live under `/workspace/survivors-nightfall-art`; `/workspace` corresponds to the user's `/Users/firfi/work` mount. Verify files and hashes before relying on them. Keep generated assets outside tracked source.

The current selected static direction is accepted by the user. Walking animation still needs work. Acceptance of the pilot's style does not complete the remaining characters' missing accessories or establish animation quality.

## Establish the visual target

For a new concept, generate a character sheet from the supplied references and choose a direction before mathematical redrawing. Use the available image-generation tool for raster concepts; a text reviewer such as Astra does not itself generate image pixels. Save previews in the shared workspace and give the user a local path they can open.

For an existing selected direction, start from that accepted appearance. Preserve the original character's identity while following the user's chosen adaptation. Treat generated concept sheets as supporting references rather than silently replacing the original. Change the visual target only through a recorded user decision.

Use one pilot to establish the shared model. Keep the whole roster visible so the pilot does not become a one-off renderer that cannot reproduce the other characters.

## Draw geometry with meaningful parts

Use the existing [sprite lab](../../tools/sprite-lab/README.md). Bend owns shape coordinates, palette choices, face construction, joints, and poses. The host runs tools, rasterizes the emitted SVG, checks artifacts, and presents them.

Construct full eyes from shared dimensions and a face frame. Derive adjoining limb segments from the same joint record. Derive outlines and fills from shared body geometry. Define hairstyle, garment, and accessory differences as character data or explicit variants of the shared renderer.

Express bangs, perspective, blinking, and profile visibility as explicit occlusion or pose choices. Unequal visible eye areas can be intentional even when the full eye shapes share dimensions. Keep structural claims scoped to the poses where they apply.

Raster tracing reproduces existing pixels, including their mistakes. Use it for extraction or comparison when useful, not as a substitute for anatomical geometry.

Add laws for general structural guarantees and finite checks for the actual artwork. Check the rendered output independently. Shared endpoint proofs do not establish raster connectivity; opaque connectivity does not establish a continuous dark outline. State which claims are proved, checked on a finite catalog, or only visually assessed.

## Run the visual iteration

1. Name the visible defect and the feature to preserve. Change the smallest relevant geometry, palette relationship, or character variant.
2. Generate a fresh output directory using the command in the sprite-lab README. The build runs Bend checks and exports SVG, large and native-size PNG, a frame strip, GIF, source snapshot, and validation reports.
3. Inspect the actual output. Compare the new drawing with the original identity reference, the selected appearance, and the previous candidate. Enlarge small references as well as reducing large ones; use consistent crops and nearest-neighbor scaling for pixel comparisons.
4. Give these artifacts to an independent image-capable reviewer. Prefer Astra when available for spatial critique. Require concrete evidence and a few prioritized edits. Record the actual reviewer; if no independent review ran, leave it unreviewed.
5. Record findings and the next edit in `reviews.json`. Record per-axis verdicts in the output's `style-review.json` and run `check_review.py` as described in the README. Its verdict is tied to the reviewed SVG, PNG, GIF, and reference hashes.
6. Apply the findings and repeat. Carry an improvement forward only after checking it against the selected appearance, not merely the preceding candidate. Update the shared style contract when an accepted construction changes.

Review these axes separately:

| Axis | Compare with the visual target |
| --- | --- |
| Silhouette | Hair mass, fringe, head outline, shoulders, hands, clothing outline, and footwear |
| Proportions | Head/body balance, torso length, facial spacing, limb thickness, and stance |
| Palette | Hue, saturation, lightness, contrast, and relative areas of colors |
| Garment identity | Outfit cut, opening, folds, accessories, and characteristic accents |
| Face and expression | Eye shape and placement, cheeks, mouth, and native-size readability |
| Rendering style | Pixel-cluster structure, contour weight, angularity, and shading density |
| Motion identity | Appearance stability through the cycle, plus observed timing and weight |

Use `pass`, `fail`, or `unreviewed` with visible evidence. Treat partial matches as unfinished rather than averaging them into a pass. Matching a few hex colors or passing geometry laws does not establish likeness. A user may select a different artistic result; record that explicit decision and its scope without rewriting previous model findings.

When reviewing animation, observe the GIF or running feature as well as the frame strip. Static frames alone cannot establish timing or smoothness. If repeated edits satisfy structural checks but still lose the style, revisit the reference comparison and shape representation before adding more constraints.

## Recognizable accessories and mascots

For small accessories, read [the accessory study](../../tools/sprite-lab/ACCESSORIES.md). Pin actual visual references with URLs and hashes before authoring geometry. A descriptive label or matching palette is not evidence that an accessory resembles its target.

Compare isolated shapes and mounted accessories. Render at the native sprite size and the actual gameplay transform; the current 32x40 portrait is drawn at 0.75, so the hero appears 24x30. Enlarged recognition and gameplay recognition are separate verdicts. Use an unlabelled, shuffled hero-only sheet for independent identification, then compare against the fixed references for fidelity. Record the reviewer and confidence; model identification is not a human usability study.

If a chest badge fails, compare placement and size before adding facial detail. Consider a held toy or charm with a larger silhouette. Prefer authoring directly on the final pixel grid over fractionally enlarging a smaller icon when critical features collapse. Preserve a few identity anchors such as ears, muzzle, hood, scarf, or heart outline. Keep unresolved members explicit; do not turn overall family consistency into per-accessory acceptance.

## Animate through joints and contact

Preserve the accepted static character. Model pelvis, hip, knee, ankle, shoulder, elbow, and wrist relationships rather than translating rectangular crops of limbs. Separate forward travel, lateral displacement, and height. For a frontal walk, keep feet in narrow lanes under their hips; use an actual profile construction for side views.

For locomotion work, check planted-foot stability in world coordinates, swing clearance, bounded limb deformation, alternating support, and the last-to-first transition. Apply contact rules to the intended state: ordinary walking, running, and jumping need different support assumptions. Check geometry again after pixel quantization.

Keep head bob and arm amplitude restrained when that matches the accepted look. The existing front foot-lift catalog is a study, not a complete stance-synchronized walk. Verify movement at gameplay size before calling it finished.

## Apply the method to the family

Once the pilot's direction is accepted, render and review each roster member through the same model. Preserve each character's source hairstyle, clothing, palette balance, and accessories. Mark individual completion in `roster.json`; a consistent family sheet does not prove every identity is complete.

Keep reusable geometry, checks, review records, and commands in the repository. Link to the existing sprite-lab documentation for implementation details instead of duplicating its parameter tables in this skill.

## Retain decisions, prune rejected outputs

Keep the selected output, its build-time source snapshot, active reference inputs, validation evidence, and the textual decision history. Keep a previous candidate until its comparison and findings are recorded. Then remove rejected generated previews and duplicate source snapshots when they no longer serve an active reference or comparison.

Pruning does not authorize deleting unrelated files or source history. Preserve pinned inputs and the selected result. Update local HTML links and rebuild the shared ZIP after cleanup. Keep the original build-time snapshot intact; store current methodology updates separately.

Finish by giving the user the retained page's actual workspace path and, when relevant, the corresponding Mac `open` command. Report separately what is selected, what passed automated checks, what was visually reviewed, and what still needs work. An implementation request requires concrete artwork or animation output, not only this methodology.
