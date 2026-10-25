# Survivors example

A Vampire Survivors clone built as a Bendvy ECS example. See [setup](../../README.md), [requirements](GAME_SPEC.md) and [reference scope](REFERENCE_SCOPE.md).

## ECS

The schema, affine world ownership and checked system contracts are defined in
[`game.bend`](game.bend). Immutable role definitions belong to
[`entity-role.bend`](entity-role.bend), with [kernel laws](entity-role/LAWS.bend);
query membership has [its own policy](movement-membership.bend) and
[laws](movement-selection/LAWS.bend). Those sources define the implementation;
this guide does not duplicate their component layouts or dispatch rules.

The authoritative pool layout and admission limits are in [`pools.bend`](pools.bend).
Party-size difficulty belongs to [`party-difficulty.bend`](party-difficulty.bend):
ordinary spawn slots scale by living, connected players, up to the existing
500-enemy ceiling. The six-tick refill cadence, enemy stats and boss schedule
are unchanged; losing a player reduces future admission without deleting mobs.
See [pool sources and proof boundaries](pools/README.md) for allocation, pickup
and lifecycle implementation. Weapon behavior belongs to
[`projectile.bend`](projectile.bend), and pickup appearance belongs to
[`loot-visual.bend`](loot-visual.bend).

The example makes no claim of whole-game formal proof or GPU/parallel-runtime
performance qualification. See [measurement evidence](../../research/shared-projectile-pool.md)
and the [offscreen birth invariant](spawn-policy/README.md) for narrower results
and limits.

## Native launch

Bend handles simulation, drawing, input, menus, audio and profile storage. Native play requires no Node.js or browser. On macOS, install Bend and Apple's Command Line Tools (`xcode-select --install`), then run from the repository root:

```sh
./examples/survivors/run.command
```

You can also double-click `run.command` in Finder. It compiles local sources and opens `dist/nightfall`; update the checkout to receive changes. Failed compilation preserves the previous binary. Use `--build-only` to compile without launching. The launcher searches `~/.bend/bin`, `~/.local/bin` and Homebrew paths; `BEND=/absolute/path/to/bend` overrides the compiler.

Profiles are stored at `~/Library/Application Support/Nightfall Survivors/nightfall-profile.txt` on macOS or `${XDG_DATA_HOME:-~/.local/share}/nightfall-survivors/nightfall-profile.txt` on Linux. `NIGHTFALL_DATA_DIR` overrides the directory. Direct binary execution uses its working directory. Browser localStorage saves are separate and are not imported automatically.

## Controls

At camp: arrows select, Left/Right change category, Enter equips or buys, Space starts, M opens permanent upgrades, and C opens the collection and recipes. In a run: WASD/arrows move, attacks are automatic, Esc pauses, and V toggles sound. XP and chests require pickup.

M opens the pause map: player, stage relic, chests and the current camera footprint. Esc or M resumes. Arena bounds are defined in [`arena.bend`](arena.bend), and relic placement in [`game.bend`](game.bend).

Rewards pause combat: 1/2/3 choose, R rerolls, K skips, B banishes. Esc defers a reward; E reopens it. Queued rewards open in order. From pause, Q returns to camp and banks collected gold once.

Run-mode timing and finale rules are defined in [`game.bend`](game.bend); progression awards are defined in [`menu-progression.bend`](menu-progression.bend).

## Browser menu

Astro prerenders every Lunar Stone menu tab into the initial HTML, including the full character and stage catalog. A small synchronous head script selects the requested `?tab=` before first paint, so Co-op links open Collection, Legacy, Achievements or Settings directly without flashing Expedition. Build-time and browser rendering share `menu-content.mjs`. It is readable without JavaScript. A small compiled Bend module owns profile normalization, unlocks, prices, purchases and progression; browser code stores its returned profile and renders its decisions. The simulation, renderer and audio load independently in the background. Start waits for them when necessary.

The Lunar Stone menu uses Moon Seal controls, with Start at the top and in a reserved lower row. Choices scroll in a separate area, so the lower action cannot cover them. Styles load directly from the page; no prototype theme switcher or sample profile is included. Each setup row shows its current icon and name. Opening a category shows all choices; locked survivors/stages display their price and requirements, and only an explicit Buy action spends gold. Progress-only modes keep their existing unlock rules.


The shared browser decoration uses header banners over rectangular panels. CSS fits N full square teeth and N−1 equal gaps into width W: side length `s = W / (2N − 1)`. Container units and `round()` keep s near 8 CSS pixels from the first paint, including after resizing. Browsers without typed length division use stable CSS container breakpoints with odd cell counts. No JavaScript geometry pass or observer is needed, so module loading cannot change the pattern. Only decorative surfaces are masked, preserving control hit areas and focus.

Browser menu portraits and in-run characters share the paths in [`survivor-art.mjs`](survivor-art.mjs). Clothing colours come from the Bend character catalogue; SVG prerendering and Canvas drawing use the same layers in solo and co-op. Canvas paths are cached once.

## Browser launch

[Browser demo](https://survivors.dearlordylord.com). [Two-player co-op](COOP.md) uses the same ECS systems with a browser host and Iroh transport. Bend compiles the simulation to JavaScript; Canvas and browser APIs handle presentation, keyboard/touch input and audio.

For browser builds and local play, use the Node.js version supported by [web/package.json](web/package.json). The co-op transport build also needs Rust 1.94+, its `wasm32-unknown-unknown` target, and `wasm-bindgen-cli` 0.2.122 ([setup](../../tools/iroh-transport/README.md#build)). Players on the hosted site install nothing. Install the pinned Astro build dependencies once:

```sh
npm ci --prefix examples/survivors/web
node examples/survivors/launch.mjs
```

This opens http://127.0.0.1:8713. For static hosting, build from the repository root:

```sh
bash examples/survivors/build-web.sh
python3 -m http.server 8713 --directory examples/survivors/dist/web
```

For the optional actual-Iroh browser check, keep the server running and use a
second terminal with Playwright and Chromium already available:

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs \
COOP_URL=http://127.0.0.1:8713/coop.html \
node tools/survivors-bot/coop-reliability-browser-check.mjs
```

A local build writes `version.json` with the Git revision, dirty state and
`buildContext: "local-development"`; it has no source fingerprint. The
publication preparation step replaces it with the immutable release manifest.

Deploy the complete `examples/survivors/dist/web` directory. Serve over HTTP; rebuild and redeploy after source changes. The hosted version needs no server-side Bend, Astro or Node.js. `index.html` is the source HTML shell; the deployable, prerendered page is `dist/web/index.html`. `content.mjs` is generated from `menu-catalog.bend` at build time; edit the Bend catalog, not the generated file.

## Publication

Use `master` locally and on GitHub. Publication stays on Sites; no GitHub Actions deployment is required.

From the repository root, prepare the next release into the existing Site checkout:

```sh
node scripts/prepare-survivors-site.mjs --site-checkout /absolute/path/to/nightfall-survivors
node scripts/verify-survivors-site.mjs --site-checkout /absolute/path/to/nightfall-survivors
```

Preparation fetches `origin/master`, checks the branch/revision, snapshots the current authored inputs (including unsaved-to-Git files), installs the pinned Astro dependencies in that isolated snapshot and runs the complete Bend + Astro build. It does not reuse the source checkout's `dist` output. `SOURCE.json` records the input and asset hashes; `version.json` identifies the revision, source fingerprint and whether local edits were included. The complete authored snapshot is saved with the Site source. A failed build leaves the previous Site files intact.

Qualification uses Bend laws, semantic mutations and native checks.

Before editing the Site checkout, open it with the Sites source helper. Prepare with the command above, then include the verifier as a required command in the helper's packaging request. Pass `--repo /absolute/path/to/bendvy-ecs-examples` when running verification from the Site checkout. If the source changes after preparation, verification fails: prepare again. Publish only the archive and pushed source commit returned by that helper. The public `/version.json` allows the deployed source fingerprint to be checked after publication.

Do not publish by manually copying an old `dist/web`. This procedure guarantees the prepared artifact matches the checked local source snapshot; it does not make later source edits or a Git push deploy themselves.

## Search and link previews

Astro renders the metadata for both `/` and `/coop.html` into the HTML head.
The shared [SEO module](seo.mjs) owns titles, descriptions, canonical URLs,
Open Graph, large Twitter cards and JSON-LD. Invitation parameters never enter
these tags. Static [share images](social/README.md), robots.txt and sitemap.xml
are included in every web build.

## Music

Adaptive chip-metal shares its Bend score and danger assessment through
[`music.bend`](music.bend). Native synthesizes stereo PCM in Bend, while the
browser renders the shared notes through Web Audio. Scheduling policy and
validation scope are linked from the [music guide](music/README.md).

## Multiplayer exploration

[Browser co-op](COOP.md) uses the shared Bend world and Iroh transport. Its
[command boundary](coop-session-README.md) documents admission, application and
proof scope. Historical design research is linked from the
[multiplayer work map](../../research/survivors-multiplayer-plan.md). Run
[`check-coop-reliability.sh`](check-coop-reliability.sh) from the repository
root for fresh-emission co-op runtime checks. These checks do not qualify a
hosted browser session or end-to-end Iroh behavior.

## Checks

Checks require Node.js, Bend, a C compiler and platform audio/window development libraries. Linux uses flock when available; other hosts use a temporary lock directory. Remove stale locks only after confirming no checks are running:

```sh
bash examples/survivors/check-native.sh
bash examples/survivors/check-native-full.sh
```

The ordinary suite includes [capability controls](capability-controls.test.py)
and checks of the replay-comparison tools. Comparing a replay from the former component
schema requires the explicit [migration verifier](../../tools/survivors-bot/ecs_migration_compare.py);
its receipt lists the representation changes excluded from gameplay equality.
For same-schema comparisons, the [exact replay verifier](../../tools/survivors-bot/replay_compare.py)
accepts the explicit layout and compares actual metadata without migration
exclusions; see its `--help`.

An optional fresh-profile kiting observation reports survival, damage, progression and enemy density without requiring survival as a pass condition:

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

The proof and host checks:

```sh
bash examples/survivors/build.sh
bash examples/survivors/check.sh
```

Pure Bend behavior is checked by universal laws.
The [proof gate](../../scripts/check-bend-laws.py) discovers the proof modules;
the [mutation gate](../../scripts/check-bend-mutants.py) checks that type-correct
semantic faults are rejected. Their executable manifests live in
[scripts/law-mutants](../../scripts/law-mutants). Native programs retain actual file, image, audio and application integration checks.
The [native geometry check](check-geometry.sh) also exercises physical pickup,
swept combat and the real rendered spawn footprint. Its floating-point
observations supplement the encoded-coordinate and structural laws; they do
not prove real-number collision arithmetic.

The [full-run controller](native-full-run.bend) drives public inputs for a native
functional observation. A scenario observation does not prove balance or every
build. Historical validation is recorded in [VALIDATION.md](VALIDATION.md) and
the [legacy cleanup receipt](../../research/ecs-legacy-cleanup-results.json).

Generated ESM stays in ignored `dist/`.
