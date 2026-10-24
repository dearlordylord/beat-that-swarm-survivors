# Native Bend runtime to browser Wasm: feasibility

Assessed 2026-10-24. Same Bend game/ECS logic in native and browser Wasm is plausible, but **Bend 2.0.38's emitted native C requires a runtime port; browser effect adapters alone are insufficient**. A bounded, single-worker wasm32 runtime is the practical first target. No performance or whole-game Wasm execution was demonstrated in this investigation.

## Version and reproducible evidence

Installed `/home/node/.bend/bin/bend version` reports `bend 2.0.38`; executable SHA-256 `df7bf5efcbfc30c91276ed48ec4489252920c3a486c76d2bed1acf36ff539515`. `/home/node/.bend/bend2` contains Base, effects and BendTT, **not compiler source**. Its CLI advertises C, JS, MJS, BendTT and native binary output, with no Wasm target.

Actual 2.0.38 runtime evidence was obtained without building anything: write `import Base\ndef main() -> U32: 1\n` to `/tmp/wasm-runtime-probe.bend`, then `bend /tmp/wasm-runtime-probe.bend -o /tmp/wasm-runtime-probe.c`. Emitted C SHA-256: `e1cae46d24651633e8409cf0f929f5f7acda5d91f7286abe2fb37f0d7721b287`. Line references below refer to that reproducible output.

The local reference compiler is **older**, not newer: `/workspace/formal-proofs/bendvy/.references/bend2/bend2/main.ts:33` says `2.0.35`, revision `a950fd683c0d76f09794078e6174fe98a1492876`, official origin `https://github.com/bendlang/bend.git`. Its [CLI output dispatch](https://github.com/bendlang/bend/blob/a950fd683c0d76f09794078e6174fe98a1492876/bend2/main.ts#L358) selects JS/MJS/C/BendTT or native compilation; no Wasm route appears. This is supporting evidence only; it is not the installed compiler's source revision. This investigation does not claim no unpublished/upstream Wasm work exists.

## Runtime obstacles and what must change

| Area | Actual emitted 2.0.38 evidence | Consequence |
| --- | --- | --- |
| Heap/address space | `corpus_setup`, line 2275, unconditionally chooses `1ull << 33` (8 GiB) for CPU; `corpus_map`, line 2231, tries high addresses starting at `1ull << 45`; `corpus_grow` maps adjacent regions in place | Cannot fit wasm32's 4 GiB address space. Replace native virtual reservation/growth with a smaller linear-memory arena and explicit capacity policy; CPU `--gpu …` memory settings do not shrink this heap. |
| Stack and fault guard | `pool_stack`, line 1685: 2 GiB reservation per evaluation/worker stack, `mprotect(PROT_NONE)`, `sigaltstack`, SIGSEGV/SIGBUS handlers | Replace with bounded explicit stacks and checked growth/overflow. Browser linear memory does not provide this POSIX guard-page arrangement. Native sparse virtual reservations are not equivalent to committed browser memory. |
| Term representation | line 175 `typedef u64 Term`; `LOC_MASK` is 40 bits; `term_make` packs tag/aux/location, and `term_peek` indexes `H[term_loc(t)]`; `io_hand`, line 2343, packs host handles | These are primarily **heap word offsets**, not all raw 64-bit pointers. Keeping 64-bit Terms is compatible with wasm32 arithmetic if arena offsets are bounded. Audit pointer/handle casts separately; JS objects need a handle table. A complete 32-bit Term rewrite is unnecessary for a first port. |
| Parallel execution | `pool_open`, line 1757, creates pthread workers; `pool_work` allocates the huge stack; condition variables and locks drive task rows; `io_help`/`io_submit` use background pthread helpers, lines 2640–2671 | Start with one worker and synchronous/nonblocking browser effect completion, or deliberately port to Emscripten pthreads. Bend forks are scheduler tasks, not POSIX `fork()` calls. Parallel semantics and progress still need validation. |
| Tail dispatch/compiler | `WL_JMP`/`WL_DYN`, lines 123–124, mandate Clang `musttail`; `preserve_none`/`preserve_most` are conditionally enabled, lines 94–100 | Verify the chosen wasm Clang/tail-call feature combination using a nontrivial generated program. Removing `musttail` blindly risks unbounded C/Wasm call-stack growth. A trampoline/switch dispatch is a fallback backend change. |
| Atomics and arithmetic | C11 32-bit atomics, locks using `__atomic_exchange_n`, and `w64_load` as relaxed `_Atomic u64` load, line 461; ordinary u64 Terms, shifts and offsets | Wasm supports i64 arithmetic; 64-bit Terms alone are not a blocker. Threaded builds require Wasm shared-memory/atomic support and suitable lowering of all atomic operations. Single-worker specialization can simplify synchronization. |
| Platform and GPU | POSIX headers at lines 29–37; `sysconf`, `/proc/self/exe`/`readlink`; conditional Metal/Foundation, CUDA/NVRTC blocks | Supply browser CPU-count/timing/process shims or remove unused native paths. Disable native Metal/CUDA; WebGPU would require a separate backend, not merely changing window effects. |

The emitted native allocator is runtime-owned (corpus banks/pages/rings); exchanging libc `malloc` alone does not repair it. Preserve its offset and sharing invariants while changing reservation, growth and stack policy. Emscripten's [portability guidance](https://emscripten.org/docs/porting/guidelines/portability_guidelines.html) and [API limitations](https://emscripten.org/docs/porting/guidelines/api_limitations.html) document the underlying browser/POSIX mismatch.

## Browser boundary and target choice

Canvas/WebGL drawing, input, Web Audio, persistent storage and clock delivery belong in browser adapters. Scheduling an animation frame, yielding to the browser, and resuming IO also require an exported/resumable runtime entry point or explicit asynchronous integration; a native blocking main loop is not a browser contract. Emscripten documents [browser main-loop integration](https://emscripten.org/docs/api_reference/emscripten.h.html#browser-execution-environment).

For public deployment, begin with wasm32, a measured small arena, explicit checked stacks, CPU execution and one worker. This preserves Bend source logic while confining changes to the compiler/runtime and browser boundary. Multithreading is a second milestone: Emscripten [pthreads documentation](https://emscripten.org/docs/porting/pthreads.html) requires shared memory and COOP/COEP deployment headers, describes main-thread blocking hazards, and states one binary cannot transparently support both threaded and nonthreaded execution. These are hosting/runtime decisions beyond display adapters.

wasm64/Memory64 increases addressability; it does **not** make POSIX mmap guards, adjacent reservation, native thread scheduling or GPU APIs work. It also does not make an 8 GiB initial corpus plus 2 GiB per-worker stacks a reasonable public-game memory budget. Do not infer Safari compatibility from a Mac's ARM64 CPU or native Bend success. The official [WebAssembly feature matrix](https://webassembly.org/features/) must be checked against the actual Safari version, and a deployed Memory64/tail-call/shared-memory probe run there. No Safari-on-Mac execution was performed here, so Memory64 is not established as a deployable Safari solution by this report.

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

The emitted module has no top-level ES imports. It contains Node `require` calls inside unused file/process effect functions and inside a process-worker source string. These do not run when importing and invoking the pure path above. Its `$0eff` registry is module-private, so replacing effects externally is not an established API. Installed 2.0.38 also exports some functions returning IO descriptions; their presence does **not** imply their effects are browser implementations. The older reference compiler's export-filter comments should not be treated as an exact description of this newer output.

The useful adapter boundary is already present in Bend:

- `native.bend:406` `view` returns the retained state and native `Image`; `native_draw.bend:124` builds its same quadtree image from native rectangles. A Canvas/WebGL host can display this image without duplicating game art or rules in JavaScript.
- `native.bend:617` `reduce`, `:642` `settle`, `:672` `timed`, and `:686` `initial` are callable pure state transitions. A browser host translates input events and uses `requestAnimationFrame`/a browser clock to drive these functions, threading the affine state once.
- `native-profile.bend:19` `fresh`, `:158` `encode`, and `:201` `decode` provide the native profile format. Browser storage can use that codec; the existing `load`/`save` path instead uses files and `Process.run("/bin/mv", …)` and must be replaced at the host boundary. Retain the native dirty/save-success semantics in any browser wrapper.
- `native_audio.bend:5` `samples` and `:10` `frequency` are pure Bend synthesis; a Web Audio adapter can deliver those samples. Existing installed JS `audio_open.js` explicitly implements a silent clock-drained device, so calling the native audio effects is not audible browser support.

The installed JS `window_open.js` explicitly returns “no display”; `window_frame.js` does not provide a browser renderer. Therefore compiling and calling native `App.run` is not the proposed solution. Use the pure exported presentation/state functions with a small browser host, keep game logic and art in the same Bend sources, and preserve the native launcher. This is substantially less compiler/runtime work than Wasm, but still requires browser input, quadtree presentation, timing, audio and profile adapters plus validation under real gameplay load.

Durable evidence is archived in `../../bend-games/research/wasm-native-feasibility-20261024/`: actual tiny C source/output, actual full Native MJS, executed browser probe script, recorded JSON result, hashes and scope. The input smoke used an empty `Nil` event list and invoked `begin` directly; it did not test keyboard/mouse delivery. No full `App.run`, audible audio, browser storage, Safari or dense-gameplay FPS was exercised. The native 8 GiB corpus and 2 GiB stacks are virtual address reservations, not assertions of equivalent physical RAM consumption. No compiler/runtime port was implemented.
