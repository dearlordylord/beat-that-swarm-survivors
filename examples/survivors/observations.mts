// Trusted local Bend ABI: reshape collections, never re-parse the simulation.
import { rows } from "./host-values.mts"
import type { Frame, Body, CoopFrame } from "./frame.mts"
function fields<T extends { $: string }>({ $: _tag, ...value }: T) {
  return value
}
function observation(value: BendABI.Game.Observation): Frame {
  const { $: _tag, bodies, offers, weapons, passives, enemiesKilled, ...scalars } = value
  return {
    ...scalars,
    bodies: rows(bodies).map((b): Body => [b.x, b.y, b.kind, b.variant, b.hp, b.maxHp, b.age, b.seed, b.radius]),
    offers: rows(offers).map(fields),
    weapons: rows(weapons),
    passives: rows(passives),
    enemiesKilled: rows(enemiesKilled)
  }
}
export function gameFrame(maybe: BendMaybe<BendABI.Game.Observation>): Frame | null {
  return maybe.$ === "None" ? null : observation(maybe.value)
}
export function coreFrame(maybe: BendMaybe<BendABI.CoopCore.Observation>) {
  if (maybe.$ === "None") return null
  const value = maybe.value
  if (value.$ === "Clock") return fields(value)
  const { $: _tag, players, requiredPlayers, ...scalars } = value.details
  const display = {
    ...observation(value.base),
    ...scalars,
    players: rows(players).map(fields),
    requiredPlayers: rows(requiredPlayers)
  }
  return display satisfies CoopFrame
}
export function projectileFrame(value: BendABI.CoopLocalProjectiles.RenderFrame) {
  return {
    shots: rows(value.shots).map(fields),
    contacts: rows(value.contacts).map(fields),
    corpses: rows(value.corpses).map(fields)
  }
}
