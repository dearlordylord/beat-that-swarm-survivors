import { at } from "./host-values.mts"
import { CHARACTERS } from "./content.mts"
// One browser sprite for prerendered SVG portraits and Canvas players (solo/co-op).
// Character identity and clothing colour come from the generated Bend catalogue.
const layers: [string | null, string][] = [
  ["#101b1b", "M7 37h20v3H7z"],
  [null, "M10 12h12v4h3v7h3v14H5V23h3v-7h2z"],
  ["#111d22", "M11 13h10v10H11z"],
  ["#e9cfad", "M12 14h8v7h-8z"],
  ["#243235", "M13 16h2v2h-2zm5 0h2v2h-2z"],
  [null, "M7 12h18v3H7zm3-4h13v4H10zm3-4h8v4h-8z"],
  ["#f1e5ae", "M4 23h3v12H4zm-1-4h5v4H3z"],
  ["#182629", "M13 24h6v3h-6zm0 10h5v3h-5z"],
  ["#ecdeb7", "M8 24h3v4H8z"]
]

export function survivorColor(id = 0) {
  return (at(CHARACTERS, id) || at(CHARACTERS, 0)).color
}

export function survivorSvg(id = 0) {
  const color = survivorColor(id)
  return `<svg viewBox="0 0 32 40" aria-hidden="true" shape-rendering="crispEdges">${layers.map(([paint, path]) => `<path fill="${paint || color}" d="${path}"/>`).join("")}</svg>`
}

let canvasLayers: [string | null, Path2D][] | undefined
export function drawSurvivor(context: CanvasRenderingContext2D, id: number, x: number, y: number, bob = 0) {
  // Lazy browser-only objects keep this module usable by Astro at build time.
  // Paths are compiled once, never rebuilt per player or per animation frame.
  canvasLayers ||= layers.map(([paint, path]) => [paint, new Path2D(path)])
  const color = survivorColor(id)
  context.save()
  // Source anchor (16, 37) is at the feet; match the existing 24px world width.
  context.translate(Math.round(x - 12), Math.round(y - 37 * 0.75 + bob))
  context.scale(0.75, 0.75)
  for (const [paint, path] of canvasLayers) {
    context.fillStyle = paint || color
    context.fill(path)
  }
  context.restore()
}
