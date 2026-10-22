# Candidate study: rule and machine puzzles as a Bendvy ECS showcase

**Hypothesis 10 of 10.** This study compares *Baba Is You*, *Opus Magnum*, and *The Incredible Machine* through *Contraption Maker*, its modern spiritual successor from the original game's designer/programmer. It asks whether a puzzle clone can expose ECS through changing rules, configurable mechanisms, and ordered simulation without first building a large real-time game. Gameplay claims below come from the developers' and publishers' own material. The ECS designs and ratings are proposals, not claims about the original games' internal architecture. No code, benchmark, or performance claim was produced.

## Recommendation

Within this rule-and-machine-puzzle group, the **strongest dynamic rule/behavior-composition demonstration** is a small *Baba Is You*-style game. The core move changes the active rules; independent gameplay systems then interpret that rule state when selecting and acting on positioned entities. A design may materialize resulting properties as component membership, or keep them in a derived `ActiveRules` table that those systems consult. The same player-visible behavior change works with either representation; only the former demonstrates structural membership churn. This is a closer match to runtime behavior composition than sheer entity count.

This is a **within-group** result, not a claim that Baba wins the overall “maximum ECS” comparison. A one-room rule puzzle has few entity families, little relation cleanup, and a narrow event/lifecycle surface. The station and modular-ship candidates have broader combinations of ownership, crew/inventory, hazards, systems, and destruction. Baba's distinctive strength is the degree to which a player's move can add or remove behavior from existing entities; its contribution is dynamic composition, not maximum total ECS breadth.

For the **best first playable slice within this group**, use the same direction, but constrain it to one authored room, four simple rules (`BABA IS YOU`, `ROCK IS PUSH`, `WALL IS STOP`, `FLAG IS WIN`), a few movable pieces, undo, and restart. This is a recognizable block-pushing rule puzzle without physics or a machine-instruction editor. Keep the grammar closed at first; advanced rule forms and campaign content can multiply the parser and puzzle-authoring work. A single-level slice is a test of the game's rule-changing choice, not evidence that a full campaign is inexpensive.

*Opus Magnum* is the better follow-up if the project specifically wants a deterministic, visibly phased machine runner and animated replay. *The Incredible Machine* is the strongest reference for a rich collection of interacting physical parts, but should wait until Bendvy has the required collision/physics host. None of these recommendations rests on evidence that the commercial games use ECS.

## What the primary sources establish

- **Baba Is You:** the official store description says the rules are blocks in the level that players can manipulate to change how the game works, alter objects, and change goals. It describes a block-pushing puzzle and over 200 levels, and names Clickteam Multimedia Fusion 2 as the game-creation tool. In his GDC talk, creator Arvi Teikari describes rules as object–verb–quality sentences, explains that various gameplay systems ask which rules are present and which objects they apply to, and walks through multi-pass sentence parsing, rule expansion, and rule disabling. He says the final implementation was mostly in Lua and highlights tables as a flexible representation. That is direct evidence of query-shaped game semantics, **not** evidence of an ECS implementation. ([official Steam page](https://store.steampowered.com/app/736260/Baba_Is_You/), [GDC session](https://gdcvault.com/play/1026590/Reading-the-Rules-of-Baba), [developer's GDC slides](https://media.gdcvault.com/gdc2020/presentations/Reading%20the%20rules_Teikari_Arvi.pdf))
- **Opus Magnum:** Zachtronics describes building alchemical machines from components and programming them with a symbol-based system that manipulates molecules. Its official game page emphasizes programmable arms, customizable tracks and glyphs, open-ended solutions, and a puzzle editor. This supports a fixed-step interpretation of mechanisms and carried atoms, but the exact simulator architecture and determinism are not documented in these sources. ([Zachtronics game page](https://www.zachtronics.com/opus-magnum/), [Zachademics description](https://zachtronics.com/zachademics/), [official Steam page](https://store.steampowered.com/app/558990/Opus_Magnum/))
- **The Incredible Machine:** Steam describes *Contraption Maker* as a spiritual successor to *The Incredible Machine* from original designer/programmer Kevin Ryan. Its feature description calls out interacting characters, contraptions, the game's physics and parts, and puzzle and game editors. This supports the physical-interaction comparison here; it does not establish details of the original game's code or architecture. ([developer/publisher Steam page](https://store.steampowered.com/app/241240/Contraption_Maker/))

## ECS-shaped work and the competing costs

| Reference | Natural ECS-shaped workload | Main cost outside ECS | Fit for a first Bendvy slice |
| --- | --- | --- | --- |
| *Baba Is You* | Text pieces and world objects coexist as positioned entities. Parsed rules change effective properties such as controllable, pushable, blocking, winning, or hazardous. Independent movement, push, obstruction, victory, and defeat systems can query relevant entity families and either consult derived rules or select materialized property markers. | A rule scanner/parser, deterministic grid occupancy and push-chain resolution, plus authored levels that make rule changes satisfying. | Strongest fit if the first level retains the physical rule blocks, a genuine rule-driven behavior change, and a visible solve. No rigid-body physics is needed. |
| *Opus Magnum* | Arms, tracks, glyphs, atom groups, output slots, and programmed mechanisms can be independently composed. Separate systems can advance instructions, move arms and atoms, transform atoms, detect invalid contact, and accept products. | A small virtual machine plus grid geometry, molecule/bond bookkeeping, collision rules, and an editing UI for placements and instruction sequences. | Viable with one arm and one product, but a machine editor and readable runner are required for the player to make the defining choice. |
| *The Incredible Machine* / *Contraption Maker* | Parts and actors can have reusable movement, collision, trigger, timed-action, and lifetime behaviors; contacts can lead to chains of events and removals. Some connections, if selected for a level, need explicit ownership/link cleanup. | The central challenge is the physics/collision simulator and its interactions, then a large part catalog and authored puzzles. | Weakest first slice. A “machine puzzle” without believable physical cause-and-effect risks looking like a generic event demo; building that feel is host work beyond ECS. |

The ratings below are ordinal expert estimates for this hypothesis only: 0 absent, 1 weak, 2 noticeable, 3 central. They are not measurements and should not be averaged into a pseudo-precise total. “Dynamic rule/behavior change” is about what the player can change in play; “structural membership churn” is about whether the selected implementation inserts/removes components. These are separate axes.

| Criterion | *Baba Is You* | *Opus Magnum* | TIM-style contraption |
| --- | ---: | ---: | ---: |
| Component composition | 3 | 3 | 3 |
| Overlapping queries | 3 | 2 | 3 |
| Dynamic rule/behavior change | 3 | 2 | 2 |
| Structural membership churn (property-marker option) | 3* | 1 | 1 |
| Meaningful phases/events | 2 | 3 | 3 |
| Relationships and cleanup | 0 | 1 | 2 |
| Small recognizable first slice | 3 | 2 | 1 |
| Load outside ECS (higher is more) | 1 | 2 | 3 |
| Novelty beyond current arena | 3 | 3 | 2 |

The `3*` for *Baba* structural membership churn applies only to the materialized property-marker option described below. With the derived-rule-table option, that structural-churn score is 0 while the dynamic rule/behavior score remains 3. This is an implementation-conditional ordinal estimate, not a trait of the commercial game. A local enum or flags value can be a valid component representation; neither flags nor a local kind match alone makes an ECS model weak. The concern is a single board-wide dispatcher that owns otherwise separable movement, obstruction, control, and victory behavior, or a growing cross-product switch that duplicates those systems for each entity kind. *Opus Magnum* gets strong composition scores because a mechanism can be assembled from different part families, but its part set is usually designed in the editor before simulation; its core novelty for this project is scheduled deterministic work, not frequent ECS archetype changes. A contraption's many interactions can cross queries, while a single physics solver can also absorb nearly all of that behavior.

## A concrete *Baba*-style ECS model

This is a proposed design, not a description of the commercial game's internal entities.

| Entity family | Example data/components | Systems that can select it |
| --- | --- | --- |
| Baba, rock, wall, flag, skull | `GridPosition`, `NounIdentity`; optionally materialized property markers such as `Controlled`, `Pushable`, `Stop`, `Win`, `Defeat` | Input/movement, push planning, occupancy, win/defeat checks, renderer |
| Word tile | `GridPosition`, `TextWord`, `Pushable` | Push planning, rule scan, occupancy, renderer |
| Level | Resource containing dimensions, immutable floor/map data, level state, and optionally a derived `ActiveRules` table | Rule scan, movement, victory check, reset/inspection |

The same `GridPosition` participates in multiple systems. Text words are ordinary positioned pieces, not a separate board-string. The parser reads their word components and positions, then computes the active rule set. There are two viable ways to make those rules affect play:

1. **Derived-rule table:** store the scanned rules in `ActiveRules`. Movement/push, obstruction, control, and goal systems each consult that table while querying the positioned entities relevant to their own work. This has dynamic behavior composition without per-rule component insertion/removal.
2. **Materialized property markers:** reconcile the derived properties onto matching nouns through explicit insert/remove commands, then pass a structural barrier. Movement, obstruction, control, and goal systems can then select entities by those markers. This makes structural membership churn visible and can simplify required-presence selection.

Both variants implement the same board rules and the same authored route once the post-move update is complete. The marker names above are one example of the second variant, not a required architecture; there is no requirement to create one component for every rule sentence or property. A local enum/flags value can also be appropriate when it represents cohesive state consumed together. Keep the rule grammar deliberately small: conditional/expanding rules would turn the slice into a language-implementation project.

Do not create an ECS entity for each empty grid cell. Use a compact occupancy/grid resource or host-owned grid helper for coordinate lookup. A dozen-by-dozen puzzle does not justify a spatial-index project. Do not add parent/child or ownership relations just to fill the relationship criterion; a single-room puzzle has little need for them. A future level entity may own pieces only if level switching and teardown exercise that relation usefully.

## One hand-authored room and a manually checked route

This is a proposed minimal level, not an official *Baba Is You* level and not a statement about its exact turn semantics. Coordinates are zero-based: 11 columns (`x=0..10`), 10 rows (`y=0..9`); leaving the board is blocked. `#` cells are actual Wall entities. At the start, the four horizontal sentences are `BABA IS YOU`, `ROCK IS PUSH`, `FLAG IS WIN`, and `WALL IS STOP`. Uppercase letters are word tiles (`V` means WIN); lowercase `b`, `r`, and `f` are the Baba, Rock, and Flag objects. For this room the parser accepts only contiguous horizontal triples of the form `(BABA|ROCK|FLAG|WALL) IS (YOU|PUSH|WIN|STOP)`; there are no conditionals, negation, or rule expansion. Guard walls pin the support rules while leaving `YOU` breakable for a loss/undo check and `STOP` movable for the solve route.

```text
 y\\x  0 1 2 3 4 5 6 7 8 9 10
  0   # # . # . # . . . . .
  1   B I Y # . # . . . . .
  2   # # . . . # . . . . .
  3   R I P # . # . . . . .
  4   # # # . . # . . f . .
  5   F I V # . # . . . . .
  6   # # # . . # . . . . .
  7   # # . . . # . . . . .
  8   W I S # . # . . . . .
  9   # . r b . # . . . . .
```

Guard Walls seal the lower side of `ROCK IS PUSH` and both vertical sides of `FLAG IS WIN`; their right-hand guards block a horizontal shift. These support rules stay intact along the solve and loss routes. In each sentence the noun at `x=0` cannot be pushed off-board, and pushing a right-hand word left would push the whole sentence off-board. `BABA IS YOU` is similarly pinned except that `YOU` can be pushed vertically into row 0 to make a clear defeat/undo check. In `WALL IS STOP`, the noun is edge-pinned, `IS` is guarded from above, and the lower-left approach to that rule is sealed by the Wall at `(0,9)` and Rock; the Wall at `(3,8)` prevents pushing `STOP` right. Walls at `(0,7)` and `(1,7)` also guard the rule from above. After the Rock is pushed left into `(1,9)`, the cell below `IS` is inaccessible along the solve route, leaving the intended useful rule change: push `STOP` upward from below. The route is:

1. From Baba `(3,9)`, move left. `ROCK IS PUSH` lets Baba push the Rock from `(2,9)` to `(1,9)`; the Wall at `(0,9)` blocks the chain. Baba ends at `(2,9)`.
2. Move up. Baba pushes the `STOP` word from `(2,8)` to `(2,7)` and ends at `(2,8)`. The row no longer spells `WALL IS STOP`; after the whole move, the active rule state no longer blocks Walls. In the materialized-marker variant, this also removes `Stop` from the Wall entities.
3. To get around the guard Wall at `(3,8)`, move down to `(2,9)`, right twice to `(4,9)`, then up to `(4,8)`. Move right three times to `(7,8)`, passing through the vertical Wall barrier at `x=5`, which is now non-blocking. Move up four times to `(7,4)`, then right onto the Flag at `(8,4)`. `FLAG IS WIN` remains active, so the level is solved.

This route makes the player's choice meaningful: move the Rock out of the way, push a word to change which entities block the path, then walk through the resulting opening. It is more than a parser demonstration because the rule change alters obstruction behavior and enables passage through the full-height barrier to the goal. The Rock rule matters in the setup turn, and the rule pieces themselves share ordinary movement/push handling with the world objects. The rule grammar is intentionally bounded; this room does not establish the cost or completeness of the original game's parser.

One intentional failure route checks recovery. After step 2, Baba can travel right to `x=4`, go up to `y=2`, move left twice to `(2,2)`, then move up to push `YOU` from `(2,1)` to `(2,0)`. With the only `BABA IS YOU` sentence broken and no other controlled entity, the level enters a lost/no-controlled-object state. Undoing that completed move restores the word and Baba position, refreshes the active rule state (and `Controlled` membership in the marker variant), and returns to play; restart reloads the diagram above. The failure does not depend on an accidental syntax edge case.

The board's occupancy helper must allow co-location with Wall entities once `Stop` is removed. It therefore cannot be a single-occupant map from cell to entity; use a small per-cell list or equivalent lookup. This is a concrete example of a limited grid-host concern adjacent to ECS, not a reason to create one entity for every empty cell.

## Turn phases and player-visible result

The meaningful player choice is which word or object to push. The player sees the active rule change, the resulting movement/collision behavior, and either a solved room or a recoverable dead end. A compact turn schedule could be:

1. Convert the directional input into one `MoveIntent` resource value.
2. Plan the push chain using the rules active at the start of the move. If any destination is blocked, leave every position unchanged. This makes a blocked chain an ordinary no-op, not a partial world mutation.
3. Commit all changed positions, then rescan the word layout and derive active rules.
4. Make the newly parsed rules authoritative for the next phase: either refresh `ActiveRules`, or reconcile materialized property markers with insert/remove commands and pass the explicit structural barrier.
5. Resolve rule-based hazards and win conditions against the updated world; publish `RuleChanged`, `LevelWon`, or `PlayerDefeated` only after the authoritative state change commits.
6. Let the renderer/HUD observe the completed turn. If the player loses their last controlled object, show undo/restart; undo restores the prior completed turn and restart reloads the level definition.

The exact order is a design decision for this clone. In particular, **all actors use the rule set frozen at the start of a directional command**. Push chains are resolved against that rule snapshot and committed; then the word layout is scanned once and the resulting active rule state is refreshed (and, in the marker variant, reconciled at a barrier) before win/defeat is checked. A word pushed during a chain therefore cannot change whether a later part of that same chain is blocked. This is an explicit slice rule, not a claim about exact *Baba Is You* compatibility. It should be covered by an independently computed move trace. Do not assume that drawing a rule-change sound or win banner can be rolled back with ECS state: publish those host effects after commit. For this small slice, undo should use a per-turn inverse/delta or an explicit quiescent state history; Bendvy's world snapshot is not an exact runtime checkpoint for queues and reader cursors.

For multiple `YOU` rules, the proposed extension treats every entity matching any active `Noun IS YOU` rule as controlled. At the start of a command it snapshots those handles in stable level/spawn order, resolves each actor's push chain sequentially against the positions already committed by earlier actors, and leaves an individual actor in place if its chain is blocked. Newly controlled entities begin responding on the next input, after the post-move rule scan. This policy can be implemented by consulting `ActiveRules` or by materialized `Controlled` membership. The authored board above contains exactly one controlled object, so this extension policy is deterministic but is not exercised by its solve trace.

An Opus-style alternative would have a puzzle phase for editing the board/program, a start action, then repeated fixed steps: execute each mechanism's current instruction, propose movement, detect conflicts/collisions, apply glyph transformations, accept outputs, and emit a terminal solved/fault result. These phases are especially legible, and replaying the same input program is a natural deterministic test **if** the implementation fixes iteration order and uses deterministic arithmetic. That is a design inference, not a verified property of Zachtronics' original. It does less to show runtime composition change because machine mechanisms generally exist before execution.

## Fit with the current Bendvy and counterarguments

The report's project context is [ordinary App guidance](../../../bendvy/docs/reference/ordinary-app.md), [the scheduled-health example](../../../bendvy/examples/scheduled-health/README.md), [the browser arena](../../../bendvy/examples/arena/README.md), and [the current scope](../../../bendvy/docs/SPEC.md). Use ordinary App registration and its declared queries as the main consumer. Bendvy provides typed component queries, ordered registered systems, deferred structural commands with explicit barriers, events/readers, and transactional boundaries. It does not provide a puzzle renderer, input loop, spatial index, physics solver, or automatic parallel execution. These capabilities can express the proposal; that is not evidence the complete game has already been qualified in Bendvy.

The decisive counterargument is that a small turn-based board can be implemented cleanly as an array of cells and a short function that scans words and applies flags. With one dozen pieces, that approach is likely simpler to author and reason about. ECS helps the *library user* if the code makes ownership and selection clearer across rule scanning, movement/pushing, hazard checks, win checks, and event observation. A flags field or a local enum match can support that design; the concern is a central `resolve_level()` that routes all of those behaviors through one board-wide dispatcher and mutates one `Cell { kind, flags }` array. Wrapping that array in one resource does not by itself make a convincing ECS showcase.

For the proposed current-App path, do not assume that an optional component query can write a marker onto absent rows: the [ordinary query builder](../../../bendvy/src/ecs/ordinary-query-builder.bend) documents `optional` as a read-only selection. A materialized-marker design therefore needs the supported structural-command path and an explicit barrier for insertions/removals. The `ActiveRules` design avoids that particular structural write path, at the cost of each relevant system consulting the derived rule data. These are design trade-offs; this study makes no claim that one representation is faster or universally preferable.

The second counterargument is the rule engine. The developer's account documents multiple parsing passes and handling for rules that create or disable other rules. If level logic spends nearly all its time parsing sentences, ECS does not eliminate that complexity. Keep the first language subset intentionally closed, predeclare the entity component families, and make one rule change visibly enable/disable behavior. The work should not grow into a complete reimplementation of all 200-plus original levels before the ECS question is answered.

The third counterargument concerns content. A syntactically valid board is not automatically an enjoyable puzzle. If a micro-level offers no consequential choice between moving a rule tile and moving an object, or if changing the active rule does not visibly change play, the result is only Sokoban with a sentence scanner. A complete first slice needs one designed route to the flag, at least one meaningful rule-breaking/reforming choice, a defeat/dead-end recovery path, undo and restart, and a visible completion state.

Finally, do not use transactions, relations, snapshots, or event streams merely to exercise API names. A blocked push should be planned atomically in game logic; it does not need to manufacture a transaction error. A one-room puzzle has no meaningful ownership graph. Events are justified only for distinct consumers such as HUD, replay log, and sound after a committed win or rule change; if the HUD is the only consumer, direct observation may be enough. The snapshot API should not be treated as exact per-move undo.

## Falsifiers and switch conditions

- If rule effects collapse into one cross-product dispatcher that owns movement, obstruction, control, hazards, and victory instead of being consumed by independent systems, the ECS-specific claim weakens. A local enum match, cohesive flags component, or derived `ActiveRules` resource alone is not a falsifier; choose the simplest representation that preserves clear system ownership.
- If the first puzzle's interesting behavior depends on a large rule grammar, conditional rules, or carefully ordered grid-resolution edge cases before one turn feels complete, the language/parser is consuming the slice. Reduce the grammar or stop recommending it as the first clone.
- If user evaluation says they value deterministic execution/replay of a mechanism more than player-driven rule/behavior changes, prefer the *Opus*-style one-machine slice. Preserve deterministic step order as an explicit contract and avoid implementing unnecessary molecule graph features in the initial level.
- If physical contact chains are the game's central player appeal and the project already has a qualified physics host, a one-room TIM-style chain reaction could then be reconsidered. Without that host, its apparent ECS richness mostly measures the work of writing physics.
- If the implementation has no meaningful rule-driven behavior change, exposes no overlap among independently owned systems, or gains no new lesson beyond the current [compound-Body arena](../../../bendvy/examples/arena/README.md), this hypothesis has failed to establish the proposed dynamic-composition showcase. Absence of component additions/removals alone only means the structural-churn axis was not exercised; if that specific lesson is required, choose the materialized-marker variant or another candidate.

## Sources

Official/developer sources for game facts:

- Arvi Teikari / Hempuli Oy, [Baba Is You on Steam](https://store.steampowered.com/app/736260/Baba_Is_You/) and [GDC 2020 talk listing](https://gdcvault.com/play/1026590/Reading-the-Rules-of-Baba).
- Arvi Teikari, [GDC presentation slides: *Reading the Rules of Baba Is You*](https://media.gdcvault.com/gdc2020/presentations/Reading%20the%20rules_Teikari_Arvi.pdf).
- Zachtronics, [Opus Magnum](https://www.zachtronics.com/opus-magnum/), [Zachademics description](https://zachtronics.com/zachademics/), and [official Steam page](https://store.steampowered.com/app/558990/Opus_Magnum/).
- Kevin Ryan / Top Meadow, [Contraption Maker on Steam](https://store.steampowered.com/app/241240/Contraption_Maker/), identified there as a spiritual successor to *The Incredible Machine* from its original designer/programmer.

Project sources read read-only: [evaluation contract](00-evaluation-contract.md), [ordinary App guide](../../../bendvy/docs/reference/ordinary-app.md), [scheduled-health](../../../bendvy/examples/scheduled-health/README.md), [arena](../../../bendvy/examples/arena/README.md), and [SPEC](../../../bendvy/docs/SPEC.md).
