import vm from "node:vm"
import ts from "typescript-compiler-api"
import { bendModule } from "../bend-module.mts"
import { at, defined } from "./host-values.mts"
// Execute the actual browser command producers with only their IO boundaries stubbed.
import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
const { default: ClientDelivery } = await bendModule<BendABI.CoopClientDelivery.API>()(
  pathToFileURL(resolve(at(process.argv, 2))),
  ["decode", "encode_command"]
)
const source = ts.transpileModule(await readFile(new URL("./coop-browser.mts", import.meta.url), "utf8"), {
  compilerOptions: { target: ts.ScriptTarget.ES2023, module: ts.ModuleKind.ESNext }
}).outputText
const functionSource = (name: string, next: string) => {
  const start = source.indexOf(`function ${name}(`)
  const end = source.indexOf(`function ${next}(`, start)
  assert.ok(start >= 0 && end > start, `actual browser ${name} producer exists`)
  return source.slice(start, end)
}
const commands = (wire: string) => {
  const decoded = ClientDelivery.decode(wire)
  assert.equal(decoded.$, "Some", "actual producer emits a canonical composite")
  if (decoded.$ !== "Some") throw Error("producer decode failed")
  assert.equal(decoded.value.receipt.$, "None")
  const rows = []
  for (let row = decoded.value.commands; row.$ === "Con"; row = row.tail) rows.push(row.head)
  return rows
}
const hostWrites: { wire: string; peer: number }[] = []
vm.runInNewContext(
  `
  const role='host',worker={},ui={};
  let sequence=0,sessionId=7,tick=19,prediction=null;
  const sentCommandTimes=new Map();
  ${functionSource("command", "signalConnection")}
  ${functionSource("sendAction", "flushClientDelivery")}
  assert.equal(sendAction({$:'Movement',x:2,y:1}),true);
  assert.equal(sendAction({$:'Choice',round:3,index:1}),true);
`,
  {
    ClientDelivery,
    defined,
    assert,
    performance,
    postCommand: (wire: string, peer: number) => {
      hostWrites.push({ wire, peer })
      return true
    }
  }
)
assert.deepEqual(
  hostWrites.map((row) => row.peer),
  [0, 0]
)
assert.deepEqual(
  hostWrites.map((row) => commands(row.wire)[0]),
  [
    { $: "Command", session: 7, player: 0, seq: 1, intendedTick: 19, action: { $: "Movement", x: 2, y: 1 } },
    { $: "Command", session: 7, player: 0, seq: 2, intendedTick: 19, action: { $: "Choice", round: 3, index: 1 } }
  ]
)

const guestWrites: string[] = []
const setup = { character: 2, arcana: 3, meta: 4, allowedWeapons: 5 }
vm.runInNewContext(
  `
  const role='guest',epoch=1,connectionEpoch=2,connected=true,sendControl=async()=>{};
  let sequence=0,sessionId=7,tick=19,prediction=null;
  const sentCommandTimes=new Map();
  const transportFailure=error=>{throw error;};
  ${functionSource("command", "signalConnection")}
  ${functionSource("connectionAction", "armConnectionDeadline")}
  connectionAction({$:'HelloAckAndSetup',version:1,token:42});
`,
  {
    ClientDelivery,
    defined,
    performance,
    selectedSetup: setup,
    transport: {
      send: async (wire: string) => {
        guestWrites.push(wire)
      }
    }
  }
)
await new Promise((resolve) => setImmediate(resolve))
assert.equal(guestWrites.length, 1)
assert.deepEqual(commands(at(guestWrites, 0)), [
  { $: "Command", session: 7, player: 1, seq: 1, intendedTick: 19, action: { $: "Setup", ...setup } }
])
console.log(
  JSON.stringify({
    status: "PASS",
    hostCommands: 2,
    guestSetup: 1,
    scope: "actual browser producers and emitted delivery codec; IO is stubbed"
  })
)
