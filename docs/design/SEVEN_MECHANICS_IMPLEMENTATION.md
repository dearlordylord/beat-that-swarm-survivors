# Seven automatic starter mechanics

The owner approved all seven mechanics in [the design matrix](CHARACTER_ABILITY_MATRIX.md), filled icon style A, and original game epithets. The review baseline is commit `ca4b29c`, the snapshot immediately before implementation. This mod remains local and must never replace the public Survivors game.

## Approved behavior

| Character | Automatic mechanic | Evolution partner |
| --- | --- | --- |
| Grove Scribe | Collected Thoughts. Three or more enemies inside one field for 60 consecutive simulation ticks trigger one additional pulse at 30% damage. | Pressed Leaf, passive/8 |
| Hearth Voyager | Safe Return. Every third completed familiar orbit pushes enemies outward. No added healing, shield, or invulnerability. | Travel Mug, passive/11 |
| Ash Pianist | Held Note. Each 30 stationary ticks banks one note, up to three. The next starter cast consumes the full bank for +75% damage. | Wideglass Lens, passive/2 |
| Sunlit Stepper | Footwork Trail. Walking places delayed marks. Pending marks survive until their first pulse. | Street Soles, passive/5 |
| Swanward | Reprise. The fan can hit once on each leg. A returning hit against its own outgoing mark deals +30% damage. | Lacquer Guard, passive/6 |
| Sepia Wanderer | Double Exposure. A radial cast echoes once after 27 ticks at its saved origin, rotated by half its spacing, at half damage. | Flight Feather, passive/12 |
| Gilt Hare | Clean Combo. Three distinct starter projectiles hitting within 120 ticks trigger one piercing punch. The punch earns no credit. | Flight Feather, passive/12 |

These mechanics apply to the character's personal starter, not every acquired weapon with the same effective projectile type. Existing numeric IDs and profile ownership remain stable. No new controls are introduced.

Collected Thoughts requires a continuous crowd count of at least three. Falling below three resets the timer. Individual enemy identities may change while the count remains sufficient. Stationary charging uses actual displacement, including a player stopped against an arena boundary. Pause and reward menus do not advance simulation timers. Death clears personal progress before revival. Additional familiars do not multiply Safe Return orbit credit.

## Architecture decision

Two independent designs inspected the shared solo and co-op combat pipeline. Both chose nested player and projectile state over external identity maps. An independent judge preferred candidate B's scheduling and serialization design, combined with candidate A's shared reducer seams and mechanic edge cases.

Personal mechanic state follows `RS.PlayerState`. Projectile state follows the projectile lifetime. Source player, loadout weapon, cast receipt, and bonus provenance distinguish personal casts from evolved secondary attacks. Delayed volleys capture their origin and emission parameters. Contact settlement uses the authoritative contact plans shared by solo and co-op.

The alternatives were an external match registry and separate ECS components. The registry would duplicate lifecycle authority across solo and co-op. Separate components would add schema machinery before delivering the seven behaviors. Nested state preserves the existing ownership model.

The finite fan survives exhausted outgoing pierce until its return begins. Its return has its own budget and hit ledger. Familiar orbit progress belongs to the owner because a familiar projectile's existing lifetime is shorter than three orbits.

Echoes keep a bounded ledger of unfulfilled angles. At tick 27, the oldest due volley receives allocation priority. If capacity is blocked, it retries on later simulation ticks without duplicating accepted angles. Eight pending volleys temporarily stop new personal Waking Frame casts until space returns. Evolved Waking Frame captures only the admitted radial spokes, excluding its secondary strikes.

Evolved Afterbeat keeps movement-triggered marks and adds periodic Gathering Ink fields. Its wording describes these two schedules instead of claiming strict alternation. Weapon-level projectile-count bonuses increase the armed-mark cap along with item bonuses, up to eight.

## Verification record

The final gameplay revision is `60574e4`. Both independent review axes have zero remaining findings; see [the review record](SEVEN_MECHANICS_REVIEW.md).

- 58 Bend mechanic checks passed: 27 policy, 23 integration, and eight review regressions.
- All 63 Bend proof entrypoints passed.
- All 22 TypeScript tests, typechecking, lint, and formatting of changed TypeScript files passed.
- Roster migration (12 checks), character kits (10 checks), native/browser catalog parity, and actual four-player starter firing passed.
- A fresh browser build compiled the changed Bend backends. Live browser checks selected and played all seven characters, verified starter icons, movement through all eight walk poses, return to idle, and no browser errors. Mobile checks verified all seven mechanic descriptions and no horizontal overflow.
- The native executable built and launched. Its menu showed the installed names and icons; starting, movement, and normal window closure worked.
- Icon regeneration matched the checked-in browser and native geometry.

The repository-wide formatting command still reports the pre-existing generated `survivor-walk-shapes.mts` formatting difference, unchanged from the review baseline. This change does not reformat that unrelated generated file.

The full native complete-run check did not finish within its existing 900-second wall limit (exit 124). Its last checkpoint was tick 28,800, level 24, HP 186, and 3,834 kills, with boss, chest, level-up, and evolved-weapon observations all present. It reported no gameplay assertion failure before cancellation. The required terminal state at ticks 36,000–37,000 remains unverified. This result is a verification gap, not a complete-run pass; no performance comparison with the baseline was made.

### Open verification issue: complete native run

Re-run `npm run test:full-game:manual` on the target native environment and confirm its terminal-state assertion. If the same wall limit prevents completion, investigate native/controller execution cost against the review baseline before changing the limit. Keep the terminal-state assertion intact. Browser checks and the focused mechanic regressions do not close this issue.
