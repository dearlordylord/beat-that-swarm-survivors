import { CHARACTERS } from './content.mjs';

import { survivorLayers } from './survivor-shapes.mjs';

export function survivorColor(id = 0) {
  return (CHARACTERS[id] || CHARACTERS[0]).color;
}

export function survivorSvg(id = 0) {
  return `<svg viewBox="0 0 32 40" aria-hidden="true" shape-rendering="crispEdges">${survivorLayers(id).map(([paint, path]) => `<path fill="${paint}" d="${path}"/>`).join('')}</svg>`;
}

const canvasLayers = new Map();
export function drawSurvivor(context, id, x, y, bob = 0) {
  // Lazy browser-only objects keep this module usable by Astro at build time.
  // Paths are compiled once, never rebuilt per player or per animation frame.
  const layers = survivorLayers(id);
  if (!canvasLayers.has(layers)) {
    canvasLayers.set(layers, layers.map(([paint, path]) => [paint, new Path2D(path)]));
  }
  context.save();
  // Source anchor (16, 37) is at the feet; match the existing 24px world width.
  context.translate(Math.round(x - 12), Math.round(y - 37 * .75 + bob));
  context.scale(.75, .75);
  for (const [paint, path] of canvasLayers.get(layers)) {
    context.fillStyle = paint;
    context.fill(path);
  }
  context.restore();
}
