# Bendvy ECS examples

Playable examples of [Bendvy](https://github.com/dearlordylord/bendvy), consuming its published **BendHub distribution**. This repository contains application code and game-design research; Bendvy itself is fetched by the Bend compiler.

## Survivors example

An ECS example using Bendvy to model a survivors simulation.
[Browser demo](https://nightfall-survivors-bendvy.leafyyew32.chatgpt.site) · [Source and usage](examples/survivors/README.md)

Install **Bend 2.0.38** and a native C compiler. On macOS, install Apple's Command Line Tools with `xcode-select --install`, then:

```sh
git clone https://github.com/dearlordylord/bendvy-ecs-examples.git
cd bendvy-ecs-examples
./examples/survivors/run.command
```

New enemies, including scheduled bosses and the Reaper, spawn beyond the supported camera views with their complete visual footprint offscreen. A checked [Bend admission policy](examples/survivors/spawn-policy/LAWS.bend) guards spawning, and living enemies display proportional HP bars in both renderers.

The launcher builds your current local sources and opens a native window. It needs neither Node.js nor a browser. Update the checkout with `git pull` to receive new source versions. See the [game guide](examples/survivors/README.md) for controls, save locations, optional browser mode and checks.

## Native-step measurements

The [native replay report](research/native-step-results.md) documents the qualified argument-transport change, exact-state checks, rejected candidates and finite workload limits. Native bots and gameplay execute compiled Bend/C; Node is used only for development and optional browser tooling.

## BendHub dependency

Application imports use the published package directly:

```bend
import bendvy-ecs-core@0.1.0.1/world.bend as W
import bendvy-ecs-core@0.1.0.1/compose.bend as Q
```

The compiler downloads the public package on first use and validates its content. No Bendvy checkout, copied ECS tree or local path alias is required. [bendhub-dependencies.json](bendhub-dependencies.json) records the audited package version, content hash and manifest hash; it is repository metadata, not a compiler-native lockfile.

```sh
python3 scripts/check-dependencies.py --registry
```

This audits all example imports and verifies the public registry binding. Every new example follows the same distribution rule. Dependency upgrades change both the imports and the recorded pin, followed by functional checks.

## Development checks

Node.js 20+ is used only for development checks and the optional browser frontend. Native Linux builds additionally need Clang, X11 development headers and ALSA development headers. Clang 19 is the qualified Linux compiler; use `CC=clang-19` where necessary.

```sh
python3 scripts/check-dependencies.py --registry
bash examples/survivors/build.sh
bash examples/survivors/check.sh
bash examples/survivors/check-native.sh
```

The longer native controller is separate:

```sh
bash examples/survivors/check-native-full.sh
```

[Validation](examples/survivors/VALIDATION.md) distinguishes executed checks from historical results and platform limitations. [Balance notes](examples/survivors/BALANCE.md) describe the current pacing work; authored difficulty values are not proof of fun or parity with another game.

## Research

[Game-selection research](research/ecs-game-selection/README.md) contains ten initial hypotheses and independent follow-up audits. [The synthesis](research/ecs-game-selection/REPORT.md) compares candidate games and the ECS interactions each could demonstrate. It is a historical investigation, not a benchmark or the current implementation specification.

[Classifier-assisted bot research](research/jev-bot-classifier.md) traces the Jev API and the control design. The [optional classifier bot](tools/survivors-bot/README.md) now classifies real upgrade offers and engine-generated movement goals, using Bend-derived mechanical context. Its separate Node 24 tool has offline checks and a bounded live integration observation; it does not establish improved gameplay decisions or add dependencies to native launch.

## License

Application source is available under **MIT OR Apache-2.0**; see [LICENSE-MIT](LICENSE-MIT) and [LICENSE-APACHE](LICENSE-APACHE). Original content and procedural graphics accompany the examples. Game titles mentioned in research identify their respective games; no assets from those games are included.

Native bot batches can also use Bend's explicit fork-join scheduler inside one process:

```sh
bash tools/survivors-bot/native-batch.sh --execution bend --count 100 --ticks 1800 --threads 8
```

The default process mode remains available. See [batch options and timing semantics](tools/survivors-bot/README.md#native-offline-batches) and the [parallelism experiment](research/bend-parallel-bots.md).

The small arithmetic and published-column Metal controls pass on M2 Max. The [full-game-code Metal experiment](research/metal-game-boundary.md#completed-paired-m2-max-experiment) now builds within 120 seconds using optional generated-runtime segment functions and seven noinline helpers. Two five-tick worlds match CPU summaries across three paired repetitions, but GPU is about 561 times slower on that tiny workload. Complete-run GPU correctness and useful acceleration remain unqualified.

For ordinary gameplay, run `./examples/survivors/run.command` from this repository root. It rebuilds the current sources and opens the native CPU game. Metal tools are research-only; use CPU for practical bot runs.
