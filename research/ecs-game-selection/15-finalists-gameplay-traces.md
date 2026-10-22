# Finalists: hand-worked gameplay traces

**Cross-review artifact.** This note turns the FTL-like run, SS14-style station emergency, and Baba Is You room proposals into small, manually reasoned design traces. The entity names and component deltas are proposed game rules. Every FTL and station number below is invented for the trace; the Baba coordinates and route are inherited from the hand-authored design in [10-rule-puzzles.md](10-rule-puzzles.md), not from an original level. Nothing here was executed, benchmarked, or proved.

The source games support the broad mechanic choices, not these exact rules or an inference about FTL/Baba internals. Subset Games describes FTL as a randomly generated crew-and-ship roguelike-like with crew orders, power allocation, target selection, pause, and encounter choices; its product text explicitly gives missile/engine/weapon/boarding solutions as examples. ([FTL on Steam](https://store.steampowered.com/app/212680/FTL_Faster_Than_Light/)) SS14 describes a round-based multiplayer role-playing game with crew jobs, detailed station systems, and player-led emergent choices. ([SS14: About](https://spacestation14.com/about/about/), [SS14 ECS guide](https://docs.spacestation14.com/en/robust-toolbox/ecs.html)) Baba's publisher describes rules as manipulable blocks; creator Arvi Teikari explains the object–verb–quality rules and that gameplay systems ask which rules are present and which objects they apply to. The creator also describes the shipped implementation as mostly Lua/table-based, so this is evidence for query-shaped *game semantics*, not ECS architecture in the original. ([Baba Is You on Steam](https://store.steampowered.com/app/736260/Baba_Is_You/), [GDC slides](https://media.gdcvault.com/gdc2020/presentations/Reading%20the%20rules_Teikari_Arvi.pdf))

## What is a proposed rule and what is a Bendvy guarantee

All values like hull, charges, room pressure, turn number, board size, damage, and node count in the traces are illustrative design inputs. A delta such as `+Operational` or `-Stop` means “the proposed game would change this entity's composition.” It does not claim that such a game, system, or outcome has already run in Bendvy.

The local Bendvy contracts I checked are narrower:

- An attached ordinary App executes registrations in order. An initial barrier is a schedule choice; queued structural commands remain pending until an explicit barrier applies them. A failed registered system stops the schedule. See [ordinary-app.md](../../../bendvy/docs/reference/ordinary-app.md) and [ordinary-app-run.bend](../../../bendvy/src/ecs/ordinary-app-run.bend).
- The transaction layer commits only recorded ECS changes and staged commands/events on success; on failure it replays the recorded inverse journal and drops the staged commands/events. It does not automatically journal arbitrary mutation or undo host I/O. Command enqueueing is separate from barrier application. See [transaction.bend](../../../bendvy/src/ecs/transaction.bend), [commands.bend](../../../bendvy/src/ecs/commands.bend), and [structural.bend](../../../bendvy/src/ecs/structural.bend).
- Queue admission is not a promise that a command will apply at the barrier. A selected `Type` capture can survive a query failure while World writes roll back, so gameplay presentation/audio must follow committed observations rather than side effects inside the callback. The ordinary App guide and [SPEC.md](../../../bendvy/docs/SPEC.md) also distinguish World saves from full schedule/runtime checkpoints.

These are documented source/API boundaries, not a qualification of any trace below. In particular, an ordinary App action touching several entity rows is a design target here; no cross-entity game system was implemented or executed for this study. The rejected player actions below are precondition refusals with no writes, not demonstrations of Bendvy transaction rollback.

## FTL-like run: route choice and a targeted final fight

An isolated battle is a combat prototype, not an FTL clone. The minimum run shell must keep a short route graph, at least one earlier encounter/reward, persistence of hull/crew/system state, one spend choice, and an exit after the final fight. This proposed trace starts at the branch *after* a common opening skirmish, so the table is the run's closing section rather than an executed or complete run. It deliberately uses two compact route branches and no authored event library.

### Proposed initial state

The fixed seed `41` selects `B1 → {RepairDock, AmmoCache} → Interceptor → Exit`. These identifiers, route edges, and all quantities in this section are invented. At `B1`, after the common opening skirmish, the run state is:

| Entity / resource | Components or value at the branch |
|---|---|
| `Run` | `CurrentNode=B1`, `Fuel=3`, `Outcome=Active`, `Seed=41` |
| `ScrapWallet` | `Scrap=2` |
| `PlayerHull` | `Team=Blue`, `Damageable`, `Targetable`, `Hull=4/6`, `Active` |
| `Reactor` | `PowerSupply=2` |
| `Shield` | `Team=Blue`, `Room=Bridge`, `PowerDraw=1`, `Powered`, `Pips=2/2` |
| `Laser` | `Team=Blue`, `Room=Weapons`, `PowerDraw=1`, `Charge=0`, `AttackDamage=1`, `SystemDamage=1`, `Operational` absent |
| `MissileLauncher` | `Team=Blue`, `Room=Weapons`, `PowerDraw=1`, `Cooldown=Ready`, `Operational` |
| `Ada` | `Team=Blue`, `Health=3/3`, `Room=Bridge`, `Order=None` |
| `Door-BW` | `DoorEndpoints=(Bridge,Weapons)`, `Closed` |
| `MissileStack` | `Ammo=0` |

On entering `Interceptor`, spawn one enemy ship (`Team=Red`, `Hull=2`, `Active`, `Targetable`, `Damageable`), one shield module (`Team=Red`, `Pips=1`, `Targetable`, `Damageable`), one gun (`SystemHealth=1`, `VolleyHits=2`, `DamagePerHit=1`, `CanFire`, `Targetable`, `Damageable`), and one small `BridgeFire` entity (`Room=Bridge`, `Hazard`, `Active`, `Damageable`, `Targetable`). This fire deals one health to crew in its room at the end of each active turn. All combat quantities and phases here are proposed toy rules. Both winning strategies face this same two-hit enemy volley. The power supply is 2: an active `Shield` and either the repaired `Laser` or `MissileLauncher` each draw 1; both route strategies keep `Shield` powered and select their weapon before combat starts. The laser starts damaged (`SystemDamage=1`, `Operational` absent), but its `AttackDamage=1` is a separate immutable weapon stat. A repair sets `SystemDamage: 1→0` and adds `Operational`; it does not change attack damage. Each combat tick accepts at most one player action; waiting is allowed and existing crew orders continue. The order is: (1) impact projectiles due this tick and commit their removals/destroyed-target state; (2) resolve that player action; (3) apply its queued structural changes at a barrier; (4) a crew order with a remote target moves one open-door room edge toward it; a repair advances one system only when the crew started that tick in the target room; commit those structural changes at a second barrier; (5) if both the enemy ship is `Active` and its gun still has `CanFire`, it fires a volley of two consecutive 1-damage hits; (6) active fire harms crew in its room; (7) at tick end, each powered player shield restores one pip up to 2, and each powered operational laser recharges from 0 to `Ready`. A ready laser fires on the player's action, consumes its ready charge, and deals 1 to an enemy shield pip if present, otherwise to a selected gun or hull; hitting the gun at zero shields reduces `SystemHealth`, and zero removes `CanFire` at the action barrier. A powered player shield absorbs one incoming hit per pip; each volley hit after its pips run out removes one player hull. A launched missile arrives at the start of the next tick, deals 1 hull damage regardless of shield pips, and its launcher returns ready at the end of its launch tick. The run loses if player hull reaches zero or no crew remain alive; it wins only when the living ship reaches Exit. These are invented deterministic rules, not claims about exact FTL combat resolution.

### Winning strategy A: buy hull margin, restore the laser, suppress the gun

Before combat, allocate one power to `Shield` and reserve one power for `Laser`; the damaged Laser draws from that reserved bar once repaired. `MissileLauncher` is unpowered. The route and service rows happen outside the combat clock.

| Player action | Exact proposed state change | Overlapping systems and structural boundary | Visible result |
|---|---|---|---|
| Travel to `RepairDock`, spend 2 scrap on hull repair, then travel to `Interceptor`. | `Run.CurrentNode: B1→RepairDock→Interceptor`; `Fuel: 3→2→1`; `ScrapWallet.Scrap: 2→0`; `PlayerHull.Hull: 4→6`. Enemy entities spawn on arrival. | Route system updates the run resource; repair touches the hull entity and scrap resource. Spawn is staged and becomes a live enemy only at the explicit arrival barrier. | The player sees the service choice consume the reward, two hull points restored, and the final opponent appear. |
| Combat turn 1: extinguish `BridgeFire` before the fire phase. | `BridgeFire.Health: 1→0`; queue `-Active`. `Ada.Health` stays 3 because the action barrier removes the active hazard before exposure. The volley consumes both shield pips (`2→0`), then end-of-turn recharge restores one (`0→1`). | The crew query reads `Room + Health`; the fire query reads `Room + Active + Hazard`. Fire is also a `Targetable + Damageable` entity. The hazard and combat systems therefore use shared room/damage data across different entity families. | The fire goes out; the crew stays healthy and one shield pip remains. |
| Turn 2: open `Door-BW`. | The volley consumes the remaining shield pip (`1→0`); its second hit changes `PlayerHull.Hull: 6→5`. Recharge restores one pip (`0→1`). | Navigation reads the same `DoorEndpoints + Open` state that an air/room-transfer system could use. The barrier publishes the door change before crew orders resolve. | The door opens; the ship takes one hull damage and one shield pip remains. |
| Turn 3: order Ada to repair `Laser`. | `Ada.Order: None→Repair(Laser)`; the open-door navigation system moves her one room edge, `Room: Bridge→Weapons`. The volley consumes the remaining shield pip, then its second hit changes `PlayerHull.Hull: 5→4`; recharge restores one pip (`0→1`). | Navigation reads `DoorEndpoints + Open`; the order query reads Ada's `Room + Order`, and Laser's `Room + SystemDamage` determines the repair destination. The same entities are later read by power and targeting systems. | Ada reaches Weapons; hull falls to 4 and one shield pip remains. |
| Turn 4: wait while Ada completes the repair. | `Laser.SystemDamage: 1→0`, queue `+Operational`; `Ada.Order: Repair(Laser)→None`; `Laser.AttackDamage` stays 1. The repair barrier commits the component change, then the charge phase changes `Laser.Charge: 0→Ready`. The volley consumes the remaining shield pip, then its second hit changes `PlayerHull.Hull: 4→3`; recharge restores one pip (`0→1`). | Repair reads Ada's `Room + Order + Health` and the Laser's `Room + SystemDamage`; the repaired Laser now participates in power allocation and later targeting. | Laser changes from damaged to ready; hull falls to 3 and one shield pip remains. |
| Turn 5: fire at the enemy shield; turn 6: target its gun. | Turn 5 shot: `Laser.Charge: Ready→0`, enemy `Shield.Pips: 1→0`. The volley consumes the remaining player-shield pip, then its second hit changes `PlayerHull.Hull: 3→2`; recharge restores one pip (`0→1`); Laser recharges `0→Ready`. On turn 6 its shot sets enemy `Gun.SystemHealth: 1→0`; queue `-CanFire` at the action barrier, so there is no turn-6 enemy volley; shield recharge restores `1→2`. | `Targetable + Damageable + Team` are shared by target selection and hit resolution. The gun is also read by the enemy-fire phase. Barrier removes `CanFire` before that phase, so it observes the disabled gun. | The enemy shield empties; the RepairDock hull margin leaves the player at hull 2, then the gun flashes offline and stops attacking. |
| Turns 7–8: fire twice at the exposed hull, then travel to Exit. | On consecutive turns the powered Laser deals `AttackDamage=1` each: enemy `Hull: 2→1→0`; at zero queue `-Active`. With the gun disabled, no further enemy volleys occur. `Run.Fuel: 1→0`; `Run.CurrentNode: Interceptor→Exit`; `Run.Outcome: Active→Won`. | Hull damage, ship-active cleanup, and the objective query reuse the enemy ship's `Team + Targetable + Damageable + Active`. Barrier applies enemy deactivation before the exit node commits the result. | Enemy ship disappears; the living player ship reaches the exit with hull 2. |

The RepairDock choice is load-bearing. If the same laser route starts combat at the un-repaired hull 4, turns 1–4 reduce it to 1; on turn 5 the laser can empty the enemy shield, but the still-active gun's two-hit volley then spends the one player-shield pip and deals the next hit to hull `1→0`. The run loses before Ada can target the gun. RepairDock's two hull points buy the turn needed to disable it.

### Winning strategy B: take missiles, keep shields online, bypass the enemy shield

Before combat, allocate one power to `Shield` and one to `MissileLauncher`; leave the damaged `Laser` unpowered.

| Player action | Exact proposed state change | Overlapping systems and structural boundary | Visible result |
|---|---|---|---|
| Travel to `AmmoCache`, take two missile parts, then travel to `Interceptor`. | `Run.CurrentNode: B1→AmmoCache→Interceptor`; `Fuel: 3→2→1`; `MissileStack.Ammo: 0→2`. Player hull stays 4 and Laser stays damaged. Enemy entities spawn on arrival as above. | The run/route layer and inventory reward alter persistent state across encounters. Enemy spawn becomes visible at a barrier. | The player enters the same final battle with less hull margin but two shield-bypassing shots. |
| Turn 1: extinguish `BridgeFire` before the fire phase. | `BridgeFire.Health: 1→0`; queue `-Active`; `Ada.Health` remains 3. The volley consumes both shield pips (`2→0`), then end-of-turn recharge restores one (`0→1`). | Fire damage and target selection overlap on `Room + Active + Targetable + Damageable`; crew exposure joins `Room + Health`. The barrier removes the fire before exposure. | The hazard is gone; the missile route can ignore the damaged laser without leaving the crew in an active fire; one shield pip remains. |
| Turn 2: launch the first missile; turn 3: after its impact, launch the second. | Turn 2 consumes one ammo (`2→1`), changes `MissileLauncher.Cooldown: Ready→Reloading→Ready`, and stages a `Missile` with `Team=Blue`, `Target=EnemyHull`, `Damage=1`, `ArrivalTick=turn 3`. At the start of turn 3 it impacts: enemy `Hull: 2→1` and missile removal is committed; the player launches missile two (`Ammo: 1→0`, same one-turn cooldown and `ArrivalTick=turn 4`). The turn-2 and turn-3 volleys each consume the remaining shield pip; their second hits change `PlayerHull.Hull: 4→3` and `3→2`, respectively, then recharge restores one pip (`0→1`) each turn. | Each launch writes launcher and ammo entities and stages a projectile; the spawn barrier makes it queryable next tick. Impact queries projectile `Team + Target + Damage` against the target's `Damageable + Hull`, then the impact barrier removes the missile. Each shot therefore crosses 2+ entities over launch and impact transactions; no single cross-phase transaction is claimed. | The enemy shield graphic remains intact; the first missile deals one hull damage, the second is in flight, and the player still has hull 2. |
| Turn 4: the second missile impacts; then travel to Exit. | At tick start, impact changes enemy `Hull: 1→0`, queues missile removal and `-Active`, which commit before the enemy-fire phase, so there is no turn-4 enemy volley. The powered player shield recharges (`1→2`). `Run.Fuel: 1→0`; after combat, `Run.CurrentNode: Interceptor→Exit`; `Run.Outcome: Active→Won`. | Impact queries projectile `Team + Target + Damage` against `Damageable + Hull`; the impact barrier removes the missile and deactivates the destroyed ship. The run objective then reads the surviving player hull and completed final-node state. | The enemy hull indicator reaches zero; the player still has hull 2 and reaches the exit alive. |
### Failed FTL action: blocked repair order is a no-op

At the branch state, before either route opens `Door-BW`, the player orders Ada to repair the Laser. The proposed order validator cannot find a path through the closed door and rejects the request before writing anything:

| Entity | Before | After rejection |
|---|---|---|
| `Ada` | `Room=Bridge`, `Order=None`, `Health=3` | Identical |
| `Door-BW` | `Closed` | Identical |
| `Laser` | `SystemDamage=1`, `AttackDamage=1`, no `Operational` | Identical |
| Run command queue / battle log | no repair command/event | unchanged |

The UI says “No route to Weapons”; no repair sound or success marker is emitted. This is a player-command refusal, not a failed Bendvy transaction. By contrast, a successful repair action touches at least the `Ada` and `Laser` entities, and a missile launch/impact touches launcher, ammo, projectile, and target entities across phases.

### FTL limits exposed by the trace

The route reward, persistent hull damage, system repair, crew assignment, and enemy-target choice all survive the one-battle simplification, but the trace still assumes a prior skirmish. If that common encounter, route selection, inter-encounter persistence/spending, and final exit are removed, the result is a tactical ship-combat demo; it should not be called an FTL clone. The minimum non-ECS work is a small seeded route graph, room adjacency/path lookup, a pauseable combat clock/input layer, renderer/HUD, and a deliberately tiny power/weapon/shield/hazard model. A robust general route generator, authored encounter catalog, or full oxygen/fire simulator is outside this trace.

## SS14-style emergency shift: spend the only repair charge or preserve pressure

The two valid routes are carried over from the [single-player emergency slice in hypothesis 07](07-space-station.md), which itself labels them as an original adaptation rather than the full social SS14 round. The published game makes crew jobs, role-play, and multiplayer interaction part of its core, so a solo engineer scenario is recognizable as a station-engineering emergency but not a full SS14 clone. ([About SS14](https://spacestation14.com/about/about/))

### Proposed fixed setup

This is a two-room deterministic scenario. All values and turn rules below are invented: `Ops` starts breathable; `Bay` starts at pressure 60/100 and loses 10 per turn while its `Breach.Active` component exists; below 40, an unsuited engineer loses one health per turn. A shuttle arrives at turn 4 and departs at turn 8. The player must be aboard and alive at departure. The round processes player action, component/command commit, explicit barrier, then power/pressure/exposure/timer systems.

| Entity | Initial components/state |
|---|---|
| `Engineer` | `Health=4`, `Room=Bay`, `Order=None`, no suit equipped |
| `RepairKit` | `RepairCharges=1`, `HeldBy=Engineer` |
| `Suit` | `StoredIn=BayLocker`, `Protective` |
| `BayLocker` | `Room=Bay`, `Container` |
| `Breach` | `Room=Bay`, `Active`, `Damageable` |
| `APC` | `Room=Bay`, `Broken`, `Repairable`, `PowerSource` |
| `Bulkhead` | `Endpoints=(Bay,Ops)`, `Open` |
| `Airlock` | `MotorPowered` absent, `Closed`, `CrankProgress=0/2` |
| `Bay`, `Ops` | `RoomAir` values `60/100`, `100/100` |
| `Shuttle` | `ArrivalTurn=4`, `DepartureTurn=8`, empty `Manifest` |

The pressure rule is intentionally tiny: the breach reduces only Bay by 10 each turn; the open bulkhead transfers the low-air hazard to Ops; a closed bulkhead cuts that graph edge; repaired APC adds `MotorPowered` to the airlock. The atmosphere/power coupling is a proposed toy solver, not an implementation of SS14 atmospherics.

### Winning strategy A: patch the breach, hand-crank the airlock

| Turn / player action | Exact proposed state change | Overlapping systems and structural boundary | Visible result |
|---|---|---|---|
| 1 — use the only charge on `Breach`. | `RepairKit.RepairCharges: 1→0`; `Breach: -Active/+Sealed`; Bay pressure remains 60 instead of falling below the unsafe threshold. | Tool-use validates the actor, held kit and target. The repair action spans `RepairKit` and `Breach`; the barrier publishes the new source state before pressure propagation. `Engineer.Room + Health` also participates in exposure checks. | Leak animation stops and the pressure readout holds. The APC remains broken and Airlock remains unpowered. |
| 2–3 — crank the airlock twice. | `Airlock.CrankProgress: 0/2→1/2→2/2`; at 2/2 add `Open`. | Interaction system writes the airlock; door lifecycle/round systems observe its committed state at the barrier. No APC or power transition occurs. | A progress indicator advances, then the unpowered lock opens by hand. |
| 4–5 — wait for shuttle arrival, then board. | On turn 4, add `Docked` to Shuttle. On turn 5, add `Aboard{Shuttle}` to Engineer and add Engineer to `Shuttle.Manifest`. At turn 8, `RoundOutcome: Active→Won` if Engineer is alive and still aboard. | Boarding updates two related entities; the shuttle-round objective reads the same Crew/Manifest relation and health used by damage/exposure. Arrival is a separate committed phase, so an earlier board request can be rejected cleanly. | The engineer boards before departure; the open leak is sealed, while the APC remains visibly broken. |

### Winning strategy B: isolate the leak, wear the suit, restore airlock power

| Turn / player action | Exact proposed state change | Overlapping systems and structural boundary | Visible result |
|---|---|---|---|
| 1 — close the bulkhead. | `Bulkhead: -Open/+Closed`. Pressure values after the tick: Bay `60→50`; Ops remains `100` because the room-edge is cut before hazard propagation. | The same `Endpoints + Open` data is read by crew navigation and pressure propagation. Barrier makes the closure visible to both before their phases. | A bulkhead animation plays; Ops pressure stays green while Bay warning turns red. |
| 2 — equip the emergency suit. | Remove `StoredIn` from Suit; add `EquippedSuit{Suit}` to Engineer and `WornBy{Engineer}` to Suit. Pressure becomes Bay `50→40`. | Equipment/containment changes two entities. Exposure system queries `Room + Health` and excludes a crew member whose referenced suit has `Protective`. | Suit icon appears; the engineer can tolerate the low-pressure bay. |
| 3 — spend the charge on the APC. | `RepairKit.RepairCharges: 1→0`; `APC: -Broken/+Operational`; after the barrier PowerSystem adds `MotorPowered` to Airlock. Breach remains `Active`; Bay pressure falls to 30, but Engineer is protected by the equipped suit. | Repair transaction touches kit and APC; power system then updates Airlock. APC is both repairable/damageable and a power source. Crew and suit remain in the exposure query. | Airlock power indicator turns green; leak and low pressure remain visible behind the closed bulkhead. |
| 4 — open the powered airlock; 5 — board the shuttle after its turn-4 arrival. | `Airlock: -Closed/+Open`; then `Engineer: +Aboard{Shuttle}` and `Shuttle.Manifest: []→[Engineer]`. At departure turn 8, commit `RoundOutcome=Won`. | Airlock state is read by exit navigation and the round objective. Boarding spans Engineer and Shuttle; the win system also checks alive/aboard state. | The suited engineer leaves through the powered lock while the breach continues in the isolated bay. |

### Failed station action: trying to board before docking is also a no-op

At turn 1, Shuttle has no `Docked` component and `Manifest=[]`. The player tries to board. The proposed boarding validator rejects before writes:

| Entity | Before | After rejection |
|---|---|---|
| `Engineer` | `Room=Bay`, no `Aboard` relation, `Health=4` | Identical |
| `Shuttle` | no `Docked`, `Manifest=[]` | Identical |
| `Round` | `Active`, timer unchanged by this command | Identical |

No `Aboard` component/relation, `Boarded` event, command queue entry, or win banner appears. This does not ask Bendvy to roll back. The valid board action later changes both Engineer and Shuttle; the failed action is an ordinary checked refusal.

### Station limits exposed by the trace

The shared door relation changes both routes and hazard spread; Crew/Health, tools, Breach, APC, Airlock and Shuttle each participate in separate overlapping mechanics. Removing room topology and the pressure/power consequences would reduce the design to a checklist. The minimum non-ECS services are grid movement/collision, a room/door graph, one bounded pressure and power solver, interaction input/UI, renderer, and shuttle clock. The broad SS14 multiplayer/social loop, mature atmosphere networks and authored station content remain absent; the trace therefore supports “station emergency” as a first slice, not a solo clone of the whole round-based game.

## Baba Is You-style room: move the rule that changes the wall query

Use the exact hand-authored board and route from [10-rule-puzzles.md](10-rule-puzzles.md): 11×10 bounds, Baba at `(3,9)`, Rock at `(2,9)`, `STOP` at `(2,8)`, a vertical wall barrier at `x=5`, and Flag at `(8,4)`. It starts with `BABA IS YOU`, `ROCK IS PUSH`, `FLAG IS WIN`, and `WALL IS STOP`. The board, dimensions, grammar subset, coordinates, and turns are a proposed room from report 10, not an official level. That report explicitly says it is a manually reasoned route and not an executed trace.

| Player action | Exact proposed state change | Overlapping systems and structural boundary | Visible result |
|---|---|---|---|
| Move left from Baba `(3,9)`. | `Baba.Position: (3,9)→(2,9)`; `Rock.Position: (2,9)→(1,9)`. `ROCK IS PUSH` remains active. | Movement queries `Position + You`; push planning also queries `Position + Pushable`; occupancy checks destination `(1,9)` against the Wall at `(0,9)`. The atomic move touches Baba and Rock (2 entities). No property composition changes, so no component barrier is needed for this move. | Baba moves left and pushes Rock against the guard Wall. |
| Move up from `(2,9)`. | `Baba.Position: (2,9)→(2,8)`; the word entity `STOP.Position: (2,8)→(2,7)`. The sentence `WALL IS STOP` breaks. Rule scan removes derived `Stop` from all physical Wall entities at the explicit barrier; text words remain pushable. | The move uses the rule set frozen at its start. Then rule scan reads `TextWord + Position`, recomputes active sentences, and stages component removals. Movement/obstacle queries before the barrier still see old `Stop`; later queries see the new composition. | The `WALL IS STOP` sentence visibly separates and the wall barrier stops blocking. |
| Optional guard detour: down to `(2,9)`, right twice to `(4,9)`, up to `(4,8)`, right three to `(7,8)`. | Baba's `Position` changes through each listed cell. At `(5,8)`, Baba co-locates with a Wall entity whose `Stop` was removed. Wall entities remain present and render; only the `Stop` component is absent. | Movement and collision query `Position + You/Stop`; the occupancy helper must allow a cell to contain both Baba and a non-stopping Wall. The barrier is already committed, so each following move sees the new query membership. | Baba visibly passes through the vertical wall line. |
| Move up four times to `(7,4)`, then right onto Flag `(8,4)`. | `Baba.Position: (7,4)→(8,4)`; `LevelState: Playing→Won` after overlap with the Flag entity carrying `Win`. | Win query joins `You + Position` with `Win + Position`; the rule-derived composition established earlier changes the route, and the goal system observes the final overlap after the move commits. | Level-complete state appears; the flag and Baba overlap. |

The optional detour above is not needed after the rule barrier removes `Stop` from every Wall: from `(2,8)`, Baba can go Right×5 to `(7,8)`, Up×4 to `(7,4)`, then Right onto the Flag. Those moves cross the former wall positions directly. This route was checked by hand; no solver was executed. The minimum non-ECS machinery is a bounded rule scanner for the closed triple grammar, deterministic push-chain planning, a multi-occupant cell lookup, keyboard input, renderer/HUD, and per-turn inverse/delta history for undo. There is no need for continuous physics, a route graph, multiplayer, or an entity for every empty cell. The dynamic rule scan is still external domain logic: ECS only demonstrates its value if independent movement, obstacle, and win queries actually consume the derived components. If one central `resolve_level()` owns the whole cell array, this is a simple Sokoban-like parser puzzle with ECS wrappers.

## What survives simplification, and what each trace asks ECS to do

| Candidate | Multi-entity transaction/action? | Minimum non-ECS infrastructure | Decision lost if reduced too far |
|---|---|---|---|
| FTL-like short run | Yes: crew repair changes Crew + System; missile launch/impact links Launcher, Ammo, Missile and target over phase transactions. Route repair also changes one hull entity plus the Scrap resource. | Seeded small route graph, room adjacency/path lookup, pause/tick/input, combat HUD, bounded power/shield/hazard rules. | Removing route, reward spending, persistent hull/system/crew state, or final exit turns it into a battle demo. A single battle is not enough to call it an FTL clone. |
| SS14 station emergency | Yes: tool repair changes Kit + Breach/APC; boarding changes Engineer + Shuttle. Suit equipment changes the Crew/Suit relation. | Grid movement/collision, room graph, toy pressure/power propagation, interaction UI, evacuation clock/renderer. Full multiplayer and mature atmos solvers are out of slice. | Removing the two repair/evacuation routes, door-pressure coupling, or visible timer turns it into a scripted checklist. Keeping the solo slice does not preserve SS14's social round. |
| Baba-like room | Yes: a push changes Baba + Rock/word; one rule change removes `Stop` from many Wall entities at a barrier. | Closed rule parser, push/occupancy helper with co-location, input/renderer, undo delta. | If removing `WALL IS STOP` does not change the collision query and open the route, this is just a parser demo or static Sokoban room. |

These traces make different ECS claims. The station scenario has the broadest shared physical world: crew, tools, rooms, doors, power, hazard and objective systems intersect. FTL keeps a stronger small-game loop by carrying state across route choices and encounters, but still needs a room graph and more phases. Baba gives the cleanest runtime component change per player input and the smallest host; its relations and long-lived simulation are weak. If “maximum ECS mechanics” dominates, SS14 is strongest among these three provided the pressure/power graph stays a real causal loop. If the priority is the smallest finished clone that still demonstrates structural composition, Baba is the safer first slice. An FTL-like prototype only qualifies as the clone candidate once it includes route choice, persistence, reward spending and an exit condition in addition to the battle.

The trace designs are not evidence of throughput or correctness. Their falsifiers are practical: if component membership changes do not alter later query results; if actions must be centralized into one record-array update to preserve coherence; if the host solver consumes more work than the ECS consumer; or if playtesters cannot distinguish a win/loss/route choice after the stated reductions, then the corresponding ECS-clone claim weakens.
