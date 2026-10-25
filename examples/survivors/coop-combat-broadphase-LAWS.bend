import Base
import ./coop-combat-broadphase.bend as B
import ./projectile-contact.bend as Contact

# Scope: exact candidate selection, ordering, visitation and guarded fallback.
# These laws do NOT prove that Float32 swept hits imply AABB overlap. The large
# outward margin and bounded fast envelope are qualified against the unchanged
# solver and complete combat-state reference by differential execution.

# Guarantees: only the declared finite coordinate interval admits fast boxes.
# Why it matters: extreme and non-finite inputs must retain the reference path.
law coordinate_envelope_exact:
  for +value:F32
  {B.coordinate(value) == Bool.and(F32.is_le((0.0 - 32768.0 : F32),value),F32.is_le(value,32768.0)) : Bool}

# Guarantees: the fast path additionally bounds both endpoints, radius and
# per-axis displacement; it does not silently widen its numeric envelope.
# Why it matters: its conservative engineering margin has a stated domain.
law path_envelope_exact:
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +radius:F32
  {B.envelope(x0,y0,x1,y1,radius) == Bool.and(Bool.and(B.coordinate(x0),B.coordinate(y0)),Bool.and(Bool.and(B.coordinate(x1),B.coordinate(y1)),Bool.and(Bool.and(F32.is_le(0.0,radius),F32.is_le(radius,1024.0)),Bool.and(F32.is_le(F32.abs((x1 - x0 : F32)),256.0),F32.is_le(F32.abs((y1 - y0 : F32)),256.0))))) : Bool}

# Guarantees: every side receives sixty-four world units of outward slack.
# Why it matters: rounding slack must not disappear in an optimization.
law outward_padding_exact:
  {B.padding() == 64.0 : F32}

# Guarantees: source and target boxes cover both movement endpoints plus the
# original radius and declared slack, retaining their actual admission flag.
# Why it matters: a current-position-only box would miss swept crossings.
law swept_bounds_exact:
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +radius:F32
  {B.bounds(x0,y0,x1,y1,radius) == B.Box{B.envelope(x0,y0,x1,y1,radius),((F32.min(x0,x1) - radius) - 64.0 : F32),((F32.max(x0,x1) + radius) + 64.0 : F32),((F32.min(y0,y1) - radius) - 64.0 : F32),((F32.max(y0,y1) + radius) + 64.0 : F32)} : B.Box}

# Guarantees: an out-of-envelope source cannot discard any unvisited target.
# Why it matters: a large/fast/exotic projectile falls back instead of tunneling.
law source_falls_back:
  for x0:F32
  for x1:F32
  for y0:F32
  for y1:F32
  for target:B.Box
  {B.overlaps(B.Box{False{},x0,x1,y0,y1},target) == True{} : Bool}

# Guarantees: an out-of-envelope target cannot be culled by a fast source box.
# Why it matters: a large or fast enemy still reaches the reference solver.
law target_falls_back:
  for source:B.Box
  for x0:F32
  for x1:F32
  for y0:F32
  for y1:F32
  {B.overlaps(source,B.Box{False{},x0,x1,y0,y1}) == True{} : Bool}

# Guarantees: fast boxes use inclusive overlap on both axes.
# Why it matters: touching a box boundary cannot exclude a candidate.
law inclusive_overlap_exact:
  for +lx0:F32
  for +lx1:F32
  for +ly0:F32
  for +ly1:F32
  for +rx0:F32
  for +rx1:F32
  for +ry0:F32
  for +ry1:F32
  {B.overlaps(B.Box{True{},lx0,lx1,ly0,ly1},B.Box{True{},rx0,rx1,ry0,ry1}) == Bool.and(Bool.and(F32.is_le(lx0,rx1),F32.is_le(rx0,lx1)),Bool.and(F32.is_le(ly0,ry1),F32.is_le(ry0,ly1))) : Bool}

# Guarantees: a previously consumed target never enters the swept solver again.
# Why it matters: reusing candidates must not repeat an existing contact.
law visited_is_excluded:
  for source:B.Box
  for target:B.Box
  {B.unvisited(True{},source,target) == False{} : Bool}

# Guarantees: an unvisited candidate is selected by exactly the overlap/fallback
# predicate, rather than an additional hidden admission rule.
# Why it matters: a broadphase must not filter by guessed damage or target HP.
law unvisited_uses_overlap:
  for +source:B.Box
  for +target:B.Box
  {B.unvisited(False{},source,target) == B.overlaps(source,target) : Bool}

# Guarantees: a retained candidate is prepended intact to the retained tail.
# Why it matters: original target order and duplicate target records survive.
law retain_exact:
  for +target:Contact.Target
  for +tail:List<&2,Contact.Target>
  {B.put(True{},target,tail) == target <> tail : List<&2,Contact.Target>}

# Guarantees: a rejected candidate leaves the retained tail intact.
# Why it matters: culling one target cannot delete any other target.
law reject_preserves_tail:
  for target:Contact.Target
  for +tail:List<&2,Contact.Target>
  {B.put(False{},target,tail) == tail : List<&2,Contact.Target>}

# Guarantees: target rows are selected in their original order by visited status
# followed by overlap/fallback, with each tail processed exactly once.
# Why it matters: filtered input must preserve the solver's contact tie behavior.
law candidate_step_exact:
  for +target:Contact.Target
  for +box:B.Box
  for +tail:List<&2,B.Item>
  for +source:B.Box
  for +visited:List<&2,U32>
  {B.candidates(B.Item{target,box} <> tail,source,visited) == B.put(B.unvisited(Contact.contains(visited,B.target_seed(target)),source,box),target,B.candidates(tail,source,visited)) : List<&2,Contact.Target>}

# Guarantees: each query builds its source box from both supplied endpoints and
# its actual radius, then filters the prepared target records.
# Why it matters: substituting a stationary source would hide fast crossings.
law query_path_exact:
  for +rows:List<&2,B.Item>
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +radius:F32
  for +visited:List<&2,U32>
  {B.query(B.Index{rows},x0,y0,x1,y1,radius,visited) == B.candidates(rows,B.bounds(x0,y0,x1,y1,radius),visited) : List<&2,Contact.Target>}
