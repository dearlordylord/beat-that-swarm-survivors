import Base
import ./coop-lobby.bend as L

law unstarted_party_never_runs:
  for seats:List<&2,L.Seat>
  {L.running(L.State{False{},seats,0}) == False{} : Bool}

law rejected_start_preserves_party:
  for state:L.State
  {L.start_selected(False{},state) == state : L.State}

law solo_host_cannot_start:
  for character:U32
  {L.can_start(L.fresh(character)) == False{} : Bool}

law invalid_seat_never_admitted:
  for started:Bool
  for seats:List<&2,L.Seat>
  {L.admit(L.State{started,seats,0},4) == False{} : Bool}

law started_setup_is_locked:
  for seats:List<&2,L.Seat>
  for epoch:U32
  for player:U32
  {L.can_configure(L.State{True{},seats,epoch},player) == False{} : Bool}


law started_host_setup_is_locked:
  for seats:List<&2,L.Seat>
  for epoch:U32
  for character:U32
  for stage:U32
  for mode:U32
  for arcana:U32
  for allowed:U32
  {L.can_configure_host(L.State{True{},seats,epoch},character,stage,mode,arcana,allowed) == False{} : Bool}
