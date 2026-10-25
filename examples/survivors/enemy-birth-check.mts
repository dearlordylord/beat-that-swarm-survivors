import { bendModule } from "../bend-module.mts"
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"

const modulePath = process.env.COOP_GAME_MODULE
const { default: Game } = await bendModule<BendABI.Game.API>()(
  modulePath ? pathToFileURL(resolve(modulePath)) : new URL("./dist/web/dist/game.mjs", import.meta.url),
  ["team_enemy_birth_allowed"]
)

const dirty: BendABI.EnemyCombat.State = {
  $: "State",
  spatial: { $: "Spatial", x: 10, y: 20, age: 77, radius: 8 },
  archetype: 3,
  identity: 41,
  vitals: { $: "Vitals", health: 2, maximum: 100 },
  status: {
    $: "Status",
    slow: { $: "Slow", ticks: 0, frozen: true },
    burn: { $: "Burn", ticks: 37, sourcePlayer: { $: "Some", value: 0 } }
  }
}
const candidate: BendABI.EnemyLifecycle.Candidate = {
  $: "Candidate",
  x: 3000,
  y: 4000,
  archetype: 9,
  identity: 41,
  vitals: { $: "Vitals", health: 900, maximum: 900 },
  radius: 18
}
const phase: BendABI.EnemyCombat.Phase = { $: "Dormant", archetype: 3 }
// This is the production admission continuation, including the branch that
// constructs the replacement lifetime, rather than a direct birth helper call.
const admitted = Game.team_enemy_birth_allowed(true, phase, dirty, candidate)
assert.deepEqual(
  admitted,
  {
    $: "Resolved",
    outcome: {
      $: "Born",
      newborn: {
        $: "Newborn",
        candidate,
        age: 0,
        status: {
          $: "Status",
          slow: { $: "Slow", ticks: 0, frozen: false },
          burn: { $: "Burn", ticks: 0, sourcePlayer: { $: "None" } }
        },
        contactDamage: 0,
        killer: { $: "None" }
      }
    }
  },
  "enemy birth must clear previous status/contact/killer"
)
const rejected = Game.team_enemy_birth_allowed(false, phase, dirty, candidate)
assert.deepEqual(rejected, {
  $: "Resolved",
  outcome: {
    $: "Sleeping",
    enemy: {
      ...dirty,
      status: {
        $: "Status",
        slow: { $: "Slow", ticks: 0, frozen: false },
        burn: { $: "Burn", ticks: 0, sourcePlayer: { $: "None" } }
      }
    }
  }
})
console.log("PASS production enemy birth admission cleans status/contact and rejection preserves prior age")
