# Reduce the full-game GPU presentation closure

The M2 Max Metal path passes arithmetic and published Hub column controls, while the full game exceeded 1200 seconds during Metal compilation. This candidate reduces reachable presentation code before a fresh, shorter host attempt.

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
bash tools/survivors-bot/metal-experiment.sh --metal-noinline-spins
```

The recommended next feasibility run explicitly selects `--metal-noinline-spins`. This opt-in diagnostic replaces only seven generated helper definition prefixes (`spin_416`, `511`, `382`, `429`, `451`, `526`, `531`) from INLINE to the runtime's existing DFAR qualifier. In this Darwin/Metal experiment DFAR becomes device noinline and expands back to INLINE for CPU computations. The runtime uses the same device qualifier for CUDA too, but this launcher accepts only Darwin arm64/Apple clang and performs no CUDA experiment. It preserves all helper bodies, FIDs, math settings and scheduling, records both C hashes and retains the original C. Every expected definition and macro branch must match exactly, otherwise the command stops.

A source audit found short helpers with large transitive INLINE graphs, suggesting excessive optimizer expansion; no actual Metal IR or causal compiler-time result has been measured. Added calls may affect GPU resource use or speed. This combined feasibility candidate does not isolate the effect of formatting removal from the noinline hint. Omit the flag to test the standard candidate; there is no automatic retry after a timeout.

The supervisor first compiles current C and checks two native CPU smoke jobs. Metal compilation is limited to 120 seconds (also the maximum), and the CPU result survives a Metal timeout. The default complete budget is 900 seconds. On successful compilation it forces GPU execution, checks exact CPU/GPU smoke parity and runs three alternating pairs of eight 120-tick jobs. Reports retain C size, function count, hashes, commands and stage durations. Preserve the final report even on failure; another timeout requires a different candidate, not a larger timeout.

## Qualification result

The full-state development fixture emitted in 25.08 seconds and ran in 149.91 seconds on Bend's JavaScript backend. All 28 expected PASS assertions were verified, including the two complete 1200-tick snapshots, actual upgrade choices and horizon checks. The twelve scenarios cover four starts, six choice/queue cases and two natural runs. This is source-level development qualification; native C full-state fixture attempts remain recorded as timeouts.

The native O3 candidate separately passed all eighteen exact JSON comparisons against the frozen previous executable. The revised supervisor passed 24 fake-runner tests and four inherited diagnostic tests. Independent review confirmed the state transformations, generated GPU closure and bounded optional-mode launch contract. Preprocessing the original and optional C with Clang 19 for CPU produced exactly identical bytes; the Metal embedded program changes as intended. No actual Metal build or GPU performance result exists for this candidate yet.

Evidence is preserved under `../bend-games/research/metal-game-boundary-20261023/`, including source/artifact hashes, summaries, full-state output, receipts, transform metadata and closure audit. Full-game Metal compilation, correctness and performance for this candidate await host execution.
