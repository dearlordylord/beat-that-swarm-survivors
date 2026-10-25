import Base
import ../projectile-contact.bend as C

# Guarantees: a projectile already touching a target reports immediate contact.
# Why it matters: an overlap must consume damage even when relative motion is zero.
law initial_contact_is_not_lost:
  for a:F32
  for b:F32
  for c:F32
  {C.initial_overlap(True{},a,b,c) == C.Hit{0.0} : C.Impact}

# Guarantees: a separated target with no approaching relative movement is missed.
# Why it matters: stationary or receding shots must not damage distant enemies.
law separated_without_approach_misses:
  for a:F32
  for b:F32
  for c:F32
  {C.moving_towards(False{},a,b,c) == C.Miss{} : C.Impact}

# Guarantees: a negative discriminant cannot create a contact.
# Why it matters: paths passing beside an enemy must leave its health unchanged.
law no_real_entry_misses:
  for b:F32
  for c:F32
  for disc:F32
  {C.discriminant_valid(False{},b,c,disc) == C.Miss{} : C.Impact}

# Guarantees: an entry within this tick returns its supplied time; a later entry misses.
# Why it matters: damage belongs to the tick traversed rather than a future tick.
law entry_gate_exact:
  for +inside:Bool
  for +time:F32
  {C.within_tick(inside,time) == Bool.pick(C.Impact,inside,C.Hit{time},C.Miss{}) : C.Impact}

# Guarantees: an excluded target never enters the ordered contacts, even on overlap.
# Why it matters: already pierced enemies must not consume the remaining hit budget.
law excluded_target_preserves_contacts:
  for seed:U32
  for impact:C.Impact
  for +rows:List<&2,C.Contact>
  {C.collect(True{},seed,impact,rows) == rows : List<&2,C.Contact>}

# Guarantees: a geometric miss never enters the ordered contacts.
# Why it matters: a projectile's pierce budget cannot be spent on an absent contact.
law missed_target_preserves_contacts:
  for seed:U32
  for +rows:List<&2,C.Contact>
  {C.add(seed,C.Miss{},rows) == rows : List<&2,C.Contact>}

# Guarantees: every admitted geometric hit is inserted with its identity and time.
# Why it matters: replacing the contact collector with all-miss must fail.
law admitted_hit_is_inserted:
  for +seed:U32
  for +time:F32
  for +rows:List<&2,C.Contact>
  {C.add(seed,C.Hit{time},rows) == C.insert(C.Contact{seed,time},rows) : List<&2,C.Contact>}

# Guarantees: inserting a contact adds exactly one entry and retains the old count.
# Why it matters: ordering cannot silently drop a target or duplicate damage.
law ordering_preserves_contact_count:
  for +item:C.Contact
  for +rows:List<&2,C.Contact>
  {List.length(&2,C.Contact,C.insert(item,rows)) == 1n+List.length(&2,C.Contact,rows) : Nat}

# Guarantees: the first-target projection uses exactly the smaller of budget and contacts.
# Why it matters: a finite-pierce projectile neither exceeds its budget nor stops early.
law exact_budget_consumption:
  for +budget:U32
  for +rows:List<&2,C.Contact>
  {List.length(&2,U32,C.first_ids(budget,rows)) == Nat.min(U32.to_nat(budget),List.length(&2,C.Contact,rows)) : Nat}

# Guarantees: a new earlier-or-tied contact is placed before the supplied head.
# Why it matters: spatial priority must win over ECS traversal order at insertion.
law earlier_contact_precedes_head:
  for +item:C.Contact
  for +head:C.Contact
  for +tail:List<&2,C.Contact>
  for earlier:{True{} == Cmp.is_le(C.compare(item,head)) : Bool}
  {C.insert(item,head <> tail) == item <> head <> tail : List<&2,C.Contact>}

# Guarantees: equal encoded entry times compare using stable target identities.
# Why it matters: simultaneous contacts must not depend on ECS row order.
law equal_time_uses_identity:
  for +left:U32
  for +right:U32
  for +time:F32
  {C.compare(C.Contact{left,time},C.Contact{right,time}) == U32.cmp(left,right) : Cmp}


def tally(~observed:C.Contact -> Bool,rows:List<&2,C.Contact>) -> Nat:
  match rows:
    case []: 0n
    case head <> tail: Nat.add(Bool.pick(Nat,observed(head),1n,0n),tally(~observed,tail))

# Guarantees: ordering retains the count of every observable contact payload.
# Why it matters: equal list lengths alone would permit replacing real targets.
law ordering_preserves_payloads:
  for ~observed:C.Contact -> Bool
  for +item:C.Contact
  for +rows:List<&2,C.Contact>
  {tally(~observed,C.insert(item,rows)) == Nat.add(Bool.pick(Nat,observed(item),1n,0n),tally(~observed,rows)) : Nat}


# Guarantees: the public budget projection returns the actual prefix identities.
# Why it matters: the correct count must not conceal replacement target identities.
law budget_preserves_prefix_identities:
  for +budget:U32
  for +rows:List<&2,C.Contact>
  {C.first_ids(budget,rows) == List.take(&2,U32,C.ids(rows),U32.to_nat(budget)) : List<&2,U32>}

def all_visited(rows:List<&2,C.Target>,+visited:List<&2,U32>) -> Bool:
  match rows:
    case []: True{}
    case C.Target{+seed,_,_,_,_,_} <> tail: Bool.and(C.contains(visited,seed),all_visited(tail,visited))

# Guarantees: when every supplied target was already pierced, public collection is empty.
# Why it matters: collector wiring must actually apply the persistent visited set.
law public_visited_targets_are_excluded:
  for +rows:List<&2,C.Target>
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +radius:F32
  for +visited:List<&2,U32>
  for +excluded:{True{} == all_visited(rows,visited) : Bool}
  {C.contacts(rows,x0,y0,x1,y1,radius,visited) == [] : List<&2,C.Contact>}

# Guarantees: both target endpoints contribute to relative displacement over this tick.
# Why it matters: moving enemies crossing a projectile cannot be treated as stationary.
# This pins numerical parameter routing, not an IEEE arithmetic correctness theorem.
law relative_endpoints_are_used:
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +ex0:F32
  for +ey0:F32
  for +ex1:F32
  for +ey1:F32
  for +radius:F32
  {C.sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius) == C.relative((x0 - ex0 : F32),(y0 - ey0 : F32),((x1 - x0) - (ex1 - ex0) : F32),((y1 - y0) - (ey1 - ey0) : F32),radius) : C.Impact}

# Guarantees: an unvisited target reported as intersecting reaches the public contact list.
# Why it matters: replacing public collection with an empty list must fail.
law public_single_hit_is_collected:
  for +seed:U32
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +ex0:F32
  for +ey0:F32
  for +ex1:F32
  for +ey1:F32
  for +radius:F32
  for +r:F32
  for +time:F32
  for +visited:List<&2,U32>
  for fresh:{False{} == C.contains(visited,seed) : Bool}
  for intersecting:{C.Hit{time} == C.sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,(radius + r : F32)) : C.Impact}
  {C.contacts(C.Target{seed,ex0,ey0,ex1,ey1,r} <> [],x0,y0,x1,y1,radius,visited) == C.Contact{seed,time} <> [] : List<&2,C.Contact>}
