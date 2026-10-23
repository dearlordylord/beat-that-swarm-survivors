import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';

// Emit Draw and Art before running this test. The benchmark owns
// its separate native compilation; this oracle performs no builds or timing.
const moduleURL = (override, fallback) => override
  ? pathToFileURL(override).href : new URL(fallback, import.meta.url).href;
const { default: Draw } = await import(moduleURL(process.env.NATIVE_DRAW_MODULE, './dist/native_draw.mjs'));
const { default: Art } = await import(moduleURL(process.env.NATIVE_ART_MODULE, './dist/native_art.mjs'));
const nil = { $: 'Nil' };
const f32 = Math.fround;
const list = rows => rows.reduceRight((tail, row) => Draw.rect(row.x, row.y, row.w, row.h, row.color, tail), nil);
const normalize = row => ({ x: f32(row.x), y: f32(row.y), w: f32(row.w), h: f32(row.h), color: row.color >>> 0 });
const overlaps = (r, x, y, size) => r.x < f32(x + size) && x < f32(r.x + r.w)
  && r.y < f32(y + size) && y < f32(r.y + r.h);
const covers = (r, x, y, size) => r.x <= x && r.y <= y
  && f32(x + size) <= f32(r.x + r.w) && f32(y + size) <= f32(r.y + r.h);

// Independent original list-clipping definition. In particular, fractional
// zero/negative extents retain its leaf-overlap behavior; do not "repair" it.
function reference(rows, x = 0, y = 0, size = 512) {
  const visible = rows.filter(row => overlaps(row, x, y, size));
  if (!visible.length) return { $: 'Pix', color: 725017 };
  if (size === 1 || covers(visible[0], x, y, size)) return { $: 'Pix', color: visible[0].color };
  const half = size / 2;
  return { $: 'Qua', tl: reference(visible, x, y, half), tr: reference(visible, x + half, y, half),
    bl: reference(visible, x, y + half, half), br: reference(visible, x + half, y + half, half) };
}

function raster(image) {
  const pixels = new Uint32Array(512 * 512);
  function visit(node, x, y, size) {
    if (node.$ === 'Pix') {
      for (let row = y; row < y + size; row++) pixels.fill(node.color, row * 512 + x, row * 512 + x + size);
      return;
    }
    assert.equal(node.$, 'Qua');
    const half = size / 2;
    visit(node.tl, x, y, half); visit(node.tr, x + half, y, half);
    visit(node.bl, x, y + half, half); visit(node.br, x + half, y + half, half);
  }
  visit(image, 0, 0, 512);
  return pixels;
}

function rowsFromList(rows) {
  const out = [];
  for (let node = rows; node.$ !== 'Nil'; node = node.tail) {
    assert.equal(node.$, 'Con');
    out.push(normalize(node.head));
  }
  return out;
}

let checked = 0;
function checkRows(label, input) {
  const rows = input.map(normalize);
  const expected = raster(reference(rows));
  assert.deepEqual(raster(Draw.image(list(rows))), expected, `${label}: public renderer`);
  checked++;
}

checkRows('empty', []);
checkRows('opaque layer ordering', [
  { x: 80, y: 80, w: 20, h: 20, color: 0xff0000 },
  { x: 0, y: 0, w: 512, h: 512, color: 0x123456 },
  { x: 0, y: 0, w: 512, h: 512, color: 0xffffff },
]);
checkRows('fractional and degenerate edges', [
  { x: -0.2, y: 511.8, w: 3.1, h: 0.2, color: 1 },
  { x: 12.5, y: 12.5, w: 0, h: 0, color: 2 },
  { x: 32.8, y: 32.8, w: -0.2, h: -0.1, color: 3 },
  { x: 511.9, y: -0.1, w: 0.1, h: 513, color: 4 },
  { x: 0, y: 0, w: 512, h: 512, color: 5 },
]);

let seed = 0x183a1942;
const random = () => (seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0);
for (let scene = 0; scene < 24; scene++) {
  const rows = Array.from({ length: 10 + scene * 7 }, () => ({
    x: (random() % 70000) / 100 - 100, y: (random() % 70000) / 100 - 100,
    w: (random() % 9000) / 100 - 0.5, h: (random() % 9000) / 100 - 0.5,
    color: random() & 0xffffff,
  }));
  rows.push({ x: 0, y: 0, w: 512, h: 512, color: scene + 100 });
  checkRows(`seeded random ${scene}`, rows);
}

const fontRows = Draw.text('FPS 59 / HP 100 [XP] / abc!?', 8.35, 12.6, 1.25, 0xabcdef,
  Draw.text('NIGHTFALL', 22.8, 40.25, 3, 0x798538, Draw.rect(0, 0, 512, 512, 0x090b0c, nil)));
checkRows('actual fonts with fractional scaling', rowsFromList(fontRows));
let sprites = Draw.rect(0, 0, 512, 512, 0x112233, nil);
for (let i = 0; i < 32; i++) {
  const x = f32(8.25 + (i * 53) % 500), y = f32(8.6 + (i * 71) % 500);
  sprites = Art.health_bar(0, 30 + i, 100, x, y, 7.25,
    Art.sprite(i % 12, i % 31, x, y, 7.25 + i % 5, 0x90ab32 + i, sprites));
}
checkRows('actual layered sprites and health bars', rowsFromList(sprites));
console.log(`PASS native renderer: ${checked} scenes, ${checked * 512 * 512} pixels per implementation; no performance claim from this test`);
