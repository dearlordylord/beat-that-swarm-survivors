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

## Completion status

Implementation and qualification are pending. This record alone does not prove
completion of any gameplay migration or performance requirement.

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
