# Thematic roster and progression pool

This is the authored mapping for the seven-character theme supplied by the user. Character IDs 0 through 6 keep the existing progression slots. Weapon, passive, evolution, union and permanent-upgrade IDs retain their mechanical meanings. The old eighth character is retired.

## Character contracts

| ID | Character | Starting attack | Automatic mechanic | Innate bonus |
| --- | --- | --- | --- | --- |
| 0 | Grove Scribe | 20: Gathering Ink | Collected Thoughts | Experience pickup radius +50%. |
| 1 | Hearth Voyager | 21: Hearth Orbit | Safe Return | Regenerate 1 health per second. |
| 2 | Ash Pianist | 14: Pressure Break | Held Note | Weapon damage +20%. |
| 3 | Sunlit Stepper | 22: Afterbeat | Footwork Trail | Movement speed +15%. |
| 4 | Swanward | 8: Silk Return | Reprise | Armor +1. |
| 5 | Sepia Wanderer | 23: Waking Frame | Double Exposure | Weapon cooldown -10%. |
| 6 | Gilt Hare | 1: Forward Drive | Clean Combo | Weapon damage +10%. Base maximum health: 125. |

All attacks and personal mechanics activate automatically. See [the approved mechanic contracts](../../docs/design/SEVEN_MECHANICS_IMPLEMENTATION.md) for charge, trail, return, echo, orbit, and combo rules. The personal object motifs describe innates and do not add inventory slots.

## Weapon and evolution mapping

Evolution requirements and secondary attacks use the existing IDs. Every weapon reaches level 8 and requires at least level 1 of its paired passive before a chest can evolve it. The evolution adds 120% damage and 35% area.

| ID | Weapon | Evolution | Required passive ID | Secondary attack ID |
| --- | --- | --- | --- | --- |
| 0 | Guiding Letter | Guiding Constellation | 1 | 5 |
| 1 | Forward Drive | Gilt Overdrive | 12 | 13 |
| 2 | Vinyl Arc | Midnight Rotation | 2 | 15 |
| 3 | Moon Orbit | Lunar Parade | 4 | 23 |
| 4 | Hearth Glow | Homecoming Glow | 11 | 19 |
| 5 | Stage Flash | Stage Thunder | 4 | 0 |
| 6 | Burning Verse | Cinder Canticle | 0 | 17 |
| 7 | Ink Rain | Collected Rain | 3 | 20 |
| 8 | Silk Return | Silver Reprise | 6 | 9 |
| 9 | Scattered Lines | Living Manuscript | 3 | 23 |
| 10 | Quiet Reflection | Stillwater Glass | 1 | 5 |
| 11 | Curtain Flash | Encore Sky | 9 | 17 |
| 12 | Ribbon Sweep | Silk Crescendo | 7 | 4 |
| 13 | Practice Thrust | Perfect Take | 12 | 8 |
| 14 | Pressure Break | Pressure Storm | 2 | 17 |
| 15 | Shadow Verse | Night Resonance | 0 | 2 |
| 16 | Mischief Crumb | Crumb Chorus | 4 | 6 |
| 17 | Homeward Comet | Homeward Meteor | 2 | 14 |
| 18 | Spotlight Lance | Gilt Spotlight | 3 | 9 |
| 19 | Garden Orbit | Museum Garden | 6 | 4 |
| 20 | Gathering Ink | Quiet Composition | 8 | 3 |
| 21 | Hearth Orbit | Traveling Hearth | 11 | 5 |
| 22 | Afterbeat | Street Crescendo | 5 | 20 |
| 23 | Waking Frame | Waking Gallery | 12 | 5 |

## Passive upgrades

| ID | Name | Effect |
| --- | --- | --- |
| 0 | Drive Weight | All weapon damage +10% per rank. |
| 1 | Pocket Metronome | Attack cooldown -7% per rank. |
| 2 | Wideglass Lens | Weapon and effect area +10% per rank. |
| 3 | Silk Spool | Weapon duration +15% per rank. |
| 4 | Split Fork | One additional projectile per rank. |
| 5 | Street Soles | Movement speed +10% per rank. |
| 6 | Lacquer Guard | Reduces incoming damage by 1 per rank. |
| 7 | Hearth Locket | Maximum health +20% per rank. |
| 8 | Pressed Leaf | Experience pickup radius +25% per rank. |
| 9 | Field Notebook | Experience gained +10% per rank. |
| 10 | Odd Die | Luck +10% per rank, improving normal enemy gold and healing drops. |
| 11 | Travel Mug | Regenerates 1 health per second per rank. |
| 12 | Flight Feather | Projectile speed +15% per rank. |
| 13 | Spare Wick | One additional full-health revival per rank. |
| 14 | Restless Box | Enemy health and count +10% per rank; experience and gold +10% per rank. |
| 15 | Gilt Record | Gold gained +15% per rank. |
| 16 | Bass Cabinet | Enemy knockback +15% per rank. |
| 17 | Steam Bowl | Healing from pickups and regeneration +20% per rank. |

## Permanent upgrades

| ID | Name | Effect |
| --- | --- | --- |
| 0 | Daily Practice | Damage +5% per rank. |
| 1 | Stamina Training | Maximum health +10% per rank. |
| 2 | After-show Rest | Regenerates 1 health per second per rank. |
| 3 | Stage Resolve | Armor +1 per rank. |
| 4 | Metronome Study | Attack cooldown -3% per rank. |
| 5 | Footwork Practice | Movement speed +5% per rank. |
| 6 | Museum Attention | Pickup radius +15% per rank. |
| 7 | Poetry Journal | Experience +5% per rank. |
| 8 | Golden Keepsake | Gold +10% per rank. |
| 9 | Encore Promise | One additional revival per rank. |

## Arcana

| ID | Name | Effect |
| --- | --- | --- |
| 0 | Glass Resolve | Might +35%, maximum health -30%. |
| 1 | Street Metronome | Attack cooldown -20%, area -15%. |
| 2 | Open Gallery | Area +35%, movement speed -15%. |
| 3 | Duet Reflection | Projectile count +1, attack cooldown +15%. |
| 4 | Mirror Resolve | Armor +3, might -15%. Taking damage releases protective orbiting leaves, even without Garden Orbit equipped. |
| 5 | Unwritten Verse | Experience +30%; enemy health and count +20%. Scattered Lines and Curtain Flash gain 20% damage, plus 5% per Restless Box rank. |
| 6 | Cosmic Hospitality | Pickup radius +100%, gold +25%. |
| 7 | Banked Ember | Duration +50%, projectile speed -20%. Burns last twice as long and deal double damage per tick. |
| 8 | Gilt Trajectory | Projectile speed +50%, might +15%. Traveling projectiles ricochet from the world boundary. |
| 9 | Garden Rest | Regenerates 2 health per second; maximum health +25%. With Hearth Glow or Garden Orbit equipped, kills on periodic life-steal pulses restore 1 health each. |
| 10 | Hopeful Footwork | Movement speed +30%, healing received +30%. |
| 11 | Composition of Wind | Knockback +75%, area +15%. Vortex pull strength increases from 3 to 7. |

## Unions

Both weapons must be level 8 or 9. A chest creates the union and consumes the second weapon. The third attack ID remains the existing union emission.

| ID | Name | Weapon IDs | Third attack ID |
| --- | --- | --- | --- |
| 0 | Letter Ensemble | 0 + 5 | 16 |
| 1 | Golden Duet | 1 + 13 | 23 |
| 2 | Midnight Session | 2 + 15 | 3 |
| 3 | Slow Dancing Halo | 3 + 23 | 18 |
| 4 | Garden Rest Home | 4 + 19 | 20 |
| 5 | D-DAY Supernova | 6 + 17 | 14 |

## Source ownership and consistency

`menu-catalog.bend` is the browser content authority. Regenerate `content.mts` with the existing build script after editing it. `native-content.bend` supplies matching native names, descriptions and recipes. Both call `character-policy.bend` for starter IDs.

For another thematic pass, change display names and imagery while retaining the numeric contracts unless a gameplay change is intentional. Keep collections, evolution names, union recipes, arcana equipment references and relic hints synchronized. Compare native display strings against compiled catalog JSON. Do not hand-edit generated browser content.

The seven-character achievements require seven owned characters or seven distinct character wins. Numeric achievement IDs are preserved so already-earned achievements remain earned.

## Visual direction

The artist names below identify the original reference brief. In-game names use the approved epithets above.

Use the accepted Nightfall sprite proportions, shared eye dimensions, continuous outlines and the visual review loop in `skills/bend-sprite-art/SKILL.md`. Check both style consistency and reference fidelity. Theme does not justify changing every character into the same silhouette.

| Character | Palette and motifs |
| --- | --- |
| RM | Indigo ink, letters, leaves, restrained gallery forms; KOYA as a small motif. |
| Jin | Cream, moonlight and peach stars; cozy travel and RJ motifs. |
| SUGA | Black, red and pale highlights; smoke, sound and SHOOKY accents. |
| j-hope | Neon green and stage light; street movement, masks and beat marks. |
| Jimin | Pink, lavender and silver; mirrored fans, ribbons and precise arcs. |
| V | Muted mauve, burgundy and warm vintage tones; dream frames and TATA hearts. |
| Jung Kook | Gold, dark stage wear and pink accents; forward streaks and COOKY motifs. |

These are adaptation choices from the user brief. They are not claims that the game reproduces a particular real performance or physical likeness.

## Authority and validation

`character-policy.bend` owns roster bounds, starter IDs and innate values. The simulation, catalog, native admission and co-op boundary consume it. Menu and native text remain separate presentation catalogs; `theme-catalog-check.mts` checks their generated values against each other. This keeps combat independent of JSON serialization. A complete character registry was considered, but would require replacing both presentation serializers.

Personal starter weapons remain upgradeable during their owner's run even when the corresponding weapon is still locked in the global pool. This does not grant a permanent collection unlock.

Legacy saves preserve wallet, permanent upgrades, earned achievements, discoveries and receipts. Retired character ID 7 is removed from ownership and win sets. Current character counts are recomputed; invalid selections fall back to Grove Scribe.

Run the native catalog parity check after compiling the current native content module:

```sh
bend examples/survivors/native-content.bend -o /tmp/nightfall-native-content.mjs
node examples/survivors/theme-catalog-check.mts /tmp/nightfall-native-content.mjs
```

Static art uses the accepted Nightfall mathematical face, contour and rig, with explicitly changed thematic palettes. See `tools/sprite-lab/THEME.md` for reproducible export. The current in-game motion uses the shared eight-frame Bend walk catalog, driven by actual travel and returning to selected idle when stopped. It remains front-facing for all travel directions. See `tools/sprite-lab/walk-README.md`.

The user-selected D accessories are integrated through the shared sprite export. RM carries KOYA, Jin RJ, SUGA SHOOKY, j-hope masked MANG, Jimin CHIMMY, V TATA and Jung Kook COOKY. The selection fixes placement and construction; it does not imply that every tiny face passes reference-fidelity review. `theme-selection.json` pins the approved artwork and the exporter checks it before changing production shapes.
