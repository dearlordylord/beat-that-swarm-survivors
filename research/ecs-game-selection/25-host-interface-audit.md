# 25 — Existing host boundary for a larger Bendvy game

**Scope.** Source-only review of the arena browser adapter, the health browser adapter, the registered `ordinary App` consumer, and current host/observation contracts. No build, compiler, test, browser, or backend was run. This records reusable paths and application-specific seams; it does not propose a broad host bridge or performance claim.

## Source authority

The inspected sources are the [arena game](../../../bendvy/examples/arena/game.bend),
[arena browser](../../../bendvy/examples/arena/browser.mjs),
[scheduled-health application](../../../bendvy/examples/scheduled-health/application.bend),
[ordinary App reference](../../../bendvy/docs/reference/ordinary-app.md) and
[ordinary App entry](../../../bendvy/src/ecs/ordinary-app-run.bend).
Read those sources for their fields and control flow; this audit does not copy
packet layouts, registration recipes or their call graph.

## Architectural finding

A browser or native presentation must retain and thread the returned simulation
owner, define its input/result boundary and own external effects. Source-level
access to state is not a ready-made host protocol. In particular, presentation
snapshots do not establish external-effect rollback, and console backend parity
does not establish a native GUI.

A larger consumer can use a compact render DTO and an explicit input adapter.
Host effect delivery needs a deliberate rule for failures and committed prefixes.
Those are application design choices whose complexity affects the first slice;
the inspected sources do not quantify their implementation cost.

## Practical boundary for a larger clone

| Concern | Existing reusable evidence | Still application/host-owned |
|---|---|---|
| Input | Bend entry functions can receive typed values; ordinary App registrations have repeatable Data arguments, and captured queries have an argument update helper. | Normalize keyboard, pointer, controller, network, or scripted input; choose a per-tick command/resource route; thread the returned affine App/State. No universal `App.run(input)` or browser host bridge is shown. |
| Simulation lifetime | `World` and registration owners live in returned `State`/`Application`; `Entry.run` returns the App for every result branch. | Keep exactly the latest returned owner in host code and choose retry/restart behavior after errors. JavaScript itself does not enforce affine use. |
| Render snapshot | Ordinary App exposes typed observations and Inspector projections; demos manually construct per-frame `Data`/JSON. | Define a stable game-owned render DTO, serialization/versioning, entity keys, interpolation and renderer-specific mapping. Ordinary `rendered` strings are not a wire protocol. |
| Effects | Typed events, independent reader cursors, system `Out` observations, and commit/failure outcomes exist. | Translate committed effect intents into audio/UI/network calls, handle schedule-prefix failure, deduplicate/retry or acknowledge externally. Host I/O is not rolled back. |
| Browser/Native | Browser Canvas adapter and a JS/Native console consumer exist separately. | Choose native windowing/rendering/input dependencies and make the host contract explicit; no shared native GUI layer is established. |

**Recommendation for candidate selection:** host integration should not decide between SS14, SoR, FTL, or Baba by itself. It does affect the size of the first vertical slice. A clone with a simple fixed-step command loop and compact render DTO can reuse the arena’s browser shell while moving from direct queries to a retained ordinary App. A content-heavy station UI or networked host will need significantly more application/host work, but this source audit does not quantify it. Keep the first host narrow, expose deterministic input/result packets, and treat rendering and external effects as adapters around committed Bend state.

## Facts, inference, and limits

The source inspection supports a retained simulation owner and separate host
presentation. The exact packet schema, serializers, entry signatures and call
order belong to the linked implementations. A stable render DTO, explicit input
adapter and committed effect delivery are design proposals, not already-qualified
host protocols.

Generated ESM, browser/native runtime interoperability for affine App owners,
package requirements, performance and latency were not executed or measured.
This audit performed no build, test or browser launch.
