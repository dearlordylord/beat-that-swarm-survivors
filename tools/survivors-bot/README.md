# Native Survivors bot tools

The supported batch launcher runs the Bend game as native code without Node.js. The ordinary game launcher remains `examples/survivors/run.command`.

## Native offline batches

The free headless controller runs through a Bend-to-C entry. From the repository root:

```sh
bash tools/survivors-bot/native-batch.sh --count 100 --ticks 1800 --workers 2 --seed 100 --profile both
```

[native-batch.sh](native-batch.sh) rebuilds and runs native Bend. The process
entry is [offline-batch.bend](../../examples/survivors/offline-batch.bend); each
process owns its world. The wrapper defines runtime thread arguments, limits,
receipt locations and failure behavior. Native execution does not require Node,
graphics, HTTP or classifier calls.

To let Bend schedule independent runs inside one process instead, use:

```sh
bash tools/survivors-bot/native-batch.sh --execution bend --count 100 --ticks 1800 --workers 1 --threads 8 --seed 100 --profile both
```

The Bend entry is [offline-parallel.bend](../../examples/survivors/offline-parallel.bend).
It joins independent simulations before emitting summaries. Its elapsed batch
time is not an individual game's time. Increasing threads requests scheduling;
it does not establish scaling.

[offline-policy.bend](../../examples/survivors/offline-policy.bend) owns the native
controller. The quiet game API shares the ordinary simulation but omits frame
presentation. Native arithmetic and route ties may differ from JavaScript;
supported behavioral parity is checked separately.

Compilation and runtime are separate costs. Backend speed and native scaling
need actual measurements; merely compiling to C does not establish a speedup.
Use a bounded external supervisor for automated campaigns.

Development checks for the new path:

```sh
bend examples/survivors/parallel/PROOF.bend --verdict
```

## Checks and evidence

The root `npm run check:typescript` gate covers types, lint and JSON boundaries. It makes no live classifier requests. [VALIDATION.md](VALIDATION.md) separately records the two successful live classifications and a matched heuristic observation. That short advanced-profile comparison does not demonstrate better decisions or better play.

## Context and actions

[bot-actions.bend](../../examples/survivors/bot-actions.bend) supplies actual legal
alternatives and immediate engine previews. [context.mts](context.mts) packages
them for the provider. Previews do not predict future combat or survival.

[planner.mts](planner.mts) owns the deterministic spatial planner, its observation
model, resource retention, routing and steering. The classifier advises that
planner through prepared legal alternatives. It cannot invent engine actions.
The planner uses omniscient engine observations; it is not a model of human
visibility, and bounded route estimates are not safety guarantees.

Receipts retain decision context, sanitized responses, outcomes and selected
source/artifact hashes. Classifier replies are external inputs; equal game seeds
do not make those replies deterministic. The provider alias is mutable and does
not identify immutable model weights or measured monetary cost.

## Persistent XP verification

[The small-core proof](../../examples/survivors/persistent-xp/PROOF.bend) covers accounting helpers, not the entire ECS lifecycle or collision geometry.

Correctness-run budgets belong to the check runners, and current pool values
belong to [pools.bend](../../examples/survivors/pools.bend). Neither supplies a
performance qualification.

## Balance comparisons and retrospective evidence

`balance-report.py` is an optional stdlib-Python analysis tool for native co-op
receipts. It does not run the game, change a policy, call a classifier, select an
automatic winner, or train model weights. Its JSON report contains seed-level
pairs, matched-tick population/HP/XP/level observations, outcome counts and a
small retrospective identifying observed failures and missing decision evidence.
The Markdown companion is a readable index into that evidence.

Supply previously recorded campaign directories and their frozen criteria to
the analyzer. It does not launch a campaign.

```sh
python3 -B tools/survivors-bot/balance-report.py compare \
  --baseline /absolute/path/to/current-population \
  --candidate /absolute/path/to/candidate-population \
  --criteria research/coop-population-v1-contract.json \
  --output /tmp/coop-population-comparison \
  --ledger /absolute/path/to/balance-exposure-ledger.json \
  --cohort development --purpose tune

```

Each campaign directory supplies `manifest.json`, explicit `seeds`, and its
relative JSONL `records` paths. Pair identity is `(seed, setupId, styleId,
partySize)`, with equal horizons and identical complete `setup` objects. Setup
and runner hashes are also compared when supplied. A game comparison requires the same
`policyHash`; a bot comparison requires the same `gameHash`. If supplied,
`gameContextHash` additionally protects game code outside the declared tuning
inputs. Source, criteria, manifest, receipt and analyzer hashes remain in the
report. A pilot lacking criteria bindings can explicitly use
`--allow-unbound-criteria`; its result is labeled `diagnostic-only`.

`horizon` is a bounded/censored observation, never a victory. Phase 3 defeat,
phase 4 endpoint victory (including its legitimate HP-zero state), and aborted
or missing summaries remain distinct. A failed campaign is inconclusive even
when some summaries are valid. The common-prefix population comparison integrates both arms over exactly the
same observed coverage; each arm's separate full-duration integral is retained
only with its own coverage. Time curves show the number of paired observed
runs at each tick; they do not silently replace missing/dead trajectories with
zero or hide the changing denominator. Population integrals use actual sample
intervals and stop at the last sample. Comparing unequal-duration integrals as
full-run pressure would be invalid. HP is net health, not total damage received;
current XP can reset at a level-up and is not cumulative collected XP.

Use **one exposure ledger across both bot and game tuning**. Before final
confirmation, every development/validation report should register its exposure
with that ledger. Register manual inspection too:

```sh
python3 -B tools/survivors-bot/balance-report.py mark \
  --ledger /absolute/path/to/balance-exposure-ledger.json \
  --axis bot --cohort development --purpose tune \
  --seeds 100,101,102,103 --note 'Inspected XP routing failures'
```

When criteria declare cohorts, the analyzer checks the actual seeds, horizon,
extra percent and declared profile restrictions against that cohort. Declared
baseline/confirmation arm assignments and every field of a declared setup
catalog are also checked; matching labels alone are insufficient. The
predeclared short pilot is labeled diagnostic even when its criteria hash is
bound; milestones beyond an alive pilot's horizon remain unknown/censored,
while an actual earlier defeat remains a known failure. First observed level 2
is a sampled upper bound, not an exact upgrade-event timestamp.

An independent final comparison uses `--cohort final --purpose evaluate` and
requires complete, criteria-bound receipts, a declared final seed cohort and
the ledger. Seeds exposed to
prior tuning or another candidate are refused. Distinct setup/style scopes
may share seeds **within the same frozen final candidate group**; they are not
new independent seeds. Re-rendering identical evidence is idempotent, while
rerunning the same scope with different evidence is not accepted as a new
independent final check. The ledger is procedural bookkeeping, not access
control: it cannot detect unrecorded runs or a person's undeclared inspection.
No confidence interval or statistical significance is inferred by this first
analysis tool; retain the raw pairs and predeclared decision rule.
