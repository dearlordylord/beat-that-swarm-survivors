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
