import Base
import ./coop-hit-effects.bend as E
import ./coop-hit-journal.bend as J
import ./coop-playback.bend as P
import ./coop-contact-playback.bend as C
import ./body-index.bend as BI

# Guarantees: effects last four display ticks and retain at most 512 entries.
# Why it matters: a recovery burst cannot leave permanent or unbounded flashes.
law limits_exact:
  {E.duration() == 4 : U32} & {E.capacity() == 512n : Nat}
# Guarantees: a fresh observer has no historical effects or consumed receipts.
# Why it matters: the initial snapshot must establish the stream before playback.
law fresh_exact:
  {E.fresh() == E.State{False{},J.playback(0),[],0} : E.State}
# Guarantees: attaching marks existing receipts seen and clears active effects.
# Why it matters: rejoining must not replay the previous party's contact flashes.
law attach_exact:
  for +journal:J.State
  {E.attach(journal) == E.State{True{},J.attach(journal),[],0} : E.State}
# Guarantees: a later accepted snapshot in the same epoch changes no FX state.
# Why it matters: new hits arriving before the first animation frame stay unseen.
law receive_current:
  for +state:E.State
  for +journal:J.State
  {E.receive_selected(True{},state,journal) == state : E.State}
# Guarantees: the first accepted journal of a new epoch establishes its baseline.
# Why it matters: rejoin skips old history at intake rather than at a later render.
law receive_changed:
  for +state:E.State
  for +journal:J.State
  {E.receive_selected(False{},state,journal) == E.attach(journal) : E.State}
# Guarantees: accepted snapshot intake chooses by attached state and journal epoch.
# Why it matters: later arrivals cannot replace the initial seen-history baseline.
law receive_entry:
  for +state:E.State
  for +journal:J.State
  {E.receive(state,journal) == E.receive_selected(E.same_epoch(state,journal),state,journal) : E.State}
# Guarantees: only an attached matching journal epoch can continue old effects.
# Why it matters: a changed connection cannot retain the old visual history.
law epoch_exact:
  for +attached:Bool
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +effects:List<&2,E.Effect>
  for +dropped:U32
  for +other:U32
  for +now:U32
  for +events:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  {E.same_epoch(E.State{attached,J.Playback{epoch,seen},effects,dropped},J.State{other,now,events,overflow,expired}) == Bool.and(attached,U32.is_eq(epoch,other)) : Bool}
# Guarantees: display lifetime begins at first due playback, including late hits.
# Why it matters: a cursor jump over the event tick must still show its effect.
law recent_exact:
  for +started:U32
  for +tick:U32
  {E.recent(started,tick) == Bool.and(U32.is_le(started,tick),U32.is_lt((tick - started : U32),4)) : Bool}
# Guarantees: effect visibility uses its display start, never its authority tick.
# Why it matters: a late receipt needs the same four-tick lifetime as an on-time one.
law visible_exact:
  for +event:J.HitEvent
  for +started:U32
  for +tick:U32
  {E.visible(E.Effect{event,started},tick) == E.recent(started,tick) : Bool}
# Guarantees: effect identity is exactly the authoritative receipt identity.
# Why it matters: repeated snapshots must identify the same visual effect.
law key_exact:
  for +event:J.HitEvent
  for +started:U32
  {E.key(E.Effect{event,started}) == J.event_key(event) : String}
# Guarantees: retaining a visible effect preserves its original start time.
# Why it matters: a redraw must not extend a flash.
law retained_true:
  for +effect:E.Effect
  for +rows:List<&2,E.Effect>
  {E.retained(True{},effect,rows) == effect <> rows : List<&2,E.Effect>}
# Guarantees: an expired effect is absent from the retained result.
# Why it matters: effects must disappear when their four display ticks end.
law retained_false:
  for +effect:E.Effect
  for +rows:List<&2,E.Effect>
  {E.retained(False{},effect,rows) == rows : List<&2,E.Effect>}
# Guarantees: retention returns the accumulated effects in their input order.
# Why it matters: bounded traversal must not silently discard the last effects.
law retain_nil:
  for +tick:U32
  for +acc:List<&2,E.Effect>
  {E.retain_go([],tick,acc) == List.reverse(&2,E.Effect,acc) : List<&2,E.Effect>}
# Guarantees: every retained entry is selected by its display lifetime.
# Why it matters: a late event cannot be discarded using its old authority age.
law retain_cons:
  for +head:E.Effect
  for +tail:List<&2,E.Effect>
  for +tick:U32
  for +acc:List<&2,E.Effect>
  {E.retain_go(head <> tail,tick,acc) == E.retain_go(tail,tick,E.retained(E.visible(head,tick),head,acc)) : List<&2,E.Effect>}
# Guarantees: membership preserves an earlier matching receipt identity.
# Why it matters: a duplicate near the front cannot restart behind other effects.
law contains_nil:
  for +id:String
  for +found:Bool
  {E.contains_go([],id,found) == found : Bool}
# Guarantees: membership considers each authoritative receipt identity.
# Why it matters: different targets and reused slots must not collapse effects.
law contains_cons:
  for +head:E.Effect
  for +tail:List<&2,E.Effect>
  for +id:String
  for +found:Bool
  {E.contains_go(head <> tail,id,found) == E.contains_go(tail,id,Bool.or(found,String.eq(E.key(head),id))) : Bool}
# Guarantees: a membership scan starts without assuming a match.
# Why it matters: a new confirmed contact must remain eligible for display.
law contains_entry:
  for +rows:List<&2,E.Effect>
  for +id:String
  {E.contains(rows,id) == E.contains_go(rows,id,False{}) : Bool}
# Guarantees: only successful host receipts due by the display tick can start.
# Why it matters: future or unsuccessful contacts cannot become hit flashes.
law eligible_exact:
  for +id:String
  for +at:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +target:U32
  for +generation:U32
  for +fraction:F32
  for +x:F32
  for +y:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +tick:U32
  {E.eligible(J.HitEvent{id,at,kind,shot,shotSeed,target,generation,fraction,x,y,tx,ty,radius,outcome},tick) == Bool.and(U32.is_eq(outcome,0),U32.is_le(at,tick)) : Bool}
# Guarantees: an eligible new effect records the current display tick as start.
# Why it matters: jumping across a hit still yields its full bounded lifetime.
law add_new:
  for +event:J.HitEvent
  for +tick:U32
  for +rows:List<&2,E.Effect>
  {E.add_selected(True{},False{},event,tick,rows) == E.Effect{event,tick} <> rows : List<&2,E.Effect>}
# Guarantees: a duplicate changes neither the active effects nor their start times.
# Why it matters: snapshot retransmission cannot prolong a flash.
law add_duplicate:
  for +allowed:Bool
  for +event:J.HitEvent
  for +tick:U32
  for +rows:List<&2,E.Effect>
  {E.add_selected(allowed,True{},event,tick,rows) == rows : List<&2,E.Effect>}
# Guarantees: an ineligible receipt never adds an effect.
# Why it matters: a future or unsuccessful hit cannot bypass the journal boundary.
law add_ineligible:
  for +duplicate:Bool
  for +event:J.HitEvent
  for +tick:U32
  for +rows:List<&2,E.Effect>
  {E.add_selected(False{},duplicate,event,tick,rows) == rows : List<&2,E.Effect>}
# Guarantees: insertion applies both eligibility and active-identity suppression.
# Why it matters: existing effects are not restarted even within one due batch.
law add_entry:
  for +event:J.HitEvent
  for +tick:U32
  for +rows:List<&2,E.Effect>
  {E.add(event,tick,rows) == E.add_selected(E.eligible(event,tick),E.contains(rows,J.event_key(event)),event,tick,rows) : List<&2,E.Effect>}
# Guarantees: an empty batch preserves the existing active effects.
# Why it matters: ordinary frames without hits must not clear live flashes.
law add_rows_nil:
  for +tick:U32
  for +effects:List<&2,E.Effect>
  {E.add_rows([],tick,effects) == effects : List<&2,E.Effect>}
# Guarantees: every due receipt is considered exactly once in batch order.
# Why it matters: simultaneous hits cannot disappear because only one was visited.
law add_rows_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +tick:U32
  for +effects:List<&2,E.Effect>
  {E.add_rows(head <> tail,tick,effects) == E.add_rows(tail,tick,E.add(head,tick,effects)) : List<&2,E.Effect>}
# Guarantees: active storage takes at most 512 entries and counts discarded entries.
# Why it matters: dense collision bursts have bounded, observable cosmetic loss.
law bounded_exact:
  for +played:J.Playback
  for +rows:List<&2,E.Effect>
  for +dropped:U32
  {E.bounded(played,rows,dropped) == E.State{True{},played,List.take(&2,E.Effect,rows,512n),(dropped + U32.from_nat(Nat.sub(List.length(&2,E.Effect,rows),512n)) : U32)} : E.State}
# Guarantees: processing expires old effects before admitting newly due receipts.
# Why it matters: stale flashes must not consume the bounded active capacity.
law completed_exact:
  for +played:J.Playback
  for +events:List<&2,J.HitEvent>
  for +rows:List<&2,E.Effect>
  for +tick:U32
  for +dropped:U32
  {E.completed(J.Played{played,events},rows,tick,dropped) == E.bounded(played,E.add_rows(events,tick,E.retain_go(rows,tick,[])),dropped) : E.State}
# Guarantees: same-epoch playback uses the typed remote sample's clock and seen set.
# Why it matters: receipt arrival must not play an event before the remote scene.
law advance_same_exact:
  for +attached:Bool
  for +played:J.Playback
  for +rows:List<&2,E.Effect>
  for +dropped:U32
  for +journal:J.State
  for +sample:P.Sample
  {E.advance_same(E.State{attached,played,rows,dropped},journal,sample) == E.completed(J.play_sample(played,journal,sample),rows,J.presentation_tick(sample),dropped) : E.State}
# Guarantees: a new or changed stream skips existing history and active effects.
# Why it matters: reconnect cannot replay old contact cosmetics.
law advance_changed:
  for +state:E.State
  for +journal:J.State
  for +sample:P.Sample
  {E.advance_selected(False{},state,journal,sample) == E.attach(journal) : E.State}
# Guarantees: an established stream advances its existing seen/effect state.
# Why it matters: an ordinary snapshot cannot behave like a reconnect.
law advance_current:
  for +state:E.State
  for +journal:J.State
  for +sample:P.Sample
  {E.advance_selected(True{},state,journal,sample) == E.advance_same(state,journal,sample) : E.State}
# Guarantees: public advancement applies the connection epoch decision.
# Why it matters: callers cannot accidentally retain the prior stream's effects.
law advance_entry:
  for +state:E.State
  for +journal:J.State
  for +sample:P.Sample
  {E.advance(state,journal,sample) == E.advance_selected(E.same_epoch(state,journal),state,journal,sample) : E.State}
# Guarantees: mapped effects retain receipt identity and age from first display.
# Why it matters: late hits fade over four shown ticks instead of expiring unseen.
law rendered_exact:
  for +id:String
  for +at:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +target:U32
  for +generation:U32
  for +fraction:F32
  for +x:F32
  for +y:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +started:U32
  for +tick:U32
  for +dx:F32
  for +dy:F32
  {E.rendered(J.HitEvent{id,at,kind,shot,shotSeed,target,generation,fraction,x,y,tx,ty,radius,outcome},started,tick,C.Point{dx,dy}) == C.Fx{id,at,kind,target,generation,dx,dy,radius,(tick - started : U32),F32.div(U32.to_f32((4 - U32.min(4,(tick - started : U32)) : U32)),4.0)} : C.Fx}
# Guarantees: every effect uses the shared lifetime-aware target-relative point.
# Why it matters: local and remote impacts must agree on the displayed recipient.
law render_effect_exact:
  for +event:J.HitEvent
  for +started:U32
  for +tick:U32
  for +index:BI.Index<P.Actor>
  {E.render_effect(E.Effect{event,started},tick,index) == E.rendered(event,started,tick,C.fx_point(BI.find(~P.Actor,index,C.target_seed(event)),event)) : C.Fx}
# Guarantees: an expired effect contributes no rendered output.
# Why it matters: render remains bounded even when called without an advance.
law render_hidden:
  for +effect:E.Effect
  for +tick:U32
  for +index:BI.Index<P.Actor>
  for +acc:List<&2,C.Fx>
  {E.render_selected(False{},effect,tick,index,acc) == acc : List<&2,C.Fx>}
# Guarantees: a visible effect contributes its mapped point to the output.
# Why it matters: an admitted late receipt must actually reach the renderer.
law render_visible:
  for +effect:E.Effect
  for +tick:U32
  for +index:BI.Index<P.Actor>
  for +acc:List<&2,C.Fx>
  {E.render_selected(True{},effect,tick,index,acc) == E.render_effect(effect,tick,index) <> acc : List<&2,C.Fx>}
# Guarantees: the render traversal returns all accumulated effects.
# Why it matters: tail traversal cannot silently discard a dense final batch.
law render_nil:
  for +tick:U32
  for +index:BI.Index<P.Actor>
  for +acc:List<&2,C.Fx>
  {E.render_rows([],tick,index,acc) == List.reverse(&2,C.Fx,acc) : List<&2,C.Fx>}
# Guarantees: each rendered effect is gated by its four-tick display lifetime.
# Why it matters: repeated render calls must neither replay nor prolong effects.
law render_cons:
  for +head:E.Effect
  for +tail:List<&2,E.Effect>
  for +tick:U32
  for +index:BI.Index<P.Actor>
  for +acc:List<&2,C.Fx>
  {E.render_rows(head <> tail,tick,index,acc) == E.render_rows(tail,tick,index,E.render_selected(E.visible(head,tick),head,tick,index,acc)) : List<&2,C.Fx>}
# Guarantees: public rendering maps effects against the exact displayed bodies.
# Why it matters: authority-space target positions must not leak into visible hits.
law render_entry:
  for +attached:Bool
  for +played:J.Playback
  for +rows:List<&2,E.Effect>
  for +dropped:U32
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +alpha:F32
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  {E.render(E.State{attached,played,rows,dropped},P.Sample{base,next,tick,fraction,alpha,players,bodies}) == E.render_rows(rows,tick,P.index_rows(bodies,BI.Empty{}),[]) : List<&2,C.Fx>}
