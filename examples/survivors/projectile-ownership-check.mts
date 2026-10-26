import { bendModule } from "../bend-module.mts"
import { at, rows as array, some } from "./host-values.mts"
// Exercise the actual scheduling/allocation/query path for both player sources.
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
const { default: C } = await bendModule<BendABI.CoopCore.API>()(pathToFileURL(resolve(at(process.argv, 2))), [
  "core_start",
  "core_join",
  "core_choose",
  "core_step"
])
let packet = C.core_start(0, 0, 100)
assert.equal(packet.$, "CorePacket")
if (packet.$ !== "CorePacket") throw Error("start failed")
packet = C.core_join(packet.state, 1, 0, 0)
const seen = new Set<number>()
for (let step = 0; step < 120; step++) {
  if (packet.$ !== "CorePacket") throw Error("transition failed")
  const state = packet.state
  if (state.shared.phase === 1 || state.shared.phase === 2) {
    for (const id of array(state.required)) {
      assert.ok(packet.$ === "CorePacket")
      packet = C.core_choose(packet.state, id, packet.state.round, 0)
    }
  } else packet = C.core_step(state, 1, 0, 0, 1)
  assert.equal(packet.$, "CorePacket")
  if (packet.$ !== "CorePacket") throw Error("transition failed")
  for (const snapshot of array(packet.state.snapshots)) {
    if (snapshot.$ !== "ProjectileSnapshot" || !snapshot.projectile.payload.active) continue
    const shot = snapshot.projectile,
      trajectory = shot.trajectory
    assert.ok(trajectory.logicalSlot < 8, "spread slot is local, never a packed player identity")
    if (shot.side.$ === "HostileShot") assert.deepEqual(trajectory.sourcePlayer, { $: "None" })
    else {
      assert.equal(trajectory.sourcePlayer.$, "Some")
      assert.ok([0, 1].includes(some(trajectory.sourcePlayer)))
      seen.add(some(trajectory.sourcePlayer))
      assert.equal(
        shot.identity % 2,
        some(trajectory.sourcePlayer),
        "allocation keeps the established per-player parity"
      )
      assert.equal(
        trajectory.weaponOwner,
        some(trajectory.sourcePlayer),
        "fixture starters preserve their distinct weapon ownership"
      )
    }
  }
}
assert.deepEqual(
  [...seen].sort((a, b) => a - b),
  [0, 1]
)
console.log("PASS actual projectile player identity, weapon ownership and local emission slots")
