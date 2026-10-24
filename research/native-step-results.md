# ArgsCarrier: qualified native replay result

On the frozen 21-trace workload, sharing one boxed query-argument carrier reduced the median candidate/reference native replay time to **0.94963** (about 5.0% less time). The geometric mean ratio was **0.95633**. All 63 reference/candidate pairs passed the exact replay oracle. This result concerns ArgsCarrier alone; the separate core `C.get` full confirmation was rejected: median 0.97579618 exceeds 0.97 and its interval upper bound 1.03951578 exceeds 1. No combined gain is claimed.

The change wraps immutable `Args` once at each of three existing query entries and unwraps it only when invoking the original selected-row callback. Query plans, capability declarations, callback order, gameplay formulas and failure branches are unchanged. Generated C for the affected traversals carries one `Term` argument instead of 34 flattened argument fields; their continuation reservation falls from 35 words to 2 including the world. This is a reached transport change, not a replacement ECS backend.

## Evidence and limits

The fixed cohort contains fresh and advanced profiles for seeds 100–109, each measuring 1200 ticks, plus natural advanced seed 101 measuring ticks 3600–4200 after its recorded prefix. The latter has 165 live enemies at the start and 179 at the end. Three rounds alternate reference-first/candidate-first order. Each native executable uses one runtime thread on CPU 0, with serialized execution and frozen input hashes.

| Statistic | Candidate/reference time |
|---|---:|
| Median,63 pairs | 0.94963049 |
| Geometric mean | 0.95633111 |
| Primary 95% fixture-cluster bootstrap interval | [0.93813699,0.97496971] |
| Secondary 95% seed-cluster bootstrap interval | [0.93701435,0.97510246] |
| Reference-first / candidate-first medians | 0.95384513 /0.94501452 |
| Round 0 /1 /2 medians | 0.99821464 /0.90075014 /0.94833717 |

The primary interval resamples 21 fixture clusters using the frozen evaluator. The separately labeled secondary analysis groups fresh, advanced and later windows sharing a seed into 10 clusters. It does not replace the primary receipt. The first round is nearly neutral and round variation is substantial; the median absolute reference-repeat deviation is 3.89%. Early samples and overlapping diagnostic repeats are not treated as independent evidence of improvement.

At 60 game ticks per simulated second, candidate throughput was:

| Workload | Simulated seconds per measured second, observed minimum / median | Milliseconds per tick, median / observed maximum |
|---|---:|---:|
| Fresh,30 windows |3.104 /4.074 |4.091 /5.370 |
| Advanced,30 windows |2.881 /4.049 |4.117 /5.786 |
| Later natural,3 windows |3.090 /3.544 |4.703 /5.393 |

These minima describe observed samples, not statistical lower bounds. They show native step headroom on these finite workloads. They do not establish endgame adequacy, whole-game FPS, bot-planning throughput or macOS performance.

The internal window excludes compilation, trace parsing, bootstrap, warmup, policy evaluation, rendering and JSON serialization. It includes the actual game commands, upgrade commands in the recorded suffix, and one typed state-materialization barrier before the stop clock. Generated C confirms the barrier returns an actual scalar before constructing the stop-clock operation. Its 0–1ms zero-suffix diagnostic cost is not subtracted.

Every pair joins the supplied numeric trace and frozen recorder semantic digest, then compares Run, cached rows, offers, snapshots, pending state, every component slot, lifecycle stamp and world-metadata field declared by the frozen observer. F32 values compare as exact bits. This is finite checkpoint equivalence, not a universal refinement proof. A separately compiled mutation adding 1.0 to the actual player-x calculation was rejected by replay and comparator. Eight oracle controls and five subprocess cleanup/failure controls passed.

The Args carrier law states the box/open roundtrip identity. Its definitional-equality proof term passed plain Bend 2.0.37 source checking, but the bounded kernel attempt exited 137 and remains incomplete. Mathematical kernel verification, universal gameplay equivalence and performance are not proved by that frontend result.

## Reproduction and provenance

Use the published BendHub dependency pinned by `bendhub-dependencies.json`: Bend 2.0.37 and `bendvy-ecs-core@0.1.0.1`, content hash `0xf435da9e535b3846d643dad16580e35f`. Set `BEND_LIB` to the directory populated from that public distribution, and `CC` to a working Clang 19 toolchain. Native gameplay and replay do not require Node; Node is used here by the repository's bounded development-check helper.

The normal-XP baseline is game commit `91a7d9286369ab13d568e91aeb57023aa80ceb20`, game SHA-256 `366aa0235e16813d798912473f465f6cba2fafa568636a939784c5383d7ac56f`. Candidate game SHA-256 is `a3be401a08129612fc5b34b8ff356ccc6289c5c4daf5129ff0f440b3c84504c6`. Foreign MAIN XP×2 and UI/balance edits were preserved separately and did not enter this normal-XP comparison. Do not compare timings across those two balance settings.

For a historical Args-only reproduction, use the archived exact Args source/harness closure or this source-bound publication commit, and create two isolated copies of that same closure. Both roles must resolve the published 0.1.0.1 dependency; do not use a current checkout upgraded to another core version for only the candidate. Replace only the reference copy's game.bend with the baseline version; leave its replay modules identical. From the candidate copy, with paths configured for those isolated copies:

```sh
export BEND=/path/to/bend-2.0.37
export BEND_LIB=/path/to/published-bendhub-library
export CC=/path/to/clang-19
export NODE=/path/to/node
export BENDVY_EXAMPLE_CPU=0
export PYTHONDONTWRITEBYTECODE=1
# REF_CHECKOUT is the isolated reference copy; CHECK_OUT is a new artifact folder.
mkdir -p "$CHECK_OUT"
git show 91a7d9286369ab13d568e91aeb57023aa80ceb20:examples/survivors/game.bend > "$REF_CHECKOUT/examples/survivors/game.bend"
source examples/common.sh
example_timeout 300 "${example_cpu[@]}" "$BEND" "$REF_CHECKOUT/examples/survivors/native-replay.bend" -o "$CHECK_OUT/reference"
example_timeout 300 "${example_cpu[@]}" "$BEND" examples/survivors/native-replay.bend -o "$CHECK_OUT/candidate"
example_timeout 1500 "${example_cpu[@]}" python3 tools/survivors-bot/measure-native-step.py \
  --reference "$CHECK_OUT/reference" --candidate "$CHECK_OUT/candidate" \
  --fixtures benchmarks/native-step/fixtures.json --rounds 3 --timeout 120 \
  --max-seconds 1500 --output "$CHECK_OUT/confirmation"
```

Both executables must use the same resolved published dependency and compiler flags. Reproduction timings depend on the host; hash identities and exact semantic acceptance are retained for each run.

[The small summary](native-step-results/args-confirm-summary.json) binds original binary, source, evaluator, trace and raw-ledger hashes. [The 63-pair table](native-step-results/args-confirm-pairs.csv) preserves every observed pair. No binary or large raw replay log is committed. Historical raw artifacts reside in the sibling research archive `../bend-games/research/native-step-20261023/args-carrier-confirmation/`; those local paths are provenance, not runtime dependencies or portable reproduction prerequisites.

## Further candidates

All measured additional candidates failed their predeclared gates; none is shipped. The updated-kind collision guard completed63 pairs with median ratio0.98933 and interval[0.97345,0.99628], below the required3% reduction. The final visible-map core patch has passing bounded JS/native owner checks and C audits, but complete game-native/performance qualification remains unrun. It is retained outside this repository as unqualified work. See [candidate results](native-step-results/candidate-results.json).
