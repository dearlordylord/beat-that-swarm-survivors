import { at } from "./host-values.mts"
import type { SurvivorLayers } from "./survivor-shapes.mts"
import { CHARACTERS } from "./content.mts"

import { survivorLayers } from "./survivor-shapes.mts"
import { survivorWalkLayers } from "./survivor-walk-shapes.mts"

export function survivorColor(id = 0) {
  return (CHARACTERS[id] || at(CHARACTERS, 0)).color
}

export function survivorSvg(id = 0) {
  return `<svg viewBox="0 0 32 40" aria-hidden="true" shape-rendering="crispEdges">${survivorLayers(id)
    .map(([paint, path]) => `<path fill="${paint}" d="${path}"/>`)
    .join("")}</svg>`
}

const canvasLayers = new Map<SurvivorLayers, [string, Path2D][]>()
export function drawSurvivor(context: CanvasRenderingContext2D, id: number, x: number, y: number, frame = -1) {
  // Lazy browser-only objects keep this module usable by Astro at build time.
  // Paths are compiled once, never rebuilt per player or per animation frame.
  const layers = frame < 0 ? survivorLayers(id) : survivorWalkLayers(id, frame)
  let paths = canvasLayers.get(layers)
  if (!paths) {
    paths = layers.map(([paint, path]) => [paint, new Path2D(path)])
    canvasLayers.set(layers, paths)
  }
  context.save()
  // Source anchor (16, 37) is at the feet; match the existing 24px world width.
  context.translate(Math.round(x - 12), Math.round(y - 37 * 0.75))
  context.scale(0.75, 0.75)
  for (const [paint, path] of paths) {
    context.fillStyle = paint
    context.fill(path)
  }
  context.restore()
}
