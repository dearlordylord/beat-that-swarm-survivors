# Survivors ECS integration record

## Integration source

- Integration branch: `refactor/survivors-ecs-integration`.
- Integration worktree: `/workspace/formal-proofs/bendvy-survivors-integration`.
- Initial base: clean `master` commit `01b4164612cd6e37d39aa75b16fab2dd253ebb0d`.
- Parent specification: <https://github.com/dearlordylord/bendvy-ecs-examples/issues/1>.
- Implementation tasks: GitHub issues 2 through 10 in the same repository.
- Existing edits in the original worktree are excluded from this integration source and must be preserved.

## Integration procedure

Workers use isolated worktrees created from the integration branch. Each completed
worker change receives independent review before integration. Review/fix loops are
bounded to three rounds; unresolved findings are recorded rather than silently
discarded. The coordinator authorizes integration after assessing the review.

The integration agent cherry-picks authorized commits, runs the relevant checks,
records the results below, and removes only the corresponding finished worker
worktree and branch after verifying the integrated commits. Baseline snapshots
and unrelated worktrees are retained. No merge to `master`, push, release build,
or publication is performed without a subsequent coordinator instruction.

## Integration evidence

| Task | Worker commit | Review evidence | Integrated commit | Checks | Cleanup |
| --- | --- | --- | --- | --- | --- |
| Setup | Not applicable | Coordinator assigned integration ownership | This record's initial commit | Integration worktree inspected clean on the declared branch/base; repository instructions read | None |
| Issue 2: baseline and qualification contract | `278cde1` | Standards and Spec reviewers passed round 1; coordinator verified 39 artifact hashes, 546 archived source files, raw mutation controls and six co-op snapshots | `94adec5` | Python syntax, receipt JSON parsing, both capture-module Node syntax checks, dependency audit and whitespace checks passed | Completed worker worktree and branch removed; external baseline retained |
| Issue 3: typed simulation/encoding boundary | `3267660`, `86c4b16`, `104e044` | Standards and Spec reviewers passed round 2 after diagnostic callers and benchmark timing were repaired | `50f62d5`, `c0b38f3`, `2ec740c` | Coordinator's native receipt: 15 checkpoints across three traces exactly matched baseline sparse ECS payloads, with Node unavailable and stable native source fingerprint; full co-op reliability, 43 UI checks, typed boundary, dense contacts, five rejoin mutants and attach proof passed. Integration reran changed JavaScript syntax, dependency audit (199 Bend modules) and whitespace checks | Completed worker worktree and branch removed; external receipts retained |
| Issue 8: explicit player/session authority | `38f0f6b`, `9f2a949`, `a3d2bc9` | Standards and Spec reviewers passed formal round 1 with no unresolved findings | `8bc3d2f`, `8bff3d9`, `bccc187` | Tracked authority receipt: 15 native checkpoints across three traces exactly matched baseline, six co-op states matched after explicit authority partition/tag changes with physical metadata retained, five raw authority controls detected mutations, public journeys and full co-op checks passed. Integration verified changed tooling syntax, all five external artifact hashes, dependency audit (200 modules) and whitespace | Worker stopped; clean completed worktree and branch removed; external receipts retained |
| Issue 4: spatial movement and targeting | `a4819af`, `9a73716`, `25fcf65`, `afdffe6`, `1ea25d7`, `0ee404e` | Standards and Spec reviewers passed round 2 and final receipt inspection, no unresolved findings | `ba31af7`, `73244bd`, `20a5d3b`, `faa20fc`, `8689d39`, `99d2842` | Tracked spatial receipt: 15 native checkpoints matched baseline facts with strict current physical checks; six co-op states passed closed authority/spatial projection and raw controls; fresh co-op suite, nine capability pairs, two kernel laws, two semantic mutants and comparator controls passed. Integration verified changed tooling/JSON syntax, all recorded external artifact hashes, dependency audit (206 modules), and whitespace | Worker stopped; clean completed worktree and branch removed; external captures retained |
| Issue 9 supporting slice: canonical transport framing only | `c3813f8` | Standards and Spec reviewers passed round 1 with no unresolved findings; coordinator verified actual browser producers and valid-syntax fallback controls | `ae00453` | Tracked transport receipt: two kernel proofs, 45 typed semantic mutants, 152 codec checks and three actual browser producers passed. Integration verified 14 artifact hashes, changed JavaScript/JSON syntax, dependency audit (206 modules), and whitespace | Clean stopped supporting worker worktree and branch removed; external transport artifacts retained |

Issue 2's baseline remains at
`/tmp/bendvy-survivors-ecs-baseline-01b4164`. The integration check initially
reported unavailable proof imports because this new worktree's existing
`vendor/bendlib` submodule had not been initialized. Initializing the already
pinned submodule at `a51756c3f84571868ad68c191a16046dbe53559c` resolved the
environment gap; the dependency audit then passed for 196 Bend modules. No
package pin or authored dependency was changed.

Issue 3 native evidence is retained at
`/tmp/survivors-issue3/native-replay-verification.json`, identifying worker source
`104e044f12d39b1905433ab61c06901b302a7bb0` and source fingerprint
`721e52ffe58e6cfd10b7ab5e1b5bd728c643f9c4a9586946912bf5add92ce70a`.
The receipt excludes only outer timing from comparison; no schema-migration
projection was used for this unchanged-schema prefactoring step. Heavy suites
were not redundantly repeated during integration.

Issue 8 evidence is tracked in `survivors-player-authority-receipt.json` and
explained in `survivors-player-authority.md`. A later optional test-only worker
commit, `42f72b5`, was explicitly excluded: the worker reported an incorrect
revival assertion in that unapproved follow-up. Only the three reviewed commits
authorized by the coordinator were integrated. The failed optional experiment
does not replace or qualify the recorded passing production checks.

Issue 4 evidence is tracked in `survivors-spatial-receipt.json` and explained in
`survivors-spatial-migration.md`; preserved captures are under
`/tmp/survivors-issue4/qualified`. The receipt identifies frozen gameplay source
`1ea25d7790e695759ea26f51afd71a5a17f2abf6`, its authored-source fingerprint and
the explicit cross-schema projection. Ordinary current-schema replay remains
strict. Integration did not repeat the already qualified heavy builds/suites.

The issue 9 supporting slice is limited to canonical command framing and
compressed snapshots with a separately routed plaintext connection handshake.
Its receipt is `survivors-transport-cleanup-receipt.json`, and artifacts remain
at `/tmp/survivors-compat-cleanup`. It does not complete issue 9 or qualify the
unintegrated entity migration, real-network behavior, native gameplay or speed.

## Completion status

Implementation and qualification are pending. This record alone does not prove
completion of any gameplay migration or performance requirement.

**Issue 8 completion correction:** the coordinator reopened issue 8 after a
broader audit exposed stale player/session consumers in the actual
`offline-coop-batch` and `offline-coop-metrics-check` entry points. Their old
Run/projection/player-lookup assumptions fail typechecking against the current
Session authority. The prior passing evidence remains valid for its stated
scope, but did not establish complete consumer migration. The 18-entrypoint
audit recorded 16 passes and these two failures at
`/tmp/survivors-entrypoint-audit/receipt.json`; the independent initial gap check
is `/tmp/survivors-offline-coop-gap-check.log`. The issue 7 worker owns the
remaining consumer fixes as part of the combined entity group. Actual
entrypoint typechecks and runs are required before issue 8 can close again.

## Planned atomic integration exception: issues 5, 6 and 7

The coordinator authorized a combined integration group for enemy, projectile
and pickup migration. The concrete inseparable boundaries are the shared
snapshot/entity-row sum and enemy-slot occupied-loot dispatch. Making the enemy
slice independently green would require throwaway legacy loot/Body adapters,
contrary to the intended cleanup.

Each worker continues in an isolated worktree and receives independent review.
After those reviews, the integration agent will create a temporary candidate
worktree from the canonical integration branch (architecture base `c089346`),
assemble the group, and resolve shared header/storage-arity conflicts. Combined
green checks and review, bounded to three rounds, precede canonical integration.
No partial worker or candidate cleanup occurs before the verified group reaches
the canonical integration branch. Issues 5, 6 and 7 remain incomplete until the
combined evidence exists. Issue 9 residual cleanup and issue 10 full functional
and bounded performance qualification remain unchanged.

Current worker ownership: `typed_results` owns issue 5 enemy migration;
`baseline` owns issue 6 projectile migration; `player_authority` owns issue 7
pickup migration. No group code has been integrated at the time of this entry.

## Entity-group candidate assembly

The isolated candidate branch `refactor/survivors-ecs-candidate` was created
from canonical integration `3e9b781`. It contains the frozen advanced worker
ledger ending at `3ade6da6db198903fbb1c30eff7685fcc24fa27a`, followed by the
reviewed pickup/offline caller correction `0471ae6`. The 87 original-to-candidate
commit mappings are in `survivors-entity-candidate-commits.json`. The assembled
code tip before this record was `b2d7f4c5c53a993f255f1646932f4f4c1776ea31`.

Patch-aware selection preserved the already integrated transport prefix.
Only two cherry-pick conflicts occurred: both were co-op check module lists,
resolved by retaining the union of transport, enemy and pickup checks. Browser
command framing and the control-frame route remained canonical; typed guest
presentation and explicit audio subjects are also present. The audio change is
already included through worker commit `35475d7`, equivalent to reviewed
supporting commit `dfc80d3`; it was not applied twice.

Candidate quick checks passed: all 18 actual Bend entry points typechecked,
including both formerly stale offline co-op consumers; changed JavaScript,
Python, JSON and shell syntax checks; the dependency audit (228 Bend modules);
whitespace; actor-consumer fixtures; ten strict replay tests; five co-op world
qualification tests; and ten enemy/projectile/pickup qualification tests.
Entrypoint evidence is `/tmp/survivors-candidate-entrypoint-audit/receipt.json`.
The authored-source manifest at `/tmp/survivors-candidate-source-manifest.json`
covers 376 example, bot-tool and pinned proof-library sources; its canonical
JSON digest is `3876f7e445f046d221c2bedf2c4f4103cce3c6483331f287dc0473a725812ca6`.

This assembly has not yet received final combined review or fresh combined
runtime qualification. Canonical integration remains unchanged at `3e9b781`;
no worker cleanup or issue completion follows from quick checks alone.

## Integration with the updated master

The user requested absorbing updated `master` after the preserved ECS worktree
was restored. The new integration worktree is
`/workspace/formal-proofs/bendvy-survivors-current-integration`, on
`refactor/survivors-ecs-current-integration`, based on master
`32f07f8daa1f821f5db67af2b71356ab25aa5446`. The ECS side is reviewed source
`f61a300c637f698689b83a94d14bdf38790e187c`, including the corrected production
death-reward geometry fixture. Interrupted earlier qualification receipts remain
incomplete and do not qualify this combined source.

The merge preserves the reviewed ECS history and the updated master's
TypeScript sources, trusted observation adapters, UI changes and native test
cache. Four isolated worker tracks own Bend Data and observation APIs, generated
host contracts, browser presentation, and bot consumers and runtime fixtures.
The concrete atomic boundary is the shared Bend Data graph and host Frame type.
All consumers must migrate together. No legacy actor adapter is introduced to
make partial branches compile.

The integration agent owns the build and check script union. Co-op checks retain
the master's TypeScript fixtures and observation boundary checks, plus ECS
effect, lifecycle, payload, ownership and production birth-wiring controls.
Ordinary checks preserve the master's UI-art checks and cached native test
behavior. The full semantic mutant gate remains an explicit manual gate as on
master and must run during final qualification. A standalone native game build
remains separate from the cached functional checks.

Authored JavaScript from the ECS side is removed only after the assigned worker
has migrated its behavior and checks into TypeScript. Generated JavaScript in
ignored output directories remains a build artifact. The package pin is
unchanged. The merge is not complete or qualified until reviewed worker changes
are assembled and the combined checks pass.

The first approved snapshots applied to this pending merge are Bend worker
`20f6fd7284dcf897c818a8a65170d20b2aff8614` and typed-bridge worker `e30c736`.
Both received Standards and Spec approval with no findings. The bridge worker's
local prerequisite `9001d55` is equivalent to the reviewed Bend snapshot and was
not applied as a second implementation. The integrator restored all 228 Bend
files from the approved Bend tree and the bridge worker's ten owned files.
The retired `spawn-lifecycle.bend` remains deleted. Master versions of
`native_art.bend`, `native_survivors.bend` and `pools.bend` remain byte-identical.

After initializing locked development dependencies, host declarations, codecs
and observation schemas generated successfully. Game and co-op core frontend
checks and the dependency audit passed. These targeted checks do not establish
whole-host typechecking while presentation and bot consumers are still pending.

The remaining reviewed snapshots are presentation worker `3d4cd6a` with 14 owned
files and bot/fixture worker `fe68a60`, capture conversion `cb48851`, and planner
correction `f8007d4` with 27 distinct owned paths. Both review axes approved all
four tracks. The planner's relic objective finding was fixed and passed the
second Spec review. Worker-local prerequisite copies were not restored over
other workers' files.

All 35 authored JavaScript paths introduced by the ECS side were removed after
verifying their TypeScript replacements. The ordinary suite now runs the real
actor-consumer and relic-planner regression tests against a freshly emitted
BotActions module. Co-op checks also run the actual typed audio producer.
The Python birth-wiring control launches its TypeScript fixture while retaining
generated pristine and mutant JavaScript modules and the named failure checks.

Combined targeted checks passed before the merge freeze. They include the full
TypeScript quality command with strict host and browser typechecks, lint,
formatting, 16 boundary tests and four ABI tests, all 18 Bend entrypoint frontend
checks, the dependency audit for 228 modules, changed tooling syntax and
whitespace. No package or BendHub pin changed. Full runtime and performance
qualification remains pending for this combined source.

## Qualified runtime and final browser delivery

The qualified native/Bend source is `c9c9ae866b161aab3627cf15c048d12813d8ced5`. Final browser delivery is
`15b52cd4aa9c29449f93008e1529b756b1dcdd75`, including local master `6ce61ea940d6a4d0f78290a07affe6b1825d0070`. UI source is `0caf4861125111d24d5e311f5653737c49ccf978`. Its master merge changes three UI files and adds the
reward-touch test. All 234 Bend files and 669 prior files remain identical to c9.
The final five-file verifier change corrects only the coordinate clock and keeps
the ordinary lifetime regression wired into the maintained test gate. Its
675-file source manifest digest is
`15b7a0acd2837be921a65a7cd6e62c2fe595cd85b0c74ba4d1c12703fd8bb1cb`.

C9 passed 15 no-Node native checkpoints, six complete co-op worlds, all 18
entrypoint checks and the explicit complete manual game at tick 36,786. Final
delivery TypeScript checks and the real-browser secondary reward-touch test
passed. Solo/UI smoke passed directly on UI source `0caf486`, which is byte-identical in the final delivery. The complete stock Iroh matrix passed directly on verifier source `15b52cd`.

The original no-slowdown requirement failed. Three alternating pairs per
scenario showed an inconclusive 6.32% normal paired-median increase and a
confirmed 8.65% terminal increase. The user's direct instruction accepted this
tradeoff and ended further optimization without a strong short lead. The
original criterion remains failed; the current approved outcome is accepted.

The evidence commit `5d0ad0f` changed only documentation and compact receipts
after the qualified browser source. It did not change the qualified runtime or UI.
Parent issue 1 stays open and unmodified. No release is packaged or deployed.

## Verification diagnostics follow-up

Reviewed diagnostics source `3e3fdcd` preserves command, working directory, exit
status, signal, configured limits and captured output across verification
runners. Controlled faults cover timeout, cancellation, spawn failure and
semantic refusal separately. All six direct diagnostic CI commands, the full
TypeScript gate, generated declarations and the dependency audit passed locally.
The initial TypeScript attempt lacked isolated Astro/Effect dependencies; its
failure and the successful dependency-prepared retry remain in
`/tmp/survivors-combined-verification-diagnostics-3e3fdcd/receipt.json`.

All 234 Bend files and browser UI/schema/protocol sources remain unchanged.
The original CI failure's child status and signal were not recorded, so its
cause is unknown. The unchanged `5d0ad0f` retry passed the entire job in 8m41s.
A controlled SIGKILL reproduction established the logging defect, not the cause
of that historical failure. CI for the new diagnostics head remains pending.

Completion evidence was published at `5d0ad0f`, and children 5–10 are closed.
The original performance criterion and the user's accepted alternative remain
unchanged. Parent issue 1 remains open and unmodified; no release was made.
