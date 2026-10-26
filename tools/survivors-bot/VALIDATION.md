# Bot validation

Current execution uses the Bend policy directly in native window and headless
runners. The old Node planner, classifier controller and file-command bridge have
been removed. Their historical receipts do not validate the current driver.

The native batch launcher's shell contract is checked with:

```sh
bash tools/survivors-bot/native-batch.test.sh
bash tools/survivors-bot/visible.test.sh
```

These checks verify launcher arguments and native process invocation. They do not
prove policy quality, balance, graphical output or performance. Run the native
Bend driver checks and actual short simulations separately when changing policy
or stepping behavior. Use [issue11](issue11/README.md) for exact audit comparisons.

## Bend-only migration checks

The visible, serial and parallel launchers now use `bot-driver.bend`. Co-op uses
the same `offline-policy.bend` with separate memory for each player.

The migration was checked with Bend 2.0.39 and LLVM Clang 19.1.7:

- Native source checks passed for visible, serial, parallel and GPU entrypoints.
  The GPU check was a source check, not a GPU execution.
- Fresh and advanced native X11 windows ran on a virtual display. Fresh reached
  tick 120 and moved from the starting position. Advanced reached tick 600,
  moved and selected one upgrade. A gameplay frame was inspected.
- Four serial native runs, two profiles and seeds 12345 and 982451653, reached
  tick 120. Every summary field except wall time matched the previous driver.
  This comparison does not establish full physical-state equality.
- Serial and parallel native runs matched summary fields for two worlds of
  120 ticks each, excluding wall time.
- Five phase-routing laws passed the proof kernel. Five type-correct routing
  mutants failed their corresponding laws. These laws cover action routing,
  not the full planner or simulation.
- Launcher fixtures and `npm run check:typescript` passed.

Run the routing proof with a bounded checker:

```sh
timeout 60 sh -c 'ulimit -t 10; exec bend examples/survivors/bot-turn-PROOF.bend --verdict'
```

On macOS, use `gtimeout` from coreutils instead of `timeout`. The persistent
mutation cases are in `scripts/law-mutants/bot-turn.json`.

These checks establish the controller migration. They do not establish a speedup
or a 100× simulation rate. The archived journal viewer receives no live feed
from the new native driver.
