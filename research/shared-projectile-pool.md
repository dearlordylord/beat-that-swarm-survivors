# Shared projectiles and persistent XP

The Survivors ECS example now uses the layout in
[`pools.bend`](../examples/survivors/pools.bend): 512 enemy/relic identities,
512 shared player-shot slots, 32 hostile shots, 12 actors and 400 XP piles.
The enemy spawner admits up to 300 normally and 500 with modifiers. These are
application budgets, guided by the [reference investigation](vampire-survivors-entity-limits.md).

Player shots carry owner/logical-position metadata separately from physical
identity. Live budgets are 40–70 per base weapon; persistent effects retain
logical-position locks. The allocator runs once per tick, never replaces a live
shot and drops saturated requests without a backlog. Existing volley amount,
spread, cooldown, evolution, union and familiar rules are preserved.

XP drops retain their positions while slots remain. At overflow one accumulator
keeps its seed, generation and coordinates until physical pickup. It is always
red. Ordinary colors use 1/5/10 XP tiers; radius grows to 8 at 100 XP and stays
there while the amount can grow further. Amounts retain the U32 representation.
Both renderers use the same Bend policy; visual size does not change pickup radius.

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
