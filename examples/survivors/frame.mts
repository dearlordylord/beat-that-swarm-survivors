import { object, number, text, boolean, array } from "./host-values.mts"
import {
  parseCoopCombatPredictionScene,
  parseCoopHitJournalState,
  parseCoopContactPlaybackFx
} from "./bend-codecs.generated.mts"
// Serialized presentation views from game.bend and coop-core.bend.
// These types carry observations; no simulation runs in the host.
export type Body = [
  x: number,
  y: number,
  kind: number,
  variant: number,
  hp: number,
  maxHp: number,
  age: number,
  seed: number,
  radius: number,
  generation?: string | number,
  owner?: number,
  sourceTick?: number,
  opacity?: number
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
export type Frame = ReturnType<typeof parseFrame>

export type CoopFrame = Frame & {
  combatForecast: BendABI.CoopCombatPrediction.Scene
  stepDistance: number
  predictionAllowed: boolean
  ownPlayerId: number
}
export function parseBody(value: unknown): Body {
  if (!Array.isArray(value) || value.length < 9 || value.length > 13)
    throw new TypeError("Expected serialized Body tuple")
  const result: Body = [
    number(value[0]),
    number(value[1]),
    number(value[2]),
    number(value[3]),
    number(value[4]),
    number(value[5]),
    number(value[6]),
    number(value[7]),
    number(value[8])
  ]
  if (value.length > 9) result[9] = typeof value[9] === "string" ? text(value[9]) : number(value[9])
  if (value.length > 10) result[10] = number(value[10])
  if (value.length > 11) result[11] = number(value[11])
  if (value.length > 12) result[12] = number(value[12])
  return result
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
    ...(row.alive === undefined ? {} : { alive: boolean(row.alive) })
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
    bodies: array(row.bodies, parseBody),
    ...(row.runId === undefined ? {} : { runId: text(row.runId) }),
    ...(row.ownPlayerId === undefined ? {} : { ownPlayerId: number(row.ownPlayerId) }),
    ...(row.coop === undefined ? {} : { coop: boolean(row.coop) }),
    ...(row.players === undefined ? {} : { players: ((v: unknown) => array(v, parsePlayer))(row.players) }),
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
export function parseCoopFrame(value: unknown): CoopFrame {
  const parsed = parseFrame(value)
  const { combatForecast, stepDistance, predictionAllowed, ownPlayerId } = parsed
  if (
    combatForecast === undefined ||
    stepDistance === undefined ||
    predictionAllowed === undefined ||
    ownPlayerId === undefined
  )
    throw new TypeError("Missing co-op frame contract")
  return { ...parsed, combatForecast, stepDistance, predictionAllowed, ownPlayerId }
}
