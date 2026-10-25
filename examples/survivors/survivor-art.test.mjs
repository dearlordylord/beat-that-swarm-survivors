import assert from 'node:assert/strict';
import { test } from 'node:test';
import { survivorSvg, drawSurvivor } from './survivor-art.mjs';

test('portraits and Canvas use the same distinct art for all eight survivors', () => {
  let compiled = 0;
  const previousPath = globalThis.Path2D;
  globalThis.Path2D = class {
    constructor(path) { this.path = path; compiled++; }
  };
  try {
    const portraits = new Set();
    for (let id = 0; id < 8; id++) {
      const svg = survivorSvg(id);
      portraits.add(svg);
      const expected = [...svg.matchAll(/<path fill="([^"]+)" d="([^"]+)"\/>/g)]
        .map(([, color, path]) => [color, path]);
      const actual = [];
      const context = {
        save() {}, restore() {}, translate() {}, scale() {},
        fill(path) { actual.push([this.fillStyle, path.path]); },
      };
      drawSurvivor(context, id, 100, 100);
      assert.deepEqual(actual, expected);
      const count = compiled;
      drawSurvivor(context, id, 110, 105, 1);
      assert.equal(compiled, count, 'movement reuses cached paths');
    }
    assert.equal(portraits.size, 8);
    assert.equal(survivorSvg(99), survivorSvg(0));
  } finally {
    globalThis.Path2D = previousPath;
  }
});
