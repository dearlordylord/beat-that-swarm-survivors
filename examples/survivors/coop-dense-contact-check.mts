#!/usr/bin/env node
import { coreFrame } from "./observations.mts"
import { list, rows as array, defined } from "./host-values.mts"
import { bendModule } from "../bend-module.mts"
import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { resolve } from "node:path"
import { fileURLToPath, pathToFileURL } from "node:url"

// Dense cosmetic journal regression. Core builds the real prepared geometry;
// the small-stack branch exercises only the bounded journal policy.

const parseCoreReceipt = (frame: BendMaybe<BendABI.CoopCore.Observation>) => {
  const view = coreFrame(frame)
  if (!view || !("contacts" in view)) throw Error("Missing contact receipt")
  return { ...view, contacts: defined(view.contacts), contactsOmitted: defined(view.contactsOmitted) }
}
function moduleUrl(variable: string, fallback: string) {
  const configured = process.env[variable]
  if (!configured) return new URL(fallback, import.meta.url)
  if (configured.startsWith("file:")) return new URL(configured)
  return pathToFileURL(resolve(configured))
}
const { default: Journal } = await bendModule<BendABI.CoopHitJournal.API>()(
  moduleUrl("COOP_JOURNAL_MODULE", "./dist/web/dist/coop-hit-journal.mjs").href,
  [
    "collect",
    "emit_capped",
    "event_id",
    "fresh",
    "ingest",
    "ingest_capped",
    "play",
    "play_sample",
    "playback",
    "shot_id",
    "window"
  ]
)
const nil = () => ({ $: "Nil" as const })
function syntheticEvent(index: number, tick = 10802) {
  const shotSlot = index % 16
  const player = Math.floor(shotSlot / 8)
  const logicalSlot = player * 65536 + (shotSlot % 8)
  const shot = Journal.shot_id(player, tick - 1, 11, logicalSlot)
  const target = Math.floor(index / 16) % 500
  const generation = tick - 1 - 500
  return {
    $: "HitEvent" as const,
    id: Journal.event_id(tick, 1, shot, target, generation),
    tick,
    kind: 1,
    shotId: shot,
    shotSeed: 512 + shotSlot,
    targetSeed: target,
    targetGeneration: generation,
    fraction: 1,
    impactX: 7200,
    impactY: 7200,
    targetAtImpactX: 7200,
    targetAtImpactY: 7200,
    radius: 1028,
    outcome: 0
  }
}
function runJournalOnly() {
  const raw = Array.from({ length: 8000 }, (_, index: number) => syntheticEvent(index))
  const bounded = Journal.emit_capped(list(raw))
  const rows = array(bounded.events)
  assert.ok(bounded.$ === "Emission")
  assert.equal(bounded.omitted, 7488)
  assert.deepEqual(rows, raw.slice(-512), "cap keeps the existing journal suffix and order")
  const journal = Journal.ingest_capped(Journal.fresh(9), 10802, bounded.events, bounded.omitted)
  assert.deepEqual(array(journal.events), rows)
  assert.equal(journal.overflow, 7488)
  assert.equal(journal.expired, 0)
  const duplicateRows = [...rows.slice(0, 100), ...rows]
  const withinBatch = Journal.ingest(Journal.fresh(9), 10802, list(duplicateRows))
  assert.deepEqual(array(withinBatch.events), rows, "incoming duplicate IDs retain first-source FIFO order")
  assert.equal(withinBatch.overflow, 0, "duplicate source rows do not count as capacity overflow")
  assert.equal(withinBatch.expired, 0)
  const priorRows = Array.from({ length: 512 }, (_, index: number) => syntheticEvent(index, 10801))
  const priorFull = Journal.ingest(Journal.fresh(9), 10801, list(priorRows))
  const afterDense = Journal.ingest_capped(priorFull, 10802, bounded.events, bounded.omitted)
  assert.deepEqual(array(afterDense.events), rows, "new dense batch wins over the prior full window")
  assert.equal(afterDense.overflow, 8000, "counts both capacity eviction and source omissions")
  assert.equal(afterDense.expired, 0)
  const resent = Journal.ingest_capped(journal, 10802, bounded.events, 0)
  assert.deepEqual(array(resent.events), rows, "bounded resend preserves event identities")
  assert.equal(resent.overflow, journal.overflow, "bounded resend does not recount omissions")
  const resentAfterDense = Journal.ingest_capped(afterDense, 10802, bounded.events, 0)
  assert.deepEqual(
    array(resentAfterDense.events),
    rows,
    "resending a dense batch does not restore the evicted prior window"
  )
  assert.equal(resentAfterDense.overflow, afterDense.overflow, "dense resend does not recount capacity eviction")
  console.log(
    "PASS small-stack journal cap: 8,000 input rows -> suffix512, prior full512 window, omitted7488, deduplicated resend"
  )
}
if (process.argv.includes("--journal-only")) {
  runJournalOnly()
} else {
  const [{ default: Core }, { default: Game }] = await Promise.all([
    bendModule<BendABI.CoopCore.API>()(moduleUrl("COOP_CORE_MODULE", "./dist/web/dist/coop-core.mjs").href, [
      "core_start",
      "journal_clock",
      "journal_team"
    ]),
    bendModule<BendABI.Game.API>()(moduleUrl("COOP_GAME_MODULE", "./dist/web/dist/game.mjs").href, [
      "contact_team",
      "cooldown_for",
      "effect_origin_index",
      "empty_owner_counts",
      "empty_shot_plan",
      "projectile_amount",
      "shot_requests",
      "team_plan",
      "team_shot_spawn"
    ])
  ])
  const contactTick = 10802
  const fireTick = contactTick - 1
  const started = Core.core_start(0, 0, 1)
  assert.ok(started.$ === "CorePacket")
  const weapons = Array.from({ length: 24 }, (_, index: number) => (index === 11 ? 8 : 0))
  const passives = Array.from({ length: 18 }, (_, index: number) => (index === 4 ? 5 : 0))
  const run = { ...started.state.shared, tick: contactTick, weapons: list(weapons), passives: list(passives) }
  const fireRun = { ...run, tick: fireTick }
  const cooldown = Game.cooldown_for(11, run.passives, run.meta, run.arcana, run.character)
  assert.equal(cooldown, 600)
  assert.equal(fireTick % cooldown, 1, "weapon 11 fires on the preceding tick")
  assert.equal(Game.projectile_amount(11, 8, run.passives, run.arcana), 8)
  const requestCount = (candidateRun: BendABI.Game.Run) =>
    array(Game.shot_requests(24, fireTick % 24, candidateRun, Game.empty_owner_counts())).filter(
      (request) => request.owner === 11
    ).length
  assert.equal(requestCount(fireRun), 8, "each player schedules all eight weapon-11 slots")
  const targetAge = 500
  const targets = Array.from({ length: 500 }, (_, seed: number) => ({
    $: "Snapshot" as const,
    body: {
      $: "Body" as const,
      x: run.px + (seed % 25) * 3,
      y: run.py + Math.floor(seed / 25) * 3,
      kind: 0,
      variant: 1,
      hp: 10000,
      maxHp: 10000,
      age: targetAge,
      seed,
      radius: 8
    },
    motion: {
      $: "Motion" as const,
      vx: 0,
      vy: 0,
      life: 0,
      pierce: 0,
      visited: nil(),
      slow: 65536,
      burn: 0,
      ownerBase: 0,
      logicalSlot: 0
    }
  }))
  const targetRows = list(targets)
  const targetBodies = list(targets.map((target) => target.body))
  const views = list([
    { $: "PlayerView" as const, id: 0, run, dx: 0, dy: 0 },
    { $: "PlayerView" as const, id: 1, run, dx: 0, dy: 0 }
  ])
  const spawnTeam = {
    $: "Team" as const,
    players: views,
    base: { $: "Args" as const, run, bodies: targetBodies, dx: 0, dy: 0, snapshots: targetRows, hits: nil() },
    plan: Game.empty_shot_plan(),
    origins: Game.effect_origin_index(targetRows)
  }
  const shots = []
  for (let player = 0; player < 2; player += 1) {
    for (let slot = 0; slot < 8; slot += 1) {
      const logicalSlot = slot + player * 65536
      const request = { $: "Some" as const, value: { $: "Request" as const, owner: 11, slot: logicalSlot, level: 8 } }
      const entity = Game.team_shot_spawn(spawnTeam, 512 + player * 8 + slot, request)
      const { body } = entity.row
      const { motion } = entity
      assert.equal(body.variant, 11)
      assert.equal(body.age, 0)
      assert.equal(motion.life, 1)
      assert.equal(motion.pierce, 9999)
      assert.equal(motion.logicalSlot, logicalSlot)
      for (const target of targets) {
        assert.ok(Math.hypot(body.x - target.body.x, body.y - target.body.y) <= body.radius + target.body.radius)
      }
      shots.push({ $: "Snapshot" as const, body, motion })
    }
  }
  const snapshots = list([...shots, ...targets])
  const team = Game.contact_team({
    $: "Team" as const,
    players: views,
    base: { $: "Args" as const, run, bodies: targetBodies, dx: 0, dy: 0, snapshots, hits: nil() },
    plan: Game.team_plan(views, snapshots),
    origins: Game.effect_origin_index(snapshots)
  })
  const journalStart = performance.now()
  const fullEvents = Core.journal_team(team)
  const journalMs = performance.now() - journalStart
  const fullRows = array(fullEvents)
  assert.equal(fullRows.length, 8000, "prepared authoritative geometry emits all 16 × 500 contacts before cap")
  assert.equal(new Set(fullRows.map((event) => event.id)).size, 8000, "source events have distinct stable lifetimes")
  assert.ok(fullRows.every((event) => event.tick === contactTick && event.kind === 1 && event.outcome === 0))
  assert.equal(new Set(fullRows.map((event) => event.shotId)).size, 16)
  assert.equal(new Set(fullRows.map((event) => event.targetSeed)).size, 500)
  assert.ok(fullRows.every((event) => event.targetGeneration === contactTick - 1 - targetAge))
  const expectedSuffix = fullRows.slice(-512)
  const emitted = Journal.emit_capped(fullEvents)
  assert.deepEqual(array(emitted.events), expectedSuffix)
  assert.equal(emitted.omitted, 7488)
  const corePacket = { ...started, state: { ...started.state, shared: { ...started.state.shared, tick: contactTick } } }
  const encodeStart = performance.now()
  const encodedPacket = Core.journal_clock(fullEvents, corePacket)
  assert.ok(encodedPacket.$ === "CorePacket")
  const encodeMs = performance.now() - encodeStart
  assert.deepEqual(encodedPacket.state, corePacket.state, "journal serialization does not change Core state")
  const parseStart = performance.now()
  const frame = parseCoreReceipt(encodedPacket.frame)
  const parseMs = performance.now() - parseStart
  assert.equal(frame.tick, contactTick)
  assert.equal(frame.contactsOmitted, 7488)
  assert.deepEqual(array(frame.contacts), expectedSuffix, "Core serializes the exact retained suffix")
  assert.ok(Buffer.byteLength(JSON.stringify(frame)) < 200000, "Encoded contact receipt stays bounded")
  const journalTimes = []
  for (let index = 0; index < 7; index += 1) {
    const startedAt = performance.now()
    const journal = Journal.ingest_capped(Journal.fresh(9), contactTick, frame.contacts, frame.contactsOmitted)
    journalTimes.push(performance.now() - startedAt)
    assert.deepEqual(array(journal.events), expectedSuffix)
    assert.equal(journal.overflow, 7488)
    assert.equal(journal.expired, 0)
  }
  const previousTick = contactTick - 1
  const previousRows = expectedSuffix.map((event) => ({
    ...event,
    tick: previousTick,
    id: Journal.event_id(previousTick, event.kind, event.shotId, event.targetSeed, event.targetGeneration)
  }))
  const priorFullJournal = Journal.ingest(Journal.fresh(9), previousTick, list(previousRows))
  assert.equal(array(priorFullJournal.events).length, 512)
  assert.equal(priorFullJournal.overflow, 0)
  const priorPlayback = Journal.collect(Journal.playback(9), priorFullJournal).state
  const priorIngestTimes = []
  for (let index = 0; index < 7; index += 1) {
    const startedAt = performance.now()
    const journal = Journal.ingest_capped(priorFullJournal, contactTick, frame.contacts, frame.contactsOmitted)
    priorIngestTimes.push(performance.now() - startedAt)
    assert.deepEqual(array(journal.events), expectedSuffix)
    assert.equal(journal.overflow, 8000, "counts 512 capacity evictions plus 7,488 source omissions")
    assert.equal(journal.expired, 0)
  }
  const _priorDenseJournal = Journal.ingest_capped(priorFullJournal, contactTick, frame.contacts, frame.contactsOmitted)
  const expiryTick = previousTick + Journal.window()
  const expiryTimes = []
  for (let index = 0; index < 7; index += 1) {
    const startedAt = performance.now()
    const journal = Journal.ingest_capped(priorFullJournal, expiryTick, nil(), 0)
    expiryTimes.push(performance.now() - startedAt)
    assert.equal(array(journal.events).length, 0)
    assert.equal(journal.overflow, 0)
    assert.equal(journal.expired, 512)
  }
  const cappedJournal = Journal.ingest_capped(Journal.fresh(9), contactTick, frame.contacts, frame.contactsOmitted)
  const sample = {
    $: "Sample" as const,
    baseObservation: contactTick - 1,
    nextObservation: contactTick,
    tick: contactTick,
    fraction: 0,
    alpha: 0,
    players: nil(),
    bodies: nil()
  }
  const freshCollect = Journal.collect(Journal.playback(9), cappedJournal)
  assert.deepEqual(array(freshCollect.events), expectedSuffix)
  const priorCollect = Journal.collect(priorPlayback, cappedJournal)
  assert.deepEqual(array(priorCollect.events), expectedSuffix)
  const duplicateCollect = Journal.collect(freshCollect.state, cappedJournal)
  assert.deepEqual(array(duplicateCollect.events), [], "arrival-time duplicate contacts are suppressed")
  const freshSample = Journal.play_sample(Journal.playback(9), cappedJournal, sample)
  assert.deepEqual(array(freshSample.events), expectedSuffix)
  const priorSample = Journal.play_sample(priorPlayback, cappedJournal, sample)
  assert.deepEqual(array(priorSample.events), expectedSuffix)
  const duplicateSample = Journal.play_sample(freshSample.state, cappedJournal, sample)
  assert.deepEqual(array(duplicateSample.events), [], "presentation-time duplicate contacts are suppressed")
  const collectFreshTimes = []
  const collectPriorTimes = []
  const collectDuplicateTimes = []
  const sampleFreshTimes = []
  const samplePriorTimes = []
  const sampleDuplicateTimes = []
  for (let index = 0; index < 7; index += 1) {
    let startedAt = performance.now()
    Journal.collect(Journal.playback(9), cappedJournal)
    collectFreshTimes.push(performance.now() - startedAt)
    startedAt = performance.now()
    Journal.collect(priorPlayback, cappedJournal)
    collectPriorTimes.push(performance.now() - startedAt)
    startedAt = performance.now()
    Journal.collect(freshCollect.state, cappedJournal)
    collectDuplicateTimes.push(performance.now() - startedAt)
    startedAt = performance.now()
    Journal.play_sample(Journal.playback(9), cappedJournal, sample)
    sampleFreshTimes.push(performance.now() - startedAt)
    startedAt = performance.now()
    Journal.play_sample(priorPlayback, cappedJournal, sample)
    samplePriorTimes.push(performance.now() - startedAt)
    startedAt = performance.now()
    Journal.play_sample(freshSample.state, cappedJournal, sample)
    sampleDuplicateTimes.push(performance.now() - startedAt)
  }
  const duplicateTimes = []
  for (let index = 0; index < 7; index += 1) {
    const startedAt = performance.now()
    const journal = Journal.ingest_capped(cappedJournal, contactTick, frame.contacts, 0)
    duplicateTimes.push(performance.now() - startedAt)
    assert.deepEqual(array(journal.events), expectedSuffix)
    assert.equal(journal.overflow, cappedJournal.overflow)
    assert.equal(journal.expired, cappedJournal.expired)
  }
  const resentJournal = Journal.ingest_capped(cappedJournal, contactTick, frame.contacts, 0)
  assert.deepEqual(array(resentJournal.events), expectedSuffix, "bounded frame resend is deduplicated")
  assert.equal(resentJournal.overflow, cappedJournal.overflow)
  const played = Journal.play(Journal.playback(9), cappedJournal, contactTick)
  assert.deepEqual(array(played.events), expectedSuffix)
  assert.equal(array(Journal.play(played.state, cappedJournal, contactTick).events).length, 0)
  const median = (values: number[]) => values.slice().sort((a, b) => a - b)[Math.floor(values.length / 2)]
  const cappedIngestMs = median(journalTimes)
  const priorIngestMs = median(priorIngestTimes)
  const duplicateIngestMs = median(duplicateTimes)
  const expiryMs = median(expiryTimes)
  const collectFreshMs = median(collectFreshTimes)
  const collectPriorMs = median(collectPriorTimes)
  const collectDuplicateMs = median(collectDuplicateTimes)
  const sampleFreshMs = median(sampleFreshTimes)
  const samplePriorMs = median(samplePriorTimes)
  const sampleDuplicateMs = median(sampleDuplicateTimes)
  console.log(
    JSON.stringify({
      contactsBeforeCap: fullRows.length,
      contactsInFrame: array(frame.contacts).length,
      contactsOmitted: frame.contactsOmitted,
      frameBytes: Buffer.byteLength(JSON.stringify(frame)),
      journalTeamMs: +journalMs.toFixed(3),
      journalClockMs: +encodeMs.toFixed(3),
      frameParseMs: +parseMs.toFixed(3),
      ingestFresh512MsMedian: +defined(cappedIngestMs).toFixed(3),
      ingestPrior512PlusNew512MsMedian: +defined(priorIngestMs).toFixed(3),
      ingestDuplicate512MsMedian: +defined(duplicateIngestMs).toFixed(3),
      ingestExpire512MsMedian: +defined(expiryMs).toFixed(3),
      collectFresh512MsMedian: +defined(collectFreshMs).toFixed(3),
      collectPrior512PlusNew512MsMedian: +defined(collectPriorMs).toFixed(3),
      collectDuplicate512MsMedian: +defined(collectDuplicateMs).toFixed(3),
      playSampleFresh512MsMedian: +defined(sampleFreshMs).toFixed(3),
      playSamplePrior512PlusNew512MsMedian: +defined(samplePriorMs).toFixed(3),
      playSampleDuplicate512MsMedian: +defined(sampleDuplicateMs).toFixed(3),
      ingestFreshOver16ms: defined(cappedIngestMs) > 1000 / 60,
      ingestPriorOver16ms: defined(priorIngestMs) > 1000 / 60,
      ingestDuplicateOver16ms: defined(duplicateIngestMs) > 1000 / 60
    })
  )
  const tinyStack = spawnSync(
    process.execPath,
    ["--stack_size=192", fileURLToPath(import.meta.url), "--journal-only"],
    { encoding: "utf8", env: process.env }
  )
  assert.equal(tinyStack.status, 0, `small-stack journal check failed:\n${tinyStack.stderr}`)
  process.stdout.write(tinyStack.stdout)
  console.log(
    "PASS dense co-op contacts: production geometry preserved, frame bounded before ingest, Core state unchanged"
  )
}
