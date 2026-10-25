# Autoresearch: Survivors headless lifecycle optimization

## Objective
Reduce fixed ten-seed headless runtime while preserving full frame traces and game mechanics; new prospective confirmation deadline2026-10-23T00:38:25Z explicitly approved by user; preserve all prior segment evidence

## Metrics
- Primary: batch_seconds (s, lower is better)
- Secondary: none yet

## How to Run
`node tools/survivors-bot/autoresearch/benchmark.mjs` prints `METRIC name=value` lines.

## Files in Scope
- examples/survivors/game.bend
- examples/survivors/body-index.bend
- examples/survivors/body-index

## Off Limits
- TBD: add off-limits files or behaviors if needed

## Constraints
- - Decision contract: batch_seconds is the primary metric; secondary evidence explains tradeoffs but should not silently override it.

## Decision Rules
- Keep when the primary metric improves or a baseline is needed and checks pass.
- Discard when the metric is equal or worse, unless the run only establishes the baseline.
- Log crashes and failed checks with a concrete rollback reason.
- Put next-step guidance in ASI so another Codex session can continue.

## Stop Conditions
- Stop when the target metric reaches the agreed threshold.
- For qualitative loops, stop when `quality_gap=0`, checks pass, and no high-impact open finding remains.
- Stop when maxIterations is reached or the user interrupts.

## Research Notes
- Source-backed facts, contradictions, and open questions go here or in linked scratchpad files.
- For deep research loops, link the scratchpad folder and summarize the current synthesis.

## What's Been Tried
- Baseline: pending

## Resume This Session

Read the current decision before resuming:

```bash
node /home/node/.codex/plugins/cache/TheGreenCedar/codex-autoresearch/3.0.0/scripts/autoresearch.mjs state --cwd /workspace/formal-proofs/bendvy-ecs-autoresearch-20261022 --report
```

Follow its next action. A measurement is a keep only after the accepted checks and repeat requirements pass.

## Run Ledger

<!-- AUTORESEARCH_RUN_LEDGER:START -->
- Run 1 measure: Baseline1 unchanged public9309539 gameplay; fixed10fresh seeds, full observation traces and existing regression gates; metric=159.467491; best=unknown.
- Run 2 measure: Baseline2 unchanged source; qualify reference timing noise with independent complete check pass; metric=156.733264; best=unknown.
- Run 3 measure: Index candidate qualification1: one forward-built immutable key index replaces repeated lifecycle list scans; complete trace equivalence passed; metric=139.214132; best=unknown.
- Run 4 discard: Index repeat175.657273 versus139.214132: cohort median fails10percent rule and repeat loses to best reference; correctness passes but no keep; metric=175.657273; best=unknown; commit=102ed51; Git: reverted scoped experiment paths (examples/survivors/game.bend, examples/survivors/body-index.bend, examples/survivors/body-index); autoresearch files preserved. Preserved 2 unowned dirty path(s). cleanup=df5aed6ddc16..
- Run 5 discard: Shot preparation gate191.379671 fails accepted improvement bound; fulltrace correct but no timing keep, no favorable-run selection; metric=191.379671; best=unknown; commit=102ed51; Git: reverted scoped experiment paths (examples/survivors/game.bend, examples/survivors/body-index.bend, examples/survivors/body-index); autoresearch files preserved. Preserved 2 unowned dirty path(s). cleanup=005e6adbcd92..
- Run 6 discard: Write-through lifecycle171.784931 fails10percent bound; protected traces and authoritative1004slot payload oracle pass, no timing keep; metric=171.784931; best=unknown; commit=102ed51; Git: reverted scoped experiment paths (examples/survivors/game.bend, examples/survivors/body-index.bend, examples/survivors/body-index); autoresearch files preserved. Preserved 2 unowned dirty path(s). cleanup=b59b59f8e6c9..
- Run 7 measure: Unchanged baseline diagnostic248.519158 confirms substantial host timing drift; retains all reference samples and original strict keep rule; metric=248.519158; best=unknown.
- Run 8 discard: Opaque Data projection306.047751 fails accepted timing rule despite sourcecheck12342projectioncases and protectedtrace checks; rejected, noallocation-to-speedclaim; metric=306.047751; best=unknown; commit=102ed51; Git: reverted scoped experiment paths (examples/survivors/game.bend, examples/survivors/body-index.bend, examples/survivors/body-index); autoresearch files preserved. Preserved 2 unowned dirty path(s). cleanup=a2c0ba16ded2..
- Run 9 discard: Skip unchanged Vitals/Motion plus write-through169.169215 fails strict10percent/cohort rule; exacttrace and authoritativepayload checks pass; noacceptedkeep; metric=169.169215; best=unknown; commit=102ed51; Git: reverted scoped experiment paths (examples/survivors/game.bend, examples/survivors/body-index.bend, examples/survivors/body-index); autoresearch files preserved. Preserved 2 unowned dirty path(s). cleanup=b59b59f8e6c9..
- Run 10 measure: Combined index plus both shot gates qualification1 118.940018; all protected checks pass; repeat required before keep, no single-run promotion; metric=118.940018; best=unknown.
- Run 11 measure: Combined repeat99.960436 and118.940018 exacttracePASS; human10percent rulepasses but pluginboundednoise91.785894 rejectskeep, retain experimental nonpromotional evidence without source delivery; metric=99.960436; best=unknown.
- Run 12 measure: Prospective R1 unchanged public baseline170.071587, all protected trace/regression checks pass; first of declaredR-C-R-C schedule; metric=170.071587; best=unknown.
- Run 13 measure: Prospective C1 identical combinedcandidate111.948148, allchecksPASS; restoreunchangedreference for declaredR2 beforefinalC2; metric=111.948148; best=unknown.
- Run 14 measure: ProspectiveR2 reference149.552497, allchecksPASS; reference range20.519090 /median159.812042=12.8395percent exceedsuseraccepted10percent driftstop. AbortbeforeC2; noacceptedkeep or codeintegration; metric=149.552497; best=unknown.
<!-- AUTORESEARCH_RUN_LEDGER:END -->
