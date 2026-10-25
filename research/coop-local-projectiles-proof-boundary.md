# Local projectile proof boundary

coop-local-projectiles-policy.bend is the Game-free shared policy used by the
runtime. Its bounded laws cover contact-point lifetime matching and fallback,
terminal receipt classification, visibility filtering, overflow accounting,
and JSON row/frame encoding. The main local-projectile module adapts ECS
records into these policy DTOs.

The broader 152-law set imported game.bend and the local-projectile adapter.
The repository's strict scripts/check-bend-laws.py gate gives each verifier
10 CPU seconds. Even a trivial equality importing game.bend exceeded that
limit in isolation, so those laws were removed rather than reported as checked.
The policy pair passes the same bounded gate.

This proof does not cover G.Run, G.team_plan, G.contact_shot_next, ECS
replay/bootstrap transitions, or the adapter that constructs policy inputs.
Those remain runtime integration and performance checks. In particular, the
prepared visibility context and one-time target projection are part of the
runtime contract: callers should prepare once per frame and reuse the context
while filtering the frame's bodies.

The emitted-module dense visibility check exercises 512 visual rows, 512 hit
receipts, and 512 unrelated bodies in one prepared context. A separate filter
microbenchmark over those same sizes matched all decisions against the served
old artifact (SHA-256 `2d7ef894116661fab2bbe49810cb9a85e7f354700aa018d00bc0db00a3f37bc0`).
Its median was 303.99 ms for eight old-style frames and 0.46 ms for eight
prepared frames on this machine. This measures only the visibility filter path;
it does not measure full rendering, gameplay, browser scheduling, or network IO.
