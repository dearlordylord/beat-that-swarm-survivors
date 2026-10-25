import { bendModule } from "../bend-module.mts"
import { object, array as parseArray, list, rows as array, defined, some } from "./host-values.mts"
import {
  parseCoopLocalProjectilesRenderShot,
  parseCoopLocalProjectilesContactFx,
  parseCoopLocalProjectilesTargetFade
} from "./bend-codecs.generated.mts"
import assert from "node:assert/strict"
import { fileURLToPath, pathToFileURL } from "node:url"
import { resolve } from "node:path"
type RenderFrame = {
  shots: Omit<BendABI.CoopLocalProjectiles.RenderShot, "$">[]
  contacts: Omit<BendABI.CoopLocalProjectiles.ContactFx, "$">[]
  corpses: Omit<BendABI.CoopLocalProjectiles.TargetFade, "$">[]
}
const renderFrame = (text: string): RenderFrame => {
  const row = object(JSON.parse(text))
  return {
    shots: parseArray(row.shots, (value) => parseCoopLocalProjectilesRenderShot({ ...object(value), $: "RenderShot" })),
    contacts: parseArray(row.contacts, (value) =>
      parseCoopLocalProjectilesContactFx({ ...object(value), $: "ContactFx" })
    ),
    corpses: parseArray(row.corpses, (value) =>
      parseCoopLocalProjectilesTargetFade({ ...object(value), $: "TargetFade" })
    )
  }
}

// Functional checks for the emitted Bend local projectile presentation core.
// Usage: bend coop-local-projectiles.bend -o /tmp/coop-local-projectiles.mjs
//        COOP_LOCAL_PROJECTILES_MODULE=/tmp/coop-local-projectiles.mjs node coop-local-projectiles-check.mts

const modulePath =
  process.env.COOP_LOCAL_PROJECTILES_MODULE ||
  fileURLToPath(new URL("./dist/web/dist/coop-local-projectiles.mjs", import.meta.url))
const C = (
  await bendModule<BendABI.CoopLocalProjectiles.API>()(pathToFileURL(resolve(modulePath)).href, [
    "accept_tick",
    "advance_tick",
    "bootstrap",
    "bounded_known",
    "confirm",
    "coop-prediction:fresh_prepared",
    "empty",
    "ensure_bootstrap",
    "event_contact",
    "flight_step",
    "observed_target",
    "overflow_added",
    "play_effects",
    "prepare_geometry",
    "prepare_visibility",
    "render",
    "should_show_authoritative",
    "should_show_prepared"
  ])
).default
const record = <T extends object, K extends keyof T>(state: T, key: K, value: T[K]): T => ({ ...state, [key]: value })
const prediction = (lead = 54, enabled = true, anchor = 0) =>
  C["coop-prediction:fresh_prepared"](128, 128, 2.5, enabled, anchor, lead)
const run = (weapon = 0, tick = 0, x = 128, y = 128) => {
  const weapons = Array(24).fill(0)
  if (weapon) weapons[weapon] = 1
  else weapons[0] = 1
  return {
    $: "Run" as const,
    phase: 0,
    tick,
    px: x,
    py: y,
    hp: 10,
    maxHp: 10,
    xp: 0,
    xpNeed: 20,
    level: 1,
    kills: 0,
    gold: 0,
    character: 0,
    weapons: list(weapons),
    passives: list(Array(18).fill(0)),
    invuln: 0,
    seed: 12345,
    stage: 0,
    arcana: 0,
    meta: 0,
    revivals: 0,
    bosses: 0,
    mode: 0,
    rerolls: 0,
    banishes: 0,
    skips: 0,
    bannedWeapons: 0,
    bannedPassives: 0,
    enemyKinds: list([]),
    relicCollected: 0
  }
}
const target = (seed: number, generation: number, x: number, y: number, radius = 12, hp = 10) => {
  const out = C.observed_target(seed, 0, 1, (generation + 1) >>> 0, x, y, radius, hp)
  assert.ok(out.$ === "Some")
  return out.value
}
const event = (shotId = "1:9:0:0", kind = 0, tick = 10, targetGeneration = 5) => ({
  $: "HitEvent" as const,
  id: `${shotId}:42:${targetGeneration}:${tick}:${kind}`,
  tick,
  kind,
  shotId,
  shotSeed: 99,
  targetSeed: 42,
  targetGeneration,
  fraction: 0.5,
  impactX: 10,
  impactY: 20,
  targetAtImpactX: 8,
  targetAtImpactY: 18,
  radius: 6,
  outcome: 0
})
const visual = (options = {}) => ({
  $: "Visual" as const,
  id: "1:1:0:0",
  owner: 0,
  slot: 65536,
  weapon: 0,
  poolSeed: 512,
  age: 0,
  originX: 100,
  originY: 100,
  shot: { $: "Shot" as const, x: 100, y: 100, vx: 8, vy: 0, radius: 5, life: 20, pierce: 1 },
  pending: false,
  predictedSeed: 0,
  predictedGeneration: 0,
  predictedX: 0,
  predictedY: 0,
  pendingAge: 0,
  confirmed: false,
  late: false,
  event: { $: "None" as const },
  guideTick: 0,
  guideX: 0,
  guideY: 0,
  fade: 0,
  ...options
})
const field = <T, K extends keyof T>(rows: T[], key: K, value: T[K]): T =>
  defined(rows.find((row) => row[key] === value))
const withoutShots = (state: BendABI.CoopLocalProjectiles.State) => record(state, "shots", { $: "Nil" as const })
let checks = 0
const check = (condition: unknown, message: string) => {
  assert.ok(condition, message)
  checks++
}
// Target generations are source tick minus age, and dead/non-enemy rows are not aim targets.
const observed = C.observed_target(42, 0, 5, 45, 300.25, 400.5, 12, 10)
check(observed.$ === "Some" && observed.value.generation === 40, "observed target birth generation")
check(some(observed).x === 300.25 && some(observed).y === 400.5, "observed target F32 boundary normalization")
check(C.observed_target(42, 1, 1, 45, 0, 0, 12, 10).$ === "None", "non-enemy rows excluded")
check(C.observed_target(42, 0, 1, 45, 0, 0, 12, 0).$ === "None", "dead targets excluded")
// The bounded bootstrap emits automatic local shots throughout its 54-tick startup lead.
const baseRun = run(0),
  targets = list([]),
  snapshots = list([]),
  p = prediction()
const bootstrap = C.ensure_bootstrap(C.empty(), 1, baseRun, 0, targets, snapshots, p)
const state = bootstrap.state
check(bootstrap.started === true && state.lastAccepted === 54, "bootstrap begins exactly once at the bounded lead")
const bootShots = array(state.shots)
check(bootShots.length === 2, "automatic weapon births inside bootstrap prefix")
check(
  bootShots.some((row) => row.id === "1:1:0:0" && row.age === 53),
  "first startup shot is locally advanced through the prefix"
)
check(
  bootShots.some((row) => row.id === "1:41:0:1" && row.age === 13),
  "second startup shot is locally advanced through the prefix"
)
const bootstrapAgain = C.ensure_bootstrap(state, 1, baseRun, 0, targets, snapshots, p)
check(bootstrapAgain.started === false, "repeated ensure does not start bootstrap twice")
assert.deepEqual(bootstrapAgain.state, state)
checks++
// A terminal receipt that arrives before local startup survives bootstrap and is applied to the rebuilt matching shot.
const oldTarget = target(42, 5, 300, 400)
const earlyTerminal = event("1:41:0:1", 2, 50, 5)
const receivedBeforeStart = C.confirm(C.empty(), earlyTerminal, 54, list([oldTarget]))
check(receivedBeforeStart.displayTick === 0, "contact receipt does not consume visual clock")
const startedAfterReceipt = C.ensure_bootstrap(receivedBeforeStart, 1, baseRun, 0, list([oldTarget]), snapshots, p)
const rebuiltShot = field(array(startedAfterReceipt.state.shots), "id", earlyTerminal.shotId)
check(
  startedAfterReceipt.started && rebuiltShot?.confirmed && rebuiltShot.late,
  "pending terminal receipt is replayed onto bootstrap shot"
)
check(
  rebuiltShot.shot.life === 0 && rebuiltShot.shot.x === 302 && rebuiltShot.shot.y === 402,
  "terminal preview uses exact displayed target contact offset"
)
check(
  array(startedAfterReceipt.state.events).some((row) => row.id === earlyTerminal.id),
  "pre-start receipt history survives merge"
)
const afterRepeat = C.ensure_bootstrap(startedAfterReceipt.state, 1, baseRun, 0, list([oldTarget]), snapshots, p)
check(!afterRepeat.started, "accepted state makes startup idempotent")
assert.deepEqual(afterRepeat.state, startedAfterReceipt.state)
checks++
// Accepted movement creates at the current displayed muzzle but spends no flight time.
const beforeAges = new Map(array(state.shots).map((row) => [row.id, row.age]))
const accepted = C.accept_tick(state, true, 1, baseRun, 0, 0, 777, 888, 81, 55, 55, targets, snapshots)
const birth = field(array(accepted.shots), "id", "1:81:0:2")
check(
  birth?.age === 0 && birth.originX === 777 && birth.originY === 888,
  "accepted local shot starts at current displayed owner position"
)
check(birth.shot.x === 777 && birth.shot.y === 888, "muzzle geometry follows the same local position")
check(
  array(state.shots).every((row) => field(array(accepted.shots), "id", row.id)?.age === beforeAges.get(row.id)),
  "accepting input does not age existing projectiles"
)
const oneVisualStep = C.advance_tick(accepted, baseRun, 777, 888, 55, targets)
const twoVisualSteps = C.advance_tick(oneVisualStep, baseRun, 777, 888, 55, targets)
check(
  field(array(oneVisualStep.shots), "id", birth.id).age === 1,
  "wall animation advances flight with no new movement command"
)
check(
  field(array(twoVisualSteps.shots), "id", birth.id).age === 2,
  "held remote tick does not stop or duplicate-gate wall flight steps"
)
check(twoVisualSteps.lastAccepted === 81, "visual flight does not change accepted-input cursor")
// An unconfirmed retired preview exposes a live canonical shot; only a matching recent terminal journal receipt suppresses it.
const knownState = withoutShots(state)
const oldBadState = record(
  C.empty(),
  "known",
  list([{ $: "KnownShot" as const, player: 1, id: "shot-id", seenTick: 0 }])
)
const preparedState = C.prepare_visibility(state)
check(
  C.should_show_prepared(preparedState, 1, 1, 1, "1:41:0:1") ===
    C.should_show_authoritative(state, 1, 1, 1, "1:41:0:1"),
  "prepared visibility agrees with compatibility query for active preview"
)
const preparedExpired = C.prepare_visibility(knownState)
check(
  C.should_show_prepared(preparedExpired, 1, 1, 1, "1:41:0:1") ===
    C.should_show_authoritative(knownState, 1, 1, 1, "1:41:0:1"),
  "prepared visibility agrees when speculative preview expired"
)
check(
  C.should_show_prepared(preparedState, 1, 0, 1, "enemy:unused") === true,
  "prepared visibility bypasses local shot searches for enemy rows"
)
const denseRows = Array.from({ length: 512 }, (_, i) => visual({ id: `1:${i}:0:${i}`, poolSeed: i }))
const denseEvents = Array.from({ length: 512 }, (_, i) => event(`1:${i}:0:${i}`, i === 0 ? 2 : 0, 100, 5))
const denseState = record(
  record(record(C.empty(), "shots", list(denseRows)), "events", list(denseEvents)),
  "displayTick",
  100
)
const denseVisibility = C.prepare_visibility(denseState)
check(
  Array.from({ length: 512 }, (_, i) => C.should_show_prepared(denseVisibility, 1, 0, 1, `enemy:${i}`)).every(Boolean),
  "prepared visibility filters 512 unrelated bodies against dense shot and receipt histories"
)
const denseReceiptVisibility = C.prepare_visibility(record(denseState, "shots", { $: "Nil" as const }))
check(
  C.should_show_prepared(denseReceiptVisibility, 1, 1, 1, "1:0:0:0") === false,
  "dense prepared history still honors a terminal receipt"
)
check(
  C.should_show_authoritative(oldBadState, 1, 1, 1, "shot-id") === true,
  "remembered unconfirmed spawn does not hide authority"
)
check(
  C.should_show_authoritative(state, 1, 1, 1, "1:41:0:1") === false,
  "active drawable preview suppresses its matching canonical echo"
)
check(
  C.should_show_authoritative(knownState, 1, 1, 1, "1:41:0:1") === true,
  "expired speculative preview exposes matching canonical echo"
)
check(
  C.should_show_authoritative(knownState, 1, 1, 1, "unrelated-shot") === true,
  "unrelated local canonical shot remains visible"
)
check(
  C.should_show_authoritative(knownState, 2, 1, 2, "1:41:0:1") === true,
  "other player canonical shot remains visible"
)
const terminalReceipt = event("1:41:0:1", 2, 50, 5)
const receivedTerminal = C.confirm(knownState, terminalReceipt, 54, targets)
check(
  C.should_show_authoritative(receivedTerminal, 1, 1, 1, terminalReceipt.shotId) === false,
  "matching recent terminal receipt suppresses canonical echo"
)
for (const kind of [0, 1]) {
  const nonterminalReceipt = C.confirm(knownState, event("1:41:0:1", kind, 50, 5), 54, targets)
  check(
    C.should_show_authoritative(nonterminalReceipt, 1, 1, 1, "1:41:0:1") === true,
    `kind ${kind} receipt does not hide live canonical shot`
  )
}
const expiredTerminal = C.advance_tick(receivedTerminal, baseRun, 128, 128, 119, targets)
check(
  C.should_show_authoritative(expiredTerminal, 1, 1, 1, "1:41:0:1") === true,
  "terminal receipt expiry exposes canonical shot again"
)
const expiredKnown = C.advance_tick(knownState, baseRun, 128, 128, 119, targets)
check(
  C.should_show_authoritative(expiredKnown, 1, 1, 1, "1:41:0:1") === true,
  "retired identity expires after playback passes its history window"
)
check(
  array(
    C.bounded_known(
      list(Array.from({ length: 700 }, (_, i) => ({ $: "KnownShot" as const, player: 1, id: `${i}`, seenTick: 1 })))
    )
  ).length === 512,
  "known identity ledger is capped"
)
check(C.overflow_added(513, 512) === 1, "one preview discarded by the 512-row cap increments the counter by one")
check(C.overflow_added(515, 512) === 3, "three discarded rows increment the counter by three")
// Attached aura rows move with the current owner, while their age changes only on visual animation steps.
const auraRun = run(3),
  auraPrediction = prediction(20),
  auraBoot = C.bootstrap(1, auraRun, 0, targets, snapshots, auraPrediction)
const aura = array(auraBoot.shots).find((row) => row.weapon === 3)
check(!!aura && aura.age === 19, "attached aura is born and advanced during startup prefix")
const auraMoved = C.accept_tick(auraBoot, true, 1, auraRun, 0, 0, 500, 600, 21, 21, 21, targets, snapshots)
const movedAura = field(array(auraMoved.shots), "id", defined(aura).id)
check(
  movedAura.age === defined(aura).age &&
    (movedAura.shot.x !== defined(aura).shot.x || movedAura.shot.y !== defined(aura).shot.y),
  "accepted local movement repositions attached aura without aging"
)
// Swept contact anticipation holds only a released finite single-pierce projectile.
const contactTarget = target(42, 0, 108, 100, 6)
const collisionGeometry = C.prepare_geometry(list([contactTarget]))
const manual = visual()
const onePierce = C.flight_step(manual, run(0, 1, 100, 100), collisionGeometry)
check(onePierce.pending === true, "finite single-pierce contact may hold its preview")
const piercingVisual = visual({ shot: { ...manual.shot, pierce: 2 } })
const piercing = C.flight_step(piercingVisual, run(0, 1, 100, 100), collisionGeometry)
check(
  piercing.pending === false && piercing.shot.x === 108 && piercing.age === 1,
  "piercing projectile continues through provisional contact"
)
const attachedVisual = visual({ weapon: 3, shot: { ...manual.shot, pierce: 9999 } })
check(
  C.flight_step(attachedVisual, run(3, 1, 100, 100), collisionGeometry).pending === false,
  "attached aura is never frozen by provisional contact"
)
// Nonterminal sweep and area receipts record effects without retiring the local projectile.
const localShot = visual({
  id: "1:9:0:0",
  age: 1,
  pending: true,
  predictedSeed: 42,
  predictedGeneration: 5,
  predictedX: 100,
  predictedY: 100,
  pendingAge: 1
})
const withLocalShot = record(C.empty(), "shots", list([localShot]))
for (const kind of [0, 1]) {
  const received = C.confirm(withLocalShot, event(localShot.id, kind, 10, 5), 20, list([oldTarget]))
  const row = array(received.shots)[0]
  check(
    defined(row).confirmed === false && defined(row).late === false && defined(row).shot.life === 20,
    `kind ${kind} receipt preserves normal projectile flight`
  )
}
const terminalState = C.confirm(withLocalShot, event(localShot.id, 2, 10, 5), 20, list([oldTarget]))
check(
  defined(defined(array(terminalState.shots))[0]).confirmed && defined(defined(array(terminalState.shots))[0]).late,
  "kind 2 terminal receipt retires late preview only"
)
const movedTarget = target(42, 5, 310, 415, 12)
const movedTerminal = event(localShot.id, 2, 10, 5)
const movedTerminalState = C.confirm(withLocalShot, movedTerminal, 20, list([movedTarget]))
const movedTerminalShot = renderFrame(C.render(movedTerminalState, 1, 20, list([movedTarget]))).shots.find(
  (row) => row.id === localShot.id
)
check(
  movedTerminalShot?.x === 312 && movedTerminalShot?.y === 417,
  "same-generation terminal preview follows current displayed target plus recorded offset"
)
const movedTerminalFx = C.render(
  C.play_effects(movedTerminalState, list([movedTerminal]), 20),
  1,
  20,
  list([movedTarget])
)
check(
  defined(renderFrame(movedTerminalFx).contacts[0]).x === 312 &&
    defined(renderFrame(movedTerminalFx).contacts[0]).y === 417,
  "same-generation terminal preview and FX share moved target contact"
)
// A target absent from the current cohort may remain as a corpse tombstone, but it cannot steer the confirmed point.
const terminalGap = event(localShot.id, 2, 10, 5)
const staleCorpse = {
  $: "Tombstone" as const,
  shotId: localShot.id,
  target: { $: "Target" as const, seed: 42, generation: 5, x: 300, y: 400, radius: 12, alive: false },
  lastSeen: 18
}
const withStaleCorpse = record(withLocalShot, "tombstones", list([staleCorpse]))
const afterSkippedDeath = C.confirm(withStaleCorpse, terminalGap, 20, list([]))
const skippedDeathFrame = renderFrame(
  C.render(C.play_effects(afterSkippedDeath, list([terminalGap]), 20), 1, 20, list([]))
)
const skippedDeathShot = skippedDeathFrame.shots.find((row) => row.id === localShot.id)
check(
  skippedDeathShot?.x === 10 && skippedDeathShot?.y === 20,
  "skipped-death terminal preview falls back to canonical event impact"
)
check(
  defined(skippedDeathFrame.contacts[0]).x === 10 && defined(skippedDeathFrame.contacts[0]).y === 20,
  "skipped-death FX uses the same canonical event impact"
)
check(
  skippedDeathFrame.corpses.length === 1 &&
    defined(skippedDeathFrame.corpses[0]).x === 8 &&
    defined(skippedDeathFrame.corpses[0]).y === 18,
  "terminal corpse marker uses canonical target-at-impact coordinates"
)
check(
  defined(skippedDeathShot).x - defined(skippedDeathFrame.corpses[0]).x ===
    terminalGap.impactX - terminalGap.targetAtImpactX &&
    defined(skippedDeathShot).y - defined(skippedDeathFrame.corpses[0]).y ===
      terminalGap.impactY - terminalGap.targetAtImpactY,
  "skipped-death projectile and corpse preserve the authoritative contact offset"
)
// Journal playback starts FX once; presentation repeats it for four remote ticks and uses one contact point.
const impact = event("1:9:0:0", 0, 10, 5)
const confirmed = C.confirm(C.empty(), impact, 20, list([oldTarget]))
check(
  renderFrame(C.render(confirmed, 1, 20, list([oldTarget]))).contacts.length === 0,
  "receipt alone does not play a hit FX"
)
const played = C.play_effects(confirmed, list([impact]), 20)
check(played.displayTick === confirmed.displayTick, "FX admission does not consume animation clock")
const fxAt20 = renderFrame(C.render(played, 1, 20, list([oldTarget]))).contacts
const fxAt20Again = renderFrame(C.render(played, 1, 20, list([oldTarget]))).contacts
check(fxAt20.length === 1 && fxAt20Again.length === 1, "confirmed FX survives repeated RAF renders")
check(
  defined(fxAt20[0]).x === 302 && defined(fxAt20[0]).y === 402,
  "FX point shares exact target-display contact offset"
)
check(
  defined(renderFrame(C.render(C.play_effects(played, list([impact]), 21), 1, 21, list([oldTarget]))).contacts[0])
    .age === 1,
  "duplicate playback cannot restart the FX timer"
)
check(
  defined(renderFrame(C.render(played, 1, 23, list([oldTarget]))).contacts[0]).opacity === 0.25,
  "FX fades over four remote ticks"
)
check(
  renderFrame(C.render(played, 1, 24, list([oldTarget]))).contacts.length === 0,
  "FX expires after four remote ticks"
)
const reusedTarget = target(42, 6, 900, 900, 12)
check(
  C.event_contact(impact, list([reusedTarget])).x === 10 && C.event_contact(impact, list([reusedTarget])).y === 20,
  "missing old lifetime falls back to event impact, never the reused slot"
)
check(array(confirmed.tombstones).length === 1, "matching target tombstone remains available through playback")
// Render rows contain Bend-owned age/opacity and bounded FX/corpse output.
const renderRows: { shots: Omit<BendABI.CoopLocalProjectiles.RenderShot, "$">[] } = renderFrame(
  C.render(state, 1, 54, targets)
)
check(
  renderRows.shots.every((row) => Number.isInteger(row.age) && row.opacity === 1),
  "projectile age and opacity are explicit render fields"
)
check(
  defined(renderFrame(C.render(played, 1, 20, list([]))).contacts[0]).x === 10 &&
    defined(renderFrame(C.render(played, 1, 20, list([]))).contacts[0]).y === 20,
  "exact-lifetime tombstone cannot move FX after target leaves current cohort"
)
check(
  renderFrame(C.render(played, 1, 20, list([]))).corpses.length === 1,
  "matching missing target renders a brief tombstone marker"
)
check(
  defined(renderFrame(C.render(played, 1, 20, list([]))).corpses[0]).x === 300 &&
    defined(renderFrame(C.render(played, 1, 20, list([]))).corpses[0]).y === 400,
  "nonterminal contact leaves an unrelated corpse at its last-seen pose"
)
console.log(
  JSON.stringify({
    status: "PASS",
    checks,
    scope:
      "emitted Bend local projectile anticipation, bootstrap merge, exact contact mapping, and bounded render cosmetics"
  })
)
