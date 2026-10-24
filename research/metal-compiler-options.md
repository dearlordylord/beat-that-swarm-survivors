# Bounded full-game Metal compiler follow-ups

Read-only investigation on 2026-10-23. No build or GPU execution was performed for this note. The seven-helper candidate used for inspection is `examples/survivors/dist/metal-experiments/run-20261023T180344Z-40471/generated.c` (SHA256 `97feec3655194fb5711411b2bf65f09e38f0104d8bcc7815e7504919f624c5c1`). These are proposed experiments, not successful compilation or correctness claims.

## Distinguish the two compilers

Apple describes source → Metal IR library → device-specific binary as separate stages. [`newLibraryWithSource:options:error:`](https://developer.apple.com/documentation/metal/metal-libraries) performs source-library work; archive/pipeline APIs subsequently need GPU-specific code. The generated-runtime source identified above contains the library/archive
construction; its call graph is not repeated here. Timestamp both boundaries before attributing a timeout to either compiler.

## New sampled evidence

During the separately supervised traced run `run-20261023T182916Z-55343`, the parent captured `/tmp/survivors-metal-library.sample.txt`: a three-second, 10 ms process sample of `MTLCompilerService` PID 56930 at 14:30:47 local time, about 60 seconds after that service launched. The trace had entered `library` and had no library-end marker at that point. All 263 samples on its active request thread include `MTLGPUCompilerBuildFromSourceToBuffer` → `llvm::ModuleInlinerWrapperPass` → `llvm::InlinerPass` → `llvm::DefaultInlineAdvisor` → `llvm::getInlineCost` → block-frequency analysis. Other sampled threads were idle/waiting.

This is actual evidence that source-library compilation was spending that interval in inlining cost analysis; it is stronger than a static source-size hypothesis. It does **not** identify the expensive function, establish the percentage of the entire build spent there, or show that seven hints helped or hurt. The sample has been preserved as `../bend-games/research/metal-game-boundary-20261023/host-seven-noinline-library.sample.txt`; the final stage result is recorded in [the candidate evidence](metal-game-boundary.md#stage-trace-on-the-m2-max). Both size optimization and broader noinline boundaries target this observed work; size optimization remains the smaller first change.

## Ranked follow-ups after stage tracing

1. **Set size optimization, preserve safe math.** Insert `opts.optimizationLevel = MTLLibraryOptimizationLevelSize;` beside `opts.mathMode = MTLMathModeSafe;` in `gpu_desc`. This changes one host compiler setting, retaining the game, scheduling and arithmetic policy. [Apple's size-optimization guidance](https://developer.apple.com/documentation/metal/minimizing-the-binary-size-of-a-shader-library) says the option limits code duplication from inlining/unrolling and can shorten compilation. That is a rationale, not evidence this game will fit 120 seconds. The installed macOS 27 SDK's `Metal.framework/Headers/MTLLibrary.h` declares the property and enum, available since macOS 13. Compare to the traced seven-helper candidate, altering only this setting. Compile success must precede exact CPU/GPU comparisons.

2. **Make every remaining generated spin helper device-noinline.** The executable transformation and inspected artifact define the remaining helper set. A mechanically auditable experiment must preserve bodies, order, calls and CPU preprocessed code. It tests whether remaining cross-helper expansion prevents compilation. It may increase device calls, stack demand or execution time; retaining safe math is insufficient to claim parity without execution. Existing noinline helpers establish syntax precedent, not scalability. Test independently from size optimization if attribution matters.

3. **Use offline compilation as a diagnostic, not an automatic fix.** `xcrun --find metal` locates the installed Metal toolchain. Apple documents [source → IR → metallib commands](https://developer.apple.com/documentation/metal/building-a-shader-library-by-precompiling-source-files) and runtime loading with `newLibraryWithURL:error:`. This can separate frontend/IR compilation from archive code generation and makes the compiler an owned process. Preserve the exact `CUBE_LOG`, Metal language revision and safe math (`-fmetal-math-mode=safe`; the local compiler's `--help` explicitly says its default is fast). A `.metallib` IR library is not the runtime's `.gpu` binary archive. To bypass `gpu_desc` source compilation, the runtime must actually load the IR library by URL; dropping an IR file at the archive path will not do it. Offline compilation moves work, but does not prove that work becomes faster.

4. **Split device work-loop segments only if smaller changes fail.** The inspected device dispatcher presents a larger optimizer-visible boundary than the proposed extracted segments. Host dispatch is not a drop-in device implementation; all state-transfer semantics require review against the source. A correct extraction needs an explicit shared state/result protocol and must preserve stack spills, returns, polling and errors. This is a compiler-backend change with a larger semantic review surface, not a small local game fix. Large source size alone does not establish it is necessary or would succeed.

Keep the existing 120-second Metal build maximum. After a timeout, preserve the trace and inspect bounded process evidence before another distinct candidate; never kill all system compiler services. None of these proposals establishes impossibility of the game on Metal, nor guarantees a feasible build. A passing build still needs forced GPU execution, gameplay-summary parity, and separately labeled timing; full-state equivalence remains a different qualification.

## If all-spin noinline still fails: mechanical segment extraction

The parent reports that the traced seven-helper build completed library creation in 89.331 seconds and then timed out in archive-add within the remaining 120-second total budget; size optimization completed library creation in 93.485 seconds and also timed out in archive-add. These observations do not isolate all archive time or establish a benefit from size mode. The next all-spin noinline trial is separate.

The source inspection distinguished textual cases from device-active and
solve-reachable cases; those counts describe different sets. The recorded
artifact and [mechanical extractor](../tools/survivors-bot/metal_segments.py)
are authoritative for the classification and transformation.

The proposed transformation isolates optimizer-visible segments while preserving
host preprocessing, device state transfer, error exits and scheduling semantics.
The executable extractor owns the state layout, macro rewrites and dispatch
recipe. An unclassified transition must fail closed rather than guess. Review
must cover polling, returns, spills and availability guards, not merely successful
compilation.

This bounds each segment's optimizer-visible control-flow graph and prevents the compiler merging segments back when `FAR` is honored. The original switch has jumps from many segments through one shared dispatcher and a large live register bank; block-frequency/branch-probability analysis can still traverse that graph even when spin calls are noinline. That is a plausible mechanism, **not** an observed cause unless a new sample identifies it.

The state pointer can force register-bank spills into thread memory, and hundreds of calls can slow execution. Exact device summary parity and bounded execution remain required even if compilation improves. Qualify the transformation first on arithmetic and raw-column controls, validate CPU preprocessed bytes against the untransformed source, and assert that no function body, FID mapping, safe-math setting, scheduling constant, or error exit changes beyond the stated state-transfer rewrite. Any residual unclassified return/transition should stop transformation rather than guess.

Read-only review of the subsequently implemented
[metal_segments.py](../tools/survivors-bot/metal_segments.py) found no concrete
state-transfer or dispatch bug. Its implementation details are not copied here.
That finding does not qualify compilation or runtime parity; those require the
separate source-bound checks.

The all-spin noinline trial reportedly completed library creation in 107.757 seconds, leaving roughly 12 seconds before archive-add hit the same total 120-second cap. This does not show that noinline improved compilation; compare it only as a distinct failed feasibility candidate. The next split candidate addresses a different optimizer boundary.

## Cleanup and operational status

Use native CPU execution for gameplay and bot batches. Metal remains an opt-in research experiment: the short paired test passed, but GPU was about 561 times slower and the 60-tick follow-up timed out. The failed all-spin-noinline and size-optimization launch modes have been removed; their results remain above as historical evidence, not runnable instructions. Stage tracing, the successful seven-helper/segment mode, and their regression fixtures remain available for reproducibility. The old session handoff and pre-cleanup experimental code were archived outside the repository under `../bend-games/research/metal-cleanup-20261023/`.
