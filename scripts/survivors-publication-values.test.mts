import { parseJson } from "../examples/survivors/host-values.mts"
import assert from "node:assert/strict"
import { test } from "node:test"
import {
  parseAstroVersion,
  parseDependency,
  parseHosting,
  parseReceipt,
  parseVersion
} from "./survivors-publication-values.mts"

const receipt = {
  schemaVersion: 2,
  siteProjectId: "site-project",
  commit: "revision",
  branch: "master",
  sourceSnapshot: "source/survivors",
  sourceFingerprint: "fingerprint",
  sourceFiles: { "game.bend": { sha256: "source-hash", mode: 0o644 } },
  files: { "index.html": "asset-hash" },
  dirty: false,
  dirtyFiles: [],
  build: { builtAt: "2026-10-25T12:00:00Z" }
}

await test("publication receipt parses every consumed nested field", () => {
  assert.deepEqual(parseReceipt(parseJson(JSON.stringify(receipt))), receipt)
  for (const malformed of [
    { ...receipt, build: null },
    { ...receipt, build: { builtAt: 4 } },
    { ...receipt, sourceFiles: { "game.bend": { sha256: "hash", mode: "644" } } },
    { ...receipt, sourceFiles: { "game.bend": { sha256: null, mode: 420 } } },
    { ...receipt, files: { "index.html": {} } },
    { ...receipt, dirtyFiles: [1] },
    { ...receipt, dirty: "false" },
    { ...receipt, sourceFingerprint: null }
  ])
    assert.throws(() => parseReceipt(malformed), TypeError)
})

await test("hosting rejects malformed shapes and preserves values for publication policy", () => {
  assert.deepEqual(parseHosting({ project_id: "project", static: { directory: "dist" } }), {
    project_id: "project",
    static: { directory: "dist" }
  })
  for (const malformed of [
    null,
    [],
    { project_id: 1 },
    { project_id: "project", static: [] },
    { project_id: "project", static: { directory: 1 } }
  ]) {
    assert.throws(() => parseHosting(malformed), TypeError)
  }
  assert.equal(parseHosting({ project_id: "", static: { directory: "old-output" } }).static?.directory, "old-output")
  assert.equal(parseReceipt({ ...receipt, schemaVersion: 1, branch: "other" }).schemaVersion, 1)
})

await test("remaining disk JSON fields are validated before consumption", () => {
  const version = { revision: "revision", branch: "master", sourceFingerprint: "hash", dirty: true, builtAt: "time" }
  assert.deepEqual(parseVersion(version), version)
  assert.throws(() => parseVersion({ ...version, dirty: 1 }), TypeError)
  assert.deepEqual(parseDependency({ bendVersion: "2.0.38", packages: {} }), { bendVersion: "2.0.38", packages: {} })
  assert.throws(() => parseDependency({ bendVersion: 2 }), TypeError)
  assert.equal(parseAstroVersion({ dependencies: { astro: "6" } }), "6")
  assert.equal(parseAstroVersion({}), null)
  assert.equal(parseAstroVersion({ dependencies: { astro: "" } }), null)
  assert.throws(() => parseAstroVersion({ dependencies: { astro: {} } }), TypeError)
  assert.throws(() => parseJson("{"), SyntaxError)
})
