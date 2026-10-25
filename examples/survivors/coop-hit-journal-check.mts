import { list, rows as array, defined } from "./host-values.mts"
// Cosmetic retention/dedup boundary checks; authoritative geometry is checked
// separately against Core's actual prepared contact resolver.
import assert from "node:assert/strict"
import { pathToFileURL, fileURLToPath } from "node:url"
const J: BendABI.CoopHitJournal.API = (
  await import(
    pathToFileURL(
      process.env.COOP_JOURNAL_MODULE || fileURLToPath(new URL("./dist/web/dist/coop-hit-journal.mjs", import.meta.url))
    ).href
  )
).default
const event = (id: string | number, tick = 100, targetGeneration = 50) => ({
  $: "HitEvent" as const,
  id: String(id),
  tick,
  kind: 0,
  shotId: J.shot_id(1, 40, 2, 65537),
  shotSeed: 8192,
  targetSeed: 42,
  targetGeneration,
  fraction: 0.25,
  impactX: 10,
  impactY: 20,
  targetAtImpactX: 11,
  targetAtImpactY: 21,
  radius: 8,
  outcome: 0
})
assert.equal(J.window(), 64)
assert.equal(J.capacity(), 512)
const original = Array.from({ length: 700 }, (_, i) => event(i))
let journal = J.ingest(J.fresh(3), 100, list(original))
assert.deepEqual(array(journal.events), original.slice(188))
assert.equal(journal.overflow, 188)
assert.equal(journal.expired, 0)
journal = J.ingest(journal, 100, journal.events)
assert.equal(journal.overflow, 188, "duplicate snapshots are not new overflow")
const sample = {
  $: "Sample" as const,
  baseObservation: 900,
  nextObservation: 901,
  tick: 99,
  fraction: 0,
  alpha: 0,
  players: list([]),
  bodies: list([])
}
assert.equal(
  array(J.play_sample(J.playback(3), journal, sample).events).length,
  0,
  "high observation IDs cannot substitute for remote presentation world tick"
)
let played = J.play(J.playback(3), journal, 99)
assert.equal(array(played.events).length, 0, "future contacts wait for remote presentation time")
played = J.play(played.state, journal, 100)
assert.deepEqual(array(played.events), original.slice(188))
played = J.play(played.state, journal, 100)
assert.equal(array(played.events).length, 0, "snapshot resend does not repeat effects")
assert.equal(array(J.play(J.attach(journal), journal, 100).events).length, 0, "rejoin consumes existing cosmetics")
assert.equal(array(J.ingest(journal, 163, list([])).events).length, 512)
const expired = J.ingest(journal, 164, list([]))
assert.equal(array(expired.events).length, 0)
assert.equal(expired.expired, 512)
assert.equal(J.ingest(journal, 90, list([])).now, 100, "host world clock does not regress")
const largeWire = J.native_events(list(original))
assert.deepEqual(
  array(JSON.parse(largeWire)),
  original,
  "700-contact receipt serialization preserves all pre-retention contacts"
)
assert.ok(
  new TextEncoder().encode(largeWire).length < 1024 * 1024,
  "700-contact stress receipt fits1MiB transport gate"
)
const wire = JSON.parse(J.native_events(list([event("42")])))
assert.deepEqual(wire, list([event("42")]))
assert.notEqual(
  J.event_id(100, 0, "1:2", 42, 50),
  J.event_id(100, 0, "1:2", 42, 51),
  "reused enemy lifetime has a distinct identity"
)
assert.notEqual(
  J.event_id(100, 1, "1:2", 42, 50),
  J.event_id(101, 1, "1:2", 42, 50),
  "AoE pulse world ticks are distinct"
)
console.log(
  "PASS confirmed cosmetic journal: cap512, age64, exact counters, FIFO, resend dedup, future playback, rejoin, lifetime identity"
)
assert.deepEqual(
  array(J.collect(J.playback(3), journal).events),
  array(J.play(J.playback(3), journal, journal.now).events),
  "arrival guide consumer uses authority tick"
)
for (const [kind, pierce, count, expected] of [
  [0, 1, 1, 2],
  [0, 3, 3, 2],
  [0, 3, 2, 0],
  [0, 9999, 20000, 0],
  [0, 0, 0, 0],
  [1, 1, 1, 1],
  [2, 1, 1, 2]
] as const)
  assert.equal(J.contact_kind(kind, pierce, count), expected, "terminal classification literal boundary")
// Successive dense journals must not grow a recursive append stack. The seen
// ledger may transiently hold prior512+incoming512, then retains newest512.
let denseSeen = J.attach(J.fresh(1))
for (let tick = 100; tick <= 104; tick++) {
  const rows = Array.from({ length: 500 }, (_, i) => event(`${tick}:${i}`, tick))
  const dense = { $: "State" as const, epoch: 1, now: tick, events: list(rows), overflow: 0, expired: 0 }
  const out = J.play(denseSeen, dense, tick)
  denseSeen = out.state
  assert.deepEqual(array(out.events), rows, "dense confirmed effects preserve FIFO")
  assert.ok(array(denseSeen.seen).length <= 512, "final seen capacity")
  assert.equal(defined(defined(array(denseSeen.seen))[0]).id, `${tick}:499`, "newest ID retained first")
  assert.equal(array(J.play(denseSeen, dense, tick).events).length, 0, "resending dense journal remains deduplicated")
}
console.log("PASS successive 500-contact batches: bounded newest-first IDs, FIFO effects, no duplicate resend")
// Raw AoE evidence must be bounded before serialization. IDs are source rows,
// so omission accounting intentionally counts rows rather than unique IDs.
const sourceBurst = Array.from({ length: 8000 }, (_, i) => event(`source:${i}`, 200))
const emission = J.emit_capped(list(sourceBurst))
assert.deepEqual(
  array(emission.events),
  sourceBurst.slice(-512),
  "emission retains the same ordered last512 source rows"
)
assert.equal(emission.omitted, 7488)
assert.equal(J.event_count(list(sourceBurst)), 8000)
assert.deepEqual(array(JSON.parse(J.native_events(emission.events))), sourceBurst.slice(-512))
let capped = J.ingest_capped(J.fresh(77), 200, emission.events, emission.omitted)
assert.equal(capped.overflow, 7488)
assert.equal(capped.expired, 0)
assert.equal(capped.epoch, 77)
assert.equal(capped.now, 200)
assert.deepEqual(array(capped.events), sourceBurst.slice(-512))
const resend = J.ingest_capped(capped, 200, emission.events, 0)
assert.equal(resend.overflow, capped.overflow, "ordinary resend retains duplicate semantics")
assert.deepEqual(array(resend.events), array(capped.events))
const prior = { $: "State" as const, epoch: 88, now: 199, events: list([event("old", 198)]), overflow: 10, expired: 4 }
const result = J.ingest_capped(prior, 200, emission.events, emission.omitted)
assert.equal(result.epoch, 88)
assert.equal(result.now, 200)
assert.equal(result.overflow, 7499)
assert.equal(result.expired, 4)
assert.deepEqual(array(result.events), sourceBurst.slice(-512))
const expiredPrior = { ...prior, events: list([event("expired", 100)]) }
const expiredResult = J.ingest_capped(expiredPrior, 200, emission.events, emission.omitted)
assert.equal(expiredResult.overflow, 7498)
assert.equal(expiredResult.expired, 5, "source omission never increments expiry")
assert.equal(J.add_omitted({ ...prior, overflow: 0xffffffff }, 2).overflow, 1, "source counter uses declaredU32 wrap")
for (let seed = 0; seed < 100; seed++) {
  const old = Array.from({ length: 20 }, (_, i) => event(String((i * 7 + seed) % 17), 100))
  const incoming = Array.from({ length: 64 }, (_, i) => event(String((i * 11 + seed) % 37), 101))
  const ids = new Set(old.map((e) => e.id)),
    expected = [...old]
  for (const row of incoming)
    if (!ids.has(row.id)) {
      ids.add(row.id)
      expected.push(row)
    }
  assert.deepEqual(
    array(J.append_unique(list(incoming), list(old))),
    expected,
    "fast dedup agrees with independent FIFO/first-occurrence oracle"
  )
}
console.log(
  "PASS raw8000 source cap512/omitted7488 before JSON, exact state/counters, and100 independent fast-dedup oracles"
)
// Independent whole-playback oracle covers existing duplicated IDs, mixed
// future/due rows and exact FIFO/seen-ledger preservation through indexing.
for (let seed = 0; seed < 100; seed++) {
  const oldSeen = Array.from({ length: 20 }, (_, i) => ({
    $: "Seen" as const,
    id: String((i * 7 + seed) % 17),
    tick: 90 + (i % 5)
  }))
  const incoming = Array.from({ length: 64 }, (_, i) => event(String((i * 11 + seed) % 37), 95 + (i % 11)))
  const expectedSeen = [...oldSeen],
    ids = new Set(oldSeen.map((row) => row.id)),
    expectedEvents = []
  for (const row of incoming)
    if (row.tick <= 100 && !ids.has(row.id)) {
      ids.add(row.id)
      expectedSeen.unshift({ $: "Seen" as const, id: row.id, tick: row.tick })
      expectedEvents.push(row)
    }
  const out = J.play_rows(list(incoming), 17, list(oldSeen), 100)
  assert.equal(out.state.epoch, 17)
  assert.deepEqual(array(out.state.seen), expectedSeen.slice(0, 512))
  assert.deepEqual(array(out.events), expectedEvents)
}
const futureThenDue = J.play_rows(list([event("same", 101), event("same", 99)]), 3, list([]), 100)
assert.equal(array(futureThenDue.events).length, 1)
assert.equal(defined(defined(array(futureThenDue.events))[0]).tick, 99, "future row cannot poison later due membership")
console.log("PASS100 independent complete-playback oracles and future-before-due same-ID regression")
