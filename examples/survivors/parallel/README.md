# Pure native job scheduler

`scheduler.bend` separates detached job indices/results from each job's affine game world. A caller supplies a named closed pure function plus a runtime Data context:

```bend
map_parallel(~JobContext,~Finished,~run_job,context,build(count,index,stride))
```

`run_job(context,index)` owns its own simulation. The scheduler shares only Data, never a World. `map_parallel` explicitly forks both branches; `map_serial` is the reference with the same result shape. `to_list` returns left-before-right order. `build` preserves `index + offset * stride` with U32 wrap, balancing admitted counts up to 10000 with 14 split levels. Its defensive fallback retains remaining indices serially if used outside that bound; callers must still enforce their count/resource limits.

The generic law proves parallel-map and serial-map result trees equal for every finite plan, Data context/result type, and closed pure job function. This is scheduler semantics, not universal game equivalence or a runtime speed theorem. Four finite kernel-checked build fixtures cover empty, singleton, odd count/nonzero stride and U32 wrap. They do not establish a universal builder index law.

Validation on installed Bend 2.0.37:

```
bend examples/survivors/parallel/PROOF.bend --check-only
bend examples/survivors/parallel/PROOF.bend --verdict
```

Both passed during implementation; the kernel check completed in under one second. Actual gameplay semantic comparisons, native fork/thread execution and throughput measurements are separate caller-level checks. The scheduler itself imports only Base; the survivors example still consumes the published BendHub ECS through its game.
