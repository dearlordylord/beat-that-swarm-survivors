import assert from "node:assert/strict"
import { test } from "node:test"
import { SurvivorLocomotion } from "./survivor-locomotion.mts"

await test("walking follows each player's traveled distance and returns to idle when stopped", () => {
  const gait = new SurvivorLocomotion()
  assert.equal(gait.frame(0, 0, 0, 0, true), -1)
  assert.equal(gait.frame(0, 18, 0, 1, true), 1)
  assert.equal(gait.frame(0, 36, 0, 2, true), 2)
  assert.equal(gait.frame(0, 36, 0, 2, true), 2, "repeated snapshot retains its pose")
  assert.equal(gait.frame(1, 36, 0, 2, true), -1, "other player starts independently")
  assert.equal(gait.frame(0, 36, 0, 3, true), -1)
  assert.equal(gait.frame(1, 36, 18, 3, true), 1, "vertical travel also drives the cycle")
  assert.equal(gait.frame(0, 36, 18, 4, false), -1, "reduced motion or death disables the cycle")
})

await test("teleports, stale ticks and player departure cannot create a false stride", () => {
  const gait = new SurvivorLocomotion()
  gait.frame(0, 0, 0, 0, true)
  assert.equal(gait.frame(0, 1000, 0, 1, true), -1)
  assert.equal(gait.frame(0, 1006, 0, 30, true), -1)
  assert.equal(gait.frame(0, 1012, 0, 29, true), -1)
  gait.retain(new Set())
  assert.equal(gait.frame(0, 1018, 0, 30, true), -1)
})

await test("gait depends on distance rather than rendering frequency or movement direction", () => {
  const gait = new SurvivorLocomotion()
  gait.frame(0, 0, 0, 0, true)
  gait.frame(1, 0, 0, 0, true)
  const a = gait.frame(0, 36, 0, 1, true)
  gait.frame(1, 0, -18, 1, true)
  assert.equal(gait.frame(1, 0, -36, 2, true), a)
  gait.frame(0, 72, 0, 2, true)
  gait.frame(0, 108, 0, 3, true)
  assert.equal(gait.frame(0, 144, 0, 4, true), 0, "the cycle wraps without changing stride distance")
})

await test("180 world units per second gives a 48-tick walk cycle at 60 simulation ticks per second", () => {
  const gait = new SurvivorLocomotion()
  gait.frame(0, 0, 0, 0, true)
  const frames = Array.from({ length: 48 }, (_, index) => gait.frame(0, (index + 1) * 3, 0, index + 1, true))
  assert.equal(new Set(frames).size, 8)
  assert.equal(frames[4], 0)
  assert.equal(frames[5], 1)
  assert.equal(frames[46], 7)
  assert.equal(frames[47], 0)
})
