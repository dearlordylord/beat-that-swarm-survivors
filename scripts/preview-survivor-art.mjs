import { mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import assert from 'node:assert/strict';
import { prototypeLayers } from '../examples/survivors/survivor-art-prototypes.mjs';

// Captures stay outside source; pass an output directory to keep a chosen set.
const output = resolve(process.argv[2] || join(tmpdir(), 'survivors-art-prototypes'));
const names = ['Mira', 'Corvin', 'Agatha', 'Seraph', 'Bran', 'Eira', 'Nox', 'Lumen'];
const titles = ['A — Village gothic', 'B — Compact silhouettes'];
const sprite = (id, variant, x, y, scale) => {
  const layers = prototypeLayers(id, variant);
  assert(layers.length > 0);
  for (const [color, path] of layers) {
    assert.match(color, /^#[0-9a-f]{6}$/i);
    assert.match(path, /^[MmhHvVlLzZ\d\s.,-]+$/);
  }
  return `<g transform="translate(${x} ${y}) scale(${scale})">${layers.map(([fill, d]) => `<path fill="${fill}" d="${d}"/>`).join('')}</g>`;
};
for (let variant = 0; variant < 2; variant++) {
  assert.equal(new Set(names.map((_, id) => JSON.stringify(prototypeLayers(id, variant)))).size, 8);
}
for (let id = 0; id < 8; id++) {
  assert.notDeepEqual(prototypeLayers(id, 0), prototypeLayers(id, 1));
}
await mkdir(output, { recursive: true });
for (let variant = 0; variant < 2; variant++) {
  const cards = names.map((name, id) => {
    const x = 16 + (id % 4) * 272;
    const y = 76 + Math.floor(id / 4) * 280;
    return `<g><rect x="${x}" y="${y}" width="260" height="266" rx="8" fill="#233035"/>
      <text x="${x + 18}" y="${y + 30}" fill="#f1e5c9" font-size="20">${name}</text>
      ${sprite(id, variant, x + 30, y + 46, 4)}
      ${sprite(id, variant, x + 192, y + 174, .75)}
      <text x="${x + 25}" y="${y + 238}" fill="#a5b2b1" font-size="13">32×40 · 4×</text>
      <text x="${x + 174}" y="${y + 238}" fill="#a5b2b1" font-size="13">24×30 · 1×</text></g>`;
  }).join('');
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1120" height="648" viewBox="0 0 1120 648"><rect width="1120" height="648" fill="#121c21"/><g font-family="sans-serif"><text x="30" y="43" fill="#f1e5c9" font-size="26">${titles[variant]}</text><g shape-rendering="crispEdges">${cards}</g></g></svg>`;
  const path = join(output, `survivors-${variant === 0 ? 'a' : 'b'}.svg`);
  await writeFile(path, svg);
  console.log(path);
}
