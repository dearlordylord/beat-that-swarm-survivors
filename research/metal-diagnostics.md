# Bounded Metal diagnostics

The full game timed out during Metal compilation after 1200 seconds on Apple M2 Max, macOS 27.0, Apple clang 21 and Bend 2.0.38. No GPU execution or speedup has been established. Retain the original report; do not increase that timeout.

From the `bendvy-ecs-examples` root on the Mac:

```sh
bash tools/survivors-bot/metal-diagnose.sh
```

Requires Python 3, Bend 2.0.38 and Apple clang. Python supervises compilation and validates results; the computations execute native Bend/C. Each invocation rebuilds from source. Send the final output including the `Report:` path; logs remain on the shared filesystem.

## What it tests

1. Eight independent arithmetic tasks, using a marked `solve!` GPU boundary.
2. Eight tasks using private raw columns from published `bendvy-ecs-core@0.1.0.1`, checking reads, swaps and final values. This is component storage, not a full ECS World or game simulation.

Each control first compiles natively and checks CPU output against an independent Python formula. Only then does it compile Metal and force GPU execution. CPU and GPU must emit the same strict five-field JSON and both match the oracle. The seed and iteration count are explicit; arithmetic wraps modulo 2^32. For n iterations and seed s, the checksum is `(8*n*s + 28*n + 4*n*(n+1)) % 2**32`; default n=128, s=100 gives 172032.

Limits per control: C emission 60 seconds, native compilation 120 seconds, Metal compilation 90 seconds, execution 30 seconds. The complete command is capped at 600 seconds and stops at the first failure. A Metal timeout retains the CPU result, artifact hashes, logs and a bounded process snapshot. Cleanup targets owned process groups, not the system Metal compiler service. `--metal-build-seconds` and `--total-seconds` may lower the caps, not raise them.

The report records source/tool/artifact hashes, C sizes, function counts, stage durations, static dispatch checks and exact outputs. `COMPLETE_SMALL_PROBES` qualifies only these controls; it is not a full-game performance result or GPU utilization measurement.

## Local evidence and interpretation

Bend 2.0.38 generated 120,713 bytes of C with 37 function IDs for arithmetic and 259,112 bytes with 49 IDs for columns, versus 5,333,935 bytes for the full game. Both passed the fixed two-argument dispatch contract. Twelve CPU/oracle cases passed, including U32 wraparound, zero checksum and 4096 iterations. Finite arithmetic proof fixtures passed kernel checking. Four simulated supervisor tests passed, including timeout preservation and rejection of equal but incorrect CPU/GPU results. Independent source and launch review passed. The subsequent Mac run passed both controls; see the host results below.

If arithmetic fails, inspect the minimal runtime/Metal failure first. If only columns fail, investigate storage-generated code. Both now pass; the [next full-game candidate](metal-game-boundary.md) removes reachable frame and summary formatting. These controls narrow the problem but do not establish compiler-time attribution.

## M2 Max host results (2026-10-23)

Run `run-20261023T162720Z-11890` completed both controls on Bend 2.0.38 / Apple clang 21 / macOS 27.0 in 10.953 seconds total. Both forced-GPU outputs exactly matched CPU and the independent oracle (172032).

| Control | Metal compilation | CPU process | GPU process |
| --- | ---: | ---: | ---: |
| Arithmetic | 0.391 s | 0.184 s | 1.856 s |
| Published Hub columns | 3.135 s | 0.130 s | 1.551 s |

These are single process wall times including startup, not repeated steady-state kernel benchmarks. GPU was slower on these tiny workloads; no game speedup follows. The runner reports 39 and 51 FID definitions respectively (the earlier manual counts were 37 and 49); generated C byte sizes match the local controls.

The basic Metal path and these raw column operations work on this host. The full-game compilation failure therefore needs investigation in the larger generated program; size alone is not established as the cause. The [current candidate](metal-game-boundary.md) moves reachable frame/result formatting outside the game GPU boundary and measures C reduction and CPU parity before a bounded host build. Full-game GPU correctness and performance remain unqualified. The original report is preserved under `../bend-games/research/metal-diagnostics-20261023/host-small-probes-pass.json`.
