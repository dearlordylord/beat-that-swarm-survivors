import assert from "node:assert/strict"
import { defined } from "../../examples/survivors/host-values.mts"
import type { RenderRow } from "./coop-browser-trace.mts"

type CoordinateSample = Pick<RenderRow, "players" | "enemies"> & { sampledAt: number }
function coordinates(row: RenderRow): CoordinateSample {
  const sampledAt = defined(row.presentationMeasurement).sampledAt
  assert.ok(Number.isFinite(sampledAt), "motion coordinates require their presentation sample clock")
  return { sampledAt, players: row.players, enemies: row.enemies }
}
function p95(values: number[]) {
  const sorted = [...values].sort((a, b) => a - b)
  return sorted[Math.max(0, Math.ceil(sorted.length * 0.95) - 1)] ?? 0
}
// Fixed default-character trajectory oracle, not a universal enemy physics bound.
export function motionOracle(rows: RenderRow[], startWall: number) {
  const warmAt = startWall + 5000,
    hostSteps: number[] = [],
    enemySteps: number[] = [],
    violations: unknown[] = []
  let activeSamples = 0,
    bufferedSamples = 0,
    bufferEntries = 0,
    bufferExits = 0,
    recoveryEntries = 0
  for (let index = 0; index < rows.length; index++) {
    const row = defined(rows[index]),
      previous = rows[index - 1]
    if (row.wall < warmAt || row.phase !== 0) continue
    activeSamples++
    if (row.remotePresentation?.buffering) bufferedSamples++
    const continuous =
      previous &&
      previous.wall >= warmAt &&
      previous.phase === 0 &&
      previous.runId === row.runId &&
      previous.round === row.round
    if (!continuous) continue
    if (row.remotePresentation?.buffering && !previous.remotePresentation?.buffering) bufferEntries++
    if (!row.remotePresentation?.buffering && previous.remotePresentation?.buffering) bufferExits++
    if (row.remotePresentation?.recovered && !previous.remotePresentation?.recovered) recoveryEntries++
    const currentSample = coordinates(row),
      previousSample = coordinates(previous)
    const elapsedMs = currentSample.sampledAt - previousSample.sampledAt
    if (!(elapsedMs > 0 && elapsedMs <= 250)) continue
    const oldHost = previousSample.players?.find((player) => player.id === 0),
      host = currentSample.players?.find((player) => player.id === 0)
    if (
      host &&
      oldHost &&
      host.character === oldHost.character &&
      host.character === 0 &&
      host.alive &&
      oldHost.alive
    ) {
      const distance = Math.hypot(host.px - oldHost.px, host.py - oldHost.py),
        allowed = 4 * ((elapsedMs * 60) / 1000) + 1
      assert.ok(Number.isFinite(distance), "remote host coordinates must be finite")
      hostSteps.push(distance / ((elapsedMs * 60) / 1000))
      if (distance > allowed)
        violations.push({
          wall: row.wall,
          elapsedMs,
          drawElapsedMs: row.at - previous.at,
          distance,
          allowed,
          previousTick: previous.tick,
          tick: row.tick,
          previousPresentation: previous.remotePresentation,
          presentation: row.remotePresentation
        })
    }
    const oldEnemies = new Map(previousSample.enemies.map((enemy) => [`${enemy.identity}:${enemy.lifetime}`, enemy]))
    for (const enemy of currentSample.enemies) {
      const old = oldEnemies.get(`${enemy.identity}:${enemy.lifetime}`)
      if (old) {
        const distance = Math.hypot(enemy.x - old.x, enemy.y - old.y)
        if (Number.isFinite(distance)) enemySteps.push(distance / ((elapsedMs * 60) / 1000))
      }
    }
  }
  return {
    clock: "browser presentation coordinate sample performance.now()",
    warmupMs: 5000,
    maxPairGapMs: 250,
    host: {
      samples: hostSteps.length,
      maxUnitsPerWallTick: hostSteps.length ? Math.max(...hostSteps) : 0,
      p95UnitsPerWallTick: p95(hostSteps),
      violationCount: violations.length,
      violations: violations.slice(0, 12)
    },
    enemies: {
      samples: enemySteps.length,
      maxUnitsPerWallTick: enemySteps.length ? Math.max(...enemySteps) : 0,
      p95UnitsPerWallTick: p95(enemySteps),
      scope: "same-generation diagnostics; monster dash mechanics have no asserted speed bound"
    },
    buffer: { activeSamples, bufferedSamples, bufferEntries, bufferExits, recoveryEntries }
  }
}
