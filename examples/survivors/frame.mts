// Serialized presentation views from game.bend and coop-core.bend.
// These types carry observations; no simulation runs in the host.
export type Body = [
  number,
  number,
  number,
  number,
  number,
  number,
  number,
  number,
  number,
  (string | number)?,
  number?,
  number?,
  number?
]
export interface Offer {
  kind: number
  id: number
  level: number
}
export interface Player {
  id: number
  px: number
  py: number
  hp: number
  maxHp: number
  character: number
  alive?: boolean
}
export interface Frame {
  worldSize: number
  worldMargin: number
  relicCollected: number
  relicX: number
  relicY: number
  runLength: number
  enemiesKilled: number[]
  mode: number
  rerolls: number
  banishes: number
  skips: number
  stage: number
  arcana: number
  revivalsUsed: number
  bossesKilled: number
  phase: number
  tick: number
  px: number
  py: number
  hp: number
  maxHp: number
  xp: number
  xpNeed: number
  level: number
  kills: number
  gold: number
  character: number
  weapons: number[]
  passives: number[]
  offers: Offer[]
  bodies: Body[]
  runId?: string
  ownPlayerId?: number
  coop?: boolean
  players?: Player[]
  roundId?: number
  rewardRound?: { id: number }
  choicePending?: boolean
  predictionAllowed?: boolean
  stepDistance?: number
  observationSeq?: number
  combatForecast?: BendABI.CoopCombatPrediction.Scene
  contactJournal?: BendABI.CoopHitJournal.State
  combatImpacts?: BendABI.CoopContactPlayback.Fx[]
  predictionTiming?: {
    anchorWorldTick: number
    displayWorldTick: number
    lead: number
    inputAckDelayMs: number
    resync: unknown
    server: unknown
  }
  remotePresentation?: {
    sampledAt: number
    sourceTick: number
    tick: number
    fraction: number
    alpha: number
    baseObservation: number
    nextObservation: number
    retainedFrames: number
    recovered: boolean
    buffering: boolean
  }
}
