# Shared projectiles and persistent XP

Historical measurements below describe commit `166b82b`, before removal of
custom map actors. They do not describe the current allocation layout.

The authoritative current allocation and admission configuration is in
[`pools.bend`](../examples/survivors/pools.bend). Assignment rules are in
[`projectile-pool.bend`](../examples/survivors/projectile-pool.bend), world and XP
integration in [`game.bend`](../examples/survivors/game.bend), and appearance
policy in [`loot-visual.bend`](../examples/survivors/loot-visual.bend).
The budgets were guided by the [reference investigation](vampire-survivors-entity-limits.md).

## Checks

- Five small-core kernel checks pass: configuration, allocator transitions,
  visual cap/colors, pickup accounting and spawn admission/lifecycle.
- The independent allocator oracle passes 305 cases. All 55,585 legacy firing
  schedule/birth cases preserve the prior birth behavior under a different
  physical slot, including union/familiar spread and new owner metadata.
- Actual ECS advances transport eight planned shots correctly. Other integration
  cases cover overlapping volleys, owner caps, pool exhaustion, reclaiming dead
  slots and hostile/player routing.
- A legal Curse-rank-5/Inverse fixture admits exactly 500 enemies; ordinary
  late-wave admission is 300. These use an explicitly injected late clock.
- 480 simultaneous deaths produce 400 physical piles and preserve all 960 XP;
  the single accumulator contains 162 XP. Pickup/reuse/generation checks pass.
- Ordinary gameplay, actual desktop/touch browser smoke, exact XP browser pixels,
  native UI/profile/FPS/XP/spawn/parallel fixtures and native app build pass.
- The unchanged native full-run controller reaches dawn and dies to the Reaper
  at tick 36563: phase 4, HP 0, level 15, 1696 kills and 16 decisions. Its existing
  boss/chest/evolution assertions pass. This is one maximum-meta defensive build,
  not a fresh-profile balance or richness qualification.

The actual `ArgsShots` carrier is covered by finite helper and two-advance ECS
integration cases. A new universal carrier proof attempt importing the complete
game exceeded the fixed kernel budget; it was archived as **unverified** and its
additive declarations were removed. The existing `ArgsHeld` lemma covers only
that constructor. No whole-game or whole-carrier proof is claimed.

## Native frame observations

A frozen native O3 fixture uses six rank-8 weapons, six passives, 90 warmup steps,
a real 1468-entity world, CPU0 and one runtime thread. Simulation, display-list
and full-image completion barriers precede their clocks. Three repetitions of
400/500-enemy configurations match complete state and PPM bytes exactly.

| Enemies | Catch-up steps | Simulation median ms | Image ms | Total ms |
| --- | ---: | ---: | ---: | ---: |
| 400 | 1 | 9 | 6 | 16 |
| 400 | 4 | 41 | 6 | 48 |
| 500 | 1 | 11 | 8 | 19 |
| 500 | 4 | 34 | 7 | 42 |

The configurations have different clocks and actual attacks: 400 enemies has
120 friendly shots / 104 hit plans; 500 has 98 / 82. Therefore the rows are not
a scaling curve. The earlier banked version had only 48 / 32 in its corresponding
400-enemy fixture; its timings are not an equivalent-work speed comparison.
The 400/500 fixtures are constructed stress scenes, not observations that every
ordinary run naturally sustains those counts. No Mac window FPS is measured.

One additional planner optimization passed all 24 exact state/image comparisons
but failed its predeclared timing gate: geometric-mean simulation ratio 1.047
(required <=0.9), with one configuration 33% slower. It was reverted; no adaptive
rerun or replacement candidate followed. Accepted Game SHA256:
`5368922f0d469bf0b22cfc1f9bf0d8e7582c1b991a25c49f9ff72af0e9880090`.

Sources, C, executables, complete state/PPMs, raw timing/functional logs and
rejected work are outside tracked source in
`../bend-games/research/shared-projectile-pool-20261023/`.
