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

## Completion status

Implementation and qualification are pending. This record alone does not prove
completion of any gameplay migration or performance requirement.
