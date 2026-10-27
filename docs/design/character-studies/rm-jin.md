# RM and Jin character, naming and icon study

Research date: 2026-10-26. Status: sourced design proposals, not production replacements.

This study separates first-party evidence, design interpretation and untested fan recognition. Proposed epithets are original combinations for the game rather than existing fan nicknames. Their connection should come from the whole character kit. No fan recognition test or trademark-register clearance was completed.

## Familiar fan handles versus original epithets

| Character | Familiar handle with direct usage evidence | Original game epithet | Trade-off |
| --- | --- | --- | --- |
| RM | **Joonie**. RM identifies this nickname in BTS's own answers during the WIRED interview; he connects it to Namjoon. **Joon** is a shorter candidate derived from his name, but the directly verified interview form is Joonie. [WIRED, BTS autocomplete interview and transcript](https://www.wired.com/video/watch/google-autocomplete-interviews-bts-bangtansonyeondan-answer-the-webs-most-searched-questions). | **Grove Scribe** | Joonie has substantially stronger evidenced fan association than an invented epithet. Grove Scribe is a newly authored descriptive combination. Neither has trademark clearance. |
| Jin | **Jinnie**. A fan's own letter on Weverse uses it; prevalence is unmeasured. **Jjan** is another option: Jin identifies it as his nickname in the WIRED transcript. [Weverse fan letter, 2024-06-12](https://weverse.io/bts/fanletter/3-167077938), [WIRED interview](https://www.wired.com/video/watch/google-autocomplete-interviews-bts-bangtansonyeondan-answer-the-webs-most-searched-questions). | **Hearth Voyager** | Jinnie is the clearer familiar-name route; Hearth Voyager carries the cosmic hospitality design. Trademark status is unknown for both. |

For a recognition-first prototype, test **Joonie · Grove Scribe** and **Jinnie · Hearth Voyager** as two-level labels. If avoiding the real-person association is the priority, use only the original epithet and accept weaker recognition. A familiar nickname is not automatically unregistered, free of personality-rights concerns, or independent of the artist's commercial identity. No such clearance is asserted here.

## Recommended matrix

| Reference character | Proposed game epithet | Physical trinket and icon | Existing starter, renamed without changing mechanics | Existing innate, renamed without changing mechanics | New mechanic to prototype separately |
| --- | --- | --- | --- | --- | --- |
| RM, ID 0 | **Grove Scribe** | **Pressed Leaf**. A closed indigo field notebook with one large pale leaf bookmark. Upgrade-family fit is passive 8, pickup radius +25% per rank. | **Gathering Ink**, weapon 20. A broad ink pool with three inward strokes and one clear center. Tooltip: “Ink fields pull enemies inward and repeatedly damage the chosen area.” | **Open Attention**. Tooltip: “Experience pickup radius +50%.” | **Collected Thoughts**. When one field has held at least three enemies for one second, it emits one finishing pulse. One pulse per field, with no new input button. |
| Jin, ID 1 | **Hearth Voyager** | **Travel Thermos**. A cream thermos with a crescent handle and a single warm opening. Upgrade-family fit is passive 11, regeneration +1 HP/second per rank. | **Hearth Orbit**, weapon 21. An amber lantern beside an incomplete orbital arc and one outgoing comet. Tooltip: “An orbiting light strikes nearby enemies and fires homing sparks.” | **Warm Welcome**. Tooltip: “Regenerate 1 health per second.” | **Safe Return**. Every third orbit completes a visible ring and releases one outward knockback pulse. It does not grant damage immunity or erase enemy projectiles. |

All displayed attack and passive names above are shorter than 24 characters. These words describe the current effects; the proposed finishers are not present in the game. The authoritative starter IDs and innate values are in [character-policy.bend](../../../examples/survivors/character-policy.bend), and current player-facing descriptions and recipes are in [menu-catalog.bend](../../../examples/survivors/menu-catalog.bend).

## RM evidence and interpretation

### Verified anchors

The first-party album-design account describes a painting-and-sculpture-led approach, a warm deep blue, and a record of thoughts and feelings from 2019 through 2022. This supports an ink, paper and collected-traces direction rather than a technological control-panel aesthetic. [Weverse Magazine, album development notes](https://magazine.weverse.io/article/view/639?artist=BTS&lang=en).

In his own interview, RM discusses exhibitions, lyrics as his musical starting point, and the lasting impression made by artists' descriptions of pebbles. This gives stronger specific evidence for a reflective writer and art observer than for a generic wizard. [Weverse Magazine, RM interview](https://magazine.weverse.io/article/view/213?lang=en).

Weverse's art feature describes his sharing and supporting art and discusses natural forms in the works he admires. The official album page confirms the project and its visual references. [Weverse Magazine, Korean art with RM](https://magazine.weverse.io/article/view/120?artist=BTS&lang=en), [BIGHIT MUSIC, album page](https://bts.ibighit.com/eng/discography/rm/detail/indigo/).

### Design interpretation

“Grove” stands for a place to observe and collect; “Scribe” makes writing visible in both the name and attack. A leaf tucked into a notebook joins nature and words without reproducing the official mascot, album cover, artist logo or a recognizable painting. The intended feeling is patient composition: pull scattered threats into a readable shape and then resolve it.

Fan recognition is a hypothesis with medium confidence when the name appears beside the indigo notebook, writer imagery and accepted character. The words alone have low confidence because they are not established fan terminology. This distinction matters: avoiding official names reduces direct borrowing, but also weakens immediate recognition.

### Three candidate epithets

| Candidate | Reason to consider it | Limited collision screen | Recommendation |
| --- | --- | --- | --- |
| **Grove Scribe** | Nature plus writing; compact and legible. | Quoted searches for the phrase, phrase plus “game”, and phrase plus “trademark” surfaced no obvious exact commercial identity. Broad fallback results are not a reliable zero-result claim. | First prototype. Suggestive naming, medium design confidence; legal status unknown. |
| **Leaf Archivist** | Nature plus collecting and memory. | Quoted phrase and game searches surfaced no obvious exact commercial identity. | Backup. Strong notebook fit, but “archivist” is longer and less immediate in a small menu. Legal status unknown. |
| **Parkside Scribe** | A more everyday observer, less fantasy-coded. | Quoted search surfaced a documentary involving Parkside and Scribe Video Center, not a clear exact-name game identity. | Distant backup. Less distinctive and more vulnerable to unrelated Parkside associations. Legal status unknown. |

Rejected routes: **Quiet Curator** already appears as a retailer's named homewares collection; **Pebble Poet** overlaps an existing artist identity. Neither observation establishes registered trademark status, but both undermine the goal of a fresh, distinctive game epithet. [Retailer's Quiet Curator collection](https://nestandbird.com.au/collections/the-quiet-curator), [Brain Pebble Poet's own website](https://www.brainpebblepoet.com/).

### Icon construction and tests

The trinket has a broad rectangular silhouette with an offset leaf. At 16 px, preserve the cover, spine edge and one leaf shape; omit veins, text and stitching. At 24 px, add one pale page edge. At 32 px, allow one vein and a small binding tab. Keep a visible gap between the leaf and spine so it does not become a generic book glyph.

The attack icon must show a containing area and inward force, not just a quill. Test a low, asymmetrical pool against a square gallery-like basin; keep three large inward strokes. Avoid tiny alphabet characters, which become noise and imply readable lyrics. The attack and trinket must remain distinguishable in monochrome: pool versus upright notebook.

For **Collected Thoughts**, count eligible enemies within a field using its existing lifetime and ownership. Emit a clearly telegraphed, capped pulse only once. A first test should compare existing weapon 20 with an otherwise identical version plus this finisher. Measure crowd control and boss damage separately; do not simultaneously add stronger pull, larger area and a damage multiplier. Persistent overlapping fields need per-field state to prevent accidental repeat pulses. These are implementation requirements for a proposal, not claims about current code.

## Jin evidence and interpretation

### Verified anchors

BIGHIT describes his first solo single as a song made with affection toward fans. Its official page uses outlander, lunar-eclipse and landing-on-Earth concept groupings. [BIGHIT release notice](https://weverse.io/bts/notice/9372), [BIGHIT MUSIC, single page](https://bts.ibighit.com/eng/discography/jin/detail/astronaut/).

Weverse's first-party character essay links his humor with putting people at ease, documents his cooking for others, and discusses his space-travel and moon imagery. It also identifies his official invented characters. Those anchors support hospitality carried through travel; they do not require copying a mascot's face into every UI icon. [Weverse Magazine, Eight ways Jin loves the world](https://magazine.weverse.io/article/view/571?artist=BTS&lang=en).

### Design interpretation

A portable warm object unites the vast-universe and sense-of-home contrast. “Hearth Voyager” names that contrast directly. A cream thermos, amber lantern and curved orbit can carry the association without an official alien, plush silhouette, album title or signature catchphrase. The thermos is not a biographical claim about an item Jin owns.

Fan recognition has medium confidence with the accepted character, moon/cosmic imagery and cozy cooking references. The epithet alone has low confidence and needs a small unlabelled identification test. Keep warmth distinct from invulnerability: the current innate heals gradually, while the current orbiting attack deals damage.

### Three candidate epithets

| Candidate | Reason to consider it | Limited collision screen | Recommendation |
| --- | --- | --- | --- |
| **Hearth Voyager** | Best expression of home carried into space. | Quoted phrase, game and trademark searches surfaced no obvious exact commercial identity; fallback results included unrelated hearth products and historical Voyager references. | First prototype. Suggestive naming; legal status unknown. |
| **Starlit Cook** | Straightforward cosmic plus cooking cue; slightly playful. | Quoted phrase and game/trademark searches surfaced no obvious exact commercial identity. | Backup. More fan humor, less emotionally broad than Hearth Voyager. Legal status unknown. |
| **Ladle Voyager** | A readable kitchen-object joke, useful if the game leans comic. | Quoted search surfaced no obvious exact commercial identity. | Comic alternate. Strong prop silhouette, weaker heroic tone. Legal status unknown. |

Rejected routes: **Moon Host** is already used by a game-server hosting service, which is especially close to game-related use. **Moonlit Host** surfaced an unrelated tabletop miniature phrase and a similar hosting name; do not prefer it when a clearer alternative exists. These are practical collision observations, not registry determinations. [Moon-Host's own company page](https://www.moon-host.de/uberuns.php).

### Icon construction and tests

At 16 px, the thermos should show a short cylinder and unmistakable crescent handle. Keep the opening dark and warm fill amber. At 24 px, introduce the lid seam. At 32 px, allow one steam ribbon; it must not be needed for identification. Test against a plain mug variant: the thermos should feel portable, while the mug may read more immediately as comfort. Neither should carry a medical cross.

The attack icon should retain one orbiting light and one direction of emission. An incomplete arc leaves enough negative space to distinguish it from a shield, ring or target. Do not add several small stars around a star; that recreates the current ambiguous asterisk at smaller scale. Amber should identify warmth, while the crescent and orbital arrangement identify travel.

For **Safe Return**, use a completed-orbit counter attached to the attack owner and a capped knockback pulse. The third circuit should visibly close the orbital arc before the pulse. This gives anticipation without asking the player to press a rhythm input. Test one pulse per three circuits, boss knockback resistance and co-op ownership. Do not describe it as a shield until a real blocking mechanic exists.

### Recipe mismatch to resolve deliberately

Current weapon 21 evolves with passive 10, the luck upgrade, not passive 11, the regeneration upgrade. **Travel Thermos** is therefore a proposed personal trinket and the visual concept for regeneration family 11. It is not currently the evolution ingredient for Jin's starter. Switching that recipe to 11 would be a gameplay change requiring explicit balance and progression checks. Retaining the existing recipe requires a distinct luck object, such as a comet charm, in the recipe UI. [Current catalog and evolution mapping](../../../examples/survivors/THEMATIC_ROSTER.md).

## Naming screen limits

All candidate screening above used public web searches on the research date. No successful candidate-by-candidate trademark-register search is claimed. No target jurisdiction or goods/services classes were supplied. The public USPTO search entry point and WIPO Global Brand Database were consulted for the available official search routes; WIPO explicitly notes that national and regional registers can also need searching. [USPTO trademark search](https://www.uspto.gov/trademarks/search), [WIPO Global Brand Database](https://www.wipo.int/en/web/global-brand-database).

Use the shortlist as creative naming work with fewer obvious direct-brand references. Do not label the candidates “not a trademark,” “cleared,” or “safe to publish.” The repository's separate prohibition on publishing this mod to the public Survivors site remains in force.
