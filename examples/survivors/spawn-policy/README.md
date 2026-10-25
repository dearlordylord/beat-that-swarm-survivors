# Offscreen spawn admission

`LAWS.bend` and `PROOF.bend` verify the geometric admission policy. The safety
law `accepted_candidate_is_outside` states, for every candidate coordinate,
camera coordinate and radius, that accepted admission implies the complete
appearance lies outside the viewport exclusion. `admission_matches_geometry`
and `fitting_side_selected` retain the exact gate and side-selection guarantees.
These are universal kernel-checked statements, not sampled placement claims.

## Production connection

The application uses the typed spawn and lifecycle policies in
[`enemy-spawn.bend`](../enemy-spawn.bend),
[`enemy-combat.bend`](../enemy-combat.bend) and
[`enemy-lifecycle.bend`](../enemy-lifecycle.bend). The birth operation itself
constructs clean status, age, contact damage and killer state; callers cannot
supply a supposedly clean motion payload. Its concrete law and the production
birth admission fixture cover that separate responsibility, including the
wiring mutation that carries old status forward.

Spatial position and age, Vitals, Status, Phase and stable Identity each have
explicit authority. The former generic payload/status passthrough and numeric
kind/age routing helpers are removed. A new lifetime cannot inherit slow,
freeze, burn or contact effects from the former occupant.

## Scope and checks

These proofs do not establish the whole ECS interpreter, every callsite,
rendering, or real-number collision arithmetic. Independent geometry fixtures
cover enemy variants and arena edges; the concrete birth fixture checks the
actual production transition. Run the kernel checks from the repository root:

```sh
python3 scripts/check-bend-laws.py examples/survivors/spawn-policy/PROOF.bend examples/survivors/enemy-lifecycle/PROOF.bend
```

Game launch does not require the proof toolchain. Arena and viewport bounds
belong to [arena.bend](../arena.bend) and [viewport.bend](../viewport.bend).
