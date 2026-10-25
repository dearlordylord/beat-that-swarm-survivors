// Trusted local Bend Data is projected directly; network validation lives at ingress.
import { rows } from "./host-values.mts"
import type { Frame, Enemy, Projectile, Pickup, PickupItem, ActorRef, CoopFrame } from "./frame.mts"
function fields<T extends { $: string }>({ $: _tag, ...value }: T) {
  return value
}
function enemy(value: BendABI.EnemyCombat.State, tick: number): Enemy {
  const { spatial, archetype, identity, vitals } = value
  return {
    ...fields(spatial),
    archetype,
    identity,
    ...fields(vitals),
    lifetime: `enemy:${identity}:${tick - Math.min(tick, spatial.age)}`
  }
}
function projectile(value: BendABI.ProjectileState.State, tick: number): Projectile {
  const { spatial, identity, side, payload, trajectory } = value
  const { vx, vy, life, pierce, weaponOwner, logicalSlot, sourcePlayer } = trajectory
  const source = sourcePlayer.$ === "Some" ? sourcePlayer.value : null
  const born = (tick - spatial.age) >>> 0
  const hostile = side.$ === "HostileShot"
  const lifetime = hostile
    ? `hostile:${identity}:${born}`
    : source === null
      ? `unowned-projectile:${identity}:${born}`
      : `${source}:${born}:${weaponOwner}:${logicalSlot}`
  return {
    ...fields(spatial),
    identity,
    hostile,
    weapon: payload.weapon,
    damage: payload.damage,
    vx,
    vy,
    life,
    pierce,
    weaponOwner,
    logicalSlot,
    sourcePlayer: source,
    birthTick: born,
    lifetime,
    tick
  }
}
function pickupItem(value: BendABI.PickupState.Item): PickupItem {
  switch (value.$) {
    case "Xp":
      return { kind: "xp", amount: value.amount, accumulator: value.accumulator }
    case "Gold":
      return { kind: "gold", coins: value.coins }
    case "Healing":
      return { kind: "healing", health: value.health }
    case "Chest":
      return { kind: "chest" }
    case "Relic":
      return { kind: "relic", stage: value.stage }
    default: {
      const exhaustive: never = value
      return exhaustive
    }
  }
}
function pickup(value: BendABI.PickupState.State): Pickup {
  return {
    ...fields(value.spatial),
    slot: value.identity,
    generation: value.payload.generation,
    active: value.payload.active,
    item: pickupItem(value.payload.item)
  }
}
function actorRef(value: BendABI.Game.ActorRef): ActorRef {
  switch (value.$) {
    case "EnemyRef":
      return { enemy: value.identity }
    case "ProjectileRef":
      return { projectile: value.identity }
    case "PickupRef":
      return { pickup: value.identity }
    default: {
      const exhaustive: never = value
      return exhaustive
    }
  }
}
export function gameFrame(value: BendABI.Game.Observation): Frame {
  const session = value.run.session,
    player = value.run.player
  return {
    ...fields(value.presentation),
    phase: session.phase,
    tick: session.tick,
    xp: session.xp,
    xpNeed: session.xpNeed,
    level: session.level,
    kills: session.kills,
    gold: session.gold,
    stage: session.stage,
    bossesKilled: session.bosses,
    mode: session.mode,
    relicCollected: session.relicCollected,
    px: player.px,
    py: player.py,
    hp: player.hp,
    maxHp: player.maxHp,
    character: player.character,
    arcana: player.arcana,
    revivalsUsed: player.revivals,
    rerolls: player.rerolls,
    banishes: player.banishes,
    skips: player.skips,
    enemiesKilled: rows(session.enemyKinds),
    weapons: rows(player.weapons),
    passives: rows(player.passives),
    players: [
      {
        id: 0,
        px: player.px,
        py: player.py,
        hp: player.hp,
        maxHp: player.maxHp,
        character: player.character,
        connected: true,
        alive: player.hp > 0
      }
    ],
    offers: rows(value.offers).map(fields),
    enemies: rows(value.enemies).map((v) => enemy(v, session.tick)),
    projectiles: rows(value.projectiles).map((v) => projectile(v, session.tick)),
    pickups: rows(value.pickups).map(pickup),
    actorOrder: rows(value.order).map(actorRef)
  }
}
export function coreFrame(value: BendABI.CoopCore.Observation) {
  switch (value.$) {
    case "NoObservation":
      return null
    case "StepObservation":
      return fields(value)
    case "ViewObservation": {
      const display = {
        ...gameFrame(value.game),
        predictionAllowed: value.predictionAllowed,
        stepDistance: value.stepDistance,
        ownPlayerId: value.ownPlayerId,
        choicePending: value.choicePending,
        roundId: value.round,
        rewardRound: { id: value.round },
        requiredPlayers: rows(value.required),
        coop: true,
        players: rows(value.players).map(({ id, player, connected }) => ({
          id,
          connected,
          px: player.px,
          py: player.py,
          hp: player.hp,
          maxHp: player.maxHp,
          character: player.character,
          alive: player.hp > 0
        })),
        combatForecast: value.forecast
      }
      return display satisfies CoopFrame
    }
    default: {
      const exhaustive: never = value
      return exhaustive
    }
  }
}
export function projectileFrame(value: BendABI.CoopLocalProjectiles.RenderFrame) {
  return {
    shots: rows(value.shots).map(fields),
    contacts: rows(value.contacts).map(fields),
    corpses: rows(value.corpses).map(fields)
  }
}
