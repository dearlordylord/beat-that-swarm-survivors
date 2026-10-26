export interface Enemy {
  opacity?: number
  tick?: number
  x: number
  y: number
  age: number
  radius: number
  archetype: number
  identity: number
  health: number
  maximum: number
  lifetime: string
}
export interface Projectile {
  opacity?: number
  identity: number
  hostile: boolean
  weapon: number
  damage: number
  x: number
  y: number
  age: number
  radius: number
  vx: number
  vy: number
  life: number
  pierce: number
  sourcePlayer: number | null
  weaponOwner: number
  logicalSlot: number
  birthTick: number
  lifetime: string
  tick: number
}
export type PickupItem =
  | { kind: "xp"; amount: number; accumulator: boolean }
  | { kind: "gold"; coins: number }
  | { kind: "healing"; health: number }
  | { kind: "chest" }
  | { kind: "relic"; stage: number }
export interface Pickup {
  lifetime?: string
  tick?: number
  opacity?: number
  slot: number
  generation: number
  active: boolean
  x: number
  y: number
  age: number
  radius: number
  item: PickupItem
}
export type ActorRef = { enemy: number } | { projectile: number } | { pickup: number }
export type DrawActorRef = ActorRef | { enemyFade: string } | { localProjectile: string }
export type EnemyFade = Enemy
export type LocalProjectile = Pick<
  Projectile,
  "identity" | "lifetime" | "hostile" | "weapon" | "age" | "x" | "y" | "radius"
> & { sourcePlayer: number; life: number; opacity: number }
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
  alive: boolean
  connected: boolean
}
export interface Frame {
  worldSize: number
  worldMargin: number
  relicCollected: number
  relicX: number
  relicY: number
  runLength: number
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
  enemiesKilled: number[]
  weapons: number[]
  passives: number[]
  offers: Offer[]
  enemies: Enemy[]
  projectiles: Projectile[]
  pickups: Pickup[]
  actorOrder: DrawActorRef[]
  runId?: string
  ownPlayerId?: number
  coop?: boolean
  players: Player[]
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
  enemyFades?: EnemyFade[]
  localProjectiles?: LocalProjectile[]
}

export type CoopFrame = Frame & {
  combatForecast: BendABI.CoopCombatPrediction.Scene
  stepDistance: number
  predictionAllowed: boolean
  ownPlayerId: number
}
