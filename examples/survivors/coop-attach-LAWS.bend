import Base
import ./coop-attach.bend as A

# Guarantees: a two-player attachment passes the original complete affine state
# to the resume adapter and ignores every new setup field.
# Why it matters: reload must not run the initial player allocation/setup again.
# The production adapter is Core.quiet; its wiring is inspected and exercised
# against full-state equality. This law does not prove arbitrary adapter behavior.
law returning_guest_uses_original_state:
  for ~State:Type
  for ~Packet:Type
  for ~resume:State -> Packet
  for ~initial:State -> U32 -> U32 -> U32 -> U32 -> Packet
  for state:State
  for character:U32
  for meta:U32
  for arcana:U32
  for mask:U32
  {A.dispatch(~State,~Packet,~resume,~initial,2n,state,character,meta,arcana,mask) == resume(state) : Packet}

# Guarantees: a one-player attachment passes the original state and all selected
# setup fields to the initial attachment adapter.
# Why it matters: the first guest must receive its selected setup, not the empty
# existing-player path. Existing core_join owns the eligibility checks.
law first_guest_uses_initial_setup:
  for ~State:Type
  for ~Packet:Type
  for ~resume:State -> Packet
  for ~initial:State -> U32 -> U32 -> U32 -> U32 -> Packet
  for state:State
  for character:U32
  for meta:U32
  for arcana:U32
  for mask:U32
  {A.dispatch(~State,~Packet,~resume,~initial,1n,state,character,meta,arcana,mask) == initial(state,character,meta,arcana,mask) : Packet}
