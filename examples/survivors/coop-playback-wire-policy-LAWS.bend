import Base
import pickup-state.bend as Pickup
import enemy-spatial.bend as Space
import ./coop-playback-wire-policy.bend as W
import ./coop-playback.bend as P
import ./coop-combat-prediction-policy.bend as Numbers
import ./body-index.bend as BI

# Guarantees: Canonical lifetime identity includes the authoritative birth and the correct actor namespace.
# Why it matters: A recycled seed or another player projectile cannot reuse an old interpolation path.
law enemy_generation_exact:
  for +seed:U32
  for +born:U32
  {W.enemy_generation(seed,born) == "enemy:" ++ U32.show(seed) ++ ":" ++ U32.show(born) : String}

# Guarantees: Canonical lifetime identity includes the authoritative birth and the correct actor namespace.
# Why it matters: A recycled seed or another player projectile cannot reuse an old interpolation path.
law projectile_generation_exact:
  for +seed:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  for +sourcePlayer:U32
  {W.projectile_generation(False{},seed,born,weapon,slot,Some{sourcePlayer}) == U32.show(sourcePlayer) ++ ":" ++ U32.show((born - 0 : U32)) ++ ":" ++ U32.show(weapon) ++ ":" ++ U32.show(slot) : String}

# Guarantees: Canonical lifetime identity includes the authoritative birth and the correct actor namespace.
# Why it matters: A recycled seed or another player projectile cannot reuse an old interpolation path.
law hostile_generation_exact:
  for +seed:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  {W.projectile_generation(True{},seed,born,weapon,slot,None{}) == "hostile:" ++ U32.show(seed) ++ ":" ++ U32.show(born) : String}

# Guarantees: The explicit source-player option is preserved as the timeline owner; None has no player owner.
# Why it matters: Projectile contact matching must not mix owner namespaces.
def specified_owner(source:Maybe<&2,U32>) -> U32:
  match source:
    case Some{player}: player
    case None{}: 4294967295
law visual_owner_exact:
  for +sourcePlayer:Maybe<&2,U32>
  {W.visual_owner(sourcePlayer) == specified_owner(sourcePlayer) : U32}

# Guarantees: Players retain their ID, character lifetime and connected liveness with F32-normalized coordinates.
# Why it matters: Disconnected characters cannot be treated as active projectile kinds.
law player_projection_exact:
  for +id:U32
  for +character:U32
  for +x:F32
  for +y:F32
  for +hp:U32
  for +connected:Bool
  {W.player_actor(id,character,x,y,hp,connected) == P.Actor{id,character,"player:" ++ U32.show(id) ++ ":" ++ U32.show(character),Numbers.from_bits(F32.bits(x)),Numbers.from_bits(F32.bits(y)),0,Bool.and(connected,U32.is_gt(hp,0)),id} : P.Actor}

# Guarantees: Enemy presentation carries its exact lifetime, normalized position,
# original age and health-derived liveness, without a projectile owner.
# Why it matters: Enemy projection never needs fabricated weapon or shot fields.
law enemy_projection_exact:
  for +identity:U32
  for +born:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +health:U32
  {W.enemy_actor(identity,born,x,y,age,health) == P.Actor{identity,0,W.enemy_generation(identity,born),Numbers.from_bits(F32.bits(x)),Numbers.from_bits(F32.bits(y)),age,U32.is_gt(health,0),4294967295} : P.Actor}

# Guarantees: Projectile presentation preserves its side, lifetime, normalized
# position, age and source; liveness requires both remaining life and pierce.
# Why it matters: A zero-damage projectile still interpolates while active.
law projectile_projection_exact:
  for +hostile:Bool
  for +seed:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  for +sourcePlayer:Maybe<&2,U32>
  for +x:F32
  for +y:F32
  for +age:U32
  for +life:U32
  for +pierce:U32
  {W.projectile_actor(hostile,seed,born,weapon,slot,sourcePlayer,x,y,age,life,pierce) == P.Actor{seed,Bool.pick(U32,hostile,7,1),W.projectile_generation(hostile,seed,born,weapon,slot,sourcePlayer),Numbers.from_bits(F32.bits(x)),Numbers.from_bits(F32.bits(y)),age,Bool.and(U32.is_gt(life,0),U32.is_gt(pierce,0)),W.visual_owner(sourcePlayer)} : P.Actor}

# Guarantees: The canonical birth index is queried at the seed with tick-minus-age as fallback.
# Why it matters: An explicit birth identity must not be replaced by an age-derived guess.
law birth_lookup_exact:
  for +births:BI.Index<U32>
  for +tick:U32
  for +age:U32
  for +seed:U32
  {W.birth(births,tick,age,seed) == BI.get(~U32,births,seed,(tick - age : U32)) : U32}

# Guarantees: Projected bodies precede extras and each original list keeps its order.
# Why it matters: The stack-safe concatenation must not reverse or omit an actor inventory.
law join_preserves_order:
  for +first:List<&2,P.Actor>
  for +second:List<&2,P.Actor>
  {W.join(first,second) == List.append(&2,P.Actor,first,second) : List<&2,P.Actor>}

# Guarantees: Frame assembly preserves observation, world tick, local receipt time and player inventory, then joins bodies and extras.
# Why it matters: All actors must remain attached to one authoritative observation and clock.
law frame_exact:
  for +observation:U32
  for +tick:U32
  for +receivedAt:Nat
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  for +extras:List<&2,P.Actor>
  {W.frame(observation,tick,receivedAt,players,bodies,extras) == P.Frame{observation,tick,receivedAt,players,W.join(bodies,extras)} : P.Frame}

# Guarantees: Typed xp projection preserves position, age, activity and lifetime.
# Why it matters: Recycling a slot must not reuse an unrelated interpolation path.
law xp_projection_exact:
  for +key:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +radius:F32
  for +active:Bool
  for +amount:U32
  for +accumulator:Bool
  {W.pickup_actor(Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Xp{amount,accumulator},generation,active},key}) == P.Actor{key,2,"pickup:" ++ U32.show(key) ++ ":" ++ U32.show(generation),x,y,age,active,4294967295} : P.Actor}

# Guarantees: Typed gold projection preserves position, age, activity and lifetime.
# Why it matters: Recycling a slot must not reuse an unrelated interpolation path.
law gold_projection_exact:
  for +key:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +radius:F32
  for +active:Bool
  for +coins:U32
  {W.pickup_actor(Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Gold{coins},generation,active},key}) == P.Actor{key,3,"pickup:" ++ U32.show(key) ++ ":" ++ U32.show(generation),x,y,age,active,4294967295} : P.Actor}

# Guarantees: Typed healing projection preserves position, age, activity and lifetime.
# Why it matters: Recycling a slot must not reuse an unrelated interpolation path.
law healing_projection_exact:
  for +key:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +radius:F32
  for +active:Bool
  for +health:U32
  {W.pickup_actor(Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Healing{health},generation,active},key}) == P.Actor{key,4,"pickup:" ++ U32.show(key) ++ ":" ++ U32.show(generation),x,y,age,active,4294967295} : P.Actor}

# Guarantees: Typed chest projection preserves position, age, activity and lifetime.
# Why it matters: Recycling a slot must not reuse an unrelated interpolation path.
law chest_projection_exact:
  for +key:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +radius:F32
  for +active:Bool
  {W.pickup_actor(Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Chest{},generation,active},key}) == P.Actor{key,5,"pickup:" ++ U32.show(key) ++ ":" ++ U32.show(generation),x,y,age,active,4294967295} : P.Actor}

# Guarantees: Typed relic projection preserves position, age, activity and lifetime.
# Why it matters: Recycling a slot must not reuse an unrelated interpolation path.
law relic_projection_exact:
  for +key:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +radius:F32
  for +active:Bool
  for +stage:U32
  {W.pickup_actor(Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Relic{stage},generation,active},key}) == P.Actor{key,9,"pickup:" ++ U32.show(key) ++ ":" ++ U32.show(generation),x,y,age,active,4294967295} : P.Actor}
