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

## Completion status

Implementation and qualification are pending. This record alone does not prove
completion of any gameplay migration or performance requirement.
