import Base
import ./coop-prediction.bend as P
import ./player-movement.bend as M
import ./coop-session.bend as S
import ./arena.bend as A

# These statements pin the timing contract, not a second game simulation.
# World time, packet identity and observation freshness are separate values.

# Guarantees: speculation spans at most the fixed sixty-world-tick window.
# Why it matters: a missing observation cannot create an unbounded local future.
law horizon_exact:
  {P.horizon() == 60 : U32}

# Guarantees: lead is ceiling(milliseconds*60/1000)+4, capped at54; the input
# milliseconds are clipped before machine multiplication can overflow.
# Why it matters: the Setup round trip includes observation delay and must leave
# six world ticks of headroom inside the prediction window.
law lead_exact:
  for +roundTripMs:U32
  {P.lead(roundTripMs) == U32.min(54,((U32.min(roundTripMs,1000) * 60 + 999) / 1000 + 4 : U32)) : U32}

# Guarantees: advancing a world-clock value saturates at the U32 limit.
# Why it matters: a cursor must not wrap into an earlier epoch near that limit.
law after_exact:
  for +tick:U32
  for +amount:U32
  {P.after(tick,amount) == (tick + U32.min(amount,(4294967295 - tick : U32)) : U32) : U32}

# Guarantees: replay counts the bounded world-clock interval, not input rows.
# Why it matters: neutral world ticks still advance cooldowns and projectiles.
law world_count_exact:
  for +anchor:U32
  for +display:U32
  {P.world_count(anchor,display) == U32.min(60,(display - U32.min(display,anchor) : U32)) : U32}

# Guarantees: connected, running, living players are precisely those eligible.
# Why it matters: a pause or death must not become speculative movement.
law prediction_gate_exact:
  for +phase:U32
  for +hp:U32
  for +connected:Bool
  {P.allowed(phase,hp,connected) == Bool.and(connected,Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0))) : Bool}

# Guarantees: missing input for a world tick is neutral.
# Why it matters: a packet for42 cannot fill an empty world tick39.
law input_empty_neutral:
  for tick:U32
  {P.input_at([],tick) == P.Direction{1,1} : P.Direction}

# Guarantees: lookup compares target world ticks and preserves the entire row's
# direction; a nonmatching row delegates to the remaining history.
# Why it matters: neither transport sequence nor list position assigns game time.
law input_row_exact:
  for seq:U32
  for +target:U32
  for +x:U32
  for +y:U32
  for +tail:List<&2,P.Input>
  for +tick:U32
  {P.input_at(P.Input{seq,target,x,y} <> tail,tick) == Bool.pick(P.Direction,U32.is_eq(target,tick),P.Direction{x,y},P.input_at(tail,tick)) : P.Direction}

# Guarantees: a row assigned to this exact world tick supplies its axes.
# Why it matters: a valid future input must not be replaced by a neutral gap.
law assigned_input_selected:
  for seq:U32
  for +target:U32
  for +x:U32
  for +y:U32
  for tail:List<&2,P.Input>
  {P.input_at(P.Input{seq,target,x,y} <> tail,target) == P.Direction{x,y} : P.Direction}

# Guarantees: duplicate-target detection uses the target clock, not packet IDs.
# Why it matters: two commands cannot silently overwrite the same world slot.
law target_present_exact:
  for seq:U32
  for +target:U32
  for x:U32
  for y:U32
  for +tail:List<&2,P.Input>
  for +tick:U32
  {P.target_present(P.Input{seq,target,x,y} <> tail,tick) == Bool.or(U32.is_eq(target,tick),P.target_present(tail,tick)) : Bool}

# Guarantees: a new local step is permitted only in the enabled sixty-tick
# interval and while the world cursor can advance without wrapping.
# Why it matters: a stalled connection must freeze instead of retargeting input.
law can_tick_exact:
  for x:F32
  for y:F32
  for distance:F32
  for +enabled:Bool
  for inputs:List<&2,P.Input>
  for +anchor:U32
  for +display:U32
  for observation:U32
  for last:U32
  {P.can_tick(P.State{x,y,distance,enabled,inputs,anchor,display,observation,last}) == Bool.and(enabled,Bool.and(U32.is_lt(P.world_count(anchor,display),60),U32.is_lt(display,4294967295))) : Bool}

# Guarantees: local commands require a fresh packet ID, valid axes, room in the
# window, and an unassigned next world tick.
# Why it matters: repeat input cannot replace a slot that the host treats first-wins.
law command_gate_exact:
  for +px:F32
  for +py:F32
  for +distance:F32
  for +enabled:Bool
  for +inputs:List<&2,P.Input>
  for +anchor:U32
  for +display:U32
  for +observation:U32
  for +last:U32
  for +seq:U32
  for +x:U32
  for +y:U32
  {P.command_allowed(P.State{px,py,distance,enabled,inputs,anchor,display,observation,last},seq,x,y) == Bool.and(P.can_tick(P.State{px,py,distance,enabled,inputs,anchor,display,observation,last}),Bool.and(Bool.not(P.target_present(inputs,P.after(display,1))),Bool.and(U32.is_gt(seq,last),Bool.and(U32.is_le(x,2),U32.is_le(y,2))))) : Bool}

# Guarantees: an accepted command retains its packet ID but is assigned exactly
# cursor+1; it does not advance the cursor or compress any world-time gap.
# Why it matters: a cooldown tick cannot acquire a later packet's movement.
law command_assigns_next_world_tick:
  for +px:F32
  for +py:F32
  for +distance:F32
  for +enabled:Bool
  for +inputs:List<&2,P.Input>
  for +anchor:U32
  for +display:U32
  for +observation:U32
  for last:U32
  for +seq:U32
  for +x:U32
  for +y:U32
  {P.command_selected(True{},P.State{px,py,distance,enabled,inputs,anchor,display,observation,last},seq,x,y) == P.State{px,py,distance,enabled,P.Input{seq,P.after(display,1),x,y} <> List.take(&2,P.Input,inputs,127n),anchor,display,observation,seq} : P.State}

# Guarantees: refusal preserves every field of the local timeline.
# Why it matters: a duplicate or invalid command cannot erase pending history.
law command_refuses:
  for +state:P.State
  for seq:U32
  for x:U32
  for y:U32
  {P.command_selected(False{},state,seq,x,y) == state : P.State}

# Guarantees: the public command path uses the complete admission decision.
# Why it matters: a correct helper must not be bypassed by the browser entrypoint.
law command_exact:
  for +state:P.State
  for +seq:U32
  for +x:U32
  for +y:U32
  {P.command(state,seq,x,y) == P.command_selected(P.command_allowed(state,seq,x,y),state,seq,x,y) : P.State}

# Guarantees: one accepted local tick advances exactly one world tick using
# only the input assigned there, and preserves all retained input identities.
# Why it matters: neither held input nor a FIFO head may shift into a missing tick.
law tick_selected_exact:
  for +x:F32
  for +y:F32
  for +distance:F32
  for +enabled:Bool
  for +inputs:List<&2,P.Input>
  for +anchor:U32
  for +display:U32
  for +observation:U32
  for +last:U32
  {P.tick_selected(True{},P.State{x,y,distance,enabled,inputs,anchor,display,observation,last}) == P.placed(distance,enabled,inputs,anchor,P.after(display,1),observation,last,P.advance_point(M.Point{x,y},distance,P.input_at(inputs,P.after(display,1)))) : P.State}

# Guarantees: a disabled or exhausted local tick preserves the timeline.
# Why it matters: a pause must not move the cursor behind the server's back.
law tick_refuses:
  for +state:P.State
  {P.tick_selected(False{},state) == state : P.State}

# Guarantees: the public tick path always applies the complete window guard.
# Why it matters: locally sending a tick that was not predicted causes another drift.
law tick_exact:
  for +state:P.State
  {P.tick(state) == P.tick_selected(P.can_tick(state),state) : P.State}

# Guarantees: history filtering keeps a row iff its assigned world tick is
# beyond the committed anchor, without renumbering it.
# Why it matters: an ACK resolves neutral holes as well as applied commands.
law unresolved_row_exact:
  for +seq:U32
  for +target:U32
  for +x:U32
  for +y:U32
  for +tail:List<&2,P.Input>
  for +anchor:U32
  {P.unresolved(P.Input{seq,target,x,y} <> tail,anchor) == Bool.pick(List<&2,P.Input>,U32.is_gt(target,anchor),P.Input{seq,target,x,y} <> P.unresolved(tail,anchor),P.unresolved(tail,anchor)) : List<&2,P.Input>}

# Guarantees: input at the committed tick is removed even if its packet was late.
# Why it matters: a rejected old input cannot be replayed on a future world tick.
law committed_input_removed:
  for seq:U32
  for +anchor:U32
  for x:U32
  for y:U32
  for +tail:List<&2,P.Input>
  {P.unresolved(P.Input{seq,anchor,x,y} <> tail,anchor) == P.unresolved(tail,anchor) : List<&2,P.Input>}

# Guarantees: resync is required for a disabled prior timeline or when authority
# reaches/passes the display cursor; ordinary earlier anchors do not request it.
# Why it matters: an ACK must not silently alter the fixed future cursor.
law resync_exact:
  for x:F32
  for y:F32
  for distance:F32
  for +enabled:Bool
  for inputs:List<&2,P.Input>
  for anchor:U32
  for +display:U32
  for observation:U32
  for last:U32
  for +incoming:U32
  {P.resync_needed(P.State{x,y,distance,enabled,inputs,anchor,display,observation,last},incoming) == Bool.or(Bool.not(enabled),U32.is_ge(incoming,display)) : Bool}

# Guarantees: cursor selection either preserves the existing display clock or
# starts an explicit neutral lead after the incoming anchor, under that policy.
# Why it matters: pending commands retain their original world tick assignments.
law cursor_exact:
  for x:F32
  for y:F32
  for distance:F32
  for +enabled:Bool
  for inputs:List<&2,P.Input>
  for anchor:U32
  for +display:U32
  for observation:U32
  for last:U32
  for +incoming:U32
  for +initialLead:U32
  {P.cursor(P.State{x,y,distance,enabled,inputs,anchor,display,observation,last},incoming,initialLead) == Bool.pick(U32,Bool.or(Bool.not(enabled),U32.is_ge(incoming,display)),P.after(incoming,U32.min(initialLead,54)),display) : U32}

# Guarantees: rejecting a stale observation preserves the complete timeline.
# Why it matters: duplicate packets cannot rewind the display clock or pending inputs.
law rejected_observation_preserves:
  for +state:P.State
  for observation:U32
  for anchor:U32
  for x:F32
  for y:F32
  for distance:F32
  for enabled:Bool
  for initialLead:U32
  {P.reconcile_selected(False{},state,observation,anchor,x,y,distance,enabled,initialLead) == state : P.State}

# Guarantees: a newly observed pause/death clears speculation and aligns both
# clocks to the committed anchor while retaining packet sequence freshness.
# Why it matters: pre-pause history cannot run after a reward or death barrier.
law disabled_reconcile_clears:
  for px:F32
  for py:F32
  for priorDistance:F32
  for priorEnabled:Bool
  for inputs:List<&2,P.Input>
  for oldAnchor:U32
  for oldDisplay:U32
  for oldObservation:U32
  for +last:U32
  for +observation:U32
  for +anchor:U32
  for +x:F32
  for +y:F32
  for +distance:F32
  for initialLead:U32
  {P.reconcile_selected(True{},P.State{px,py,priorDistance,priorEnabled,inputs,oldAnchor,oldDisplay,oldObservation,last},observation,anchor,x,y,distance,False{},initialLead) == P.State{x,y,distance,False{},[],anchor,anchor,observation,last} : P.State}

# Guarantees: observations must be newer and their world anchor must not rewind.
# Why it matters: a fresh packet ID cannot smuggle an older simulation state.
law reconciliation_admission_exact:
  for +state:P.State
  for +observation:U32
  for +anchor:U32
  for +x:F32
  for +y:F32
  for +distance:F32
  for +enabled:Bool
  for +initialLead:U32
  {P.reconcile(state,observation,anchor,x,y,distance,enabled,initialLead) == P.reconcile_selected(Bool.and(P.observation_newer(state,observation),U32.is_ge(anchor,P.anchor_world_tick(state))),state,observation,anchor,P.normalize(x),P.normalize(y),P.normalize(distance),enabled,initialLead) : P.State}

# Guarantees: packet observation freshness is strict and independent of clocks.
# Why it matters: a duplicate observation must never replace an accepted anchor.
law observation_newer_exact:
  for x:F32
  for y:F32
  for distance:F32
  for enabled:Bool
  for inputs:List<&2,P.Input>
  for anchor:U32
  for display:U32
  for +prior:U32
  for last:U32
  for +observation:U32
  {P.observation_newer(P.State{x,y,distance,enabled,inputs,anchor,display,prior,last},observation) == U32.is_gt(observation,prior) : Bool}

# Guarantees: movement prediction uses the exact authoritative F32 operation order.
# Why it matters: a second movement formula would drift independently of timing.
law shared_movement_exact:
  for +x:F32
  for +y:F32
  for +distance:F32
  for +dx:F32
  for +dy:F32
  {M.move_point(x,y,distance,dx,dy) == M.Point{F32.clamp((x + dx * distance / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max()),F32.clamp((y + dy * distance / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max())} : M.Point}

# Guarantees: direction codes use the same negative/neutral/positive axis map.
# Why it matters: correct target timing cannot compensate for a wrong axis decoder.
law axis_exact:
  for +code:U32
  {S.axis(code) == Bool.pick(F32,U32.is_eq(code,0),(0.0 - 1.0 : F32),Bool.pick(F32,U32.is_eq(code,2),1.0,0.0)) : F32}

# Guarantees: a detached point step calls shared movement with the assigned axes.
# Why it matters: timeline replay cannot use stale held input for this world tick.
law point_step_exact:
  for +x:F32
  for +y:F32
  for +distance:F32
  for +dx:U32
  for +dy:U32
  {P.advance_point(M.Point{x,y},distance,P.Direction{dx,dy}) == M.move_point(x,y,distance,S.axis(dx),S.axis(dy)) : M.Point}

# Guarantees: an empty position interval preserves its anchor point.
# Why it matters: catching up to authority cannot manufacture a movement tick.
law position_zero:
  for tick:U32
  for rows:List<&2,P.Input>
  for distance:F32
  for +point:M.Point
  {P.replay_position(0n,tick,rows,distance,point) == point : M.Point}

# Guarantees: each position replay step advances the world clock once and uses
# precisely that tick's lookup, including neutral gaps.
# Why it matters: the camera and combat replay must use the same time assignment.
law position_successor:
  for +fuel:Nat
  for +tick:U32
  for +rows:List<&2,P.Input>
  for +distance:F32
  for +point:M.Point
  {P.replay_position(1n+fuel,tick,rows,distance,point) == P.replay_position(fuel,P.after(tick,1),rows,distance,P.advance_point(point,distance,P.input_at(rows,P.after(tick,1)))) : M.Point}

def fresh_display(enabled:Bool,+anchor:U32,initialLead:U32) -> U32: Bool.pick(U32,enabled,P.after(anchor,U32.min(initialLead,54)),anchor)
# Guarantees: startup prewarms the neutral interval up to anchor+lead, with
# empty command history and unchanged packet/observation freshness counters.
# Why it matters: the first keypress belongs to the future cursor, not to an
# earlier cooldown tick in the received snapshot.
law fresh_exact:
  for +x:F32
  for +y:F32
  for +distance:F32
  for +enabled:Bool
  for +anchor:U32
  for +initialLead:U32
  {P.fresh(x,y,distance,enabled,anchor,initialLead) == P.placed(P.normalize(distance),enabled,[],anchor,fresh_display(enabled,anchor,initialLead),0,0,P.replay_position(U32.to_nat(P.world_count(anchor,fresh_display(enabled,anchor,initialLead))),anchor,[],P.normalize(distance),M.Point{P.normalize(x),P.normalize(y)})) : P.State}

def running_spec(state:P.State,observation:U32,+anchor:U32,x:F32,y:F32,+distance:F32,initialLead:U32) -> P.State:
  match state:
    case P.State{_,_,_,enabled,inputs,_,+display,_,last}:
      +cursor = Bool.pick(U32,Bool.or(Bool.not(enabled),U32.is_ge(anchor,display)),P.after(anchor,U32.min(initialLead,54)),display)
      +rows = P.unresolved(inputs,anchor)
      P.placed(distance,True{},rows,anchor,cursor,observation,last,P.replay_position(U32.to_nat(P.world_count(anchor,cursor)),anchor,rows,distance,M.Point{x,y}))
# Guarantees: accepted authority replaces the point anchor, filters resolved
# target ticks, and replays the full retained world interval to the fixed cursor.
# Why it matters: an ACK cannot replay commands from an old position or squeeze
# neutral cooldown ticks out of the history.
law running_reconcile_exact:
  for +state:P.State
  for +observation:U32
  for +anchor:U32
  for +x:F32
  for +y:F32
  for +distance:F32
  for +initialLead:U32
  {P.reconcile_running(state,observation,anchor,x,y,distance,initialLead) == running_spec(state,observation,anchor,x,y,distance,initialLead) : P.State}

# Guarantees: enabled reconciliation invokes that complete authority replay.
# Why it matters: the production branch cannot bypass a correct replay helper.
law active_reconcile_exact:
  for +state:P.State
  for +observation:U32
  for +anchor:U32
  for +x:F32
  for +y:F32
  for +distance:F32
  for +initialLead:U32
  {P.reconcile_selected(True{},state,observation,anchor,x,y,distance,True{},initialLead) == P.reconcile_running(state,observation,anchor,x,y,distance,initialLead) : P.State}

# Guarantees: a combat anchor is compatible exactly when its world clock equals
# the prediction history's anchor, independently of packet sequence.
# Why it matters: replaying correctly timed input from a different scene clock
# would shift every cooldown and contact again.
law anchor_match_exact:
  for x:F32
  for y:F32
  for distance:F32
  for enabled:Bool
  for inputs:List<&2,P.Input>
  for +anchor:U32
  for display:U32
  for observation:U32
  for last:U32
  for +tick:U32
  {P.matches_anchor(P.State{x,y,distance,enabled,inputs,anchor,display,observation,last},tick) == U32.is_eq(anchor,tick) : Bool}

# Guarantees: a host-provided coordinate is decoded through the native F32 bits.
# Why it matters: JSON parses decimal F32 text as binary64, which must not become
# a different starting point for movement than the combat cohort receives.
law normalize_exact:
  for +value:F32
  {P.normalize(value) == P.from_bits(F32.bits(value)) : F32}

# Guarantees: decoding a 32-bit word preserves every bit in the resulting F32.
# Why it matters: the normalization helper cannot silently scale or clamp the
# exact native value that was encoded by the authoritative simulation.
law from_bits_exact:
  for +word:Word(32n)
  {P.from_bits(U32{word}) == F32{word} : F32}
