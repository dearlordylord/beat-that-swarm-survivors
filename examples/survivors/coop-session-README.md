# Co-op command boundary

This is the deterministic admission boundary, not a second game simulation.
`coop-session.bend` owns identity/sequence admission and movement expiration;
`coop-protocol.bend` owns canonical command encoding/decoding. The game core owns
setup legality, reward-round eligibility and effects. An admitted `Choice` is
not evidence that its reward was applied. Authenticated transport identity must
be mapped to player 0 (host) or 1 (guest) by the host, never trusted from payload.

Commands are `Command{session,player,seq,intendedTick,action}`. Actions:

- `Movement{x,y}`: each axis 0/1/2 means -1/0/+1; core normalizes diagonals.
- `Choice{round,index}`: positive round and index below 16; core validates the
  actual round, offer index and whether this player already chose.
- `Setup{character,arcana,meta,allowedWeapons}`: character/arcana IDs, existing
  packed meta code and weapon bitmask. Core additionally validates setup and
  only permits setup before starting. Stage and mode belong to the host.

`encode(command)` emits BSC1 text. `decode(text)` returns `Some{value:command}`
or `None{}`. Numbers are canonical decimal u32, no extra fields, maximum 160
characters. Decoder checks framing; `Session.receive` checks action bounds.
The Rust byte envelope separately bounds bytes before text decoding.

`fresh(session)` starts an admission state. `receive(state,authenticatedPlayer,
command)` returns `Admission{state,accepted,command}`. Rejected commands leave the
state unchanged. Sequence numbers are per player across all action kinds, strictly
increasing, start above 0 and never wrap. At exhaustion a new session is needed.
No input queue or rollback: latest admitted movement applies at the next eligible
game tick; `intendedTick` is diagnostic, not a promise to apply at that tick.

Call `clock(state)` once per virtual 1/60s scheduling step, including reward
pauses. This is independent of gameplay ticks. After 18 admission ticks without
new movement, directions become neutral. Call `applied(gameTick,state)` only when
the world actually takes a step; lane `appliedSeq/appliedTick` records the first
world tick that consumed the latest input. `directions(state)` returns F32
`Directions{x0,y0,x1,y1}`. `disconnect(1,state)` permanently neutralizes/removes
guest admission; `disconnect(0,state)` ends all admission. Character death does
not call host disconnect.

Run `bash examples/survivors/check-coop-session.sh`. Four narrow laws check with
the BendTT kernel; tests check positive admission, identity isolation, duplicate
and old-sequence refusal, expiration, terminal sessions,1000 codec roundtrips and
10,000 generated transitions against an independent reference. Five executable
mutants cover owner bypass, duplicate acceptance, late expiration, reject-all
dispatch and reject-all policy. The kernel laws pin disconnect/end denial and
the receive dispatcher; the independent runtime model and mutants qualify
identity, sequence and positive admission policy rather than proving them for
all inputs.

`coop-network-emulator.bend` uses virtual `Scheduled{at,event}` deliveries and
records accepted events (latest first). `replay` replays that accepted history at
the recorded admission clocks. 100 schedules exercise loss, delay/jitter,
reordering, duplication and guest departure. This module oracle covers admission state.
The separate
`bash examples/survivors/check-coop-game.sh` drives the actual shared-world core
with scheduled commands and replays the accepted history. It compares both player
observations and all serialized authoritative CoreState fields at every admission
clock, including sparse components, allocator/handles, snapshots and rewards.
The bounded scenarios cover delivery faults, departure and independently delayed
level choices. They do not prove arbitrary-network or cross-backend floating-point
determinism. No classifier, renderer, network or real sleeps are needed.
