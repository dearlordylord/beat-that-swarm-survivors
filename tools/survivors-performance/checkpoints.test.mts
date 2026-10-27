import assert from "node:assert/strict"
import { test } from "node:test"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join, resolve } from "node:path"
import { gzipSync } from "node:zlib"
import {
  captureCheckpoint,
  compareCheckpoints,
  json,
  loadEngine,
  measureWindow,
  readCheckpoint
} from "./checkpoints.mts"

const modulePath = process.env.SURVIVORS_PERF_TEST_MODULE ?? resolve("examples/survivors/dist/web/dist/game.mjs")

await test("checkpoint JSON rejects values JSON.stringify would silently change or omit", () => {
  for (const value of [undefined, { action() {} }, { counter: 1n }, { value: NaN }, new Date(), [undefined]])
    assert.throws(() => json(value), /Checkpoint/)
  const cycle: { next?: unknown } = {}
  cycle.next = cycle
  assert.throws(() => json(cycle), /cycle/)
  assert.equal(json({ tick: 1, values: [0, true, null] }), '{"tick":1,"values":[0,true,null]}')
})

await test("real Bend checkpoint restores independently and enforces compatibility and replay digests", async () => {
  const directory = await mkdtemp(join(tmpdir(), "survivors-checkpoint-test-"))
  try {
    const file = join(directory, "early.json.gz")
    const fixture = await captureCheckpoint(modulePath, file, {
      character: 4,
      seed: 12345,
      tick: 1,
      steps: 3,
      dx: 1,
      dy: 0
    })
    const restored = await readCheckpoint(file)
    assert.equal(restored.stateJson, fixture.stateJson)
    const engine = await loadEngine(modulePath)
    const first = measureWindow(engine, restored),
      second = measureWindow(engine, restored)
    assert.equal(first.end.tick, 4)
    assert.deepEqual(first.end, second.end)
    assert.equal(first.errors, 0)
    assert.throws(() => measureWindow({ ...engine, moduleSha256: "changed" }, restored), /Module hash differs/)
    assert.equal(measureWindow({ ...engine, moduleSha256: "changed" }, restored, true).end.tick, 4)
    assert.throws(
      () => measureWindow(engine, { ...restored, initial: { ...restored.initial, digest: "wrong" } }),
      /initial observation differs/
    )
    assert.throws(
      () => measureWindow(engine, { ...restored, expected: { ...restored.expected, digest: "wrong" } }),
      /Replay result differs/
    )
    const corrupt = join(directory, "corrupt.json.gz")
    await writeFile(corrupt, gzipSync(json({ ...restored, stateSha256: "wrong" })))
    await assert.rejects(readCheckpoint(corrupt), /checksum mismatch/)
    const report = await compareCheckpoints(
      { checkpoint: file, module: modulePath },
      { checkpoint: file, module: modulePath },
      1
    )
    assert.equal(report.rows.length, 2)
    assert.ok(report.rows.every((row) => row.end.tick === 4 && row.errors === 0))
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})
