# Ready-to-play menu and explicit unlocks — 24 October 2026

The user selected prototype A. Production now shows a compact run preview, icon/name in all four collapsed choices, all locked entries when a category is open, and a separate price/requirement/Buy inspector. Browsing a locked item cannot purchase or equip it. Start is available at the top and in a persistent lower bar. GitHub source links remain in the header.

Actual Chromium smoke passes fresh-profile disabled purchases, no spend or equipment change on inspection, an explicit 250-gold Corvin purchase (300→50), persistence after reload, and a stage purchase at its actual catalog price leaving 10 gold. Existing desktop/mobile gameplay, map, reward, focus, pause, collection and reload checks pass. The browser save fixtures are isolated; no user profile was edited. No combat/Bend/native changes are part of this menu revision. See ../../research/menu-start-flow.md.

# Adaptive chip-metal audio — 24 October 2026

Music score and threat assessment are shared Bend code. Perception uses player HP, enemy proximity/type, hostile projectiles and lethal Reaper threats. Hosts replace the latest target rather than queuing transitions; arrangement changes at bars with hysteresis and a slower release. Already scheduled playback has a bounded 30 ms browser / 46 ms native structural horizon, not zero latency. See music/README.md.

The small scheduling core passes kernel verification. A mutant that holds the old band at a boundary fails that proof. Emitted-code tests cover danger ordering, lethal threats, rapid target reversals, smoothing/hysteresis and 11,720 note events across all stages/bands. Five browser adapter tests cover separate SFX/music budgets, scheduling freshness, pause/resume and unchanged SFX gain. Ordinary gameplay still reaches tick 600 alive, level 2, with its first choice at tick 450; no simulation tuning was changed.

Actual Chromium Web Audio scheduling runs independently of RAF and passes pause/resume. Three eight-second OfflineAudioContext listening sketches pass the retained RMS >0.003 and peak <0.98 diagnostic gates after a music-only gain adjustment; RMS calm/pressure/danger is about 0.0062/0.0082/0.0125, maximum peaks 0.088/0.104/0.149, no clipped samples. The original quieter renders and failed diagnostic logs are retained. Rest duration is descriptive, not an audibility requirement. This is PCM/scheduling evidence, not a physical-speaker audition or musical-quality proof.

Full browser UI smoke passes with audio enabled and no page errors. Native stereo/voice lifetime/cap/paused cues/clock/queue/reset/observation regressions pass, together with existing UI/profile/FPS/loot/spawn checks and application compilation. A pure native synthesis fixture generates 22,528 stereo frames with ten continuously active voices (about 1.022 s audio) in 2 ms wall time on this host. That excludes device IO, graphics and scheduling latency. No physical macOS audio device or new game FPS benchmark was tested.

Receipts, source hashes, rejected mutant and WAV sketches: `../../../bend-games/research/adaptive-chip-metal-20261024/`. Prior observations below concern earlier audio implementations.

# Expanded arena and pause map — 24 October 2026

The current world is 14,400×14,400, centered at (7,200,7,200); stage relics lie 3,600 units from the start. Both presentations show a pause map with player/chest/relic/camera markers. M toggles the map and preserves an already-open reward choice. Enemy movement and combat displacement clamp complete sprite envelopes, while the player margin preserves melee reach at corners.

Fresh emitted gameplay passes the full suite: 42,532 offscreen placements, 3,480 actual live birth transitions, 496 movement/knockback/pull cases plus all 31 corner-reach cases, unchanged XP/projectile/lifecycle/queue/finale checks and seven natural upgrade choices. All five relics were collected by ordinary input at tick 1,144 using the legal purchased-profile fixture, with unlock/persistence/one-time reward assertions preserved. The objective runner now allows 1,800 movement ticks per stage and 90 wall seconds because destinations are farther away; no coordinate or inventory injection was introduced. The revised spawn-policy kernel proof passes.

Actual Chromium passes map pause/resume, frozen tick, relic marker, reward-panel priority and existing controls/mobile/reload checks. Two renderer-map unit checks pass. Native profile/UI/FPS/loot/lifecycle checks and application compilation pass; native execution covers M pause/resume/reward priority and large-enemy charging/displacement bounds. Native and browser map captures were inspected. No physical macOS window or new FPS benchmark was run.

Bot navigation retains 4,096 cells and a bounded local window; source/emitted-policy checks, 864 offer/route cases, 14,400 risk-grid cell checks and 38 host tests pass. These are correctness checks, not whole-run progression or performance evidence. Receipts and source snapshots: `../../../bend-games/research/expanded-arena-20261024/`. Previous balance observations below refer to earlier world geometry.

# Actor-free balance follow-up — 24 October 2026

The current tuning is described in BALANCE.md. A fresh emitted Game passes the complete gameplay suite, including 42,532 offscreen placements, 148 incarnation-status regressions, actor absence, XP conservation, upgrade queues, horde capacities and actual Reaper deaths. Ordinary smoke reaches tick 600 alive at level 2, with its first choice at tick 450. This does not establish fresh completion or human difficulty.

Two unchanged deterministic input-only policies compared the saved actor-free baseline with this candidate: seed 100, character 0, fresh unlock mask, stage/Arcana 0, no permanent purchases or classifier, up to 3,600 simulation ticks. The novice loot-chaser died at tick 591 without a choice before tuning; afterwards it received its first choice at tick 814 and died at tick 1,235, level 2. The simple kiter died at tick 615 before tuning; afterwards it remained alive at tick 3,600 with 56 HP and 78 kills. The kiter collected only 14 XP and earned no level, so its survival is not evidence of build progression. These are two diagnostic policies, not a win-rate estimate or proof of beginner fairness. Contact pressure and eventual death remain possible.

Browser menu/input/touch/pause/reward/persistence smoke passed. Native profile/UI/FPS/loot/spawn fixtures and application compilation passed (physical window not opened). The existing input-only native kiter reached tick 3,600 alive, HP 70, 59 kills, one hit event and no level-up; this separately confirms a native survival path, not XP progression. No current complete-run or FPS performance result is claimed.

Current diagnostics and source snapshots are archived under `../../../bend-games/research/actor-free-balance-20261024/`. Earlier observations below qualify earlier source revisions only.

# Custom map actors removed — 24 October 2026

The current world has 1,456 identities: 512 enemy/relic slots, 512 player projectiles, 32 hostile projectiles and 400 persistent XP piles. The actor range is empty. Towers and rescue wisps, their automatic damage/slow and XP/gold/healing rewards, and bot goals for them were removed. Player weapon effects remain.

Fresh emitted gameplay and Chromium checks passed (`/tmp/survivors-no-actors-gameplay.log`, `/tmp/survivors-no-actors-browser.log`). Regressions cover former NPC locations and injected obsolete tower snapshots: no actor bodies, passive rewards, tower damage or slow. The ordinary stationary smoke dies at tick 435; this is not a complete-run or performance claim. Actual Bend-backed bot action and offline-policy parity checks passed, including rejection of removed actor goals. All-U32 pool laws prove the actor range empty.

Native UI/profile, rendering fixtures, spawn-lifecycle checks and application compilation passed; no physical window was opened. The unchanged complete-run controller reached death at tick 36,583 (level 1, 14 kills, 167 gold, zero choices), so its stricter level/chest/boss/evolution progression oracle **failed**. Earlier actor-assisted progression results do not qualify this revision. No controller or oracle was changed to hide that failure.

Evidence: `../../../bend-games/research/no-map-actors-20261024/`. Earlier measurements below describe earlier source versions and do not qualify the actor-free game.

# Automatic reward panel follow-up

The current local follow-up restores automatic level/treasure panels with combat paused. Esc defers and E reopens; queued choices open in order. XP awards and bonuses are unchanged; the first threshold remains 100 and subsequent thresholds are doubled. Verification below is separate from the previous revision:

- `/tmp/survivors-auto-gameplay.log`: the emitted gameplay suite passed; seven natural API level-ups reached at tick 1,533. The injected-clock capacity check retained 511 living enemies. The short nearest-loot controller first earned a reward at tick 296 and reached level 2 with one choice before death at tick 511.
- `/tmp/survivors-auto-browser.log`: desktop/mobile smoke and explicit seeded-XP checks passed for automatic opening, frozen simulation, Esc deferral, E reopening, automatic queued promotion and final choice/resume. The fixture uses real Bend transitions; no production testing hook was added.
- `/tmp/survivors-auto-native.log`: native profile/UI execution and application compilation passed. UI assertions cover automatic level and treasure panels, queued promotion, deferred choices, and a seeded-XP boundary through the actual ECS/frame path. This check did not open a physical window.

All receipt paths are local development outputs, not committed artifacts. These checks apply to the local automatic-panel/cost follow-up, not the historical complete-run observations below. No new full-run, macOS, FPS or final-level-count result is claimed for this cost change.

# Previous standalone revision validation — 22 October 2026

The examples now import the published BendHub package rather than a local ECS source tree. See the [root dependency instructions](../../README.md). The current fixed pool contains 748 entities: 512 enemy/loot slots, 192 player shots, 32 hostile shots and 12 independent actors. The first level needs 100 XP and subsequent thresholds use `100 + 3 * L + L * L / 3`, with the previous level as L. XP pacing is slower and the native reward panel is opened explicitly with E; combat continues with pending rewards until the panel opens, and Esc resumes it.

| Current check | Observed evidence | Scope |
| --- | --- | --- |
| Emitted Bend gameplay and content suite | `/tmp/nightfall-paced-hub-check.log`: catalogs, profiles, trajectories, recipes, public API, objectives, balance, defeat and ordinary gameplay passed | Executed using the current BendHub-importing sources |
| Horde capacity | Same log: 511 admitted enemies, 511 present at tick 21,672, phase 0 | Injected-clock capacity regression; not an input-only complete run or frame-rate measurement |
| Early pressure and independent actors | 96 enemies at tick 120; eight wisps and four wards; ward damage 24, slow 90; Reaper control-immunity regression passed | Functional boundary checks; injected-clock finales are not complete-run witnesses |
| Deferred progression | Pending reward queue regression passed at tick 7 with five queued rewards; native UI tests below cover level and treasure panels | Simulation and explicitly fabricated UI boundaries are distinguished |
| Fresh stationary defeat | Tick 421, phase 3, HP 0, 83 kills, 122 gold | One fresh-profile stationary scenario |
| Fresh moving loot-chasing policy | Death at tick 511 (about 8.52 simulated seconds), level 3, two choices, 124 kills; first reward at tick 296 (about 4.93 seconds) | One novice nearest-loot policy, not representative human playtesting or a complete-run progression result |
| Native profile, deferred UI and application build | `/tmp/nightfall-examples-native-final.log`: profile persistence/roundtrip, both pending phase 1 and phase 2 panels, E opening, Esc resuming, numeric input before opening, queued next choice remaining closed, atomic reward banking and native application compilation passed | Actual Linux native functional execution and headless captures; reward/terminal boundaries are explicitly fabricated. A later instruction-text polish does not change game or queue behavior; its final application/window check is recorded below |
| Fresh native kiting diagnostic | `/tmp/nightfall-native-pacing.log`: tick 3,600 (60 simulated seconds), phase 0, HP 70, level 4, 187 kills, three choices; first reward tick 540 (9 seconds), maximum 163 living enemies, first damage tick 162, minimum HP 32, four health-drop events | Actual fresh native-UI initialization: start → configure 0/0 → fresh weapon mask, Glass Heart, 70 initial HP. Input-only observation, not a full run or FPS measurement |
| Final launcher and actual Linux window | `/tmp/nightfall-examples-launcher-build.log` and `/tmp/nightfall-examples-window.log` passed after the instruction polish; native window started, accepted input, held paused pixels, returned to camp, saved and closed gracefully | Final Linux/aarch64 binary SHA-256: `737be4a0ef9dcedde69261b0c53e4bbc15e44709e68b32fed9d2f3e5e8c1ae2b`; no macOS or physical audio qualification |
| Optional browser frontend | `/tmp/nightfall-examples-browser.log`: menu, collection, gameplay, keyboard/touch movement, modal focus, pause, abandon and reload passed | Headless Chromium functional smoke; deferred reward behavior is covered by the core and native UI tests |
| Current native complete run | `/tmp/nightfall-paced-native-full.log`: alive at tick 36,000 with HP 187, level 41 and 4,905 kills; actual Reaper death at tick 36,713 (about 10:11.88), phase 4, HP 0, level 41, 4,924 kills, 2,161 gold and 42 decisions; boss, chest and evolution assertions passed | Current input-only native witness with maximum purchased upgrades, character 2 and Arcana 9. One advanced build; not a fresh-profile win-rate estimate or FPS measurement |
| Clean GitHub Actions environment | [Run 39827302691](https://github.com/dearlordylord/bendvy-ecs-examples/actions/runs/39827302691), application commit `7ead4db`: Ubuntu 24.04 x64, Bend 2.0.37, fresh BendHub cache; gameplay checks, native profile/UI tests and application build passed | Clean distributed-dependency execution; not an actual-window, full-run, macOS or performance qualification |
| macOS Apple Silicon | Not executed in this environment | Portable launcher implementation is not native macOS execution evidence |

The native kiting and JavaScript nearest-loot scenarios use different unlock initialization and reward-selection policies as well as different movement. Their outcomes are separate observations, not an isolated causal comparison of movement strategies or representative human playtesting.

The paced-suite receipt supersedes the earlier `/tmp/bendvy-ecs-examples-hub-check.log` observation of level 10 after 600 ticks; that earlier result used a different XP threshold and is not current evidence.

The current native full-run witness observed levels `[12, 23, 24, 25, 29, 30, 32, 34, 39, 41]` at minutes 1 through 10. Its ignored executable SHA-256 is `e926f1cd1f9367a9d8da97799b00926a3ff95c3ffc637bd66ecf3b0fc2226e03`. It reaches the real time limit and actual Reaper death through public inputs; this advanced purchased profile does not establish fresh-profile viability across builds.

The raw receipt paths identify local development evidence and are not files shipped with this repository. No FPS target, numerical balance equivalence or player enjoyment result is claimed. The observed 42 decisions are below the authored target of 60–80; that target is not an achieved result. Historical witnesses below do not replace current-revision validation.

---

# Historical native delivery — 22 October 2026

The following evidence belongs to the previous 428-slot native delivery and its earlier XP and reward-panel behavior. It does not qualify the current 748-slot BendHub-based revision, its slower progression, deferred reward selection or current native executable. The authentic complete-run and Linux window witnesses remain historical evidence only.

| Historical requirement | Observed evidence | Status |
| --- | --- | --- |
| Complete run with revised pressure and actual Reaper death | Pure Bend `native-full-run.bend`, compiled to a native Linux/aarch64 executable; only public start/configure/choose/advance inputs | Pass: tick 36,661, phase 4, HP 0, level 185, 6,405 kills, 7,870 gold, 188 upgrade decisions |
| Alive at the time limit, then lethal pursuit | Same complete run, maximum legal permanent upgrades `[5,5,5,3,5,5,5,5,5,2]`, Agatha, Standard Graveyard, Living Tree | At tick 36,000: HP 372, level 182, 6,293 kills; actual death followed 661 ticks later |
| Ordinary gameplay and content regressions | `/tmp/survivors-native-final-check-v2.log` passed catalog, profiles, projectiles, recipes, API, objectives, balance, defeat and smoke | Pass on the final simulation; fresh defeat tick 349, 39 kills, 66 gold; ordinary input survives 600 ticks with 111 kills |
| Dense opening and independent actors | Final ordinary suite: 62 enemies at tick 120; eight wisps/four wards; ward damage 24 and slow 90; injected-clock finales for Standard/Inverse/Trial | Pass on the final simulation. Injected-clock tests are boundary regressions, not complete-run witnesses |
| Reaper control immunity and terminal reward | Pinned source check `/tmp/nightfall-reaper-immune-check.log`; complete native run uses the current simulation hash below | Pass: final runtime confirms 25 damage is applied, freeze/slow/pull/knock are rejected and pursuit continues |
| Native profile persistence | `/tmp/nightfall-native-profile-run.log` reports native file roundtrip, invalid/truncated recovery, names and collections passing | Pass; final native UI also writes, reloads and deduplicates terminal/abandonment reward paths |
| Native UI, renderer captures and complete executable | `/tmp/nightfall-native-final-v2/receipt.json`: PASS with unchanged source/tool guards; actual typed UI input flow, positive 37-gold boundary and final Clang 19 application build | Pass; captures in `/tmp/nightfall-native-delivery-captures`, final executable SHA-256 `dd3ff4e268711f358c0132a2b634c8d4b9f381ccc94310e31a8763a7dcff5c98` |
| Real native window/event lifecycle | `/tmp/nightfall-native-window-v2/receipt.json`: PASS, exact binary/source/tool guards, isolated Xvfb, actual 1024×768 window captures | Start/input delivery, unchanged paused pixels, camp return, saved profile and graceful window close pass; physical audio output is not qualified |
| macOS Apple Silicon | Portable launcher and Bend native frontend are implemented | Not executed on macOS in this environment |
| Independent final Spec/Standards review | Independent review cleared source, runtime receipts and corrected abandonment/recipe/control findings; Astra approved native graphics and bounded window plan | Pass for the declared scope; macOS execution and human balance playtesting remain separate |

This is one advanced defensive-build witness, not an estimate of fresh-profile win rate, proof that every build survives, measured parity with Vampire Survivors, a performance result or a universal correctness claim. The native full controller does not inject clocks, inventories, health, entities or terminal outcomes. Its 42,000-action fuel includes level-up choices; success requires actual phase 4 with zero health between ticks 36,000 and 37,000, plus observed boss, chest, level-up and evolution events.

## Historical source bindings and receipts

The successful native full run used `check-native-full.sh` under the shared heavy lock, a 300-second compilation bound, a 900-second runtime bound and a fresh temporary working directory. Receipt `/tmp/nightfall-native-full-v1.log` records the following hashes and the successful terminal output. Compilation used the reviewed private Clang 19.1.7 toolchain on Linux/aarch64; no compiler optimization flags were changed. An initial standalone compiler identity probe omitted its required private-root variable and failed; the actual compile/run had both approved environment variables from the start, and a clean compiler identity was appended after completion.

| Native full-run source | SHA-256 |
| --- | --- |
| game.bend | `363d917bf617930f1983edf6f69a75c1a5c4153633eb5b0fb5b5fd982fae72cc` |
| actors.bend | `be902db163d8c1da6e88ff6f402c84086be35f0c5a49a9bf4393a025e90e1729` |
| encounters.bend | `a01bf07bb63ed2c542b65aacb49836ce362925c42e717c536c689d32a915702e` |
| projectile.bend | `26d2aac48b3c2cac231545975c9b0ce57cd1029516b80b46f7f7a6cede2d317f` |
| native-full-run.bend | `cd8cbe552eee3681126c874226de2f45e959a5e7465b37ad999abed247b23eae` |
| check-native-full.sh | `e30d9d122ddb86630fe823db2d4b8fc156f43e0d9cbfdbaea79a16c7a634199a` |

The earlier JavaScript controller receipt `/tmp/survivors-native-v3-full.log` is partial: it was deliberately interrupted after tick 10,800 when review required Reaper control-immunity repairs. It is not a completion pass. Earlier ordinary receipt `/tmp/survivors-native-balance-check.log` failed its stale-source check during concurrent edits; the successor `/tmp/survivors-native-v2-check.log` passed, but still predates the final immunity/reward changes. Native build diagnostics `/tmp/nightfall-native-check.log` and `/tmp/nightfall-native-final-check.log` include missing local ALSA headers and a Clang 14 internal compiler error respectively; neither qualifies the final native executable.

Final ordinary suite: `/tmp/survivors-native-final-build.log` and `/tmp/survivors-native-final-check-v2.log`. The first final ordinary attempt, `/tmp/survivors-native-final-check.log`, caught a missing Dawn Reaper entry in the optional browser collection; production catalog metadata was repaired and the unchanged oracle passed. That JavaScript-only metadata repair does not change the native Bend closure.

Final native UI/capture/build: `/tmp/nightfall-native-final-v2/{receipt.json,manifest.json,raw.log}`; status PASS, 144.418 seconds, exact native sources and tools guarded before and after execution through `ReceiptBoundary`. The manifest retains native frontend hashes. Explicitly injected upgrade, terminal and positive-gold boundaries are labeled as such; genuine menu, movement, pause and busy-world input cases are separate. Native profile and launcher results are reused from their matching earlier receipts. Linux build-only dependencies were extracted to temporary sysroots; no npm or project dependency was added.

Actual native window: `/tmp/nightfall-native-window-v2/receipt.json`, PASS in 4.554 seconds, immutable binary/source/tool guards. Actual X11 pixels and device logs are retained in `/tmp/nightfall-window-FkGY64`; gameplay, stable pause and camp return were inspected. The earlier `/tmp/nightfall-native-window-v1/receipt.json` is INCOMPLETE: Xvfb could not compile its keyboard map before the game started. Its successor supplies isolated Debian keyboard data/compiler resources and a reviewed Xvfb-only compiler-path shim; no game binary or system installation was modified. The window diagnostic verifies event delivery and screenshots; quantitative movement is asserted separately by the headless native UI test.

Independent Spec/Standards review found no remaining blocking issue in the delivered scope. Astra reviewed the actual native renderer captures and graphics. No macOS/Metal execution, physical audio output, human enjoyment study or general balance equivalence is claimed.

---

# Historical browser delivery — 22 October 2026

The following records describe the previous browser delivery and its previous balance. They do not qualify the current native frontend, denser waves, independent actors or Reaper finale. Independent Spec and Standards reviews at that historical delivery found no remaining blocking issue after the healing, pierce, discovery and progression corrections.

| Requirement | Evidence | Result |
| --- | --- | --- |
| Complete single-player run | Input-only controller, Standard arena 0, character 0, maximum permanent upgrades, Arcana 9 | Victory at tick 36,000; 11,269 kills; level 250; four bosses; weapon 0 evolved to level 9 |
| Defeat and continued progression | Fresh profile, character 0, no permanent upgrades, ordinary enemy-seeking input | Defeat at tick 478; HP 0; seven kills; 64 gold; terminal state stays terminal |
| Weapons and builds | Actual emitted Bend functions, 24 trajectory/lifetime controls, 24 positive/negative evolution recipes, six union recipes and bounded offers | Pass; includes delayed impacts, gravity, homing, return, healing and finite-pierce regressions |
| Public progression commands | Natural level-ups and opaque State consumption | Stage/Arcana selection, four modes, unlock mask, reroll/banish/skip charges and invalid-phase no-ops pass |
| Arena objectives and unlocks | Input-only traversal in all five arenas, then profile persistence/reload | Artifacts recovered at ticks 184/184/184/184/263; designated weapons open; artifacts do not respawn |
| Trial | Two independent zero-meta/max-meta inputs | Five-minute endpoint; permanent-health bonus disabled; HP 125 in both Trial cases |
| Persistent profile | Purchases, caps, replay deduplication, goals, unlocks and malformed-save recovery | Pass |
| Browser | Chromium through existing Playwright, desktop and 390×844 touch viewport | Keyboard/touch movement, focus trapping, pause, collection navigation, abandon and reload pass; portrait rendering inspected |
| Bend/ECS authority | Source check, stock ESM build, independent review and reached query execution | Four narrow query passes; affine world ownership; Body/Vitals/Motion storage; fixed 416-slot pool; no core changes |
| Content breadth | Catalog checks and independent source review against GAME_SPEC/REFERENCE_SCOPE | 24 weapons, 24 evolutions, six unions, 18 passives, 12 Arcana, eight heroes, five arenas, four modes, 30 enemies/bosses, ten permanent upgrades, 20 achievements |

The breadth review checks distinct mechanics, interaction paths, objectives and unlocks. Catalog totals alone do not establish numerical equivalence to the current Vampire Survivors catalog. The full run is one advanced-build witness, not exhaustive balance testing of every combination. No universal correctness or comparative performance result is asserted.

## Source bindings and retained receipts

The full simulation and ordinary suite used immutable snapshot `/tmp/nightfall-validation-20261022-v4`. Only presentation scaling and the enemy-discovery regression changed afterward. Affected checks passed against the final 399-file snapshot `/tmp/nightfall-validation-20261022-v6`; its executable closure was hash-compared to this worktree. The Bend source and emitted backend are unchanged between those snapshots. Manifests and raw logs remain outside the repository.

| Source | SHA-256 |
| --- | --- |
| game.bend | `41446f2651ddf4cf4b323484bae9d8e1992dde7029c41b53f8c91902128a9aee` |
| projectile.bend | `26d2aac48b3c2cac231545975c9b0ce57cd1029516b80b46f7f7a6cede2d317f` |
| encounters.bend | `e853b04f04786903edd38e39c7e603b42d134cb816a349901aedc49cd7651929` |

Receipts: `/tmp/survivors-build-v4.log`, `/tmp/survivors-check-v4.log`, `/tmp/survivors-full-v4.log`, `/tmp/survivors-frontend-v5.log`, `/tmp/survivors-browser-v6.log`. Browser environment: Node 24.20.0, installed Playwright at `/tmp/blob-reconnect-tools/node_modules/playwright/index.mjs`, existing libraries from `/tmp/chromium-libs/extracted/usr/lib/aarch64-linux-gnu`; no packages installed for the game.

Historical failures are preserved: v1 reached victory but failed its evolution assertion; v2r reached tick 28,800 before its unchanged 360-second deadline. Neither is presented as a successful final qualification. The original Bendvy repository recorded the scoped 900-second successor in its `docs/limits.md`; that file is not part of this standalone repository.

## FPS and pooled-spawn correction — 2026-10-23

The native application builds with Bend 2.0.38 / Clang 19 on Linux arm64. Fourteen native FPS/culling checks and three native spawn-lifecycle regressions pass. The ordinary public frame-producing API remains available; native play uses the equivalent quiet live API. Three hundred complete-state development comparisons cover active, held, queued and terminal rewards. Spawn checks cover 148 stale-status/tower/boss/age-wrap cases (including actual ECS writes), 42,532 geometric placements, and 5,590 live spawn transitions. Universal admission/lifecycle laws pass kernel checking; rejected mutants and proof limits are documented in [the invariant notes](spawn-policy/README.md).

A controlled single-CPU/native O3 diagnostic used 1004 real ECS entities, 100/400 active enemies, 20 measured steps and three alternating pairs. The old frame-producing path versus quiet path matched complete native state in all twelve observations. Median step times were 4.7→3.6 ms at 100 enemies and 7.5→4.25 ms at 400. The window includes one final completion barrier, excludes rendering, startup/warmup and the after-clock full snapshot. These are current-host simulation observations, not measured Mac FPS or a universal 60-FPS guarantee. Raw evidence: `../bend-games/research/native-live-step-20261023/`.

A separate display-list clipping shortcut showed no native improvement and was reverted. Its evidence remains in `../bend-games/research/native-render-20261023/`; it is not part of the game update. Early native body/health-bar culling remains, with on-screen HP visibility preserved by focused checks.


## Dense-scene renderer correction — 2026-10-23

The native renderer now paints display-list entries back-to-front into touched
quadtree branches instead of repeatedly clipping the full list. An independent
pixel oracle passes 29 scenes / 7,602,176 pixels, including fractional geometry,
fonts, sprites, opaque ordering and health bars. A frozen full-frame native
fixture with 400 enemies, 48 projectiles and 32 hit plans passes twelve runs: all
complete state payloads and 512-square PPM bytes match the original renderer.
Three alternating-pair medians are 37→14 ms total at one catch-up step and
55→31 ms at four; Image construction is 31→7 and 30→7 ms respectively.
These are Linux CPU fixture measurements, not measured Mac FPS. The exact
contract, raw evidence paths and limits are in
[the renderer report](../../research/native-renderer-performance.md).

The final production native windowed application compiles with Bend 2.0.38 and
Clang 19 on Linux arm64. The final pixel oracle, BendHub dependency audit
(54 modules) and unchanged spawn-policy kernel proofs pass. Final source/binary
hashes and logs: `../bend-games/research/native-render-final-20261023/`.

## Public browser game — 2026-10-23

[Play the public game](https://nightfall-survivors-bendvy.leafyyew32.chatgpt.site).
The current ordinary build/gameplay suite and real Chromium browser smoke pass,
including keyboard/touch movement, rewards, pause, collection and profile reload.
All three stages have empty stderr and no source-guard failures. The browser
edition uses the current Bend simulation compiled to JavaScript, with the
existing Canvas/input/audio frontend; it does not run the native image renderer.

`build-web.sh` passes and its ten static files match the published package
byte-for-byte. Generated game module SHA256:
`021a431ba33449e32183885144bbbda7ecfc2a25ae098bb034f090e9f5154a9b`.
A separate anonymous check of the deployed public URL passes HTTP 200, game
start, advancing ticks, keyboard movement and paused tick stability, with zero
page errors or failed script/module responses. This is a short functional
browser check, not a complete online run or browser performance qualification.

Sites project: `appgprj_6adc187631688191ba85f51abdc97f4f`; public version 1,
source commit `059e4adc1041666d44e88632d1d2ba94fdc39ac3`, deployed successfully.
The deployment source checkout retains `.openai/hosting.json` and `SOURCE.json`;
the latter binds the game source revision, asset hashes and BendHub dependency.
Raw game/browser receipts and captures are retained outside tracked source in
`../bend-games/research/public-web-game-20261023/`.


## Shared projectile pool and XP revision — 2026-10-24

The current layout has 1468 entities, 400 physical XP entries and 512 shared
player-projectile slots with explicit owner/logical-position metadata.
Configuration, allocation, visual-cap, pickup and spawn small-core kernel checks
pass. The ordinary suite, 305 allocator cases, 55,585 birth/schedule comparisons,
actual ECS owner transport, legal 300/500 enemy admission, simultaneous 480-drop
XP conservation, desktop/touch browser flow, exact XP browser colors/capped
footprints, native UI/profile/FPS/XP/spawn/parallel fixtures and native application
build pass. The final integrated visual/allocator test adapters use the ordinary
game build and pass separately.

The unchanged maximum-meta native controller passes a full run: tick 36563,
phase 4, HP 0, level 15, 1696 kills, 1203 gold and 16 decisions, with its existing
boss/chest/evolution assertions. This qualifies one defensive build only.
Native source hashes match before/after execution; headless captures are retained.
No actual macOS window/FPS or general balance parity is claimed.

See [the pool report](../../research/shared-projectile-pool.md) for 400/500-enemy
frame observations, proof boundaries and the rejected planner optimization.
Raw source-bound evidence: `../bend-games/research/shared-projectile-pool-20261023/`.
The earlier 1004-entity/48-shot timings above describe their earlier revision.
