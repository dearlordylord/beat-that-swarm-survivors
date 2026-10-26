import assert from "node:assert/strict"
import { readFileSync, writeFileSync } from "node:fs"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../../examples/bend-module.mts"
import { at } from "../../examples/survivors/host-values.mts"

const [commonPath, gamePath, sourcePath, output, targetText = "1200", stationary = "false"] = process.argv.slice(2)
assert.ok(
  commonPath && gamePath && sourcePath && output,
  "usage: qualification-trace-capture.mts COMMON.mjs GAME.mjs SOURCE.trace OUTPUT.trace [TICKS] [true|false]"
)
assert.ok(stationary === "true" || stationary === "false", "stationary must be true or false")
const [{ default: Common }, { default: Game }] = await Promise.all([
  bendModule<BendABI.NativeReplayCommon.API>()(pathToFileURL(resolve(commonPath)), ["start"]),
  bendModule<BendABI.Game.API>()(pathToFileURL(resolve(gamePath)), ["advance", "choose"])
])
function u32(text: string) {
  assert.match(text, /^\d+$/, "trace words must be decimal U32")
  const value = Number(text)
  assert.ok(Number.isInteger(value) && value >= 0 && value <= 0xffffffff, "trace word outside U32")
  return value
}
const words = readFileSync(sourcePath, "utf8").trim().split(/\s+/).map(u32)
assert.ok(words.length >= 9, "current replay requires all nine header words")
assert.equal(at(words, 0), 1313231410)
assert.equal(at(words, 1), 1)
const profile = at(words, 2),
  seed = at(words, 3),
  warmup = at(words, 4),
  endTick = at(words, 5),
  actualEnd = at(words, 6),
  finalPhase = at(words, 7),
  count = at(words, 8)
assert.ok(
  profile <= 1 && warmup <= actualEnd && actualEnd <= endTick && finalPhase <= 4,
  "invalid current replay header"
)
const decode = (word: number) => at(new Float32Array(new Uint32Array([word]).buffer), 0)
interface Move {
  tick: number
  dx: number
  dy: number
}
const moves: Move[] = []
let offset = 9
for (let index = 0; index < count; index++) {
  const opcode = at(words, offset++),
    tick = at(words, offset++),
    phase = at(words, offset++)
  if (opcode === 0) {
    const dx = at(words, offset++),
      dy = at(words, offset++)
    assert.ok(phase === 0 && Number.isFinite(decode(dx)) && Number.isFinite(decode(dy)), "invalid replay movement")
    moves.push({ tick, dx, dy })
  } else {
    assert.ok(opcode === 1 && (phase === 1 || phase === 2), "invalid replay upgrade")
    at(words, offset++)
  }
}
assert.equal(offset, words.length, "current replay count must consume the complete input")
assert.ok(stationary === "true" || moves.length > 0, "source trace must contain movement")
const target = u32(targetText),
  actions: string[] = []
let packet = Common.start(profile, seed),
  move = 0
while (packet.$ === "Packet" && packet.state.run.session.tick < target && actions.length < target * 2) {
  const run = packet.state.run.session
  if (run.phase === 0) {
    while (move + 1 < moves.length && at(moves, move + 1).tick <= run.tick) move++
    const { dx, dy } = stationary === "true" ? { dx: 0, dy: 0 } : at(moves, move)
    actions.push(`0 ${run.tick} 0 ${dx} ${dy}`)
    packet = Game.advance(packet.state, decode(dx), decode(dy))
  } else if (run.phase === 1 || run.phase === 2) {
    actions.push(`1 ${run.tick} ${run.phase} 0`)
    packet = Game.choose(packet.state, 0)
  } else break
}
assert.ok(packet.$ === "Packet", "actual public replay journey failed")
const run = packet.state.run.session
writeFileSync(
  output,
  `1313231410 1 ${profile} ${seed} 0 ${target} ${run.tick} ${run.phase} ${actions.length}\n${actions.join("\n")}\n`
)
console.log(
  JSON.stringify({ status: "passed", profile, seed, tick: run.tick, phase: run.phase, actions: actions.length })
)
