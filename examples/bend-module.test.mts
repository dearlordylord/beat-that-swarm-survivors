import assert from "node:assert/strict"
import { test } from "node:test"
import { mkdtemp, writeFile, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import path from "node:path"
import { spawnSync } from "node:child_process"
import { bendModule } from "./bend-module.mts"

interface API {
  answer(): number
  extra(): number
}
const moduleUrl = (source: string) => `data:text/javascript,${encodeURIComponent(source)}`
await test("exposes required and present optional callable exports from a loaded module", async () => {
  const { default: api } = await bendModule<API>()(moduleUrl("export default {answer:()=>42}"), ["answer"], ["extra"])
  assert.equal(api.answer(), 42)
  assert.equal(api.extra, undefined)
  const loaded = await bendModule<API>()(moduleUrl("export default {answer:()=>42,extra:()=>7}"), ["answer"], ["extra"])
  assert.equal(loaded.default.extra?.(), 7)
})
await test("rejects missing, invalid and malformed module exports at import time", async () => {
  for (const source of ["export default null", "export default {}", "export default {answer:42}"])
    await assert.rejects(bendModule<API>()(moduleUrl(source), ["answer"]), TypeError)
  await assert.rejects(
    bendModule<API>()(moduleUrl("export default {answer:()=>42,extra:7}"), ["answer"], ["extra"]),
    TypeError
  )
})
await test("quality gate rejects the previously accepted implicit-any JSON assignment", async () => {
  const directory = await mkdtemp(path.join(tmpdir(), "bendvy-unsafe-gate-"))
  try {
    const fixture = path.join(directory, "unsafe.mts")
    await writeFile(
      fixture,
      'const input: {score:number} = JSON.parse(\'{"score":"wrong"}\'); console.log(input.score.toFixed(2));\n'
    )
    const result = spawnSync(
      process.execPath,
      [
        path.resolve("node_modules/oxlint/bin/oxlint"),
        "--config",
        path.resolve(".oxlintrc.json"),
        "--deny-warnings",
        fixture
      ],
      { encoding: "utf8", timeout: 30000 }
    )
    assert.ifError(result.error)
    assert.notEqual(result.status, 0)
    assert.match(result.stdout + result.stderr, /no-unsafe-assignment/)
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})

await test("TypeScript rejects constructing a transport before its native resource exists", async () => {
  const directory = await mkdtemp(path.join(tmpdir(), "bendvy-private-transport-"))
  try {
    const fixture = path.join(directory, "transport.mts")
    await writeFile(
      fixture,
      `import { CoopTransport } from ${JSON.stringify(path.resolve("examples/survivors/coop-transport.mts"))};\nnew CoopTransport(() => {});\n`
    )
    const result = spawnSync(
      path.resolve("node_modules/.bin/tsc"),
      [
        "--ignoreConfig",
        "--strict",
        "--noEmit",
        "--skipLibCheck",
        "--target",
        "ES2023",
        "--module",
        "NodeNext",
        "--allowImportingTsExtensions",
        "--typeRoots",
        path.resolve("node_modules/@types"),
        "--types",
        "node",
        fixture,
        path.resolve(".typescript/bend.d.ts")
      ],
      { encoding: "utf8", timeout: 30000 }
    )
    assert.ifError(result.error)
    assert.notEqual(result.status, 0)
    assert.match(result.stdout + result.stderr, /constructor.*private|private.*constructor/i)
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})
