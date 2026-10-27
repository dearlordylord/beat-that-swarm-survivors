import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../bend-module.mts"
import { defined } from "./host-values.mts"
import { WEAPONS, PASSIVES, CHARACTERS, ARCANA, META_UPGRADES, ACHIEVEMENTS, UNIONS, COLLECTIONS } from "./content.mts"

const location = pathToFileURL(resolve(defined(process.argv[2])))
const { default: native } = await bendModule<BendABI.NativeContent.API>()(location, [
  "name",
  "description",
  "evolved_name",
  "evolved_description",
  "weapon_recipe",
  "evolution_passive",
  "starter"
])
const groups = [
  [WEAPONS, 0],
  [PASSIVES, 1],
  [CHARACTERS, 2],
  [ARCANA, 4],
  [META_UPGRADES, 5],
  [ACHIEVEMENTS, 7],
  [UNIONS, 8]
] as const
for (const [items, category] of groups) {
  for (const [index, item] of items.entries()) {
    assert.equal(native.name(category, index), item.name)
    assert.equal(native.description(category, index), item.description)
  }
}
assert.deepEqual(
  CHARACTERS.map((item) => item.name),
  ["Grove Scribe", "Hearth Voyager", "Ash Pianist", "Sunlit Stepper", "Swanward", "Sepia Wanderer", "Gilt Hare"]
)
assert.deepEqual(
  CHARACTERS.map((item) => item.weapon),
  [20, 21, 14, 22, 8, 23, 1]
)
for (const item of CHARACTERS) assert.equal(native.starter(item.id), item.weapon)
for (const item of WEAPONS) {
  assert.equal(native.evolution_passive(item.id), item.passive)
  assert.equal(native.evolved_name(item.id), item.evolvedName)
  assert.equal(native.evolved_description(item.id), item.evolvedDescription)
  assert.equal(COLLECTIONS.weapons[item.id]?.name, item.name)
  assert.equal(COLLECTIONS.evolutions[item.id]?.name, item.evolvedName)
  assert.ok(native.weapon_recipe(item.id).includes(item.evolvedName))
  assert.ok(native.weapon_recipe(item.id).includes(defined(PASSIVES[item.passive]).name))
}
console.log("PASS seven characters and all themed native/browser names, descriptions, recipes and collections agree")
