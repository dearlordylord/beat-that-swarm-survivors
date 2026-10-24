# Native Bend runtime to browser Wasm: feasibility

Assessed 2026-10-24. Same Bend game/ECS logic in native and browser Wasm is plausible, but **Bend 2.0.38's emitted native C requires a runtime port; browser effect adapters alone are insufficient**. A bounded, single-worker wasm32 runtime is the practical first target. No performance or whole-game Wasm execution was demonstrated in this investigation.

## Version and reproducible evidence

Installed `/home/node/.bend/bin/bend version` reports `bend 2.0.38`; executable SHA-256 `df7bf5efcbfc30c91276ed48ec4489252920c3a486c76d2bed1acf36ff539515`. `/home/node/.bend/bend2` contains Base, effects and BendTT, **not compiler source**. Its CLI advertises C, JS, MJS, BendTT and native binary output, with no Wasm target.

Actual 2.0.38 runtime evidence was obtained without building anything: write `import Base\ndef main() -> U32: 1\n` to `/tmp/wasm-runtime-probe.bend`, then `bend /tmp/wasm-runtime-probe.bend -o /tmp/wasm-runtime-probe.c`. Emitted C SHA-256: `e1cae46d24651633e8409cf0f929f5f7acda5d91f7286abe2fb37f0d7721b287`. Line references below refer to that reproducible output.

The local reference compiler is **older**, not newer: `/workspace/formal-proofs/bendvy/.references/bend2/bend2/main.ts:33` says `2.0.35`, revision `a950fd683c0d76f09794078e6174fe98a1492876`, official origin `https://github.com/bendlang/bend.git`. Its [CLI output dispatch](https://github.com/bendlang/bend/blob/a950fd683c0d76f09794078e6174fe98a1492876/bend2/main.ts#L358) selects JS/MJS/C/BendTT or native compilation; no Wasm route appears. This is supporting evidence only; it is not the installed compiler's source revision. This investigation does not claim no unpublished/upstream Wasm work exists.

## Runtime obstacles and what must change

The reproducible generated C and archived source below are authoritative for
runtime constants, layouts, macros and call order. This report does not maintain
a parallel copy of them. The inspected areas were native heap reservation,
stack guards, term/address representation, scheduler/IO workers, tail dispatch,
atomic operations and platform/GPU integration.

The resulting port requirements are architectural: use a bounded browser-memory
policy; preserve owner/offset/sharing invariants; validate tail-call behavior;
and supply explicit browser scheduling and effects. Replacing libc allocation
or display adapters alone is insufficient. Start with one worker to bound the
first qualification surface. Native virtual reservations do not imply equivalent
physical memory use.

Emscripten's [portability guidance](https://emscripten.org/docs/porting/guidelines/portability_guidelines.html)
and [API limitations](https://emscripten.org/docs/porting/guidelines/api_limitations.html)
document the underlying browser/POSIX mismatch.

## Browser boundary and target choice

Canvas/WebGL drawing, input, Web Audio, persistent storage and clock delivery belong in browser adapters. Scheduling an animation frame, yielding to the browser, and resuming IO also require an exported/resumable runtime entry point or explicit asynchronous integration; a native blocking main loop is not a browser contract. Emscripten documents [browser main-loop integration](https://emscripten.org/docs/api_reference/emscripten.h.html#browser-execution-environment).

For public deployment, begin with wasm32, a measured small arena, explicit checked stacks, CPU execution and one worker. This preserves Bend source logic while confining changes to the compiler/runtime and browser boundary. Multithreading is a second milestone: Emscripten [pthreads documentation](https://emscripten.org/docs/porting/pthreads.html) requires shared memory and COOP/COEP deployment headers, describes main-thread blocking hazards, and states one binary cannot transparently support both threaded and nonthreaded execution. These are hosting/runtime decisions beyond display adapters.

wasm64/Memory64 increases addressability; it does **not** make POSIX mmap guards, adjacent reservation, native thread scheduling or GPU APIs work. Addressability alone does not make the inspected native reservation policy an appropriate public-game memory budget. Do not infer Safari compatibility from a Mac's ARM64 CPU or native Bend success. The official [WebAssembly feature matrix](https://webassembly.org/features/) must be checked against the actual Safari version, and a deployed Memory64/tail-call/shared-memory probe run there. No Safari-on-Mac execution was performed here, so Memory64 is not established as a deployable Safari solution by this report.

A meaningful next gate is a small nontrivial generated-C program running under wasm32 with bounded allocation, recursion/tail dispatch, shared values and a yielding effect, followed by a deterministic game-step comparison against native. Until that succeeds, describe the route as a runtime-port project rather than an adapter-only build option.

## Lower-cost alternative: the existing JavaScript backend

**A browser JavaScript host can reuse the same native Bend gameplay, UI and artwork without first porting the C runtime.** This route now has a limited actual-browser smoke result, not just source-level plausibility.

With the parent task's frozen source after actor removal, emitted the complete `examples/survivors/native.bend` using installed Bend 2.0.38: `bend examples/survivors/native.bend -o /tmp/wasm-native-browser-probe.mjs`. The resulting approximately 1.3 MB module has SHA-256 `19c0c306ef138f169e324288a1779857c76c6f70e5cd9d2e7b06d6858a9db033` and 936 default-object exports. In existing headless Chromium, imported its unchanged source through a browser Blob ES module with `typeof process === "undefined"` and `typeof require === "undefined"`. Successfully called:

```
profile = M["native-profile:fresh"]()
state = M.initial(profile)
state = M.reduce({$: "Nil"}, state)
state = M.settle(M.timed(1000, state))
state = M.begin(state)
state = M.settle(M.timed(1017, state))
drawn = M.view(state)
text = M["native-profile:encode"](profile)
```

Result: `state.$ === "Native"`, `drawn.$ === "Tuple"`, `drawn.snd.$ === "Qua"` with `tl/tr/bl/br` image quadrants, and a 139-character profile encoding. Probe script `/tmp/wasm-native-browser-smoke.mjs` used the already-installed Playwright 1.63.0; no browser, toolchain or dependencies were installed. This proves module loading and a small pure native-game path in Chromium. It does not establish whole-game correctness, browser FPS, audible output, persistence behavior, pixel presentation, Safari performance, or long-run memory use.

The exact emitted module and probe are retained with the evidence below.
Successful pure exports do not establish browser implementations of native IO.
The application adapter seams belong to [native.bend](../examples/survivors/native.bend),
[native_draw.bend](../examples/survivors/native_draw.bend),
[native-profile.bend](../examples/survivors/native-profile.bend) and
[native_audio.bend](../examples/survivors/native_audio.bend).
Their signatures and effect implementations are not copied here.

The lower-cost proposal is a browser host around the existing pure Bend
presentation/state boundaries, preserving native launch and shared gameplay/art.
It still needs explicit input, drawing, timing, audio and profile adapters plus
validation under real load. Merely invoking the native application entry does
not establish that host.

Durable evidence is archived in `../../bend-games/research/wasm-native-feasibility-20261024/`: actual tiny C source/output, actual full Native MJS, executed browser probe script, recorded JSON result, hashes and scope. The input smoke used an empty `Nil` event list and invoked `begin` directly; it did not test keyboard/mouse delivery. No full `App.run`, audible audio, browser storage, Safari or dense-gameplay FPS was exercised. The inspected native reservation policy does not establish physical RAM consumption. No compiler/runtime port was implemented.
