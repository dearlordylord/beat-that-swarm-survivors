import assert from 'node:assert/strict';
import test from 'node:test';
import { Renderer } from './renderer.mjs';

function map(frame) {
  const rectangles = [], views = [], circles = [];
  const context = {
    fillStyle: '', strokeStyle: '',
    fillRect(x, y, width, height) { rectangles.push({ color: this.fillStyle, x, y, width, height }); },
    strokeRect(...values) { views.push(values); },
    arc(...values) { circles.push(values); },
    beginPath() {}, moveTo() {}, lineTo() {}, closePath() {}, stroke() {}, fill() {},
  };
  const canvas = { width: 360, dataset: {}, getContext: () => context, setAttribute(name, value) { this[name] = value; } };
  Renderer.prototype.drawMap.call({ width: 1024, height: 640 }, canvas, frame);
  return { canvas, rectangles, views, circles };
}
const frame = {
  worldSize: 14400, px: 7200, py: 7200, relicX: 10800, relicY: 7200, relicCollected: 0,
  bodies: [[8000, 7200, 5], [7000, 7000, 0], [7100, 7100, 2], [7300, 7300, 7]],
};
test('map marks player, chest and relic without enemy or XP markers', () => {
  const rendered = map(frame);
  assert.equal(rendered.canvas.dataset.chests, 1);
  assert.equal(rendered.canvas.dataset.relic, '1');
  assert.equal(rendered.rectangles.length, 2, 'Only background and chest are rectangles');
  assert.equal(rendered.rectangles[1].color, '#f5d17b');
  assert.equal(rendered.circles.length, 1, 'Only player gets a circular marker');
  assert.deepEqual(rendered.circles[0].slice(0, 3), [180, 180, 3]);
  assert.match(rendered.canvas['aria-label'], /Enemies are not shown/);
});
test('map viewport clips to world edges and collected relic disappears', () => {
  const rendered = map({ ...frame, px: 20, py: 20, relicCollected: 1, bodies: [] });
  assert.equal(rendered.canvas.dataset.relic, '0');
  assert.equal(rendered.canvas.dataset.chests, 0);
  const scale = 336 / 14400;
  assert.deepEqual(rendered.views[0], [12, 12, 532 * scale, 340 * scale]);
});
