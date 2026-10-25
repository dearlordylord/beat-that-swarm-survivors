# How candidates are compared

These are analytical research criteria, not new Bendvy requirements or approved laws.

## Two different goals

- **The fullest demonstration of ECS:** how many independent gameplay mechanics naturally use composition, queries, events, relations, phases and lifecycles.
- **The best first clone:** whether a recognizable, complete game can be built with the current ECS and a bounded host layer without first building a new engine.

Do not hide the distinction behind one average score. The result must present a choice for each goal and explain the tradeoff.

## Ordinal assessment

Any scores in the final comparison are the coordinator's expert judgment, not measurement results. Scale: 0 — absent, 1 — weak, 2 — noticeable, 3 — defines the game. Fractional scores and a spuriously precise total are unnecessary.

| Criterion | What must be demonstrated |
|---|---|
| Composition | Reusable capabilities create different game objects without a new monolithic class for each combination or a universal dispatcher of all responsibilities |
| Intersecting queries | One entity participates in several systems, and systems also operate across different entity families |
| Structural changes | Adding/removing components changes available behavior during play |
| Events and phases | Several independent reactions to an event and visible meaning in system/barrier order |
| Relations | Ownership, carrying, equipping, targets, crew and chains, with correct reference cleanup |
| First-slice suitability | A small complete gameplay loop remains recognizable after content cuts |
| Work outside ECS | Whether complex physics, networking, an editor, huge content or specialized solvers are required |
| Novelty relative to arena | What this consumer checks beyond the existing compound Body + direct query demo |

## Mandatory objections

1. Could the entire slice be implemented as one array of structs with a short update? If so, how does ECS help the user, rather than only the library author?
2. Is most complexity hidden in pathfinding, a graph solver, cellular automaton, renderer or authored content?
3. Will the cuts leave a recognizable clone of the selected game, or only an abstract sandbox?
4. Are systems being proposed merely for API coverage? Transactional failure, inspection and snapshots must solve a real problem.
5. Is there evidence for the original architecture? Words such as “components,” “entities” and “millions of pixels” do not establish data-oriented ECS.
6. Has the player perspective been checked: what choice do they make, what do they see after acting, and how do they win/lose?

## Relation to the current project

Source: local `bendvy/docs/reference/ordinary-app.md`, `examples/scheduled-health/README.md`, `examples/arena/README.md` and `docs/SPEC.md` at the time of research.

- A new application should treat ordinary App registration as its main entry point. Arena is useful for a browser host, not as a model of ECS completeness.
- Registered systems execute in the specified order; automatic parallel execution is not an established property.
- Accesses are declared through the capability API, and the world is passed affinely. Do not plan unrestricted mutations through aliased references as in C#/Lua.
- Component queries allow Type payloads through owner-preserving bindings, but repeated Args/Out have Data constraints on the specified ordinary route.
- ECS rollback has boundaries: external IO and some capture changes are not rolled back with the world. Gameplay UI/audio must not publish victory before commit.
- Deferred commands become visible at an explicit barrier. A projectile created in the current phase must not accidentally receive several ticks due to traversal order.
- A world snapshot is not an exact execution checkpoint: queues, event readers and runtime state require an explicit policy. Basic/graph save rejects pending structural commands.
- ECS does not automatically provide a spatial index, collision solver, navmesh, renderer, input, audio or network replication.

Potential future slice checks are proposals. They are not run in this study and do not qualify performance.

## Clarification after granularity review

Marker-component counts and the absence of all `kind`/enum branches are not ECS quality criteria. Related data may live in a composite component, flags or an enum; local interpretation of such values is compatible with ECS. Evaluate independent data ownership, entity selection and rule reuse, not splitting every field. Dynamic behavior changes through a resource/rule table differ from structural component insertion/removal; both are valid and must be assessed separately. Behavior changes do not require materializing every derived tag in World. [Granularity review](23-component-granularity-audit.md).

If “demonstrate ECS” means regular bulk passes and explicit disjoint accesses, swarm/shapez/RTS may lead instead. This is a conceptual workload choice, not a performance measurement or a promise of parallel execution in the current Bendvy. [Alternative interpretation](22-data-oriented-counterargument.md).
