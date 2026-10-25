import Base
import ../combat-policy.bend as C

# Guarantees: damage that exhausts health returns zero, for every health and hit amount.
# Why it matters: lethal player or enemy hits must not wrap into a large living health value.
law lethal_hit_exhausts_health:
  for +hp: U32
  for +damage: U32
  for lethal: {False{} == U32.is_lt(damage,hp) : Bool}
  {C.lose(hp,damage) == 0 : U32}

# Guarantees: a nonlethal hit subtracts precisely its damage.
# Why it matters: armor and source modifiers must reach the actual remaining health unchanged.
law surviving_hit_debits_exactly:
  for +hp: U32
  for +damage: U32
  for survives: {True{} == U32.is_lt(damage,hp) : Bool}
  {C.lose(hp,damage) == (hp - damage : U32) : U32}

# Guarantees: active invulnerability suppresses all contact pressure, regardless of its size.
# Why it matters: the final pressure multiplier must not reintroduce damage during invulnerability.
law invulnerable_contact_does_no_damage:
  for +hit: U32
  for +invuln: U32
  for amount: U32
  for protected: {False{} == U32.is_eq(invuln,0) : Bool}
  {C.contact_damage(hit,invuln,amount) == 0 : U32}

# Guarantees: without contact, no pressure damage is applied.
# Why it matters: time-based pressure alone must not hit an untouched player.
law absent_contact_does_no_damage:
  for +hit: U32
  for invuln: U32
  for amount: U32
  for absent: {False{} == U32.is_lt(0,hit) : Bool}
  {C.contact_damage(hit,invuln,amount) == 0 : U32}

# Guarantees: admitted contact preserves its complete damage amount.
# Why it matters: refusing all damage must not satisfy the protection laws.
law vulnerable_contact_applies_damage:
  for +hit: U32
  for +invuln: U32
  for +amount: U32
  for contact: {True{} == U32.is_lt(0,hit) : Bool}
  for vulnerable: {True{} == U32.is_eq(invuln,0) : Bool}
  {C.contact_damage(hit,invuln,amount) == amount : U32}
