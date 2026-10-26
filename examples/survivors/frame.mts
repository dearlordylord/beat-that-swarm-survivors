import { object, number, text, boolean, array } from "./host-values.mts"
import {
  parseCoopCombatPredictionScene,
  parseCoopHitJournalState,
  parseCoopContactPlaybackFx
} from "./bend-codecs.generated.mts"
// Serialized presentation views from game.bend and coop-core.bend.
// These types carry observations; no simulation runs in the host.
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
export type Frame = Omit<ReturnType<typeof parseFrame>, "actorOrder"> & {
  actorOrder: DrawActorRef[]
  enemyFades?: EnemyFade[]
  localProjectiles?: LocalProjectile[]
}

export type CoopFrame = Frame & {
  combatForecast: BendABI.CoopCombatPrediction.Scene
  stepDistance: number
  predictionAllowed: boolean
  ownPlayerId: number
}
export function parseEnemy(value: unknown): Enemy {
  const row = object(value)
  return {
    x: number(row.x),
    y: number(row.y),
    age: number(row.age),
    radius: number(row.radius),
    archetype: number(row.archetype),
    identity: number(row.identity),
    health: number(row.health),
    maximum: number(row.maximum),
    lifetime: text(row.lifetime)
  }
}
export function parseProjectile(value: unknown): Projectile {
  const row = object(value)
  return {
    identity: number(row.identity),
    hostile: boolean(row.hostile),
    weapon: number(row.weapon),
    damage: number(row.damage),
    x: number(row.x),
    y: number(row.y),
    age: number(row.age),
    radius: number(row.radius),
    vx: number(row.vx),
    vy: number(row.vy),
    life: number(row.life),
    pierce: number(row.pierce),
    sourcePlayer: row.sourcePlayer === null ? null : number(row.sourcePlayer),
    weaponOwner: number(row.weaponOwner),
    logicalSlot: number(row.logicalSlot),
    birthTick: number(row.birthTick),
    lifetime: text(row.lifetime),
    tick: number(row.tick)
  }
}
export function parsePickup(value: unknown): Pickup {
  const row = object(value),
    item = object(row.item)
  let payload: PickupItem
  switch (item.kind) {
    case "xp":
      payload = { kind: "xp", amount: number(item.amount), accumulator: boolean(item.accumulator) }
      break
    case "gold":
      payload = { kind: "gold", coins: number(item.coins) }
      break
    case "healing":
      payload = { kind: "healing", health: number(item.health) }
      break
    case "chest":
      payload = { kind: "chest" }
      break
    case "relic":
      payload = { kind: "relic", stage: number(item.stage) }
      break
    default:
      throw new TypeError("Unknown pickup kind")
  }
  return {
    slot: number(row.slot),
    generation: number(row.generation),
    active: boolean(row.active),
    x: number(row.x),
    y: number(row.y),
    age: number(row.age),
    radius: number(row.radius),
    item: payload
  }
}
export function parseActorRef(value: unknown): ActorRef {
  const row = object(value)
  if (Object.keys(row).length !== 1) throw new TypeError("Invalid actor reference")
  if ("enemy" in row) return { enemy: number(row.enemy) }
  if ("projectile" in row) return { projectile: number(row.projectile) }
  if ("pickup" in row) return { pickup: number(row.pickup) }
  throw new TypeError("Unknown actor reference")
}
export function parseOffer(value: unknown): Offer {
  const row = object(value)
  return { kind: number(row.kind), id: number(row.id), level: number(row.level) }
}
function parsePlayer(value: unknown): Player {
  const row = object(value)
  return {
    id: number(row.id),
    px: number(row.px),
    py: number(row.py),
    hp: number(row.hp),
    maxHp: number(row.maxHp),
    character: number(row.character),
    alive: boolean(row.alive),
    connected: boolean(row.connected)
  }
}
function parseRemotePresentation(value: unknown) {
  const row = object(value)
  return {
    sampledAt: number(row.sampledAt),
    sourceTick: number(row.sourceTick),
    tick: number(row.tick),
    fraction: number(row.fraction),
    alpha: number(row.alpha),
    baseObservation: number(row.baseObservation),
    nextObservation: number(row.nextObservation),
    retainedFrames: number(row.retainedFrames),
    recovered: boolean(row.recovered),
    buffering: boolean(row.buffering)
  }
}
function parsePredictionTiming(value: unknown) {
  const row = object(value)
  return {
    anchorWorldTick: number(row.anchorWorldTick),
    displayWorldTick: number(row.displayWorldTick),
    lead: number(row.lead),
    inputAckDelayMs: number(row.inputAckDelayMs),
    resync: row.resync,
    server: row.server
  }
}
export function parseFrame(value: unknown) {
  const row = object(value)
  return {
    worldSize: number(row.worldSize),
    worldMargin: number(row.worldMargin),
    relicCollected: number(row.relicCollected),
    relicX: number(row.relicX),
    relicY: number(row.relicY),
    runLength: number(row.runLength),
    mode: number(row.mode),
    rerolls: number(row.rerolls),
    banishes: number(row.banishes),
    skips: number(row.skips),
    stage: number(row.stage),
    arcana: number(row.arcana),
    revivalsUsed: number(row.revivalsUsed),
    bossesKilled: number(row.bossesKilled),
    phase: number(row.phase),
    tick: number(row.tick),
    px: number(row.px),
    py: number(row.py),
    hp: number(row.hp),
    maxHp: number(row.maxHp),
    xp: number(row.xp),
    xpNeed: number(row.xpNeed),
    level: number(row.level),
    kills: number(row.kills),
    gold: number(row.gold),
    character: number(row.character),
    enemiesKilled: array(row.enemiesKilled, number),
    weapons: array(row.weapons, number),
    passives: array(row.passives, number),
    offers: array(row.offers, parseOffer),
    enemies: array(row.enemies, parseEnemy),
    projectiles: array(row.projectiles, parseProjectile),
    pickups: array(row.pickups, parsePickup),
    actorOrder: array(row.actorOrder, parseActorRef),
    ...(row.runId === undefined ? {} : { runId: text(row.runId) }),
    ...(row.ownPlayerId === undefined ? {} : { ownPlayerId: number(row.ownPlayerId) }),
    ...(row.coop === undefined ? {} : { coop: boolean(row.coop) }),
    players: array(row.players, parsePlayer),
    ...(row.roundId === undefined ? {} : { roundId: number(row.roundId) }),
    ...(row.rewardRound === undefined
      ? {}
      : { rewardRound: ((v: unknown) => ({ id: number(object(v).id) }))(row.rewardRound) }),
    ...(row.choicePending === undefined ? {} : { choicePending: boolean(row.choicePending) }),
    ...(row.predictionAllowed === undefined ? {} : { predictionAllowed: boolean(row.predictionAllowed) }),
    ...(row.stepDistance === undefined ? {} : { stepDistance: number(row.stepDistance) }),
    ...(row.observationSeq === undefined ? {} : { observationSeq: number(row.observationSeq) }),
    ...(row.combatForecast === undefined ? {} : { combatForecast: parseCoopCombatPredictionScene(row.combatForecast) }),
    ...(row.contactJournal === undefined ? {} : { contactJournal: parseCoopHitJournalState(row.contactJournal) }),
    ...(row.combatImpacts === undefined
      ? {}
      : { combatImpacts: ((v: unknown) => array(v, parseCoopContactPlaybackFx))(row.combatImpacts) }),
    ...(row.predictionTiming === undefined ? {} : { predictionTiming: parsePredictionTiming(row.predictionTiming) }),
    ...(row.remotePresentation === undefined
      ? {}
      : { remotePresentation: parseRemotePresentation(row.remotePresentation) })
  }
}
