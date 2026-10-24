import assert from 'node:assert/strict';
import test from 'node:test';
import { Renderer, framePlayers } from './renderer.mjs';

test('legacy solo observation retains its one player without changing coordinates', () => {
  assert.deepEqual(framePlayers({ px: 20, py: 30, hp: 40, maxHp: 50, character: 6 }),
    [{ id: 0, px: 20, py: 30, hp: 40, maxHp: 50, character: 6 }]);
});

test('co-op actors are depth-sorted together with bodies and drawn once', () => {
  const drawn = [], context = {
    fillRect() {}, createRadialGradient: () => ({ addColorStop() {} }),
  };
  const renderer = {
    ctx: context, time: 0, width: 1024, height: 640,
    ground() {}, boundary() {}, hazards() {}, effect() {}, healthBar() {}, damage() {}, relicCompass() {},
    observedPlayer(player) { drawn.push(`player${player.id}`); },
    body(body) { drawn.push(`body${body[0]}`); },
  };
  Renderer.prototype.draw.call(renderer, {
    px: 50, py: 50, character: 0,
    players: [{ id: 1, px: 60, py: 70 }, { id: 0, px: 50, py: 20 }],
    bodies: [[1, 30, 0], [2, 10, 0], [3, 80, 0]],
  }, 1 / 60, { reducedMotion: true, showDamage: false });
  assert.deepEqual(drawn, ['body2', 'player0', 'body1', 'player1', 'body3']);
});
