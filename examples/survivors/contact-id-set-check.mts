import { bendModule } from "../bend-module.mts"
import { list } from "./host-values.mts"
import assert from "node:assert/strict"
import { performance } from "node:perf_hooks"
import { fileURLToPath, pathToFileURL } from "node:url"
const modulePath =
  process.env.CONTACT_ID_SET_MODULE || fileURLToPath(new URL("./dist/contact-id-set.mjs", import.meta.url))
const IdSet = (
  await bendModule<BendABI.ContactIdSet.API>()(pathToFileURL(modulePath).href, ["contains", "empty", "insert"])
).default
function compare(ids: string[], queries = ids) {
  let trie = IdSet.empty()
  const reference = new Set()
  for (const id of ids) {
    trie = IdSet.insert(trie, id)
    reference.add(id)
  }
  for (const query of queries) {
    assert.equal(IdSet.contains(trie, query), reference.has(query), `membership for ${JSON.stringify(query)}`)
  }
  return trie
}
function checkInsertEquation(ids: string[], queries: string[]) {
  let trie = IdSet.empty()
  for (const query of queries)
    assert.equal(IdSet.contains(trie, query), false, `empty set contains ${JSON.stringify(query)}`)
  for (const key of ids) {
    const before = trie
    const after = IdSet.insert(before, key)
    for (const query of queries) {
      assert.equal(
        IdSet.contains(after, query),
        key === query || IdSet.contains(before, query),
        `insert equation for ${JSON.stringify(key)} / ${JSON.stringify(query)}`
      )
    }
    trie = after
  }
}
const exactStrings = [
  "",
  "a",
  "ab",
  "abc",
  "abd",
  "ab",
  "a\0",
  "\0a",
  "contact:1",
  "contact:01",
  "contact:001",
  "contact:10",
  "é",
  "e\u0301",
  "終",
  "雪",
  "🙂",
  "🧩",
  "a🧩b"
]
compare(exactStrings, [...exactStrings, "ac", "abe", "contact:1x", "É", "🧩a", "a🧩"])
checkInsertEquation(exactStrings, [...exactStrings, "ac", "abe", "contact:1x", "É", "🧩a", "a🧩"])
const duplicateEdges = {
  $: "Node" as const,
  terminal: false,
  edges: list([
    { $: "Edge" as const, char: "a", child: IdSet.insert(IdSet.empty(), "x") },
    { $: "Edge" as const, char: "a", child: IdSet.insert(IdSet.empty(), "y") },
    { $: "Edge" as const, char: "b", child: IdSet.insert(IdSet.empty(), "z") }
  ])
}
assert.equal(IdSet.contains(duplicateEdges, "ax"), true)
assert.equal(IdSet.contains(duplicateEdges, "ay"), false, "lookup follows the first duplicate edge")
assert.equal(IdSet.contains(duplicateEdges, "bz"), true)
for (const key of ["ay", "ax", ""]) {
  const after = IdSet.insert(duplicateEdges, key)
  for (const query of ["", "ax", "ay", "az", "bz", "bq"]) {
    assert.equal(
      IdSet.contains(after, query),
      key === query || IdSet.contains(duplicateEdges, query),
      `duplicate-edge insertion equation for ${JSON.stringify(key)} / ${JSON.stringify(query)}`
    )
  }
}
const longPrefix = `${"same-prefix:".repeat(16)}🧩:`
const longIds = [`${longPrefix}1`, `${longPrefix}10`, `${longPrefix}100`, longPrefix, ""]
compare(longIds, [...longIds, `${longPrefix}2`, `${longPrefix.slice(0, -1)}x`])
checkInsertEquation(longIds, [...longIds, `${longPrefix}2`, `${longPrefix.slice(0, -1)}x`])
for (const count of [512, 8000]) {
  const ids = Array.from(
    { length: count },
    (_, index: number) => `cosmetic-contact:${"shared-prefix/".repeat(8)}${index}`
  )
  const queries = [...ids, `${ids[0]}x`, `${ids.at(-1)}x`, "cosmetic-contact:missing"]
  const start = performance.now()
  compare(ids, queries)
  const trieMilliseconds = performance.now() - start
  const referenceStart = performance.now()
  const reference = new Set(ids)
  let hits = 0
  for (const query of queries) if (reference.has(query)) hits++
  assert.equal(hits, count)
  const nativeSetMilliseconds = performance.now() - referenceStart
  console.log(
    `${count} exact IDs: trie insert+lookup ${trieMilliseconds.toFixed(2)}ms; native Set build+lookup ${nativeSetMilliseconds.toFixed(2)}ms`
  )
}
console.log(
  "PASS exact contact ID trie: empty/prefix IDs, numeric IDs, duplicates, Unicode, long shared prefixes, and distinct near-collisions"
)
