# Reduce the full-game GPU presentation closure

The M2 Max Metal path passes arithmetic and published Hub column controls, while the full game exceeded 1200 seconds during Metal compilation. Presentation reduction alone did not meet the compile budget. A subsequent optional segment-dispatch transformation now compiles and runs short full-game-code batches; see the final experiment below.

## Change

Game initialization, seed/configuration/mode/unlock application and reward choice/promotion share their existing state transitions through a finish callback. Presentation APIs retain their frame-producing callbacks; native bot initialization and choices use quiet callbacks throughout. Movement already used quiet advancement.

Parallel jobs return 15 detached U32 summary fields. The host converts these fields to the original JSON schema after joining. Profile names are parsed on the host and jobs receive a numeric mode. Safety-fuel failure is a separate result variant; actual game failure text remains a String, with its CLI prefix added on the host. Policy goal tie-breaks also legitimately retain strings.

## Generated-code evidence

On Bend 2.0.38, the GPU entry generates 4,877,269 bytes of C and 1073 FID definitions, versus 5,333,935 bytes and 1208 for the previous entry: 8.56% fewer bytes and 135 fewer functions. An independent traversal of all FID references in generated work-loop cases finds 968 cases reachable from solve, including numeric capture and excluding frame/row/offer JSON, game packet formatting and host summary formatting. The version-specific forced-dispatch contract passes; solve retains the audited row `[4,0,1,0]`.

These are source/compiler-resource observations, not a Metal compile-time or runtime speedup claim. The full generated program still includes host summary functions; the reachable GPU closure is the relevant boundary.

## Validation

Eighteen CPU jobs exactly match the previous Bend 2.0.38 executable across zero-tick initialization, eight 120-tick runs, fresh/advanced 1200-tick runs with upgrades, wrapping seeds and nonstandard global indices/strides. Every original JSON field is compared, including null wallMs. This is summary parity, supplemented by the authoritative-state fixture below.

`bash examples/survivors/check-quiet-boundary.sh` compares ordinary and quiet paths using the existing exact world observer: all actual component columns and lifecycle stamps, allocator/world metadata, raw floating-point bits, Run, bodies, offers, snapshots and pending rewards. It covers fresh/advanced starts, wrapping seeds, queued level/chest transitions, invalid choices, terminal/no-op phases and natural 1200-tick runs. Both sides use the previously qualified quiet movement used by the old native bot; initialization and choices compare the old presentation-producing path against the new quiet path. This is a development check on the Bend JavaScript backend: emission is capped at 90 seconds and execution at 180 seconds. The native O3 integration is checked separately by the eighteen summary-parity jobs. Attempts to compile/run this larger observer fixture natively hit bounded compilation/runtime limits on the development host; they are not counted as passes or as full native-state parity.

## Host experiment

From the examples repository root on the Mac:

```sh
bash tools/survivors-bot/metal-experiment.sh --metal-noinline-spins --metal-segment-functions --metal-stage-trace --smoke-ticks 1 --count 2 --ticks 5
```

The successful short-horizon command also selects segment functions and records its lowered smoke/measurement horizons. The original `--metal-noinline-spins` mode by itself did not pass the build cap. This opt-in diagnostic replaces only seven generated helper definition prefixes (`spin_416`, `511`, `382`, `429`, `451`, `526`, `531`) from INLINE to the runtime's existing DFAR qualifier. In this Darwin/Metal experiment DFAR becomes device noinline and expands back to INLINE for CPU computations. The runtime uses the same device qualifier for CUDA too, but this launcher accepts only Darwin arm64/Apple clang and performs no CUDA experiment. It preserves all helper bodies, FIDs, math settings and scheduling, records both C hashes and retains the original C. Every expected definition and macro branch must match exactly, otherwise the command stops.

A source audit found short helpers with large transitive INLINE graphs, suggesting excessive optimizer expansion; no actual Metal IR or causal compiler-time result has been measured. Added calls may affect GPU resource use or speed. This combined feasibility candidate does not isolate the effect of formatting removal from the noinline hint. Omit the flag to test the standard candidate; there is no automatic retry after a timeout.

The supervisor first compiles current C and checks two native CPU smoke jobs. Metal compilation is limited to 120 seconds (also the maximum), and the CPU result survives a Metal timeout. The default complete budget is 900 seconds. On successful compilation it forces GPU execution, checks exact CPU/GPU smoke parity and runs three alternating pairs of eight 120-tick jobs. Reports retain C size, function count, hashes, commands and stage durations. Preserve the final report even on failure; another timeout requires a different candidate, not a larger timeout.

## Qualification result

The full-state development fixture emitted in 25.08 seconds and ran in 149.91 seconds on Bend's JavaScript backend. All 28 expected PASS assertions were verified, including the two complete 1200-tick snapshots, actual upgrade choices and horizon checks. The twelve scenarios cover four starts, six choice/queue cases and two natural runs. This is source-level development qualification; native C full-state fixture attempts remain recorded as timeouts.

The native O3 candidate separately passed all eighteen exact JSON comparisons against the frozen previous executable. The revised supervisor passed 24 fake-runner tests and four inherited diagnostic tests. Independent review confirmed the state transformations, generated GPU closure and bounded optional-mode launch contract. Preprocessing the original and optional C with Clang 19 for CPU produced exactly identical bytes; the Metal embedded program changes as intended. The first subsequent M2 Max run built native C and passed CPU smoke, but Metal preparation exceeded its 120-second cap. Later segment-function results are recorded below.

Evidence is preserved under `../bend-games/research/metal-game-boundary-20261023/`, including source/artifact hashes, summaries, full-state output, receipts, transform metadata and closure audit. Host run `run-20261023T180344Z-40471` on M2 Max / macOS 27.0 / Apple clang 21 / Bend 2.0.38 emitted C in 37.045 s, built natively in 45.601 s and passed two CPU smoke jobs in 1.266 s. The seven-prefix noinline transformation matched the reviewed hashes, but Metal preparation exceeded 120 s. The report is archived as `host-seven-noinline-timeout.json` in that evidence directory. The combined timer cannot attribute this timeout to library compilation or pipeline/archive generation. At that stage GPU correctness and performance remained unmeasured; subsequent short-horizon qualification appears below.

## Stage trace on the M2 Max

Run `run-20261023T182916Z-55343` adds only host-side flushed monotonic stage markers to the seven-helper candidate. C emission took 12.875 s, native build 15.011 s and CPU smoke 0.346 s. Metal again reached the unchanged 120 s cap. `newLibraryWithSource` completed in 89.331148 s; function lookup took 0.000327 s. `addComputePipelineFunctionsWithDescriptor` began next and had not completed when the remaining approximately 30.7 s expired. Archive creation itself took 0.000105 s. This localizes the final timeout to archive population, while source compilation consumed most of the budget.

A three-second sample during source compilation found all 263 active-request-thread samples inside LLVM inline-cost/block-frequency analysis. A separate two-second sample during archive population found 174 active-request-thread samples in the Apple GPU backend's AlwaysInliner/block-frequency analysis. These snapshots establish work during those intervals, not whole-build percentages or which generated function caused it. Samples, raw stage log and unchanged report are archived alongside the earlier receipts as `host-seven-noinline-{library,archive}.sample.txt`, `host-seven-noinline-stages.log` and `host-seven-noinline-stage-timeout.json`. The sampled compiler process subsequently exited; it was not killed.

The optional `--metal-stage-trace` preserves pre-trace C and records both hashes. It logs begin/end around library creation, function lookup, archive creation/population/serialization/loading and pipeline creation. The source embeds its own complete C text; the added host sections are preprocessed out of effective device code. `--metal-optimize-size` separately selects Metal's documented library-size optimization while retaining safe math; it is an experimental compiler option, not a gameplay change. See [compiler options and primary sources](metal-compiler-options.md).

## Further bounded candidates

The seven-helper variant with `--metal-optimize-size` (`run-20261023T183222Z-58434`) spent 93.485011 s in library creation and again timed out at archive population within the same 120 s cap. The all-spin noinline variant (`run-20261023T183552Z-62539`) changed the remaining helper prefixes too: all 760 helpers use device noinline, of which 36 already did. It spent 107.757159 s in library creation and timed out at archive population. Neither establishes GPU correctness or a compilation benefit. Reports are archived as `host-size-seven-noinline-timeout.json` and `host-all-noinline-timeout.json`.

`--metal-segment-functions` is a separate candidate-specific runtime diagnostic. It extracts the device work-loop switch's 1073 textual segments (971 active device cases, with CPU-only guards retained) into direct FAR/noinline functions, sharing an explicit lane state with the 87 registers, stack pointer, result count, sequence flags, next FID and poll counter. A terminal return is distinct from a request to dispatch another segment. Stack-room errors, polling errors and self loops preserve those paths. The default native branch remains the original runtime; `BEND_SEGMENT_CPU_CHECK` selects the same extracted dispatcher on CPU solely for qualification.

The extracted dispatcher passed eighteen native summary comparisons across six scenarios: 1/60/120/1200 ticks, fresh/advanced profiles, wrapped seeds and 1/2/4/8 threads. The 1200-tick cases include actual reward choices. Original versus transformed default native preprocessing is byte-identical with `BEND_METAL=0`. These checks qualify the extraction on CPU; they are neither GPU nor full-authoritative-state equivalence. Source review separately found no semantic blocker. Evidence: `host-segments-native-summary-parity.json`, `host-segments-native-preprocessor.json`, plus the [review and extraction contract](metal-compiler-options.md).

## First completed full-game-code GPU observations

The all-spin/noinline plus segment-functions run `run-20261023T184231Z-68124` emitted C in 13.214 s, built native code in 19.348 s, and completed the Metal build in **32.124 s**, within the unchanged 120 s cap. Source library creation took 7.406041 s, archive population 24.508604 s and serialization 0.089648 s. The two-world/60-tick GPU smoke then exceeded its separate 180 s cap without summaries, so that original experiment failed and produced no paired benchmark. A host sample during execution was waiting in Metal command-buffer completion; it does not identify a device stall versus slow progress. Report: `host-segments-build-pass-runtime-timeout.json`; sample: `host-segments-runtime.sample.txt`.

Reusing that exact binary and GPU sidecar, `reuse-segments-20261023T184717Z` completed one fresh world at seed 100 on forced Metal at horizons 0, 1 and 5. All emitted summary fields matched CPU exactly. GPU process times were 11.235 s, 5.686 s and 16.290 s; CPU process times were 0.206 s, 0.046 s and 0.046 s respectively. These are individual observations with startup/cache effects, **not** repeated timing medians. The 0-tick case checks initialization; the 1/5-tick cases run actual full-game code. This establishes short-horizon execution, not reward-choice coverage, full-run completion, or complete state equivalence. GPU performance is much worse than CPU for these tiny jobs. Report and replay script: `host-segments-short-gpu-parity.json` and `reuse-segment-probe.py`.

`--smoke-ticks` can explicitly lower the smoke horizon from its unchanged 60-tick default to 1..60 ticks. A smaller successful run qualifies only its recorded horizon. This permits bounded feasibility/performance comparisons without changing gameplay or silently relabeling the failed 60-tick smoke.

## Completed paired M2 Max experiment

`run-20261023T185242Z-72940` completed from fresh C emission using seven-helper noinline plus segment functions, retaining safe math and the published Hub dependency. C emission took 24.511 s, native build 13.516 s and Metal build **59.303 s** (library 6.873509 s, archive population 52.261149 s). No build cap was raised. Two one-tick CPU/GPU smoke summaries matched. Three paired repetitions then compared two five-tick worlds, seed 100/fresh and seed 101/advanced, with eight CPU threads and alternating order. All summary fields matched CPU/GPU and the canonical repetition. `status=PASS`, `semanticParity=PASS`, `dispatch=VERIFIED`; CPU fallback was forbidden.

| Repetition | Order | CPU wall | GPU wall |
| --- | --- | ---: | ---: |
| 0 | CPU, GPU | 0.042512 s | 23.948838 s |
| 1 | GPU, CPU | 0.078842 s | 23.553930 s |
| 2 | CPU, GPU | 0.042679 s | 24.015853 s |
| Median | | **0.042679 s** | **23.948838 s** |

GPU is approximately **561.14 times slower** for this short batch. The wall times include process/runtime startup and cached library loading, exclude compilation and smoke, and do not establish steady-state throughput, optimal occupancy or large-batch scaling. This successful test uses the actual game/ECS code, not the small arithmetic/column controls. Its five-tick horizon has no reward choices; neither ten-minute completion, GPU full-state equivalence nor a game speedup is established.

Report: `../bend-games/research/metal-game-boundary-20261023/host-seven-segments-paired-pass.json`. Exact local artifacts and logs remain in `examples/survivors/dist/metal-experiments/run-20261023T185242Z-72940/`. Original C, each transformation input, hashes, executable and sidecar remain available. The successful measurement script and segment transformation are archived with the receipts. Restoring all helper inlining with segment functions (`run-20261023T184851Z-72133`) completed library creation in 7.126827 s but timed out during archive population; it is preserved as `host-segments-inline-archive-timeout.json`. Its short archive sample was in GPU backend machine-code/live-interval passes, not the earlier library inline-cost pass.

The same successful seven-helper/segment binary was then reused for the original two-world/60-tick horizon (`reuse-segments-long-20261023T185809Z`). CPU completed in 0.389 s. GPU library/archive/pipeline loading completed, but execution emitted no summaries before the unchanged 180 s runtime cap. Report: `host-seven-segments-60tick-timeout.json`; replay: `reuse-segment-long.py`. Thus the five-tick paired PASS must not be relabeled as passing the default smoke, complete simulations or useful GPU throughput. These observations do not prove a general impossibility theorem; they identify the current implementation's practical limit.

Final launcher checks: 29 experiment tests plus four inherited small-diagnostic tests; dependency audit passes for all 50 Bend modules. The only post-hardware supervisor adjustment moves the game-specific smoke-horizon report field out of the shared constructor so the small-diagnostic subclass remains compatible; emitted C and execution behavior are unchanged.

## Cleanup and operational status

Use native CPU execution for gameplay and bot batches. Metal remains an opt-in research experiment: the short paired test passed, but GPU was about 561 times slower and the 60-tick follow-up timed out. The failed all-spin-noinline and size-optimization launch modes have been removed; their results remain above as historical evidence, not runnable instructions. Stage tracing, the successful seven-helper/segment mode, and their regression fixtures remain available for reproducibility. The old session handoff and pre-cleanup experimental code were archived outside the repository under `../bend-games/research/metal-cleanup-20261023/`.

Cleanup verification: 27 retained experiment tests and four small-diagnostic tests pass after removing the two failed launch modes. The native game launcher regression and published BendHub dependency audit also pass. Game simulation and the ordinary native launch path were not changed by this cleanup.
