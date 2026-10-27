import assert from "node:assert/strict"
import { test } from "node:test"
import { itemIcon, rewardIcon } from "./item-icons.mts"
import { ITEM_ICON_SHAPES } from "./item-icon-shapes.mts"
import { renderMenuContent } from "./menu-content.mts"
import { freshProfile } from "./progression.mts"

await test("all selected weapon, relic and innate icons render inline vector artwork", () => {
  for (const kind of ["weapon", "passive", "personal"] as const) {
    const count = kind === "weapon" ? 24 : kind === "passive" ? 18 : 7
    assert.equal(ITEM_ICON_SHAPES[kind].length, count)
    for (let id = 0; id < count; id++) {
      const markup = itemIcon(kind, id, 20)
      assert(markup.includes(`data-icon="${kind}/${id}"`))
      assert(markup.includes('width="20" height="20"'))
      assert.match(markup, /<path /)
      assert(!markup.includes("<text"))
      assert(!markup.includes("http:"))
    }
  }
})

await test("rewards distinguish weapon IDs from passive IDs and escape unsupported glyphs", () => {
  assert.equal(rewardIcon(0, 1, "?", 24), itemIcon("weapon", 1))
  assert.equal(rewardIcon(3, 1, "?", 24), itemIcon("weapon", 1))
  assert.equal(rewardIcon(1, 1, "?", 24), itemIcon("passive", 1))
  assert.notEqual(rewardIcon(0, 1, "?"), rewardIcon(1, 1, "?"))
  assert.equal(rewardIcon(5, 1, "<union>"), "&lt;union&gt;")
  assert.equal(itemIcon("weapon", 24), "")
})

await test("the collection uses vectors for every weapon, evolution and relic", () => {
  const state = { profile: freshProfile(), character: 0, stage: 0, arcana: 0, mode: 0 }
  for (const tab of ["weapons", "evolutions", "passives"]) {
    const html = renderMenuContent("collection", state, tab)
    const count = tab === "passives" ? 18 : 24
    const kind = tab === "passives" ? "passive" : "weapon"
    assert.equal((html.match(/class="item-icon"/g) || []).length, count)
    for (let id = 0; id < count; id++) assert(html.includes(`data-icon="${kind}/${id}"`))
  }
})
