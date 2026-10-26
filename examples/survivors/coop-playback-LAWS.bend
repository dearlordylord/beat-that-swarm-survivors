import Base
import ./coop-playback.bend as P
import ./body-index.bend as BI
import ./list-map.bend as LM

# Guarantees: Fresh playback has no frames and a buffering zero cursor.
# Why it matters: Joining never invents an authoritative frame.
law fresh_exact:
  {P.fresh() == P.State{[],P.Cursor{0,0n,0n,P.Priming{}},False{},6} : P.State}

# Guarantees: Only strictly newer observation and nondecreasing world tick are admitted.
# Why it matters: Delayed transport messages cannot rewind the combat timeline.
law admission_exact:
  for +o0:U32
  for +t0:U32
  for a0:Nat
  for p0:List<&2,P.Actor>
  for b0:List<&2,P.Actor>
  for +o1:U32
  for +t1:U32
  for a1:Nat
  for p1:List<&2,P.Actor>
  for b1:List<&2,P.Actor>
  {P.admissible(P.Frame{o0,t0,a0,p0,b0},P.Frame{o1,t1,a1,p1,b1}) == Bool.and(U32.is_gt(o1,o0),U32.is_ge(t1,t0)) : Bool}

# Guarantees: Rejected admission preserves the complete timeline state.
# Why it matters: A stale snapshot cannot reset the interpolation buffer.
law rejected_preserves_state:
  for +state:P.State
  for new:P.Frame
  {P.push_decided(False{},state,new) == state : P.State}

# Guarantees: First admission stores that frame at its tick with zero fraction.
# Why it matters: The guest sees initial world tick zero without waiting six ticks.
law initial_frame_visible:
  for cursor:P.Cursor
  for recovered:Bool
  for +delay:U32
  for +new:P.Frame
  {P.push_decided(True{},P.State{[],cursor,recovered,delay},new) == P.State{[P.indexed(new)],P.Cursor{P.world_tick(new),0n,P.received_at(new),P.Priming{}},False{},delay} : P.State}

# Guarantees: A same-tick update replaces the newest frame and retains at most seven earlier entries.
# Why it matters: Paused rewards refresh without accumulating duplicate world times.
law same_tick_replaces:
  for +new:P.Indexed
  for old:P.Indexed
  for +tail:List<&2,P.Indexed>
  {P.retain(True{},new,old <> tail) == new <> List.take(&2,P.Indexed,tail,7n) : List<&2,P.Indexed>}

# Guarantees: A later tick prepends one frame and retains at most seven previous entries.
# Why it matters: A stalled browser cannot grow its snapshot history without bound.
law later_tick_bounded:
  for +new:P.Indexed
  for +rows:List<&2,P.Indexed>
  {P.retain(False{},new,rows) == new <> List.take(&2,P.Indexed,rows,7n) : List<&2,P.Indexed>}

# Guarantees: An evicted cursor recovers to the oldest retained tick and refills the buffer.
# Why it matters: Long suspension does not interpolate against discarded frame payloads.
law eviction_forward_recovery:
  for tick:U32
  for fraction:Nat
  for +at:Nat
  for buffering:P.Mode
  for +oldest:U32
  {P.recovered_cursor(True{},P.Cursor{tick,fraction,at,buffering},oldest) == P.Cursor{oldest,0n,at,P.Priming{}} : P.Cursor}

# Guarantees: Without eviction recovery the exact cursor survives admission.
# Why it matters: Ordinary network packets do not repeatedly reset presentation time.
law no_eviction_preserves_cursor:
  for +cursor:P.Cursor
  for oldest:U32
  {P.recovered_cursor(False{},cursor,oldest) == cursor : P.Cursor}

# Guarantees: Elapsed time uses nondecreasing local Nat microseconds capped at one second.
# Why it matters: Clock regressions and background resumes cannot wrap or replay arbitrary lag.
law elapsed_exact:
  for +now:Nat
  for +before:Nat
  {P.elapsed(now,before) == Nat.min(Nat.sub(Nat.max(now,before),before),1000000n) : Nat}

# Guarantees: Fractional ticks accumulate the supplied rate per capped elapsed microsecond.
# Why it matters: Presentation advances continuously between twenty-Hz snapshots.
law fraction_exact:
  for +fraction:Nat
  for +now:Nat
  for +before:Nat
  for +rate:Nat
  {P.fraction_after(fraction,now,before,rate) == Nat.add(Nat.min(fraction,999999n),Nat.mul(Nat.min(Nat.sub(Nat.max(now,before),before),1000000n),rate)) : Nat}

# Guarantees: Whole-tick addition saturates at the U32 maximum.
# Why it matters: Long-running world clocks cannot wrap presentation into the distant past.
law tick_saturates_exact:
  for +tick:U32
  for +units:Nat
  {P.tick_after(tick,units) == (tick + U32.from_nat(Nat.min(Nat.div(units,1000000n),U32.to_nat((4294967295 - tick : U32)))) : U32) : U32}

# Guarantees: The initial public clock enters the Priming waiting path.
# Why it matters: The actual startup branch uses the independently pinned waiting policy.
law buffer_clock_exact:
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.clock(P.Cursor{tick,fraction,previous,P.Priming{}},now,latest,delay) == P.wait_clock(P.Priming{},tick,fraction,previous,now,latest,delay) : P.Cursor}

# Guarantees: Reaching the latest authority tick holds exactly there and reenters buffering.
# Why it matters: The client cannot invent remote enemy or projectile movement after data ends.
law underrun_holds_latest:
  for tick:U32
  for fraction:Nat
  for +now:Nat
  for +latest:U32
  for mode:P.Mode
  {P.clock_running(True{},tick,fraction,now,latest,mode) == P.Cursor{latest,0n,now,P.Holding{}} : P.Cursor}

# Guarantees: Before underrun the exact continuously advanced tick and fraction are retained.
# Why it matters: Normal render frames do not quantize motion to received snapshot cadence.
law running_cursor_exact:
  for +tick:U32
  for +fraction:Nat
  for +now:Nat
  for latest:U32
  for +mode:P.Mode
  {P.clock_running(False{},tick,fraction,now,latest,mode) == P.Cursor{tick,fraction,now,mode} : P.Cursor}

# Guarantees: Interpolation requires equal key, kind, generation and owner and two live actors.
# Why it matters: Recycled enemy or projectile slots never draw a path between different lifetimes.
law identity_exact:
  for +k0:U32
  for +t0:U32
  for +g0:String
  for x0:F32
  for y0:F32
  for a0:U32
  for +h0:Bool
  for +o0:U32
  for +k1:U32
  for +t1:U32
  for +g1:String
  for x1:F32
  for y1:F32
  for a1:U32
  for +h1:Bool
  for +o1:U32
  {P.identity(P.Actor{k0,t0,g0,x0,y0,a0,h0,o0},P.Actor{k1,t1,g1,x1,y1,a1,h1,o1}) == Bool.and(U32.is_eq(k0,k1),Bool.and(U32.is_eq(t0,t1),Bool.and(String.eq(g0,g1),Bool.and(U32.is_eq(o0,o1),Bool.and(h0,h1))))) : Bool}

# Guarantees: An actor absent from the future frame keeps its older authoritative state.
# Why it matters: A disappearing actor remains in the coherent older inventory until its transition tick.
law unmatched_preserves_old:
  for +old:P.Actor
  for alpha:F32
  {P.matched(None{},old,alpha) == old : P.Actor}

# Guarantees: A failed identity check preserves the exact older actor.
# Why it matters: Slot reuse never causes a teleporting interpolation across unrelated actors.
law different_lifetime_preserves_old:
  for +old:P.Actor
  for new:P.Actor
  for alpha:F32
  {P.blended(False{},old,new,alpha) == old : P.Actor}

# Guarantees: A valid interpolation changes only x and y using one common alpha.
# Why it matters: Identity, health, owner and lifetime metadata remain authoritative.
law blend_only_positions:
  for +key:U32
  for +kind:U32
  for +generation:String
  for +x0:F32
  for +y0:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  for k1:U32
  for t1:U32
  for g1:String
  for +x1:F32
  for +y1:F32
  for a1:U32
  for h1:Bool
  for o1:U32
  for +alpha:F32
  {P.blended(True{},P.Actor{key,kind,generation,x0,y0,age,alive,owner},P.Actor{k1,t1,g1,x1,y1,a1,h1,o1},alpha) == P.Actor{key,kind,generation,F32.lerp(x0,x1,alpha),F32.lerp(y0,y1,alpha),age,alive,owner} : P.Actor}

# Guarantees: An empty timeline has no renderable sample.
# Why it matters: No fake frame is fabricated before handshake snapshot admission.
law empty_sample:
  for cursor:P.Cursor
  for recovered:Bool
  for delay:U32
  {P.sample(P.State{[],cursor,recovered,delay}) == None{} : Maybe<&2,P.Sample>}

# Guarantees: Nonempty public admission applies the ordered metadata decision.
# Why it matters: The browser calls this boundary, so a detached predicate is insufficient.
law push_wiring:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +cursor:P.Cursor
  for +recovered:Bool
  for +delay:U32
  for +new:P.Frame
  {P.push(P.State{head <> tail,cursor,recovered,delay},new) == P.push_decided(P.admissible(P.frame(head),new),P.State{head <> tail,cursor,recovered,delay},new) : P.State}

# Guarantees: Rendering advances exactly the single cursor using the latest authority tick.
# Why it matters: All combat families share one timeline rather than independent extrapolation.
law advance_wiring:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +cursor:P.Cursor
  for +recovered:Bool
  for +delay:U32
  for +now:Nat
  {P.advance(P.State{head <> tail,cursor,recovered,delay},now) == P.State{head <> tail,P.clock(cursor,now,P.world_tick(P.frame(head)),delay),recovered,delay} : P.State}

# Guarantees: Bracketing selects the older frame only when its tick is reached.
# Why it matters: Future births stay absent before their authoritative frame time.
law bracket_selects_reached:
  for +old:P.Indexed
  for +new:P.Indexed
  for +tick:U32
  for +fraction:Nat
  for continue:Unit -> P.Sample
  {P.bracket_selected(True{},old,new,tick,fraction,continue) == P.sample_pair(old,new,tick,fraction,P.ratio(P.world_tick(P.frame(old)),P.world_tick(P.frame(new)),tick,fraction)) : P.Sample}

# Guarantees: Frames newer than the cursor are skipped to search earlier authority.
# Why it matters: Arrival of a newer packet cannot reveal its future actor inventory early.
law bracket_skips_future:
  for ~continue:Unit -> P.Sample
  for old:P.Indexed
  for new:P.Indexed
  for tick:U32
  for fraction:Nat
  {P.bracket_selected(False{},old,new,tick,fraction,continue) == continue(Unit{}) : P.Sample}

# Guarantees: Sampling passes the same cursor to the single bracket lookup.
# Why it matters: Rendering players and projectiles cannot choose different presentation clocks.
law sample_wiring:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +tick:U32
  for +fraction:Nat
  for at:Nat
  for buffering:P.Mode
  for recovered:Bool
  for delay:U32
  {P.sample(P.State{head <> tail,P.Cursor{tick,fraction,at,buffering},recovered,delay}) == Some{P.bracket(head <> tail,head,tick,fraction)} : Maybe<&2,P.Sample>}
# Guarantees: Both actor families use the older inventory and exactly the same interpolation alpha.
# Why it matters: Enemy contact and confirmed projectile positions cannot drift onto separate clocks.
law sample_cohort_exact:
  for +observation:U32
  for oldTick:U32
  for oldAt:Nat
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  for oldPlayers:BI.Index<P.Actor>
  for oldBodies:BI.Index<P.Actor>
  for +next:U32
  for nextTick:U32
  for nextAt:Nat
  for nextPlayers:List<&2,P.Actor>
  for nextBodies:List<&2,P.Actor>
  for +playerIndex:BI.Index<P.Actor>
  for +bodyIndex:BI.Index<P.Actor>
  for +tick:U32
  for +fraction:Nat
  for +alpha:F32
  {P.sample_pair(P.Indexed{P.Frame{observation,oldTick,oldAt,players,bodies},oldPlayers,oldBodies},P.Indexed{P.Frame{next,nextTick,nextAt,nextPlayers,nextBodies},playerIndex,bodyIndex},tick,fraction,alpha) == P.Sample{observation,next,tick,fraction,alpha,LM.map(~P.Actor,~P.Actor,~P.Mix,~P.mix_actor,P.Mix{playerIndex,alpha},players),LM.map(~P.Actor,~P.Actor,~P.Mix,~P.mix_actor,P.Mix{bodyIndex,alpha},bodies)} : P.Sample}

# Guarantees: Interpolation alpha is the exact fractional cursor distance divided by the frame gap.
# Why it matters: All layers use one common machine arithmetic formula; float range is checked separately.
law ratio_exact:
  for +older:U32
  for +newer:U32
  for +tick:U32
  for +fraction:Nat
  {P.ratio(older,newer,tick,fraction) == Bool.pick(F32,U32.is_gt(newer,older),F32.div(F32.add(U32.to_f32((tick - older : U32)),F32.div(F32.from_nat(fraction),1000000.0)),U32.to_f32(U32.max(1,(newer - older : U32)))),0.0) : F32}

# Guarantees: Host playback buffers three ticks and guest playback buffers six.
# Why it matters: Improving guest continuity does not add another host input delay.
law delay_exact:
  for +own:U32
  {P.delay_for(own) == Bool.pick(U32,U32.is_eq(own,0),3,6) : U32}

# Guarantees: Client-specific initialization carries the selected delay into its empty timeline.
# Why it matters: Runtime initialization uses the proved role policy rather than a JavaScript branch.
law fresh_for_exact:
  for +own:U32
  {P.fresh_for(own) == P.State{[],P.Cursor{0,0n,0n,P.Priming{}},False{},P.delay_for(own)} : P.State}
# Guarantees: A running clock uses elapsed fractional ticks and the monotonic receipt clock.
# Why it matters: Receiving packets cannot secretly replace continuous presentation with stepped time.
law running_clock_wiring:
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.clock(P.Cursor{tick,fraction,previous,P.Playing{}},now,latest,delay) == P.move_clock(P.Playing{},tick,fraction,previous,now,latest,delay) : P.Cursor}

# Guarantees: The computed whole tick is compared to authority before accepting its fractional remainder.
# Why it matters: A long resume cannot extrapolate past the latest received frame.
law running_units_exact:
  for +tick:U32
  for +units:Nat
  for +now:Nat
  for +latest:U32
  for +mode:P.Mode
  {P.running_units(tick,units,now,latest,mode) == P.clock_running(U32.is_ge(P.tick_after(tick,units),latest),P.tick_after(tick,units),Nat.mod(units,1000000n),now,latest,mode) : P.Cursor}

# Guarantees: Existing-frame admission retains by tick equality and bounds the resulting state.
# Why it matters: The public push path must actually use replacement and eviction policy.
law push_existing_exact:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +cursor:P.Cursor
  for +delay:U32
  for +new:P.Indexed
  {P.push_existing(head,tail,cursor,delay,new) == P.pushed_rows(P.retain(U32.is_eq(P.world_tick(P.frame(head)),P.world_tick(P.frame(new))),new,head <> tail),cursor,new,delay) : P.State}

# Guarantees: Every actor lookup uses its own key and the later-frame index at the shared alpha.
# Why it matters: An accidentally reused lookup key cannot interpolate one actor toward its neighbour.
law actor_lookup_exact:
  for +index:BI.Index<P.Actor>
  for +alpha:F32
  for +old:P.Actor
  {P.mix_actor(P.Mix{index,alpha},old) == P.matched(BI.find(~P.Actor,index,P.actor_key(old)),old,alpha) : P.Actor}
# Guarantees: Retention produces at most eight frames for every input history.
# Why it matters: Even a large backlog cannot grow interpolation memory beyond its fixed capacity.
law retained_history_bounded:
  for sameTick:Bool
  for new:P.Indexed
  for rows:List<&2,P.Indexed>
  {Nat.is_le(List.length(&2,P.Indexed,P.retain(sameTick,new,rows)),8n) == True{} : Bool}
# Guarantees: Empty public admission always enters the first-frame path.
# Why it matters: A newly joined browser must make its initial snapshot visible.
law push_empty_wiring:
  for +cursor:P.Cursor
  for +recovered:Bool
  for +delay:U32
  for +new:P.Frame
  {P.push(P.State{[],cursor,recovered,delay},new) == P.push_decided(True{},P.State{[],cursor,recovered,delay},new) : P.State}

# Guarantees: Accepted nonempty admission indexes the incoming frame once and enters bounded retention.
# Why it matters: Public admission cannot bypass replacement and queue capacity policy.
law accepted_push_wiring:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +cursor:P.Cursor
  for recovered:Bool
  for +delay:U32
  for +new:P.Frame
  {P.push_decided(True{},P.State{head <> tail,cursor,recovered,delay},new) == P.push_existing(head,tail,cursor,delay,P.indexed(new)) : P.State}

# Guarantees: Retained rows recover against the actual oldest retained frame tick.
# Why it matters: A queue eviction cannot keep a cursor pointing into deleted payloads.
law pushed_rows_wiring:
  for +rows:List<&2,P.Indexed>
  for +cursor:P.Cursor
  for +new:P.Indexed
  for +delay:U32
  {P.pushed_rows(rows,cursor,new,delay) == P.bounded_state(rows,cursor,P.world_tick(P.frame(P.oldest(rows,new))),delay) : P.State}

# Guarantees: Bounded state preserves the exact retained rows and tests the real cursor against oldest tick.
# Why it matters: Recovery may only advance an evicted cursor; ordinary packets preserve its position.
law bounded_state_exact:
  for +rows:List<&2,P.Indexed>
  for +tick:U32
  for +fraction:Nat
  for +at:Nat
  for +buffering:P.Mode
  for +oldest:U32
  for +delay:U32
  {P.bounded_state(rows,P.Cursor{tick,fraction,at,buffering},oldest,delay) == P.State{rows,P.recovered_cursor(U32.is_lt(tick,oldest),P.Cursor{tick,fraction,at,buffering},oldest),U32.is_lt(tick,oldest),delay} : P.State}

# Guarantees: The final entry of the newest-first history is the recovery anchor.
# Why it matters: Recovery cannot accidentally jump directly to the latest snapshot.
law oldest_empty:
  for +fallback:P.Indexed
  {P.oldest([],fallback) == fallback : P.Indexed}

# Guarantees: Oldest-frame lookup traverses the retained order without rearranging it.
# Why it matters: Cursor recovery is based on chronological retained history.
law oldest_cons:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for fallback:P.Indexed
  {P.oldest(head <> tail,fallback) == P.oldest(tail,head) : P.Indexed}

# Guarantees: A found future actor is blended only after the complete lifetime and alive predicate.
# Why it matters: Actual indexed sampling must enforce identity, not only a standalone helper.
law matched_found_wiring:
  for +new:P.Actor
  for +old:P.Actor
  for +alpha:F32
  {P.matched(Some{new},old,alpha) == P.blended(P.identity(old,new),old,new,alpha) : P.Actor}

# Guarantees: Bracketing an exhausted history holds its fallback frame with zero interpolation.
# Why it matters: No earlier data must not synthesize an unknown actor position.
law bracket_empty:
  for +new:P.Indexed
  for +tick:U32
  for +fraction:Nat
  {P.bracket([],new,tick,fraction) == P.sample_pair(new,new,tick,fraction,0.0) : P.Sample}

# Guarantees: Recursive bracketing compares the actual cursor to each frame and searches only its tail.
# Why it matters: Public sampling cannot select a future inventory before its birth frame.
law bracket_cons:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +new:P.Indexed
  for +tick:U32
  for +fraction:Nat
  {P.bracket(head <> tail,new,tick,fraction) == P.bracket_selected(U32.is_ge(tick,P.world_tick(P.frame(head))),head,new,tick,fraction,u => P.bracket(tail,head,tick,fraction)) : P.Sample}

# Guarantees: Advancing an empty timeline preserves it exactly.
# Why it matters: Render callbacks before the first snapshot cannot fabricate state.
law advance_empty:
  for +cursor:P.Cursor
  for +recovered:Bool
  for +delay:U32
  for now:Nat
  {P.advance(P.State{[],cursor,recovered,delay},now) == P.State{[],cursor,recovered,delay} : P.State}

# Guarantees: Indexed interpolation uses the actor's stored key.
# Why it matters: Lookup cannot silently target another actor in the future cohort.
law actor_key_exact:
  for +key:U32
  for kind:U32
  for generation:String
  for x:F32
  for y:F32
  for age:U32
  for alive:Bool
  for owner:U32
  {P.actor_key(P.Actor{key,kind,generation,x,y,age,alive,owner}) == key : U32}

def frame_count(state:P.State) -> Nat:
  match state:
    case P.State{rows,_,_,_}: List.length(&2,P.Indexed,rows)

# Guarantees: Public push preserves the eight-frame invariant whenever it already holds.
# Why it matters: Together with fresh state this bounds every reachable history, including stale packets.
law public_push_preserves_bound:
  for +state:P.State
  for +new:P.Frame
  for bounded:{Nat.is_le(frame_count(state),8n) == True{} : Bool}
  {Nat.is_le(frame_count(P.push(state,new)),8n) == True{} : Bool}
# Guarantees: Index construction starts from and preserves the supplied empty-row accumulator.
# Why it matters: The lookup index contains only admitted authoritative actors.
law index_rows_empty:
  for +index:BI.Index<P.Actor>
  {P.index_rows([],index) == index : BI.Index<P.Actor>}

# Guarantees: Each admitted actor is indexed under its own key before continuing with remaining actors.
# Why it matters: Snapshot interpolation cannot silently skip an entire authoritative actor family.
law index_rows_cons:
  for +head:P.Actor
  for +tail:List<&2,P.Actor>
  for +index:BI.Index<P.Actor>
  {P.index_rows(head <> tail,index) == P.index_rows(tail,BI.insert(~P.Actor,index,P.actor_key(head),head)) : BI.Index<P.Actor>}

# Guarantees: Players and bodies each receive their own index from the exact admitted frame lists.
# Why it matters: Separate actor-key namespaces cannot contaminate one another during interpolation.
law indexed_exact:
  for +observation:U32
  for +tick:U32
  for +at:Nat
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  {P.indexed(P.Frame{observation,tick,at,players,bodies}) == P.Indexed{P.Frame{observation,tick,at,players,bodies},P.index_rows(players,BI.Empty{}),P.index_rows(bodies,BI.Empty{})} : P.Indexed}

# Guarantees: Initial clock anchoring uses the frame's actual local receipt timestamp.
# Why it matters: A first render cannot consume elapsed time measured from an unrelated epoch.
law received_at_exact:
  for observation:U32
  for tick:U32
  for +at:Nat
  for players:List<&2,P.Actor>
  for bodies:List<&2,P.Actor>
  {P.received_at(P.Frame{observation,tick,at,players,bodies}) == at : Nat}
# Guarantees: An indexed frame exposes the exact canonical frame it stores.
# Why it matters: Timeline decisions cannot read metadata from a different snapshot.
law frame_projection_exact:
  for +source:P.Frame
  for players:BI.Index<P.Actor>
  for bodies:BI.Index<P.Actor>
  {P.frame(P.Indexed{source,players,bodies}) == source : P.Frame}

# Guarantees: World-time decisions use the frame's stored world tick.
# Why it matters: Bracketing and recovery must compare actual authoritative time.
law world_tick_projection_exact:
  for observation:U32
  for +tick:U32
  for at:Nat
  for players:List<&2,P.Actor>
  for bodies:List<&2,P.Actor>
  {P.world_tick(P.Frame{observation,tick,at,players,bodies}) == tick : U32}

# Guarantees: Cache references use the frame's stored observation identifier.
# Why it matters: Payload selection cannot silently reference a different authoritative snapshot.
law observation_projection_exact:
  for +observation:U32
  for tick:U32
  for at:Nat
  for players:List<&2,P.Actor>
  for bodies:List<&2,P.Actor>
  {P.observation(P.Frame{observation,tick,at,players,bodies}) == observation : U32}

# Guarantees: An empty playback accepts its first authoritative frame.
# Why it matters: The IO payload cache can use the same admission boundary as playback.
law accepts_empty:
  for cursor:P.Cursor
  for recovered:Bool
  for delay:U32
  for new:P.Frame
  {P.accepts(P.State{[],cursor,recovered,delay},new) == True{} : Bool}

# Guarantees: Nonempty playback exposes exactly the latest-frame metadata admission decision.
# Why it matters: Rejected duplicate or stale payloads cannot overwrite the IO cache behind the model.
law accepts_latest:
  for +head:P.Indexed
  for tail:List<&2,P.Indexed>
  for cursor:P.Cursor
  for recovered:Bool
  for delay:U32
  for +new:P.Frame
  {P.accepts(P.State{head <> tail,cursor,recovered,delay},new) == P.admissible(P.frame(head),new) : Bool}

# Guarantees: State admission and the exposed IO admission boolean use exactly the same decision.
# Why it matters: Cache updates and playback updates cannot disagree about a received snapshot.
law push_admission_consistent:
  for +state:P.State
  for +new:P.Frame
  {P.push(state,new) == P.push_decided(P.accepts(state,new),state,new) : P.State}

# Guarantees: Excess backlog selects sixty-six ticks per second; otherwise sixty.
# Why it matters: The nominal controller has a bounded ten-percent catch-up rate.
law rate_selected_exact:
  for +behind:Bool
  {P.rate_selected(behind) == Bool.pick(Nat,behind,66n,60n) : Nat}

# Guarantees: Speed-up occurs exactly when integer backlog exceeds configured delay plus one.
# Why it matters: Delayed startup and underrun cannot leave the presentation clock permanently behind.
law rate_for_exact:
  for +tick:U32
  for +latest:U32
  for +delay:U32
  {P.rate_for(tick,latest,delay) == Bool.pick(Nat,Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)),66n,60n) : Nat}

# Guarantees: The nominal rate helper is at least sixty and at most sixty-six.
# Why it matters: Emergency84 is separate and bounded by mode_rate_bounds.
law rate_for_bounds:
  for +tick:U32
  for +latest:U32
  for +delay:U32
  {Bool.and(Nat.is_ge(P.rate_for(tick,latest,delay),60n),Nat.is_le(P.rate_for(tick,latest,delay),66n)) == True{} : Bool}

# Independent enum specifications make every public mode and threshold observable.
def waiting_spec(mode:P.Mode) -> Bool:
  match mode:
    case P.Priming{}: True{}
    case P.Holding{}: True{}
    case P.Playing{}: False{}
    case P.Boosting{}: False{}
def refill_spec(mode:P.Mode,delay:U32) -> U32:
  match mode:
    case P.Priming{}: delay
    case P.Holding{}: 1
    case P.Playing{}: 1
    case P.Boosting{}: 1
def boost_spec(mode:P.Mode,tick:U32,latest:U32,delay:U32) -> Bool:
  match mode:
    case P.Boosting{}: Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n))
    case _: Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),4n))
def mode_rate_spec(mode:P.Mode,tick:U32,latest:U32,delay:U32) -> Nat:
  match mode:
    case P.Boosting{}: 84n
    case _: Bool.pick(Nat,Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)),66n,60n)

# Guarantees: Only priming and holding suppress normal timeline movement.
# Why it matters: The IO adapter exports buffering from the actual model mode.
law waiting_exact:
  for +mode:P.Mode
  {P.waiting(mode) == waiting_spec(mode) : Bool}

# Guarantees: Buffering metadata projects the cursor's exact mode.
# Why it matters: Diagnostics cannot mistake boost for starvation.
law buffering_projection_exact:
  for rows:List<&2,P.Indexed>
  for tick:U32
  for fraction:Nat
  for at:Nat
  for +mode:P.Mode
  for recovered:Bool
  for delay:U32
  {P.is_buffering(P.State{rows,P.Cursor{tick,fraction,at,mode},recovered,delay}) == waiting_spec(mode) : Bool}

# Guarantees: Initial/history reset waits D ticks; subsequent starvation waits one.
# Why it matters: A producer gap must not repeatedly impose full startup latency.
law refill_exact:
  for +mode:P.Mode
  for +delay:U32
  {P.refill(mode,delay) == refill_spec(mode,delay) : U32}

# Guarantees: Enter emergency above D+4, retain it only while above D+1.
# Why it matters: A full snapshot interval separates entry and exit thresholds.
law boost_exact:
  for +mode:P.Mode
  for +tick:U32
  for +latest:U32
  for +delay:U32
  {P.boost(mode,tick,latest,delay) == boost_spec(mode,tick,latest,delay) : Bool}

# Guarantees: The selected flag chooses precisely Boosting or Playing.
# Why it matters: The controller never retains a waiting mode when it resumes.
law selected_mode_exact:
  for +active:Bool
  {P.selected_mode(active) == Bool.pick(P.Mode,active,P.Boosting{},P.Playing{}) : P.Mode}

# Guarantees: Emergency runs at84; ordinary playback retains the60/66 deadband.
# Why it matters: All remote combat uses one bounded-rate clock.
law mode_rate_exact:
  for +mode:P.Mode
  for +tick:U32
  for +latest:U32
  for +delay:U32
  {P.mode_rate(mode,tick,latest,delay) == mode_rate_spec(mode,tick,latest,delay) : Nat}

# Guarantees: Every controller mode selects a rate between60 and84.
# Why it matters: Emergency recovery cannot produce an arbitrary speed burst.
law mode_rate_bounds:
  for +mode:P.Mode
  for +tick:U32
  for +latest:U32
  for +delay:U32
  {Bool.and(Nat.is_ge(P.mode_rate(mode,tick,latest,delay),60n),Nat.is_le(P.mode_rate(mode,tick,latest,delay),84n)) == True{} : Bool}

# Guarantees: Resume spends only the last monotonic sample interval, capped33334µs.
# Why it matters: Background silence cannot spend accumulated suspension time.
law resume_units_exact:
  for +fraction:Nat
  for +now:Nat
  for +previous:Nat
  for +rate:Nat
  {P.resume_units(fraction,now,previous,rate) == Nat.add(Nat.min(fraction,999999n),Nat.mul(Nat.min(Nat.min(Nat.sub(Nat.max(now,previous),previous),1000000n),33334n),rate)) : Nat}

# Guarantees: Waiting keeps the exact cursor/fraction and records monotonic now.
# Why it matters: Repeated holding callbacks do not accrue time debt.
law waiting_holds_exact:
  for +mode:P.Mode
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for latest:U32
  for delay:U32
  {P.wait_decided(False{},mode,tick,fraction,previous,now,latest,delay) == P.Cursor{tick,fraction,Nat.max(now,previous),mode} : P.Cursor}

# Guarantees: Readiness resets the prior latch and uses capped resume credit.
# Why it matters: No stale emergency state or whole-hold debt survives starvation.
law ready_resumes_exact:
  for mode:P.Mode
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.wait_decided(True{},mode,tick,fraction,previous,now,latest,delay) == P.running_units(tick,P.resume_units(fraction,now,previous,P.mode_rate(P.selected_mode(P.boost(P.Playing{},tick,latest,delay)),tick,latest,delay)),Nat.max(now,previous),latest,P.selected_mode(P.boost(P.Playing{},tick,latest,delay))) : P.Cursor}

# Guarantees: The actual waiting path compares authority to mode-specific refill.
# Why it matters: The public clock cannot bypass startup/starvation distinction.
law wait_clock_exact:
  for +mode:P.Mode
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.wait_clock(mode,tick,fraction,previous,now,latest,delay) == P.wait_decided(Bool.and(U32.is_ge(latest,tick),U32.is_ge((latest - tick : U32),P.refill(mode,delay))),mode,tick,fraction,previous,now,latest,delay) : P.Cursor}

# Guarantees: Active advancement uses this cursor's hysteresis and selected rate.
# Why it matters: Catch-up is connected to the actual public sampling timeline.
law move_clock_exact:
  for +mode:P.Mode
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.move_clock(mode,tick,fraction,previous,now,latest,delay) == P.running_units(tick,P.fraction_after(fraction,now,previous,P.mode_rate(P.selected_mode(P.boost(mode,tick,latest,delay)),tick,latest,delay)),Nat.max(now,previous),latest,P.selected_mode(P.boost(mode,tick,latest,delay))) : P.Cursor}

# Guarantees: The public Holding constructor uses the starvation waiting path.
# Why it matters: Resume semantics cover the real underrun branch.
law holding_clock_wiring:
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.clock(P.Cursor{tick,fraction,previous,P.Holding{}},now,latest,delay) == P.wait_clock(P.Holding{},tick,fraction,previous,now,latest,delay) : P.Cursor}

# Guarantees: The public Boosting constructor preserves hysteresis during movement.
# Why it matters: Emergency does not toggle off merely at the entry threshold.
law boosting_clock_wiring:
  for +tick:U32
  for +fraction:Nat
  for +previous:Nat
  for +now:Nat
  for +latest:U32
  for +delay:U32
  {P.clock(P.Cursor{tick,fraction,previous,P.Boosting{}},now,latest,delay) == P.move_clock(P.Boosting{},tick,fraction,previous,now,latest,delay) : P.Cursor}
