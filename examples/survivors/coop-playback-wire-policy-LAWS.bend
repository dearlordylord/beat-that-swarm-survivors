import Base
import ./coop-playback-wire-policy.bend as W
import ./coop-playback.bend as P
import ./coop-combat-prediction-policy.bend as Numbers
import ./body-index.bend as BI

# Guarantees: Canonical lifetime identity includes the authoritative birth and the correct actor namespace.
# Why it matters: A recycled seed or another player projectile cannot reuse an old interpolation path.
law enemy_generation_exact:
  for +seed:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  {W.generation(0,seed,born,weapon,slot) == "enemy:" ++ U32.show(seed) ++ ":" ++ U32.show(born) : String}

# Guarantees: Canonical lifetime identity includes the authoritative birth and the correct actor namespace.
# Why it matters: A recycled seed or another player projectile cannot reuse an old interpolation path.
law projectile_generation_exact:
  for +seed:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  {W.generation(1,seed,born,weapon,slot) == U32.show((slot / 65536 : U32)) ++ ":" ++ U32.show((born - 0 : U32)) ++ ":" ++ U32.show(weapon) ++ ":" ++ U32.show((slot % 65536 : U32)) : String}

# Guarantees: Canonical lifetime identity includes the authoritative birth and the correct actor namespace.
# Why it matters: A recycled seed or another player projectile cannot reuse an old interpolation path.
law hostile_generation_exact:
  for +seed:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  {W.generation(7,seed,born,weapon,slot) == "hostile:" ++ U32.show(seed) ++ ":" ++ U32.show(born) : String}

# Guarantees: Only friendly projectiles use the player encoded in the logical slot; other kinds have no player owner.
# Why it matters: Projectile contact matching must not mix owner namespaces.
law visual_owner_exact:
  for +kind:U32
  for +slot:U32
  {W.visual_owner(kind,slot) == Bool.pick(U32,U32.is_eq(kind,1),(slot / 65536 : U32),4294967295) : U32}

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

# Guarantees: Kinds one and seven use positive life and pierce as the live marker; other actors use positive health.
# Why it matters: Gameplay projectiles may have zero health yet must interpolate while active.
law body_liveness_exact:
  for +kind:U32
  for +hp:U32
  for +life:U32
  for +pierce:U32
  {W.body_liveness(kind,hp,life,pierce) == Bool.pick(Bool,Bool.or(U32.is_eq(kind,1),U32.is_eq(kind,7)),Bool.and(U32.is_gt(life,0),U32.is_gt(pierce,0)),U32.is_gt(hp,0)) : Bool}

# Guarantees: Projected bodies use the shared lifetime, owner and liveness policies and normalize both coordinates.
# Why it matters: The live projection boundary must actually apply the rules that prevent projectile stepping.
law body_projection_exact:
  for +seed:U32
  for +kind:U32
  for +born:U32
  for +weapon:U32
  for +slot:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +hp:U32
  for +life:U32
  for +pierce:U32
  {W.body_actor(seed,kind,born,weapon,slot,x,y,age,hp,life,pierce) == P.Actor{seed,kind,W.generation(kind,seed,born,weapon,slot),Numbers.from_bits(F32.bits(x)),Numbers.from_bits(F32.bits(y)),age,W.body_liveness(kind,hp,life,pierce),W.visual_owner(kind,slot)} : P.Actor}

# Guarantees: The canonical birth index is queried at the seed with tick-minus-age as fallback.
# Why it matters: An explicit birth identity must not be replaced by an age-derived guess.
law birth_lookup_exact:
  for +births:BI.Index<U32>
  for +tick:U32
  for +age:U32
  for +seed:U32
  {W.birth(births,tick,age,seed) == BI.get(~U32,births,seed,(tick - age : U32)) : U32}

# Guarantees: Rejected extras produce no actor.
# Why it matters: Combat actors cannot be duplicated in the additional render inventory.
law extra_rejected:
  for +key:U32
  for +kind:U32
  for +variant:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +hp:U32
  for +tick:U32
  {W.extra_selected(False{},key,kind,variant,x,y,age,hp,tick) == None{} : Maybe<&2,P.Actor>}

# Guarantees: Retained extras carry item lifetime, normalized position, original age and explicit liveness, and no player owner.
# Why it matters: Loot and stage objects retain their separate presentation identity.
law extra_kept:
  for +key:U32
  for +kind:U32
  for +variant:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +hp:U32
  for +tick:U32
  {W.extra_selected(True{},key,kind,variant,x,y,age,hp,tick) == Some{P.Actor{key,kind,"item:" ++ U32.show(kind) ++ ":" ++ U32.show(variant) ++ ":" ++ U32.show((tick - age : U32)),Numbers.from_bits(F32.bits(x)),Numbers.from_bits(F32.bits(y)),age,U32.is_gt(hp,0),4294967295}} : Maybe<&2,P.Actor>}

# Guarantees: Exactly kinds zero, one and seven are excluded from the extras path.
# Why it matters: The IO adapter cannot independently decide which bodies belong to the canonical combat cohort.
law extra_policy_exact:
  for +key:U32
  for +kind:U32
  for +variant:U32
  for +x:F32
  for +y:F32
  for +age:U32
  for +hp:U32
  for +tick:U32
  {W.extra_actor(key,kind,variant,x,y,age,hp,tick) == W.extra_selected(Bool.not(Bool.or(U32.is_eq(kind,0),Bool.or(U32.is_eq(kind,1),U32.is_eq(kind,7)))),key,kind,variant,x,y,age,hp,tick) : Maybe<&2,P.Actor>}

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
