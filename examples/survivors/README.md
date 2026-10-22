# Nightfall Survivors

An original single-player survivors game built on the published BendHub distribution of Bendvy. Follow the [repository setup and dependency instructions](../../README.md) before launching; no local Bendvy checkout is required. The native version uses Bend for the simulation, drawing, input, menus, sound and profile storage. Bend's window/audio runtime talks to the operating system. No browser or Node.js is needed to play the native version.

On macOS (including Apple Silicon), install Bend and Apple's Command Line Tools (`xcode-select --install`), then launch from your checkout:

```sh
./examples/survivors/run.command
```

You can also double-click `run.command` in Finder. Each launch compiles the current local Bend sources and runs `dist/nightfall` in its own window. There is no npm install. The launcher does not download Git updates: update your checkout normally to receive remote changes. A failed compilation preserves the previous binary. `--build-only` builds without opening a window. The launcher finds Bend in `~/.bend/bin`, `~/.local/bin` and Homebrew paths; `BEND=/absolute/path/to/bend` overrides the compiler.

Native profiles live in `~/Library/Application Support/Nightfall Survivors/nightfall-profile.txt` on macOS, or `${XDG_DATA_HOME:-~/.local/share}/nightfall-survivors/nightfall-profile.txt` on Linux. Set `NIGHTFALL_DATA_DIR` to override the directory. The native profile is separate from the browser's localStorage; it does not automatically import browser progress. When running the binary directly, its working directory determines the profile location.

At camp, use arrows to select, Left/Right to change category, Enter to equip or buy, and Space to start. M opens permanent upgrades; C opens the collection, recipes and unlock requirements. During a run, use WASD or arrow keys to move; attacks are automatic. Esc pauses and V toggles sound. Earned upgrades wait while combat continues: press E to open the reward panel, then 1/2/3 to choose. Opening the panel pauses the arena; Esc closes it and resumes combat without discarding the pending reward. R rerolls, K skips and B banishes while the reward panel is open. From pause, Q returns to camp and banks collected gold once. Blue experience shards remain on the ground until physically collected; chests must also be picked up. Choose upgrades, combine a level VIII weapon with its matching relic, and collect boss chests to evolve it.

The first level requires 100 XP; subsequent thresholds grow as `100 + 3 * L + L * L / 3` using the previous level L. This makes progression slower; pending rewards queue instead of repeatedly interrupting movement. The collection explains all 24 weapons, 24 evolutions, six weapon unions and 18 passive upgrades. Eight heroes have different starting weapons; twelve Arcana reshape builds. Five arenas have distinct encounters, hazards and a recoverable artifact that opens a weapon. Characters, arenas, weapons and modes open through survival, kills, discoveries, bosses and victories. Legacy gold purchases permanent upgrades. Native progress is saved to disk between runs.

Standard and Inverse reach dawn after ten simulated minutes, then a lethal Reaper pursues you. Surviving until dawn earns completion credit when the run ends. Endless continues without the Reaper. The separate five-minute Trial accelerates waves and disables permanent upgrades. Both deaths and victories earn gold; ending a run from the pause screen keeps the gold already collected.

## Browser version

The earlier browser frontend remains available for comparison and automated simulation checks:

```sh
bash examples/survivors/build.sh
node examples/survivors/launch.mjs
```

This path requires Node.js 20+ and opens http://127.0.0.1:8713. The portable `run.command` now starts the native version.

## Checks

Qualification scripts require Node.js 20+, Bend, a C compiler and the platform audio/window development libraries. They use portable Node timeouts; Linux uses flock when available and other hosts use a temporary lock directory. Remove a stale lock directory only after confirming no checks are running:

```sh
bash examples/survivors/check-native.sh
bash examples/survivors/check-native-full.sh
```

An optional one-minute fresh-profile kiting observation reports survival, damage, progression and enemy density without requiring survival as a pass condition:

```sh
bash examples/survivors/check-native-pacing.sh
```

This diagnostic initializes the fresh native UI loadout and uses input-only control. Its outcome is a scenario observation, not a full-run balance qualification or frame-rate measurement.

`check-native.sh` checks the launcher, native profile, real UI event flow and exact Bend-rendered frame captures, then compiles the windowed application. `check-native-full.sh` drives a full native run using public gameplay inputs. Native `run.command` does not require Node.js or the test helpers. The native application was qualified with Clang 19.1.7 on Linux arm64; set `CC` to select your compiler. macOS compilation uses the local Apple toolchain.

An optional actual-window diagnostic also uses Xvfb and xdotool. With those installed system-wide on Linux, build the native executable first, then run:

```sh
NIGHTFALL_X11_SYSROOT=/ bash examples/survivors/native-window-smoke.sh
```

`NIGHTFALL_X11_SYSROOT`, `XVFB`, `XDOTOOL` and `NIGHTFALL_BINARY` can point at an isolated development fixture. This diagnostic does not install packages.

The optional emitted-backend regression suite:

```sh
bash examples/survivors/build.sh
bash examples/survivors/check.sh
bash examples/survivors/check-full.sh
```

The ordinary suite checks catalogs, purchases, corrupted-save recovery, actual projectile trajectories, evolution/union recipes, healing and pierce regressions, public commands, all five artifact pickups, unlock persistence and a fresh-profile defeat. The longer full-run controller uses maximum purchased upgrades and Arcana 9, chooses through the public API and checks a genuine ten-minute completion with a boss, chest and evolution. The current native witness reached dawn at level 41 and died to the Reaper at tick 36,713 (about 10:11.88), with 42 upgrade/reward decisions. This validates one advanced purchased build on the slower-XP, larger-horde revision, not fresh-profile win rates or every build. Historical complete-run results remain separately labeled. See [VALIDATION.md](VALIDATION.md) for checks actually executed against the current sources.

Browser checks reuse an already installed Playwright; they never install packages:

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs bash examples/survivors/check-browser.sh
```

They verify desktop keyboard and mobile touch movement, modal focus, pause, collection navigation and profile reload. Generated ESM stays in ignored `dist/`.

## Bend and ECS

`game.bend` owns the affine world and orchestrates four real queries: projectile updates write geometry and motion; enemy movement writes geometry and reads motion; combat reads geometry and writes health/status; lifecycle applies entity transitions to geometry. A fixed pool contains 1004 entities: 512 enemy/relic slots, 192 player projectile slots, 32 hostile projectile slots, 12 independent world actors and 256 persistent XP piles. XP leaves enemy slots immediately. When the XP pool fills, new XP merges into the nearest existing pile without automatic credit; that pile stays at its original position. Capacity is not a measured frame-rate result: an injected-clock regression admits 511 simultaneous enemies, while actual complete-run density and performance require separate validation. Eight rescue wisps react to nearby enemies and seek the central refuge after activation; four ward sentinels have their own health, activation state and attack cooldown. Their local pulses damage and slow enemies through the same combat pipeline. Dead actors remain inactive and rescue rewards occur once. `projectile.bend` and `encounters.bend` define weapon motion, enemy roles, bosses and arena hazards. The native frontend consumes typed Bend state directly; the optional JavaScript frontend does not calculate combat outcomes. Actor state currently reuses Body, Vitals and Motion; it does not introduce a separate ActorState component. See [BALANCE.md](BALANCE.md) for the current difficulty pass and its validation limits.

The game requirements are in [GAME_SPEC.md](GAME_SPEC.md), and the original-game feature benchmark is in [REFERENCE_SCOPE.md](REFERENCE_SCOPE.md). Catalog totals alone do not establish equivalent richness. No formal proof of the entire game or GPU/parallel-runtime performance qualification is claimed.
