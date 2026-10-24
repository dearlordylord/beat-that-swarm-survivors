# Shared projectile assignment

`projectile-pool.bend` allocates logical `Request{owner,slot,level}` values to supplied free physical identities. It imports no game types. `allocate(freeSeeds,liveCounts,caps,requests)` returns `Plan{assignments,count}`; `lookup(plan,seed)` returns `Maybe<Request>`.

Requests retain input priority. A capped or invalid owner (>=24) is dropped without consuming a free identity. Accepted requests take the first free identity and increment that owner's count. A full pool drops remaining emissions; there is no backlog and no active-shot replacement.

Callers must provide unique identities that are actually free, and 24-entry live-count/cap lists from the same frame. The allocator does not inspect the world or prove that premise. Logical slot controls spread/evolution/familiar behavior and must remain independent of physical seed.

The kernel laws cover exact accepted/refused state transitions, invalid-owner refusal and structural preservation of a saturated plan. They do not claim full-game equivalence or a new proof of the existing Patricia index. `allocator.test.mjs` compares emitted Bend against an independent sequential assignment model, including exact lookup metadata and caps. It takes the emitted module path as its optional first argument.
