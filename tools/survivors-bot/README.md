# Bend bots

The bot policy lives in [offline-policy.bend](../../examples/survivors/offline-policy.bend).
The native window and headless runners call that same Bend implementation.
Movement, XP planning, memory and upgrade selection stay in the native process.
There is no Node/Python bot controller, observation file or JSON command bridge.

Run these commands from the repository root. Native builds require Bend and the
[pinned LLVM Clang toolchain](../../toolchains/README.md).

## Watch a bot

```sh
bash tools/survivors-bot/visible.sh --profile fresh --seed 12345
bash tools/survivors-bot/visible.sh --profile advanced --seed 12345 --ticks 1800
bash tools/survivors-bot/visible.sh --unlimited --profile advanced --ticks 1800
```

The launcher rebuilds the current Bend sources before opening the native window.
Close the window or press Escape to stop. `--ticks` bounds game time; `--seconds`
bounds wall time. Zero means no bound. `--build-only` compiles without opening a
window. `--no-build` deliberately reuses the existing binary.

By default, the window runs at realtime pace. `--unlimited` removes the wait
between simulation steps and can take multiple steps between rendered frames.
Simulation yields to rendering and input after an eight millisecond work slice,
or after its current step finishes if that step takes longer. Display refresh
and rendering still cost time, so this mode is not a headless benchmark.
`NIGHTFALL_BOT_PACING=unlimited` selects the same mode through the environment.

## Headless simulations

```sh
bash tools/survivors-bot/native-batch.sh --count 10 --ticks 1800 --profile both --workers 2
bash tools/survivors-bot/native-batch.sh --count 10 --ticks 1800 --profile both --execution bend --threads 2
```

Each world runs the game and bot natively without rendering or a realtime delay.
Process execution distributes independent worlds across `--workers`. Bend
execution uses its runtime thread pool inside one process. Both write run receipts
and summary JSONL under `examples/survivors/dist/native-batches/`. Output is a
report, not a transport used to make decisions. No 100× speed claim is established.

`balance-report.py` is an offline report analyzer, not a game runner. Strict audit
comparison work continues separately in GitHub issue #11.

## Archived decision journals

```sh
npm run journal -- --receipt /absolute/path/to/archived-run.jsonl --host 0.0.0.0
```

The optional Node journal server is a read-only viewer for older decision logs.
The native bot does not feed that old journal protocol. The viewer never sends
commands to the game. Classifier-backed Node controllers and their dependencies
have been removed.
