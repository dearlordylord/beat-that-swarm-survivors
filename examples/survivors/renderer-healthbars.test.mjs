import assert from "node:assert/strict";
import test from "node:test";
import { Renderer } from "./renderer.mjs";

function draw(kind, variant, hp, maximum, radius = 10) {
  const rectangles = [];
  const ctx = {
    fillStyle: "",
    fillRect(x, y, width, height) {
      rectangles.push({ x, y, width, height, color: this.fillStyle });
    },
  };
  Renderer.prototype.healthBar.call(
    { ctx, xy: () => [100, 100] },
    [0, 0, kind, variant, hp, maximum, 0, 0, radius],
  );
  return rectangles;
}

test("all enemy variants display full-health bars above their sprites", () => {
  for (let variant = 0; variant < 31; variant++) {
    const [border, track, fill] = draw(0, variant, 100, 100);
    assert.equal(fill.width, track.width);
    assert.equal(fill.color, "#a5e2a0");
    assert.ok(border.y < 100 - 24);
    assert.ok(border.width > track.width);
  }
});

test("damage uses observed current and maximum HP and clamps overheal", () => {
  assert.equal(draw(0, 0, 50, 100)[2].width, 10);
  assert.equal(draw(0, 0, 1, 100)[2].width, 0.2);
  assert.equal(draw(0, 0, 200, 100)[2].width, 20);
  assert.ok(draw(0, 30, 100, 100, 40)[0].y < 100 - 80);
});

test("dead enemies and non-enemy entities have no enemy HP bar", () => {
  assert.deepEqual(draw(0, 0, 0, 100), []);
  for (let kind = 1; kind <= 11; kind++) {
    assert.deepEqual(draw(kind, 0, 100, 100), []);
  }
});
