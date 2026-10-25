import Base
import ../pickup-state.bend as Pickup
import ../pickup-xp-pool.bend as Pool
import ../enemy-spatial.bend as Space

# Guarantees: collecting active XP pays its exact amount once, clears occupancy
#   and amount, and preserves the slot identity and lifetime generation.
# Why it matters: overlapping players and pool reuse must not duplicate XP or
#   make a collected incarnation indistinguishable from the next one.
law collected_xp_is_exact:
  for +x: F32 for +y: F32 for age: U32 for radius: F32
  for +amount: U32 for +marked: Bool for +identity: U32 for +generation: U32
  {Pickup.step(True{},Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Xp{amount,marked},generation,True{}},identity}) == Pickup.Outcome{Pickup.State{Space.Spatial{x,y,0,0.0},Pickup.Payload{Pickup.Xp{0,marked},generation,False{}},identity},Pickup.Reward{amount,0,0,0,0}} : Pickup.Outcome}

# Guarantees: an inactive pickup produces no reward and changes no facts.
# Why it matters: a second collector in the same incarnation cannot claim the
#   previous pickup again, and an unused pool slot cannot fabricate a reward.
law inactive_pickup_is_inert:
  for +space: Space.Spatial for +item: Pickup.Item
  for +identity: U32 for +generation: U32 for found: Bool
  {Pickup.step(found,Pickup.State{space,Pickup.Payload{item,generation,False{}},identity}) == Pickup.Outcome{Pickup.State{space,Pickup.Payload{item,generation,False{}},identity},Pickup.Reward{0,0,0,0,0}} : Pickup.Outcome}

# Guarantees: overflow adds its unsigned amount to the chosen active XP pile.
# Why it matters: reaching the fixed pool budget must merge the actual drop
#   amount instead of losing or duplicating the reward.
law overflow_amount_is_exact:
  for x: F32 for y: F32 for age: U32 for radius: F32
  for +amount: U32 for marked: Bool for identity: U32 for generation: U32
  for +incoming: U32
  {Pickup.amount(Pool.merge_overflow(True{},Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Xp{amount,marked},generation,True{}},identity},incoming)) == (amount + incoming : U32) : U32}

# Guarantees: overflow preserves the selected pile's incarnation label.
# Why it matters: a larger visible pile is still the same pickup lifetime for
#   collection, observations and co-op reconciliation.
law overflow_generation_is_preserved:
  for x: F32 for y: F32 for age: U32 for radius: F32
  for amount: U32 for marked: Bool for identity: U32 for +generation: U32
  for incoming: U32
  {Pickup.generation(Pool.merge_overflow(True{},Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Xp{amount,marked},generation,True{}},identity},incoming)) == generation : U32}
