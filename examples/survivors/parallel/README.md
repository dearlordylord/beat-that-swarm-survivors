# Pure native job scheduler

`scheduler.bend` separates detached job indices/results from each job's affine game world. A caller supplies a named closed pure function plus a runtime Data context:

```bend
map_parallel(~JobContext,~Finished,~run_job,context,build(count,index,stride))
```

The caller owns each simulation independently. [scheduler.bend](scheduler.bend)
shares detached Data between jobs rather than sharing an affine World. Its
implementation defines index arithmetic, plan ordering, admitted bounds and
fallback behavior; callers remain responsible for their resource limits.

The generic law proves parallel-map and serial-map result trees equal for every finite plan, Data context/result type, and closed pure job function. This is scheduler semantics, not universal game equivalence or a runtime speed theorem. Four finite kernel-checked build fixtures cover empty, singleton, odd count/nonzero stride and U32 wrap. They do not establish a universal builder index law.

Validation on installed Bend 2.0.37:

```
bend examples/survivors/parallel/PROOF.bend --check-only
bend examples/survivors/parallel/PROOF.bend --verdict
```

Both passed during implementation; the kernel check completed in under one second. Actual gameplay semantic comparisons, native fork/thread execution and throughput measurements are separate caller-level checks. The scheduler itself imports only Base; the survivors example still consumes the published BendHub ECS through its game.
