# Offscreen birth invariant

`LAWS.bend` and `PROOF.bend` verify the admission and lifecycle core used by the game. The main safety law is `accepted_newborn_is_outside`: for every coordinate, camera coordinate, radius and supplied clean Motion value, admission implies that the unchanged newborn point satisfies the offscreen exclusion predicate. It is a universal kernel-checked implication, not a sampled placement claim.

Other laws preserve the entire payload, supply exactly the clean status, reject dormant revival, and distinguish actual births/boss resets from an existing age counter wrapping to zero. A well-typed mutation that admits every candidate fails the safety law. Mutations that always choose Fresh/Existing or ignore prior identity fail their corresponding laws.

## Production connection

`game.bend` routes the updated row through `spawn-lifecycle.bend`. A fresh row bypasses previous-incarnation combat and returns its accepted coordinates and initial health with `empty_motion()`. Existing rows use the original combat path. ECS writes install the new Vitals/Motion and commit the returned Body.

This fixes a reproduced defect: spawning was initially offscreen, but combat interpolated the new point from the corpse position using the previous occupant's slow/freeze. A frozen slot could therefore put its replacement exactly at the player. Tower pulses could also damage the replacement at the old corpse position. Newborn status reset prevents that interpolation and those old-position hits.

## Scope and checks

The formal proof covers the small admission/lifecycle core. It does not prove the entire ECS query interpreter, every game callsite, camera rendering, or IEEE floating-point implementation. The exclusion geometry conservatively includes the native raster and supported browser camera; independent tests cover all enemy variants and arena edges. A separate proof attempt importing the complete game exceeded its fixed kernel CPU budget and was archived as unverified, not shipped as a completed proof.

The production connection is additionally checked by native C regressions for old slow/freeze/burn/tower hits and by JavaScript development tests exercising real ECS writes, boss replacement and the age-wrap case. `spawn-policy.test.mjs` checks 42,532 placements and 3,480 actual live birth transitions against the post-step camera.

From the repository root, with the matching development proof toolchain installed:

```sh
ELAN_TOOLCHAIN=leanprover/lean4:v4.34.0 bend examples/survivors/spawn-policy/PROOF.bend --verdict
```

Game launch itself does not require the proof toolchain. Source-bound receipts and rejected mutants are stored outside the checkout in `../bend-games/research/survivors-fps-spawn-20261023/`.

Arena geometry and movement bounds belong to [arena.bend](../arena.bend).
[arena.test.mjs](../arena.test.mjs) exercises movement, displacement and corner
reach against the implementation. These boundary tests are execution evidence,
not an all-game theorem.
