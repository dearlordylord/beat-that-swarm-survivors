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

The launcher reuses the native binary when its build inputs are unchanged.
It checks content hashes of Bend sources, compiler tools, Bend runtime and package
cache, dependency pins and SDK identity files. Changed inputs or a changed binary
trigger a rebuild. The first launch after this update rebuilds once to save the
build receipt. Profile, seed, pacing and run limits do not require recompilation.
Close the window or press Escape to stop. `--ticks` bounds game time; `--seconds`
bounds wall time. Zero means no bound. `--build-only` compiles without opening a
window. `--rebuild` forces compilation. `--no-build` deliberately reuses the
existing binary without checking its inputs. Native build receipts remain under
the ignored `dist` directory.

By default, the window runs at realtime pace. `--unlimited` uses a separate
simulation loop that advances continuously and requests a picture approximately
every 100 ms. There is no eight millisecond simulation budget. About 10 FPS is
intentional in this mode; TPS and SPEED show the simulation rate independently.
Presentation and simulation share a thread, so drawing still consumes time.
Close/Escape is handled on presentations. An expensive simulation step can delay
the next presentation. This mode is not a headless benchmark.
`NIGHTFALL_BOT_PACING=unlimited` selects the same mode through the environment.

The bot window displays FPS, actual simulation ticks per wall second (TPS), and
game-time speed relative to 60 ticks per second. Measurements use half-second
wall-clock windows and include simulation, rendering and display waits. The
active `REALTIME` or `UNLIMITED` mode appears beside them. Startup shows dashes
until the first complete measurement window.

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
