# Character names, icons and ability matrix

Research date: 2026-10-26. This is a design study. No production names, icons, recipes or abilities were changed.

The reviewed visual direction is filled vector style A. All geometry is authored in Bend. The study includes 24 base weapon icons, 18 existing shared relic icons, and seven personal object motifs. The personal motifs express innates; they do not create a seven-item inventory system.

## Naming evidence and limits

The familiar-handle column records direct artist or fan usage. It is not an availability claim. The game-epithet column contains screened working candidates; recognition from those words alone is untested. No candidate has received trademark clearance. JOONIE also names an [active unrelated brand](https://www.joonie.kr/), so a familiar fan nickname is not automatically a clean route.

The [USPTO describes a clearance search across related marks and goods or services](https://www.uspto.gov/trademarks/search/comprehensive-clearance-search-similar-trademarks). [WIPO notes that its database does not remove the need to check national or regional registers](https://www.wipo.int/en/web/global-brand-database/index). This study performed limited exact-phrase web collision screening, not that broader work.

Rejected candidates include Petalguard, Velvet Drifter, Giltbound, Velvet Aperture, Sidewalk Sun and Quiet Curator because visible products or creator identities already use those names. The individual studies link the evidence.

## Seven-character matrix

| Reference | Familiar handle, status unknown | Working game name | Personal object motif | Starter wording | Innate wording | New mechanic proposal |
| --- | --- | --- | --- | --- | --- | --- |
| RM | Joonie / Joon | Grove Scribe | Leaf Journal | Gathering Ink, weapon/20 | Open Attention: Experience pickup radius +50%. | Collected Thoughts |
| Jin | Jinnie / Jjan | Hearth Voyager | Hearth Lantern | Hearth Orbit, weapon/21 | Warm Welcome: Regenerate 1 health per second. | Safe Return |
| SUGA | Yoongi | Ash Pianist | Quiet Keys | Pressure Break, weapon/14 | Quiet Power: Weapon damage +20%. | Held Note |
| j-hope | Hobi | Sunlit Stepper | Street Sole | Afterbeat, weapon/22 | Light Feet: Movement speed +15%. | Footwork Trail |
| Jimin | Mimi / Mochi | Swanward | Silver Fan | Silk Return, weapon/8 | Poised Guard: Armor +1. | Reprise |
| V | TaeTae | Sepia Wanderer | Pocket Frame | Waking Frame, weapon/23 | Loose Time: Weapon cooldown -10%. | Double Exposure |
| Jung Kook | Kookie / Koo | Gilt Hare | Training Wrap | Forward Drive, weapon/1 | Tempered Heart: Weapon damage +10%. Base maximum health: 125. | Clean Combo |

Primary evidence, collision observations and alternative candidates are in [RM and Jin](character-studies/rm-jin.md), [SUGA and j-hope](character-studies/suga-jhope.md), and [Jimin, V and Jung Kook](character-studies/jimin-v-jungkook.md). The invented epithets are design inferences, not artist self-descriptions. The personal RM notebook is displayed as Leaf Journal to distinguish it from the actual shared passive Pressed Leaf; this is a wording alias for the reviewed notebook drawing.

## Current recipes and proposed changes

A held mascot, a personal motif, a shared relic and a run charm are separate concepts. Current evolution partners overlap. Changing a displayed word does not authorize silently changing a recipe.

| Starter | Current actual partner | Proposed partner | Scope |
| --- | --- | --- | --- |
| RM, weapon/20 | passive/8, KOYA Focus: Experience pickup radius +25% per rank. | passive/8, Pressed Leaf | Retain current recipe. |
| Jin, weapon/21 | passive/10, TATA Curiosity: Luck +10% per rank, improving normal enemy gold and healing drops. | passive/11, Travel Mug | Optional recipe and balance change, not applied. |
| SUGA, weapon/14 | passive/2, Gallery Lens: Weapon and effect area +10% per rank. | passive/2, Wideglass Lens | Retain current recipe. |
| j-hope, weapon/22 | passive/3, Long Encore: Weapon duration +15% per rank. | passive/5, Street Soles | Optional recipe and balance change, not applied. |
| Jimin, weapon/8 | passive/10, TATA Curiosity: Luck +10% per rank, improving normal enemy gold and healing drops. | passive/6, Lacquer Guard | Optional recipe and balance change, not applied. |
| V, weapon/23 | passive/12, Golden Tempo: Projectile speed +15% per rank. | passive/12, Flight Feather | Retain current recipe. |
| Jung Kook, weapon/1 | passive/12, Golden Tempo: Projectile speed +15% per rank. | passive/12, Flight Feather | Retain current recipe. |

## New mechanic priorities

Prototype Footwork Trail first, then Reprise. They change routing and return-path decisions rather than only multiplying damage. Held Note is the next candidate if stillness can remain a meaningful risk. These are starting hypotheses, not implemented or playtested balance.

### 1. j-hope: Footwork Trail

Draw the fight with your route and let pursuers meet the delayed beat.

Replace periodic placement with one mark per 40 world units traveled at baseline cooldown. Cooldown bonuses reduce this threshold with a 24-unit floor. Keep the existing first pulse at age 25 and later pulses every 45 ticks. Pending marks cannot be evicted before their first pulse. Bound the pending queue at eight per owner; when full, suppress placement and cap carried distance at one placement threshold. After a mark pulses, promote it to the armed pool. Start with three armed marks per owner; projectile-count bonuses raise that cap, up to eight. Evict only the oldest already-pulsed mark. Teleports add no trail distance.

Required Bend state. Per-player actual movement, bounded pending and armed mark queues, and first-pulse state. No client animation counter enters game logic.

Current-mechanic tooltip. "Leaves beat marks at your position. They arm after a delay and pulse at nearby enemies."

[Primary creative reference](https://magazine.weverse.io/article/view/1308?lang=en). [Nickname usage evidence](https://weverse.io/bts/live/2-159709015).

### 2. Jimin: Reprise

Set up the outward arc and reposition for the return.

Outgoing hits mark enemies for that owner and cast. The same fan consumes its own marks on return for +30% damage once per marked enemy. Give the fan separate bounded outgoing and returning hit sets and pierce budgets, permitting at most one hit per enemy on each leg. The current lifetime-wide visited filter must change for this attack; adding marks alone is insufficient. Marks expire with the cast; other players and later casts cannot consume them.

Required Bend state. Owner/cast/enemy marks, separate per-leg hit ledgers and bounded pierce budgets, and one return-consumption flag per mark.

Current-mechanic tooltip. "A silver fan flies out and returns through enemies."

[Primary creative reference](https://magazine.weverse.io/article/view/56?lang=en). [Nickname usage evidence](https://weverse.io/bts/fanpost/0-104434870).

### 3. SUGA: Held Note

Choose a dangerous moment of stillness, then release pressure.

Each 30 consecutive stationary simulation ticks stores one note, up to three. Movement resets the partial stillness timer but preserves earned notes. Regular automatic casts do not consume one or two notes. Once three are stored, the next starter cast consumes all three once for +75% damage on that cast. No storage during pause, menus or death; death clears the bank. No charge-input button.

Required Bend state. Per-player consecutive-stillness timer, capped note bank, and one consumed receipt per starter cast.

Current-mechanic tooltip. "Throws a sound charge that explodes after a short delay."

[Primary creative reference](https://magazine.weverse.io/article/view/819?lang=en). [Nickname usage evidence](https://weverse.io/bts/fanletter/3-222972051).

### 4. RM: Collected Thoughts

Gather a scattered crowd into one deliberate composition.

A field that holds at least three enemies for 60 ticks releases one finishing pulse at 30% of its base damage. One pulse per field; the pulse cannot trigger itself.

Required Bend state. Per-field captured-enemy timer and one resolved flag.

Current-mechanic tooltip. "Ink fields pull enemies inward and repeatedly damage the chosen area."

[Primary creative reference](https://magazine.weverse.io/article/view/639?artist=BTS&lang=en). [Nickname usage evidence](https://www.wired.com/video/watch/google-autocomplete-interviews-bts-bangtansonyeondan-answer-the-webs-most-searched-questions).

### 5. V: Double Exposure

Leave an echo in a place you have already abandoned.

A radial cast leaves a frame at its cast origin. After 27 ticks, it emits one second volley rotated by half the original volley spacing at 50% base damage. The echo stays at the recorded origin and cannot create another echo.

Required Bend state. Bounded delayed cast event with owner, origin, angle, damage and a non-echo flag.

Current-mechanic tooltip. "Frames fire projectiles outward in several directions."

[Primary creative reference](https://magazine.weverse.io/article/view/436?lang=en). [Nickname usage evidence](https://weverse.io/bts/fanpost/0-103714295).

### 6. Jin: Safe Return

Carry a small sense of home through hostile space.

Every third completed familiar orbit releases one short outward knockback pulse. It grants no shield or invulnerability and does not heal beyond the existing innate.

Required Bend state. Owner-specific completed-orbit count; one pulse per third orbit.

Current-mechanic tooltip. "An orbiting light strikes nearby enemies and fires homing sparks."

[Primary creative reference](https://magazine.weverse.io/article/view/571?artist=BTS&lang=en). [Nickname usage evidence](https://www.wired.com/video/watch/google-autocomplete-interviews-bts-bangtansonyeondan-answer-the-webs-most-searched-questions).

### 7. Jung Kook: Clean Combo

Keep a clean line through the crowd and earn a stronger follow-through.

Three successful starter-projectile hits within 120 ticks trigger one piercing straight punch at base starter damage. Each projectile earns at most one combo credit; the bonus punch earns none. Reset on expiry or death and keep counters per owner.

Required Bend state. Owner-specific three-hit counter, expiry tick and credited projectile identity.

Current-mechanic tooltip. "Fast gold streaks fire in your movement direction."

[Primary creative reference](https://magazine.weverse.io/article/view/433?lang=en). [Nickname usage evidence](https://weverse.io/bts/fanpost/4-122878021).

Each prototype must preserve deterministic simulation ticks, pause behavior, damage ownership and co-op player isolation. Delayed attacks retain their owner and cast identity. Bonus emissions cannot recursively trigger themselves. Cooldown, projectile count, duration and area upgrades must still have explicit effects. Animation distance in TypeScript is presentation state and must never become the authority for a Bend gameplay mechanic.

## Shared catalog wording

IDs, current effects and recipes below are baseline facts from the generated catalog. Proposed wording is draft copy. All proposed names have unknown trademark status. New evolution names are presentation proposals; they do not claim new evolved mechanics.

### Base weapons

| ID | Current name | Proposed wording | Tooltip |
| --- | --- | --- | --- |
| 0 | Starlight Letter | Guiding Letter | Homing letters seek the nearest enemy. |
| 1 | Golden Rush | Forward Drive | Fast gold streaks fire in your movement direction. |
| 2 | Vinyl Arc | Vinyl Arc | Throws records in an arc through enemies. |
| 3 | Moon Orbit | Moon Orbit | Moon discs orbit you and damage nearby enemies. |
| 4 | Warm Hearth | Hearth Glow | Damages enemies in a small aura around you. |
| 5 | Spotlight Snap | Stage Flash | Places short-lived strikes at targeted enemy positions. |
| 6 | Red Verse | Burning Verse | Fires piercing verses that burn enemies. |
| 7 | Indigo Rain | Ink Rain | Creates persistent damaging ink pools. |
| 8 | Mirror Fan | Silk Return | A silver fan flies out and returns through enemies. |
| 9 | Poem Fragment | Scattered Lines | Creates damaging paper fields around you. |
| 10 | Quiet Reflection | Quiet Reflection | Fires aimed mirror shards that slow enemies on hit. |
| 11 | Final Bow | Curtain Flash | An infrequent flash damages enemies across a large area. |
| 12 | Ribbon Sweep | Ribbon Sweep | Sweeps a wide ribbon through enemies ahead of you. |
| 13 | Practice Line | Practice Thrust | Thrusts a long gold strike in your movement direction. |
| 14 | D-DAY Release | Pressure Break | Throws a sound charge that explodes after a short delay. |
| 15 | Shadow Verse | Shadow Verse | Fires piercing sound blades in several directions. |
| 16 | SHOOKY Mischief | Mischief Crumb | Homing crumbs chase nearby enemies. |
| 17 | Astronaut Comet | Homeward Comet | Drops comets that explode after a short delay. |
| 18 | Stage Beam | Spotlight Lance | Fires a fast piercing beam along a line. |
| 19 | Leaf Orbit | Garden Orbit | Leaves orbit you and damage nearby enemies. |
| 20 | Indigo Composition | Gathering Ink | Ink fields pull enemies inward and repeatedly damage the chosen area. |
| 21 | Home Star | Hearth Orbit | An orbiting light strikes nearby enemies and fires homing sparks. |
| 22 | Street Beat | Afterbeat | Leaves beat marks at your position. They arm after a delay and pulse at nearby enemies. |
| 23 | Dream Frame | Waking Frame | Frames fire projectiles outward in several directions. |

| Weapon ID | Current evolution name | Proposed evolution name | Actual proposed description |
| --- | --- | --- | --- |
| 0 | Constellation Letter | Guiding Constellation | Alternates Guiding Letter with Stage Flash. Damage +120%; area +35%. |
| 1 | Golden Overdrive | Gilt Overdrive | Alternates Forward Drive with Practice Thrust. Damage +120%; area +35%. |
| 2 | Midnight Rotation | Midnight Rotation | Alternates Vinyl Arc with Shadow Verse. Damage +120%; area +35%. |
| 3 | Astronaut Halo | Lunar Parade | Alternates Moon Orbit with Waking Frame. Damage +120%; area +35%. |
| 4 | Homecoming Glow | Homecoming Glow | Alternates Hearth Glow with Garden Orbit. Damage +120%; area +35%. |
| 5 | Stage Thunder | Stage Thunder | Alternates Stage Flash with Guiding Letter. Damage +120%; area +35%. |
| 6 | Agust Inferno | Cinder Canticle | Alternates Burning Verse with Homeward Comet. Damage +120%; area +35%. |
| 7 | Namjooning Rain | Collected Rain | Alternates Ink Rain with Gathering Ink. Damage +120%; area +35%. |
| 8 | MUSE Reflection | Silver Reprise | Alternates Silk Return with Scattered Lines. Damage +120%; area +35%. |
| 9 | Indigo Manuscript | Living Manuscript | Alternates Scattered Lines with Waking Frame. Damage +120%; area +35%. |
| 10 | FACE Stillness | Stillwater Glass | Alternates Quiet Reflection with Stage Flash. Damage +120%; area +35%. |
| 11 | Encore Sky | Encore Sky | Alternates Curtain Flash with Homeward Comet. Damage +120%; area +35%. |
| 12 | Silk Crescendo | Silk Crescendo | Alternates Ribbon Sweep with Hearth Glow. Damage +120%; area +35%. |
| 13 | Perfect Take | Perfect Take | Alternates Practice Thrust with Silk Return. Damage +120%; area +35%. |
| 14 | Agust Storm | Pressure Storm | Alternates Pressure Break with Homeward Comet. Damage +120%; area +35%. |
| 15 | Daechwita Echo | Night Resonance | Alternates Shadow Verse with Vinyl Arc. Damage +120%; area +35%. |
| 16 | Cookie Chorus | Crumb Chorus | Alternates Mischief Crumb with Burning Verse. Damage +120%; area +35%. |
| 17 | Homeward Meteor | Homeward Meteor | Alternates Homeward Comet with Pressure Break. Damage +120%; area +35%. |
| 18 | Golden Spotlight | Gilt Spotlight | Alternates Spotlight Lance with Scattered Lines. Damage +120%; area +35%. |
| 19 | Museum Garden | Museum Garden | Alternates Garden Orbit with Hearth Glow. Damage +120%; area +35%. |
| 20 | Order in Chaos | Quiet Composition | Alternates Gathering Ink with Moon Orbit. Damage +120%; area +35%. |
| 21 | RJ Constellation | Traveling Hearth | Orbiting lights fire homing sparks and add targeted slowing strikes. Damage +120%; area +35%. |
| 22 | HOPE Block Party | Street Crescendo | Alternates Afterbeat with Gathering Ink. Damage +120%; area +35%. |
| 23 | TATA Dreamscape | Waking Gallery | Alternates Waking Frame with Stage Flash. Damage +120%; area +35%. |

### Shared relics

| ID | Current name | Proposed wording | Tooltip |
| --- | --- | --- | --- |
| 0 | GOLDEN Drive | Drive Weight | All weapon damage +10% per rank. |
| 1 | Beat Clock | Pocket Metronome | Attack cooldown -7% per rank. |
| 2 | Gallery Lens | Wideglass Lens | Weapon and effect area +10% per rank. |
| 3 | Long Encore | Silk Spool | Weapon duration +15% per rank. |
| 4 | Harmony Split | Split Fork | One additional projectile per rank. |
| 5 | Dance Sneakers | Street Soles | Movement speed +10% per rank. |
| 6 | Mirror Guard | Lacquer Guard | Reduces incoming damage by 1 per rank. |
| 7 | Warm Heart | Hearth Locket | Maximum health +20% per rank. |
| 8 | KOYA Focus | Pressed Leaf | Experience pickup radius +25% per rank. |
| 9 | Lyric Notebook | Field Notebook | Experience gained +10% per rank. |
| 10 | TATA Curiosity | Odd Die | Luck +10% per rank, improving normal enemy gold and healing drops. |
| 11 | RJ Comfort | Travel Mug | Regenerates 1 health per second per rank. |
| 12 | Golden Tempo | Flight Feather | Projectile speed +15% per rank. |
| 13 | Second Encore | Spare Wick | One additional full-health revival per rank. |
| 14 | Jack in the Box | Restless Box | Enemy health and count +10% per rank; experience and gold +10% per rank. |
| 15 | Platinum Record | Gilt Record | Gold gained +15% per rank. |
| 16 | Bass Pulse | Bass Cabinet | Enemy knockback +15% per rank. |
| 17 | Home Cooking | Steam Bowl | Healing from pickups and regeneration +20% per rank. |

### Run charms

| ID | Current name | Proposed wording | Tooltip |
| --- | --- | --- | --- |
| 0 | FACE of Glass | Glass Resolve | Might +35%, maximum health -30%. |
| 1 | Street Metronome | Street Metronome | Attack cooldown -20%, area -15%. |
| 2 | Indigo Gallery | Open Gallery | Area +35%, movement speed -15%. |
| 3 | Duet Reflection | Duet Reflection | Projectile count +1, attack cooldown +15%. |
| 4 | Mirror Resolve | Mirror Resolve | Armor +3, might -15%. Taking damage releases protective orbiting leaves, even without Leaf Orbit equipped. |
| 5 | Unwritten Verse | Unwritten Verse | Experience +30%; enemy health and count +20%. Poem Fragment and Final Bow gain 20% damage, plus 5% per Jack in the Box rank. |
| 6 | Cosmic Hospitality | Cosmic Hospitality | Pickup radius +100%, gold +25%. |
| 7 | D-DAY Ember | Banked Ember | Duration +50%, projectile speed -20%. Burns last twice as long and deal double damage per tick. |
| 8 | Golden Trajectory | Gilt Trajectory | Projectile speed +50%, might +15%. Traveling projectiles ricochet from the world boundary. |
| 9 | Namjooning | Garden Rest | Regenerates 2 health per second; maximum health +25%. With Warm Hearth or Leaf Orbit equipped, kills on periodic life-steal pulses restore 1 health each. |
| 10 | Hopeful Footwork | Hopeful Footwork | Movement speed +30%, healing received +30%. |
| 11 | Composition of Wind | Composition of Wind | Knockback +75%, area +15%. Vortex pull strength increases from 3 to 7. |

Run charms have draft wording only. Their twelve icons, ten permanent-upgrade icons, six union icons, five stage-relic icons, and distinct evolved artwork remain later scope. This study does not claim to replace every icon-bearing subsystem.

## Visual iteration and integration contract

1. Keep the current glyph and actual mechanic beside each proposed object.
2. Author shape, color and geometry in Bend on a shared 32-unit canvas with two-unit padding and consistent contours.
3. Compare filled A and etched B before expanding. A was independently recommended because its solid masses survive 20/24px display.
4. Review an unlabelled shuffled sheet before revealing names. Record object readability separately from mechanic meaning and fan association.
5. Inspect 16/20/24/32px vectors and 34px HUD slots with rank overlays. Sixteen pixels is a fallback, not an exact-object guarantee.
6. Revise concrete failures. Pressure changed from flame-like to split keys, the footprint gained a diagonal sole, the beam gained a horizontal emitter, and the record gained a visible label.
7. Retain source snapshots, artifact hashes and independent findings. Finite bounds checks do not establish recognition or aesthetics.
8. Integrate a future reviewed selection through a kind-and-ID icon helper. Do not insert raw SVG into catalog icon strings; some consumers escape those strings and others render markup.

Browser consumers include starter badges, cards, loadouts, collections and co-op rewards. Native currently uses text labels and needs explicit icon drawing and layout space. Generate native draw geometry from the same Bend source so native launch still requires no Node.js.

Rebuild the study with `python3 tools/icon-lab/study-build.py`. Component commands and review histories are in [the personal icon lab](../../tools/icon-lab/README.md), `tools/icon-lab/pool-README.md`, and `tools/icon-lab/weapon-README.md`. The machine-readable matrix is [study-matrix.json](../../tools/icon-lab/study-matrix.json).

## Wording audit finding

`arcana/9` describes one base health per qualifying kill, and `game.bend:882` implements one before healing multipliers. Its unused catalog synergy metadata says `healthPerKill: 2`. Keep the correct tooltip and track the metadata discrepancy for a separate verified content correction. No gameplay behavior was changed here.

## Future mechanic acceptance cases

These are requirements for later Bend prototypes, not tests that have already passed.

- A pending Footwork Trail mark always reaches its first pulse at age 25, including after movement-speed and cooldown upgrades. Queue sizes remain bounded and suppressing placement cannot build an unbounded catch-up burst.
- Reprise can hit the same enemy once on each leg and consumes only marks from its own owner and cast. Returning contacts are not blocked by the old lifetime-wide visited list. Both leg budgets remain finite.
- Held Note reaches three notes while the starter continues firing automatically, including with cooldown upgrades. One or two stored notes survive ordinary casts. Movement resets the partial timer, pause freezes it, and death clears the bank.
- All delayed emissions retain ownership, cannot trigger themselves recursively, and respect deterministic pause and co-op isolation.
