# Character studies: the quiet producer and the street dancer

Mechanic follow-up: the consolidated [character matrix](../CHARACTER_ABILITY_MATRIX.md) supersedes the initial mechanic sketches below. It adds protected pending trail marks, separate fan hit ledgers, and full-bank-only note consumption after code review. The artist-source findings remain unchanged.

Research date: 2026-10-27. These are design proposals for the private themed mod. Nothing in this document changes production names, abilities, or item IDs.

The proposed names are original descriptive game epithets, not asserted existing fan nicknames. Their intended fan associations have not been tested with fans. Exact-phrase web searches identify obvious collisions only. No registry clearance, jurisdiction-specific assessment, or claim that a name is unregistered has been made.

## Familiar handles and the naming tradeoff

| Source inspiration | Familiar handle supported by primary usage | Suggested display stack | What remains unknown |
| --- | --- | --- | --- |
| SUGA / Agust D | **Yoongi**. The official tour report explicitly identifies Min Yoongi alongside the other personas. A fan letter on Weverse also uses Min Yoongi to address SUGA. [Official tour report](https://magazine.weverse.io/article/view/819?lang=en), [direct fan-letter usage](https://weverse.io/bts/fanletter/3-222972051). | **Yoongi** as the recognition-first handle; **Ash Pianist** as the original subtitle. | Personal-name or fan usage does not establish trademark availability. Actual fan recognition of a particular UI spelling has not been tested. |
| j-hope | **Hobi**. Official Weverse LIVE search metadata labels the artist as “hobi” and j-hope. [Official LIVE page](https://weverse.io/bts/live/4-192319138); another official LIVE page uses the same artist identity. [Official LIVE page](https://weverse.io/bts/live/2-159709015). | **Hobi** as the recognition-first handle; **Sunlit Stepper** as the original subtitle. | Familiarity is supported by official usage, but trademark and name-rights status is unknown. |

For the user's fan-recognition goal, these handles are substantially less indirect than fantasy epithets alone. For a roster that avoids direct real-person names, retain only the original epithets and accept weaker recognition. Neither route is certified trademark-free. “Yoongles” was not adopted because this study did not establish an adequate primary usage source for that spelling.

## Recommended matrix

| Source inspiration | Proposed game nickname | Physical trinket and icon | Current attack wording and icon | Current innate wording and icon | New ability direction, not implemented |
| --- | --- | --- | --- | --- | --- |
| SUGA / Agust D | **Ash Pianist** | **Ivory Key**, a small unbranded piano-key charm. Three ivory keys and two short black keys form the silhouette; one restrained red accent connects it to the character palette. | **Pressure Break**. “Throws a sound charge that bursts after a delay, damaging an area.” Icon: a compact charge or piano key splitting into two broad shockwave wedges. | **Quiet Power**. “All weapon damage +20%.” Icon: one heavy key with a small red core. This describes character ID 2's existing innate bonus, not a new collectible effect. | **Held Note**. Brief safe stillness banks up to three echoes; the next automatic sound-charge explosion spends them for extra damage. No manual charge button. |
| j-hope | **Sunlit Stepper** | **Street Sole**, an unbranded dance sneaker charm. Raised heel, long toe, clear sole, and one bright lace panel. No manufacturer stripes or logo. | **Afterbeat**. “Leaves beat marks at your position. They arm after a delay and pulse at pursuers.” Icon: one footprint followed by a separate expanding ring. | **Light Feet**. “Movement speed +15%.” Icon: a lifted heel with two short motion strokes. This describes character ID 3's existing innate bonus. | **Footwork Trail**. Actual traveled distance lays delayed pulses. The player choreographs the trail through positioning; there is no rhythm-input judgement. |

The two sets differ in silhouette and feeling. The producer's vertical key and compressed burst suggest stored pressure. The dancer's horizontal shoe and separated trailing ring suggest travel and delayed consequences. A music note shared by both would erase this distinction.

## SUGA / Agust D

### Verified source anchors

BIGHIT's album page identifies SUGA as the writer of every track and overall producer of D-DAY. It describes Haegeum's use of the traditional Korean string instrument. This supports musician/producer objects and sound-based effects, without needing album lettering or a copied cover design. [BIGHIT MUSIC, D-DAY](https://bts.ibighit.com/eng/discography/suga/detail/d-day/).

The first-party tour report describes a progression through created personas toward liberation. Its staging gradually removes panels and exposes the underlying structure. It also documents SUGA playing a brown piano and a guitar signed by the members. The suggested ash and piano combination comes from these staging and instrument anchors; the source does not call him “Ash Pianist.” [Weverse Magazine, D-DAY world tour report](https://magazine.weverse.io/article/view/819?lang=en).

The official character page describes SHOOKY as a small prankster. That supports retaining some playfulness rather than treating the adaptation as a uniformly angry or bleak character. A face copied from SHOOKY is unnecessary for the new UI trinket. [BT21 character catalog](https://www.bt21.com/character).

### Naming candidates and collision screen

| Candidate | Intended association | Search observation | Decision |
| --- | --- | --- | --- |
| **Ash Pianist** | Piano plus the dismantled/burned stage; quiet musician with an intense release. | Exact-phrase search surfaced mostly partial-token results, including real pianist Steve Ash, rather than a clearly matching game-character brand. That nearby musician identity is still a naming caution. [Steve Ash's own biography](https://www.steveashpiano.com/bio). | Recommended provisional epithet. Association confidence is moderate when paired with the character art and key icon; untested alone. Not cleared. |
| **Quiet Cinder** | Restrained surface and residual heat. | No relevant exact-name commercial identity surfaced in the limited exact-phrase screen. The words themselves are common. | Usable fallback, but less specifically connected to the musician. Not cleared. |
| **Cinder Pianist** | A more literal combination of the same two visual anchors. | Search surfaced nearby composer/pianist identity “Cinder Music,” although not the full proposed phrase. [Creator profile](https://musescore.com/user/85322308). | Lower preference because of nearby musician naming and awkward spoken rhythm. Not cleared. |

A rejected exploration, **Ember Scribe**, surfaced an existing web identity at `theemberscribe.com`. It should not be represented as a clean candidate. “D-DAY,” “Agust D,” song titles, and mascot names are excluded from the recommended game epithet rather than treated as newly invented names.

### Vector construction and size gates

Draw the trinket as an object, with a loop or top attachment, not a rectangular keyboard screenshot. At 16 px, retain only the three-key outer silhouette, two black-key cuts, and one red core. At 24 px, add a single ivory highlight. At 32 px, a small chip or bevel may show wear. Do not depend on letters, a tiny staff, or individual glowing particles.

The ability icon must still identify an explosion when shown in one color. Keep the central charge large and give the two shockwave wedges open space. Do not use an exclamation mark or a generic starburst as the entire icon. The passive icon keeps the intact key; the attack icon breaks the same object apart. This creates a family without making the two slots indistinguishable.

### Current mechanics and honest wording

Character ID 2 starts with weapon 14. Its current catalog describes a thrown sound charge with a delayed area detonation; its innate is might +20%. There is no player-held charge meter, stillness bonus, or manually timed release. The proposed current tooltip deliberately promises only the implemented delay and area damage. [Local thematic contract](../../../examples/survivors/THEMATIC_ROSTER.md), [character policy](../../../examples/survivors/character-policy.bend), and [menu catalog](../../../examples/survivors/menu-catalog.bend).

The current evolution requires passive ID 2. The piano-key artwork must not silently change that recipe or pretend an innate bonus is a collectible. If a key icon is assigned to a common-pool item, its tooltip must use that item's own mechanical contract.

### Optional new mechanic: Held Note

Prototype rule, not implemented: after 0.4 seconds of continuous stillness, bank one echo every 0.4 seconds, up to three. The next automatic weapon-14 explosion consumes the bank and gains 20% damage per echo. Moving interrupts further banking but does not remove stored echoes. Taking damage clears the bank. Show three large red pips beside the attack icon rather than a second timing bar.

The intended play pattern is a brief deliberate pause in a safe pocket, followed by repositioning and release. Preserve the automatic attack. Test the risk of encouraging unsafe stationary play and ensure the ordinary attack remains useful at zero echoes. The numerical values are starting hypotheses, not balanced specifications.

## j-hope

### Verified source anchors

BIGHIT explicitly frames HOPE ON THE STREET VOL.1 around j-hope's street-dance roots and ties it to a documentary exploring that identity. This is a stronger foundation for a shoe, floor mark, or portable sound object than a generic sunshine badge. [BIGHIT MUSIC, HOPE ON THE STREET VOL.1](https://bts.ibighit.com/eng/discography/j-hope/detail/hope-on-the-street/index.html).

The official Jack In The Box page describes the desire to move beyond an established mold. It pairs stories inside and outside the box. This supports a bright/dark contrast, but does not require copying the album title or packaging into the game. [BIGHIT MUSIC, Jack In The Box](https://bts.ibighit.com/eng/discography/j-hope/detail/jack-in-the-box/index.html).

The first-party interview emphasizes continued creativity and the practical attention he puts into performances. The game translation should therefore make deliberate movement matter, rather than claiming the current periodic trap is already a dance-combo system. [Weverse Magazine, j-hope interview](https://magazine.weverse.io/article/view/1308?lang=en).

The official BT21 page associates MANG with dancing and a mysterious mask. This supports movement and theatrical duality as secondary anchors. The sneaker proposal does not copy MANG's face, mask, or heart-shaped mouth. [BT21 character catalog](https://www.bt21.com/character).

### Naming candidates and collision screen

| Candidate | Intended association | Search observation | Decision |
| --- | --- | --- | --- |
| **Sunlit Stepper** | Bright stage presence plus physical footwork. “Sunlit” is our metaphor, not a verified official nickname. | Limited exact-phrase searches, including a game qualifier, surfaced no relevant exact-name commercial identity. | Recommended provisional epithet. Stronger with shoe/trail imagery than on its own. Fan recognition and clearance remain unverified. |
| **Daylight Freestyler** | Optimism and expressive dance. | Limited exact-phrase searches surfaced no relevant exact-name commercial identity. | More explicit about dance, but longer and less compact in the character picker. Not cleared. |
| **Pavement Spark** | Street roots plus energetic ignition. | Searches surfaced literal pavement/spark discussions and unrelated software terminology, not an obvious exact-name game identity. | More compact fallback; weaker association with a person. Not cleared. |

Reject **Sidewalk Sun** as a clean candidate because an existing 2023 music release uses the exact title. [Apple Music release page](https://music.apple.com/mx/album/sidewalk-sun-ep/1713627548). Reject **Daybreak Dancer** because the phrase already names commercial music and other subjects. [Music seller's own catalog](https://www.audiosparx.com/sa/archive/Dramatic/Whimsical-Music/Daybreak-Dancer/327052). These are collision observations, not findings that the phrases are legally protected or prohibited.

### Vector construction and size gates

The shoe needs a readable heel-to-toe axis, an inset dark ankle opening, and a continuous light sole. At 16 px, remove laces and retain the toe/heel distinction. At 24 px, allow one lace bar. At 32 px, add a restrained colored inset. Avoid a winged shoe, which would read as a generic speed power-up and lose the street-dance reference. Avoid a recognizable sportswear logo.

The attack icon uses a footprint and a detached ring behind it. The passive uses the sneaker alone. Color can link both to the amber/teal character palette, but the separation must survive grayscale. Do not put an asterisk, cross, or literal “beat” letter on the shoe.

### Current mechanics and honest wording

Character ID 3 starts with weapon 22 and movement speed +15%. Weapon 22 currently leaves marks at the player's position; marks arm after a delay and pulse at pursuers. Emission is periodic, not conditional on distance, a dance input, or a combo counter. **Afterbeat** is a presentation rename for that existing attack, not a claim of a newly implemented rhythm system. [Local thematic contract](../../../examples/survivors/THEMATIC_ROSTER.md), [character policy](../../../examples/survivors/character-policy.bend), and [menu catalog](../../../examples/survivors/menu-catalog.bend).

The existing weapon's paired evolution passive is ID 3, not the movement-speed passive ID 5. Keep the distinction visible when replacing icons and wording.

### Optional new mechanic: Footwork Trail

Prototype rule, not implemented: actual world travel places a mark every 32 world units, with a minimum 0.25-second interval and a maximum of six active marks. Each mark arms after 0.45 seconds, then uses the existing pulse behavior. Position changes caused by teleport/reset must not count as traveled distance. Measure diagonal movement by distance, not by adding axis magnitudes.

A character who stops can still use other weapons, but this starter's next mark requires moving. That makes a real tradeoff and should be tested before adoption. If this is too punishing, let the existing periodic emission remain as a slow fallback rather than falsely claiming that standing still produces dance steps. Never turn the feature into mandatory beat-matched button presses without a separate product decision.

## Search and acceptance limits

Exact-phrase searches were run on 2026-10-27 for all six retained candidates and the three rejected explorations. Search absence is not evidence of absence from trademark registries, unindexed games, regional shops, transliterations, or similar-sounding names. Treat naming as **provisional, not cleared**. Treat fan recognition as **untested**, not as a measured success rate.

The immediate production-safe pass is wording and icon art only. New mechanics require Bend implementation, explicit rules, and live playtests. Render every proposed icon at 16, 24 and 32 px, compare on actual menu/HUD backgrounds, run an independent unlabeled visual review, record hashes and findings, and revise before adopting the family.
