# Co-op population v1: implementation and measured qualification

The candidate changes ordinary population admission from 200% to 125% of the
solo budget for two living players. It preserves the one-player budget, floors
percentage arithmetic and caps admission at 500. HP, damage, XP, timed bosses,
weapon rules and the underlying stage pressure curve are not tuning axes in
this experiment. Existing enemies are not removed when a player dies.

## Experiment identity

The [contract](coop-population-v1-contract.json) was committed before the formal
campaign. Its SHA-256 is
`5661dd428f784a2ecad0aaa5b087e49448520eadfd4f5f553e86e14faed56ff0`.
The [selection](coop-population-v1-selection.json) freezes extra25 before the
final cohort. Historical setup amendments and the initial technical pilot are
disclosed in the contract; they are not independent balance evidence.

Both controllers execute the existing resource-memory policy in one actual
`CoopCore` world, with independent memories and real legal upgrade choices.
Gameplay is compiled Bend/C. Python launches processes, retains receipts and
analyzes observations. There are no classifier requests, model training or
runtime difficulty adjustments.

Normalized game context:
`5b528a6b2dab0ceaf100d5210d4df0fef273632fdfaf2a107c086ce239f754d4`.
Policy:
`9b63e95df0d72d6e60786995671e97c08aae52c91a41031753e46b4046a91279`.
Frozen snapshots retain source and binary hashes; the compiler version is Bend
2.0.38. These identify the observed builds, not a byte-reproducible toolchain.

## Early-game evidence

Four development seeds tested extra100/50/25/0 for 7,200 ticks. Four new
validation seeds compared the preferred extra25 with extra100 for the same
horizon. All 24 episodes reached that bounded horizon; none is a victory.

| Paired cohort | Seeds | Mean living enemies at 120s, old → candidate | Mean final level, old → candidate |
| --- | --- | --- | --- |
| Development | 100–103 | 466 → 287.25 | 2.25 → 3.25 |
| Validation | 104729, 130363, 155921, 196613 | 464.25 → 288.25 | 2.75 → 3.75 |

Per-seed level deltas are +1/+1/+1/+1 in development and +3/+1/0/0 in
validation. This supports lower early population without observed progression
starvation in this small fixed-controller panel. It does not establish human
difficulty, a target win rate, statistical significance or a universal HP
benefit. HP is net health and upgrades can change maximum HP.

V1 telemetry misclassified timed boss variants 20–29 as ordinary. Total living
population and gameplay fields remain valid; **V1 ordinary/boss split fields
must not be used**. V2 fixes the full 20–30 range and retains an actual native
counter fixture, laws and mutants. Old receipts are preserved rather than
rewritten. The final cohort uses V2 consistently in both arms. Both coefficient replays
(extra100 and extra25, seed 100, 7,200 ticks) matched all 242 rows after excluding
only `ordinaryPopulation`, `bossPopulation` and `wallMs`. This finite replay
checks telemetry neutrality; it is not a proof for all seeds.

The first integrated gate passed 52 proof files but its mutant preflight spent
the fixed CPU budget emitting large, unused JavaScript artifacts. The preflight
now uses the compiler's `--check-only` on the same declared consumer/import
graph. Valid and ill-typed body controls are retained. Independent review also
checked invalid imported bodies (including unused imports) and caller type
mismatches. The 10 CPU/60 wall limits and named-law rejection requirements are
unchanged. This retains semantic typechecking, not per-mutant JS-codegen
qualification; fresh normal emitted/native artifact checks remain separate.

## Full-horizon qualification

The frozen final panel requests 36,000 ticks (ten game minutes) for seeds
982451653 and 961748941, crossed with fresh and advanced setups. This is two
seeds in two setups, not four independent seeds. All eight episodes completed
without infrastructure failure:

| Setup | Seed | Old extra100 | Candidate extra25 |
| --- | ---: | --- | --- |
| Fresh | 982451653 | Defeat at tick 29,386; level 10 | Defeat at tick 22,280; level 8 |
| Fresh | 961748941 | Defeat at tick 29,528; level 9 | Horizon 36,000; level 20; only player 1 alive |
| Advanced | 982451653 | Horizon 36,000; level 21; both alive | Horizon 36,000; level 23; both alive |
| Advanced | 961748941 | Horizon 36,000; level 21; both alive | Horizon 36,000; level 22; both alive |

The first fresh seed regresses by 7,106 ticks (about 118 seconds). This is retained
as an adverse result. The other fresh seed reaches the horizon with one survivor;
it does not establish that both players survive. All horizon outcomes are phase 0
bounded observations, **not victories**. The campaign does not observe the
post-horizon ending, and deaths truncate the unplayed late game.

Independent review reproduced the common-prefix population integrals and found
about 27–29% lower sampled population on these four paired trajectories. Coverage
ends at each pair's earlier last sample, without extrapolation after death.
This supports the declared population easing; it does not support universal
survival improvement or a claim of no late-game regression. The selected
coefficient was not retuned using these final seeds.

## Retained checks and evidence

[The evidence index](coop-population-v1-evidence.json) retains all 32 experimental
episode summaries, source/artifact identities, sampled curves, report hashes,
the shared exposure ledger, both telemetry-neutrality replays and the separate
solo control. Complete source snapshots, native binaries and raw captures remain
outside tracked source under the recorded `/tmp/coop-pop-*` paths.

The integrated check passed 52/52 proof files and 380/380 semantic mutants under
the original strict limits. It also passed fresh emitted-runtime checks,
the 1,267,245-case population oracle, 18 actual native population-counter fixtures,
geometry/contact/capability checks, 24 analyzer controls and 16 supervisor controls.
The BendHub audit passed: the example consumes the published dependency.

Actual solo `offline-batch.bend`, seed 100 fresh, reached 7,200 ticks at phase 0,
HP 64 and level 4. This is a solo integration control, not a causal Core1-versus-Core2
comparison. The zero/one-player arithmetic and old coefficient equivalence have
their own laws and retained runtime checks.

The actual-Iroh browser matrix passed on 42 exact fresh runtime assets:
0/200ms before-send delay are interactive regression checks; 600ms is a bounded
overload check only. Guest rejoin, touch ownership, map sampling and intentional
worker/renderer failure recovery passed. These are finite Chromium diagnostics,
not formal proof or physical Safari qualification.

The [independent final review](coop-population-v1-final-review.md) accepts the
scoped population change, preserving the adverse seed and evidence limits.
Fresh-source packaging and publication remain the release step; physical mobile
difficulty remains a human acceptance check.

## Bot retrospective and next iteration

The [development-only retrospective](coop-bot-retrospective-v1.md) identifies
missing causal evidence before proposing a controller change. The two policies
can converge on the same route, but physical proximity alone does not prove
that reserving XP clusters would help. The next bot-axis experiment should
first record goal changes, chosen cluster, reachable alternatives, route risk
and retention/rejection reasons. Only demonstrated contention with a viable
alternative justifies testing a bounded reservation policy.

The analyzer uses paired seeds, complete setup identities, source hashes and
one exposure ledger across game and bot experiments. Missing outcomes are
inconclusive; horizon is censored, not a victory. Population curves use sampled
common coverage, without extrapolating after death. The ledger cannot detect
undeclared manual inspection. Codex remains the offline author of the next
candidate; the current bots do not improve themselves after a run.
