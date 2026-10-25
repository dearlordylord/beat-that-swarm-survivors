import { array, number, object, text } from "../../examples/survivors/host-values.mts"
import { parseFrame } from "../../examples/survivors/frame.mts"
import type { Frame, Offer } from "../../examples/survivors/frame.mts"
export type { Frame, Offer }
export interface Point {
  x: number
  y: number
}
export interface MechanicsCurrent {
  hp: number
  maxHp: number
  gold: number
  weapons: number[]
  passives: number[]
  speedMultiplier: number
  pickupRadius: number
  xpAwardFor100BaseXp: number
  durationMultiplier: number
  projectileSpeedMultiplier: number
  weaponStats: {
    id: number
    rank: number
    baseHitDamage: number
    cooldownTicks: number
    selfFieldRadius: number
    areaMultiplier: number
  }[]
}
export interface Mechanics {
  source: string
  notes?: string
  current: MechanicsCurrent
  offers: { offerIndex: number; offer: Offer; after: MechanicsCurrent }[]
  resourceRules?: { xpDefaultValue?: number }
}
export interface Goal {
  id: string
  kind: string
  target: Point
  distance: number
  observedTick: number
  resource?: { baseXp: number; generation: number; autoClaimTicks: null }
  reward?: { xp?: number }
  experience?: number
}
export interface History {
  tick: number
  hp: number
  action?: string
  offer?: Offer | undefined
  goal?: string
  target?: Point | null
}
export interface ClassifierResponse {
  runId: string
  decisionSeq: number
  candidatesHash: string
  selectedCandidateId: string
  model?: string
  latencyMs?: number
  usage?: unknown
  probabilities?: unknown
}
export type Classify = (request: unknown, options: { timeoutMs: number }) => Promise<ClassifierResponse>
export type Emit = (record: unknown) => void

function parseOffer(value: unknown): Offer {
  const row = object(value)
  return { ...row, kind: number(row.kind), id: number(row.id), level: number(row.level) }
}
function parseCurrent(value: unknown): MechanicsCurrent {
  const row = object(value)
  return {
    ...row,
    hp: number(row.hp),
    maxHp: number(row.maxHp),
    gold: number(row.gold),
    weapons: array(row.weapons, number),
    passives: array(row.passives, number),
    speedMultiplier: number(row.speedMultiplier),
    pickupRadius: number(row.pickupRadius),
    xpAwardFor100BaseXp: number(row.xpAwardFor100BaseXp),
    durationMultiplier: number(row.durationMultiplier),
    projectileSpeedMultiplier: number(row.projectileSpeedMultiplier),
    weaponStats: array(row.weaponStats, (value) => {
      const stat = object(value)
      return {
        ...stat,
        id: number(stat.id),
        rank: number(stat.rank),
        baseHitDamage: number(stat.baseHitDamage),
        cooldownTicks: number(stat.cooldownTicks),
        selfFieldRadius: number(stat.selfFieldRadius),
        areaMultiplier: number(stat.areaMultiplier)
      }
    })
  }
}
export function parseMechanics(value: unknown): Mechanics {
  const row = object(value)
  return {
    ...row,
    source: text(row.source),
    current: parseCurrent(row.current),
    ...(row.notes === undefined ? {} : { notes: text(row.notes) }),
    offers: array(row.offers, (value) => {
      const offer = object(value)
      return {
        ...offer,
        offerIndex: number(offer.offerIndex),
        offer: parseOffer(offer.offer),
        after: parseCurrent(offer.after)
      }
    }),
    ...(row.resourceRules === undefined ? {} : { resourceRules: parseResourceRules(row.resourceRules) })
  }
}
function parseResourceRules(value: unknown): NonNullable<Mechanics["resourceRules"]> {
  const row = object(value)
  return row.xpDefaultValue === undefined ? row : { ...row, xpDefaultValue: number(row.xpDefaultValue) }
}
export function parseGoals(value: unknown): Goal[] {
  return array(value, (value) => {
    const row = object(value),
      target = object(row.target)
    const goal: Goal = {
      ...row,
      id: text(row.id),
      kind: text(row.kind),
      target: { x: number(target.x), y: number(target.y) },
      distance: number(row.distance),
      observedTick: number(row.observedTick)
    }
    if (row.resource !== undefined) {
      const resource = object(row.resource)
      if (resource.autoClaimTicks !== null) throw new TypeError("Expected persistent resource")
      goal.resource = {
        ...resource,
        baseXp: number(resource.baseXp),
        generation: number(resource.generation),
        autoClaimTicks: null
      }
    }
    if (row.reward !== undefined) {
      const reward = object(row.reward)
      goal.reward = reward.xp === undefined ? reward : { ...reward, xp: number(reward.xp) }
    }
    if (row.experience !== undefined) goal.experience = number(row.experience)
    return goal
  })
}
export function parseObservation(value: unknown) {
  const row = object(value)
  return {
    sequence: number(row.sequence),
    frame: parseFrame(row.frame),
    actions: parseGoals(row.actions),
    mechanics: parseMechanics(row.mechanics)
  }
}
