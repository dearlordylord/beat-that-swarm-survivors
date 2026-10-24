# Survivors example

A Vampire Survivors clone built as a Bendvy ECS example. See [setup](../../README.md), [requirements](GAME_SPEC.md) and [reference scope](REFERENCE_SCOPE.md).

## ECS

`game.bend` owns the affine world and runs queries with declared component access: projectile updates write geometry and motion; enemy movement writes geometry and reads motion; combat reads geometry and writes health/status; lifecycle applies entity transitions. `projectile.bend` and `encounters.bend` implement weapon motion, enemies and hazards.

The pool layout is defined in [`pools.bend`](pools.bend): 512 enemy/relic slots, 512 shared player-projectile slots, 32 hostile-projectile slots and 400 XP piles (1456 entities total). Ordinary enemy admission reaches 300; Curse and run modifiers can raise it to 500. XP leaves enemy slots immediately and requires physical collection. Overflow accumulates in one marked red pile, preserving its identity and position until pickup. Visual size grows with XP up to radius 8 at 100 XP; further XP still accumulates.

Player shots carry their owning weapon and logical spread slot in Motion. A once-per-tick allocator shares free slots across equipped weapons, preserves live shots and applies per-weapon live budgets of 40–70; persistent fields retain their logical-slot limits. Volley amounts and firing cadence are unchanged. See [pool behavior](pools/README.md).

Pool capacity is not a frame-rate result. The example makes no claim of whole-game formal proof or GPU/parallel-runtime performance qualification. See [balance](BALANCE.md), [current pool/frame measurements](../../research/shared-projectile-pool.md) and the verified [offscreen birth invariant](spawn-policy/README.md) for narrower results and limits.

## Native launch

Bend handles simulation, drawing, input, menus, audio and profile storage. Native play requires no Node.js or browser. On macOS, install Bend and Apple's Command Line Tools (`xcode-select --install`), then run from the repository root:

```sh
./examples/survivors/run.command
```

You can also double-click `run.command` in Finder. It compiles local sources and opens `dist/nightfall`; update the checkout to receive changes. Failed compilation preserves the previous binary. Use `--build-only` to compile without launching. The launcher searches `~/.bend/bin`, `~/.local/bin` and Homebrew paths; `BEND=/absolute/path/to/bend` overrides the compiler.

Profiles are stored at `~/Library/Application Support/Nightfall Survivors/nightfall-profile.txt` on macOS or `${XDG_DATA_HOME:-~/.local/share}/nightfall-survivors/nightfall-profile.txt` on Linux. `NIGHTFALL_DATA_DIR` overrides the directory. Direct binary execution uses its working directory. Browser localStorage saves are separate and are not imported automatically.

## Controls

At camp: arrows select, Left/Right change category, Enter equips or buys, Space starts, M opens permanent upgrades, and C opens the collection and recipes. In a run: WASD/arrows move, attacks are automatic, Esc pauses, and V toggles sound. XP and chests require pickup.

M opens the pause map: player, stage relic, chests and the current camera footprint. Esc or M resumes. The arena is 14,400 × 14,400 world units; relics are 3,600 units from the central start. Enemy movement and knockback keep the complete sprite inside the arena.

Rewards pause combat: 1/2/3 choose, R rerolls, K skips, B banishes. Esc defers a reward; E reopens it. Queued rewards open in order. From pause, Q returns to camp and banks collected gold once.

Standard and Inverse reach dawn after ten simulated minutes, then spawn a lethal Reaper; reaching dawn earns completion credit when the run ends. Endless has no Reaper. The five-minute Trial accelerates waves and disables permanent upgrades.

## Browser launch

[Browser demo](https://nightfall-survivors-bendvy.leafyyew32.chatgpt.site). Bend compiles the simulation to JavaScript; Canvas and browser APIs handle presentation, keyboard/touch input and audio.

For local play, with Node.js 20+:

```sh
node examples/survivors/launch.mjs
```

This opens http://127.0.0.1:8713. For static hosting, build from the repository root:

```sh
bash examples/survivors/build-web.sh
python3 -m http.server 8713 --directory examples/survivors/dist/web
```

Deploy the complete `examples/survivors/dist/web` directory. Serve over HTTP; rebuild and redeploy after source changes. The hosted version needs no server-side Bend or Node.js.

## Music

Adaptive chip-metal uses a shared Bend score and danger assessment: nearby enemies, enemy types, hostile shots and player health change the arrangement at bar boundaries. The latest target replaces older observations; changes never queue. Native synthesizes stereo PCM in Bend, while the browser renders those notes through Web Audio. See [music](music/README.md) for timing and validation scope.

## Checks

Checks require Node.js 20+, Bend, a C compiler and platform audio/window development libraries. Linux uses flock when available; other hosts use a temporary lock directory. Remove stale locks only after confirming no checks are running:

```sh
bash examples/survivors/check-native.sh
bash examples/survivors/check-native-draw.sh
bash examples/survivors/check-native-full.sh
bash examples/survivors/check-quiet-boundary.sh
```

An optional one-minute fresh-profile kiting observation reports survival, damage, progression and enemy density without requiring survival as a pass condition:

```sh
bash examples/survivors/check-native-pacing.sh
```

This diagnostic initializes the fresh native UI loadout and uses input-only control. Its outcome is a scenario observation, not a full-run balance qualification or frame-rate measurement.

`check-quiet-boundary.sh` uses the Bend JavaScript backend for a development-only comparison of complete authoritative state across frame-producing and quiet bot initialization, reward choices and natural runs. Native bot execution uses Bend/C.

`check-native-draw.sh` compares every pixel of 29 scenes against an independent display-list oracle, including fractional geometry, sprite layering, fonts and health bars.

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

The ordinary suite covers catalogs, saves, projectiles, recipes, public commands, artifacts and unlocks. The full-run controller checks ten-minute completion, a boss, chest and evolution using maximum purchased upgrades and Arcana 9. This qualifies one advanced build, not fresh-profile win rates or every build. See [VALIDATION.md](VALIDATION.md) for executed checks and witness results.

Browser checks reuse an already installed Playwright; they never install packages:

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs bash examples/survivors/check-browser.sh
```

They verify desktop keyboard and mobile touch movement, modal focus, pause, collection navigation and profile reload. Generated ESM stays in ignored `dist/`.
