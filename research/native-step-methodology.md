# Native game-step measurement methodology

This document records the replay method and its provenance, not an optimization result or a speed gain. Raw local evidence is retained under `../bend-games/research/native-step-20261023/`; preparation artifacts and source snapshots are under `/tmp/native-step-20261023/` on the measurement host.

## Fixed native workload

A typed Bend recorder runs the ordinary game with the native policy and records its movement and upgrade commands. The measured native replay imports no policy: it applies those fixed commands to the actual `G` game entry points. Trace parsing, bootstrap, warmup, JSON observations, rendering, and classifier calls are outside the timed window. No classifier is called by this workload.

The frozen manifest, `benchmarks/native-step/fixtures.json`, contains 21 traces: seeds 100–109 in both fresh and advanced profiles, each covering ticks 0–1200, plus advanced seed 101 with a natural prefix through tick 3600 and a measured suffix through tick 4200. That latter fixture had 165 live enemies at the warm boundary and 179 at the end; it is a measured natural workload, not a claim about maximum density. The manifest binds each numeric trace and the recorder's semantic observation digest.

Each replay is checked against the supplied trace header, action count, fixture identity, tick/phase outcome, and final checkpoint. Reference and candidate semantic records must also match one another and the frozen recorder digest. This prevents two executions of the same unintended fallback trace from qualifying.

## State oracle and controls

The historical observer and its exact observation schema are retained with the
source inventory identified below. Current observation code belongs to
[native-replay-observe.bend](../examples/survivors/native-replay-observe.bend),
and strict comparison belongs to [replay_compare.py](../tools/survivors-bot/replay_compare.py).
The experiment requires complete declared state rather than a selected gameplay
summary; source-derived slot counts and field inventories are not repeated here.

Eight offline oracle tests cover equal states, authoritative payload and metadata mutations, malformed/incomplete records, numeric trace binding, and timing-record handling. Five subprocess controls exercise completion, child failure, timeout, interruption cleanup, and frozen-input drift. These are harness checks, not independent gameplay proofs.

A separate source copy changed the actual player-x calculation in `G.advance_raw_with` by adding `1.0`. It was compiled and replayed against the same valid recorded trace. The native replay rejected the resulting tick/phase divergence, and the semantic comparator rejected the incomplete result. The assessed game source was untouched. The receipt is `/tmp/native-step-20261023/negative-control/receipt.json`.

## Timer completion and provenance

Before stopping the clock, a typed, nonserializing completion barrier folds every actual component payload and lifecycle stamp, current clock, and the Run/rows/offers/snapshots/pending fields into an observable U32 value. The generated C was inspected: the force continuation receives a native scalar digest before constructing the stop-clock `IO.now`; full JSON observation follows the clock. The digest is a materialization barrier, not the correctness oracle. Its once-per-window cost is included in the metric. Zero-suffix diagnostics measured 0–1 ms for this completion path; that diagnostic is not subtracted from results.

The frozen baseline game source SHA-256 is `366aa0235e16813d798912473f465f6cba2fafa568636a939784c5383d7ac56f` (baseline game commit `91a7d92`). The forced replay binary SHA-256 is `38b8f01b563cb4f69446384a019b6e7689e7a5434ad248aa163bf66ffe53a896`; its generated C SHA-256 is `e7095c5aa8ddc9cdf80ce57f62f3e5083c0898e738410431598fab5bb2be8f65`. The complete source inventory is `/tmp/native-step-20261023/baseline-forced-source/MANIFEST.json`; timer review is `/tmp/native-step-20261023/timing-forcing-final-review.json`. Builds use Bend 2.0.37, Clang 19, and the pinned BendHub ECS distribution.

Measurements use serialized native executions, one runtime thread, fixed paired AB/BA ordering, bounded wall time, and hashes checked before and after samples. Process wall time is retained separately from the internal replay window. Early observations, including the first 7987 ms sample and overlapping diagnostic repeats, establish neither an improvement nor a representative baseline. Optimization conclusions require the later declared comparison and its complete receipts.

## Scope of the Args carrier law

[The Args-carrier laws](../examples/survivors/args-carrier/LAWS.bend) define the narrow transport property. It does not prove gameplay equivalence, native timing, allocation behavior, or a speed gain. The corresponding proof is definitional roundtrip equality. A Bend source-check exit 0 must be distinguished from a successful kernel verdict: the retained 2.0.35 `--verdict --check-only` attempt used an unsupported CLI combination, and the corrected `--verdict` attempt hit its 10-second CPU limit. Those attempts are not proof passes. Subsequent 2.0.37 checker or kernel results must be reported with their own completed receipt rather than inferred from the law's simplicity.
