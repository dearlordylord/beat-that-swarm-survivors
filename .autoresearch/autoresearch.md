# Autoresearch: Survivors headless lifecycle optimization

## Objective
Reduce fixed ten-seed headless runtime while preserving full frame traces and game mechanics; overall deadline 2026-10-23T00:11:00Z accepted by user

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
