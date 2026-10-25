import { drawSurvivor } from './survivor-art.mjs';
import Game from "./dist/game.mjs";

/* Presentation only. All positions, health, drops and weapon effects come from Bend. */
const TAU = Math.PI * 2;
const shotIdentity = body => typeof body[9] === "string"
  ? `generation:${body[9]}` : `slot:${body[7]}:${body[9] ?? ""}`;
const THEMES = [
  ["#121c20", "#1c2b2b", "#334139", "#76917a"],
  ["#211d26", "#302835", "#534452", "#b79b79"],
  ["#191c2c", "#252b3e", "#40435b", "#a3a3ba"],
  ["#142a33", "#203c46", "#406774", "#b2d5d8"],
  ["#291c24", "#3e252b", "#694035", "#d79964"],
];
const COLORS = [
  "#f5d17b",
  "#9ce5fa",
  "#ad9dff",
  "#ff967d",
  "#d5ec95",
  "#75e6d4",
  "#ffce76",
  "#c791f5",
  "#a1d7ff",
  "#f6a2cf",
  "#e7edc1",
  "#ff8765",
  "#9bffc2",
  "#a6b6ff",
  "#edca86",
  "#e3aaff",
  "#89e5d8",
  "#ffcb8f",
  "#d1e88a",
  "#92cbff",
  "#f8a5a5",
  "#b8a6ff",
  "#f7e7a1",
  "#b4fff4",
];
function hash(x, y = 0) {
  let n = Math.imul(x | 0, 374761393) ^ Math.imul(y | 0, 668265263);
  n = Math.imul(n ^ (n >>> 13), 1274126177);
  return (n >>> 0) / 4294967296;
}
// Observed player positions only; this helper never advances or predicts gameplay.
export function framePlayers(frame) {
  return Array.isArray(frame.players) && frame.players.length
    ? frame.players
    : [{ id: frame.ownPlayerId ?? 0, px: frame.px, py: frame.py, hp: frame.hp,
      maxHp: frame.maxHp, character: frame.character }];
}
function rect(c, x, y, w, h, col) {
  c.fillStyle = col;
  c.fillRect(Math.round(x), Math.round(y), w, h);
}
export class Renderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d", { alpha: false });
    this.reset();
    this.resize();
    this.handleResize = () => this.resize();
    globalThis.addEventListener?.("resize", this.handleResize);
    if (globalThis.ResizeObserver) {
      this.resizeObserver = new ResizeObserver(this.handleResize);
      this.resizeObserver.observe(canvas);
    }
  }
  reset() {
    this.time = 0;
    this.previous = new Map();
    this.shotPositions = new Map();
    this.labels = [];
    this.camera = null;
  }
  resize() {
    const bounds = this.canvas.getBoundingClientRect();
    const aspect =
      bounds.width > 0 && bounds.height > 0
        ? bounds.width / bounds.height
        : 1024 / 640;
    // Portrait keeps the same vertical world scale and shows a narrower world.
    // Landscape keeps its horizontal world scale. Simulation coordinates never change.
    this.width = aspect < 1 ? Math.max(1, Math.round(640 * aspect)) : 1024;
    this.height = aspect < 1 ? 640 : Math.max(1, Math.round(1024 / aspect));
    if (this.canvas.width !== this.width) this.canvas.width = this.width;
    if (this.canvas.height !== this.height) this.canvas.height = this.height;
    this.ctx.imageSmoothingEnabled = false;
  }
  draw(frame, dt = 1 / 60, options = {}) {
    if (!frame) return;
    this.time += Math.min(0.05, Math.max(0, dt));
    this.options = options;
    this.frame = frame;
    const c = this.ctx,
      t = this.time,
      px = Number(frame.px) || 0,
      py = Number(frame.py) || 0;
    this.camera = { x: px - this.width / 2, y: py - this.height / 2 };
    this.theme = THEMES[(Number(frame.stage) || 0) % 5];
    c.fillStyle = this.theme[0];
    c.fillRect(0, 0, this.width, this.height);
    this.ground();
    this.boundary();
    this.hazards();
    const bodies = Array.isArray(frame.bodies) ? frame.bodies : [];
    // A forecast may reconcile a volley into another physical pool slot.
    // Heading belongs to its semantic lifetime, and expires with that lifetime.
    const shotKeys = new Set(bodies.filter(b => b[2] === 1 || b[2] === 7).map(shotIdentity));
    for (const key of this.shotPositions?.keys() || [])
      if (!shotKeys.has(key)) this.shotPositions.delete(key);
    for (const b of bodies) if (b[2] === 6) this.effect(b, true);
    const ordered = bodies
      .filter((b) => b[2] !== 6)
      .slice()
      .sort((a, b) => a[1] - b[1]);
    const players = framePlayers(frame).slice().sort((a, b) => a.py - b.py || a.id - b.id);
    let playerIndex = 0;
    for (const b of ordered) {
      while (playerIndex < players.length && b[1] > players[playerIndex].py)
        this.observedPlayer(players[playerIndex++], players.length > 1);
      this.body(b);
    }
    while (playerIndex < players.length)
      this.observedPlayer(players[playerIndex++], players.length > 1);
    for (const b of bodies) if (b[2] === 6) this.effect(b, false);
    for (const b of bodies) this.healthBar(b);
    if (options.showDamage !== false) this.damage(bodies, dt);
    const shade = c.createRadialGradient(
      this.width / 2,
      this.height / 2,
      Math.min(this.width, this.height) * 0.2,
      this.width / 2,
      this.height / 2,
      Math.hypot(this.width, this.height) * 0.53,
    );
    shade.addColorStop(0, "#03071300");
    shade.addColorStop(0.65, "#03071316");
    shade.addColorStop(1, "#02050bd9");
    c.fillStyle = shade;
    c.fillRect(0, 0, this.width, this.height);
    this.relicCompass();
    if (!options.reducedMotion) {
      c.fillStyle = "#d6e8d64a";
      for (let i = 0; i < 19; i++) {
        let x =
            (hash(i, 8) * this.width +
              Math.sin(t * 0.15 + i) * 20 +
              this.width) %
            this.width,
          y =
            (hash(i, 9) * this.height -
              t * (3 + hash(i, 2) * 7) +
              this.height * 20) %
            this.height;
        c.fillRect(x, y, 1, 1);
      }
    }
  }
  xy(x, y) {
    return [x - this.camera.x, y - this.camera.y];
  }
  worldSize() {
    return Number(this.frame?.worldSize) || Game.world_size();
  }
  drawMap(canvas, frame) {
    const c = canvas.getContext("2d"), size = canvas.width, pad = 12,
      span = size - pad * 2, world = Number(frame.worldSize) || Game.world_size(),
      scale = span / world, point = (x, y) => [pad + x * scale, pad + y * scale];
    c.fillStyle = "#121c20"; c.fillRect(0, 0, size, size);
    c.strokeStyle = "#334139"; c.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const at = pad + span * i / 4;
      c.beginPath(); c.moveTo(at, pad); c.lineTo(at, size - pad); c.stroke();
      c.beginPath(); c.moveTo(pad, at); c.lineTo(size - pad, at); c.stroke();
    }
    const left = Math.max(0, frame.px - this.width / 2),
      top = Math.max(0, frame.py - this.height / 2),
      right = Math.min(world, frame.px + this.width / 2),
      bottom = Math.min(world, frame.py + this.height / 2),
      [viewX, viewY] = point(left, top);
    c.strokeStyle = "#b8c9ca";
    c.strokeRect(viewX, viewY, (right - left) * scale, (bottom - top) * scale);
    let chests = 0;
    for (const body of frame.bodies || []) {
      if (body[2] !== 5) continue;
      const [x, y] = point(body[0], body[1]);
      c.fillStyle = "#f5d17b"; c.fillRect(x - 3, y - 3, 6, 6); chests++;
    }
    const hasRelic = !frame.relicCollected && Number.isFinite(frame.relicX) && Number.isFinite(frame.relicY);
    if (hasRelic) {
      const [x, y] = point(frame.relicX, frame.relicY);
      c.fillStyle = "#a6b6ff"; c.beginPath(); c.moveTo(x, y - 5);
      c.lineTo(x + 4, y); c.lineTo(x, y + 5); c.lineTo(x - 4, y); c.closePath(); c.fill();
    }
    const players = framePlayers(frame);
    for (const player of players) {
      const [x, y] = point(player.px, player.py);
      const own = player.id === (frame.ownPlayerId ?? 0);
      c.fillStyle = player.hp === 0 ? "#8f838b" : own ? "#ffffff" : "#9ce5fa";
      c.beginPath(); c.arc(x, y, own ? 3 : 4, 0, TAU); c.fill();
    }
    canvas.dataset.players = players.length;
    canvas.dataset.chests = chests; canvas.dataset.relic = hasRelic ? "1" : "0";
    canvas.dataset.worldSize = world;
    canvas.setAttribute("aria-label", `Arena map. You at ${Math.round(frame.px)}, ${Math.round(frame.py)}. ${chests} chests. ${hasRelic ? "Stage relic marked." : "Stage relic collected."} ${players.length > 1 ? `${players.length - 1} teammate marked in blue; fallen players in gray. ` : ""}Enemies are not shown.`);
  }
  ground() {
    const c = this.ctx,
      th = this.theme,
      s = 64,
      x0 = Math.floor(this.camera.x / s) - 1,
      y0 = Math.floor(this.camera.y / s) - 1;
    for (let iy = y0; iy < y0 + Math.ceil(this.height / s) + 3; iy++)
      for (let ix = x0; ix < x0 + Math.ceil(this.width / s) + 3; ix++) {
        let [x, y] = this.xy(ix * s, iy * s),
          h = hash(ix, iy);
        rect(c, x, y, s, s, h > 0.6 ? th[1] : th[0]);
        c.fillStyle = th[2];
        c.globalAlpha = 0.3;
        for (let j = 0; j < 4; j++) {
          let z = hash(ix * 7 + j, iy);
          c.fillRect(
            x + z * 60,
            y + hash(iy * 11 + j, ix) * 60,
            2 + (j % 2) * 3,
            1,
          );
        }
        c.globalAlpha = 1;
        if (h > 0.86) {
          c.strokeStyle = th[2];
          c.globalAlpha = 0.35;
          c.strokeRect(Math.round(x + 4), Math.round(y + 5), 53, 51);
          c.globalAlpha = 1;
        }
        if (
          h < 0.062 &&
          Math.hypot(ix * s - this.frame.px, iy * s - this.frame.py) > 65
        )
          this.landmark(x + 30, y + 35, h, ix, iy);
      }
    // Map limits remain visual; collision and movement belong to the simulation.
    const [a, b] = this.xy(0, 0);
    c.strokeStyle = this.theme[2];
    c.lineWidth = 12;
    c.strokeRect(a, b, this.worldSize(), this.worldSize());
    c.lineWidth = 1;
  }
  boundary() {
    const c = this.ctx,
      [left, top] = this.xy(0, 0),
      right = left + this.worldSize(),
      bottom = top + this.worldSize();
    c.save();
    c.fillStyle = "#070c13";
    if (left > 0) c.fillRect(0, 0, left, this.height);
    if (right < this.width)
      c.fillRect(right, 0, this.width - right, this.height);
    if (top > 0) c.fillRect(0, 0, this.width, top);
    if (bottom < this.height)
      c.fillRect(0, bottom, this.width, this.height - bottom);
    const fence = (vertical, position, start, end) => {
      if (
        position < -40 ||
        position > (vertical ? this.width : this.height) + 40
      )
        return;
      c.strokeStyle = "#7f8b84";
      c.lineWidth = 2;
      c.beginPath();
      if (vertical) {
        c.moveTo(position, start);
        c.lineTo(position, end);
      } else {
        c.moveTo(start, position);
        c.lineTo(end, position);
      }
      c.stroke();
      for (let along = Math.floor(Math.max(-30, start) / 28) * 28; along < Math.min(end, (vertical ? this.height : this.width) + 30); along += 28) {
        if (along < -30 || along > (vertical ? this.height : this.width) + 30)
          continue;
        const x = vertical ? position : along,
          y = vertical ? along : position;
        rect(c, x - 3, y - 3, 6, 6, "#3c4a48");
        rect(c, x - 1, y - 5, 2, 9, "#a4aaa0");
      }
    };
    fence(true, left, top, bottom);
    fence(true, right, top, bottom);
    fence(false, top, left, right);
    fence(false, bottom, left, right);
    for (const [edge, inside, horizontal] of [
      [left, 1, false],
      [right, -1, false],
      [top, 1, true],
      [bottom, -1, true],
    ]) {
      if (edge < -70 || edge > (horizontal ? this.height : this.width) + 70)
        continue;
      const gradient = horizontal
        ? c.createLinearGradient(0, edge, 0, edge + inside * 60)
        : c.createLinearGradient(edge, 0, edge + inside * 60, 0);
      gradient.addColorStop(0, "#070c13a0");
      gradient.addColorStop(1, "#070c1300");
      c.fillStyle = gradient;
      if (horizontal)
        c.fillRect(0, Math.min(edge, edge + inside * 60), this.width, 60);
      else c.fillRect(Math.min(edge, edge + inside * 60), 0, 60, this.height);
    }
    c.restore();
  }
  // This mirrors the Bend hazard geometry for presentation only. Damage remains
  // exclusively authoritative in encounters.bend; warnings precede each pulse.
  hazards() {
    const c = this.ctx,
      stage = (this.frame.stage || 0) % 5,
      tick = this.frame.tick || 0;
    if (tick <= 600) return;
    const periods = [360, 420, 240, 300, 180],
      pulses = [300, 360, 180, 240, 120];
    const phase = tick % periods[stage],
      until = pulses[stage] - phase;
    if (until > 90 || until < -12) return;
    const progress = Math.max(0, Math.min(1, 1 - until / 90));
    c.save();
    c.translate(-this.camera.x, -this.camera.y);
    c.beginPath();
    // Leave the permanent central escape cross clear in all five arenas.
    const center = this.worldSize() / 2, low = center - 90, high = center + 90;
    c.rect(0, 0, low, low);
    c.rect(high, 0, low, low);
    c.rect(0, high, low, low);
    c.rect(high, high, low, low);
    c.clip();
    c.fillStyle = ["#c48e73", "#a28be2", "#b0cf69", "#8bcfe7", "#ee8757"][
      stage
    ];
    c.strokeStyle = c.fillStyle;
    c.lineWidth = 2;
    c.globalAlpha = until >= 0 ? 0.09 + progress * 0.17 : 0.32;
    c.setLineDash(until >= 0 ? [7, 7] : []);
    if (stage === 3) {
      const left = Math.max(0, this.camera.x - 100),
        right = Math.min(this.worldSize(), this.camera.x + this.width + 100),
        top = Math.max(0, this.camera.y - 100),
        bottom = Math.min(this.worldSize(), this.camera.y + this.height + 100);
      for (let sum = Math.floor((left + top) / 700) * 700; sum < right + bottom; sum += 700) {
        c.beginPath();
        c.moveTo(left, sum - left);
        c.lineTo(right, sum - right);
        c.lineTo(right, sum + 95 - right);
        c.lineTo(left, sum + 95 - left);
        c.closePath();
        c.fill();
        c.stroke();
      }
    } else {
      const size = [480, 640, 400, 700, 520][stage];
      const offset = stage === 2 ? 240 : 0;
      const width = [65, 70, 160, 95, 100][stage];
      const height = [65, 490, 160, 95, 160][stage];
      for (let yy = Math.max(0, Math.floor((this.camera.y - size) / size) * size); yy < Math.min(this.worldSize(), this.camera.y + this.height); yy += size)
        for (let xx = Math.max(0, Math.floor((this.camera.x - size) / size) * size); xx < Math.min(this.worldSize(), this.camera.x + this.width); xx += size) {
          const x = xx + offset,
            y = yy + (stage === 1 ? 150 : offset);
          if (
            x + width < this.camera.x ||
            x > this.camera.x + this.width ||
            y + height < this.camera.y ||
            y > this.camera.y + this.height
          )
            continue;
          c.fillRect(x, y, width, height);
          c.strokeRect(x + 1, y + 1, width - 2, height - 2);
          if (until >= 0) {
            c.save();
            c.globalAlpha = 0.35 + progress * 0.4;
            c.font = "bold 16px monospace";
            c.textAlign = "center";
            c.fillText("!", x + width / 2, y + Math.min(height / 2, 40) + 6);
            c.restore();
          }
        }
    }
    c.restore();
  }
  landmark(x, y, h, ix, iy) {
    const c = this.ctx,
      th = this.theme,
      stage = (this.frame.stage || 0) % 5;
    this.shadow(x, y, 18, 7);
    if (stage === 1) {
      rect(c, x - 14, y - 32, 28, 32, "#171925");
      rect(c, x - 12, y - 30, 24, 3, th[2]);
      for (let i = 0; i < 7; i++)
        rect(
          c,
          x - 11 + i * 3,
          y - 26,
          2,
          20,
          ["#806e78", "#657586", "#93866e"][i % 3],
        );
      rect(c, x - 15, y - 7, 30, 4, th[2]);
    } else if (stage === 3) {
      c.fillStyle = "#527e8e";
      c.beginPath();
      c.moveTo(x - 11, y);
      c.lineTo(x - 5, y - 27);
      c.lineTo(x + 3, y - 39);
      c.lineTo(x + 11, y - 8);
      c.lineTo(x + 5, y + 2);
      c.fill();
      c.fillStyle = "#9dd4df";
      c.beginPath();
      c.moveTo(x - 5, y - 27);
      c.lineTo(x + 3, y - 39);
      c.lineTo(x + 2, y - 5);
      c.fill();
    } else if (hash(ix + 2, iy) > 0.45) {
      rect(c, x - 9, y - 23, 18, 25, th[2]);
      rect(c, x - 6, y - 28, 12, 5, th[2]);
      rect(c, x - 1, y - 20, 2, 12, th[3]);
      rect(c, x - 5, y - 16, 10, 2, th[3]);
      rect(c, x - 13, y, 26, 4, "#131c1e");
    } else {
      rect(c, x - 10, y - 17, 20, 18, th[2]);
      rect(c, x - 7, y - 20, 14, 4, th[3]);
      rect(c, x - 3, y - 13, 6, 13, th[1]);
      if (stage === 4) {
        c.fillStyle = "#ff8d47";
        c.beginPath();
        c.moveTo(x - 4, y - 18);
        c.lineTo(x + 1, y - 32);
        c.lineTo(x + 5, y - 19);
        c.fill();
      }
    }
  }
  shadow(x, y, rx = 12, ry = 4) {
    const c = this.ctx;
    c.fillStyle = "#00000065";
    c.beginPath();
    c.ellipse(x, y + 3, rx, ry, 0, 0, TAU);
    c.fill();
  }
  healthBar(b) {
    if (b[2] !== 0 || !(b[4] > 0)) return;
    const [x, y] = this.xy(b[0], b[1]);
    const radius = Math.max(1, Number(b[8]) || 5);
    const width = Math.max(20, radius * 2);
    const top = y - Math.max(24, radius * 2) - 8;
    const ratio = Math.min(1, b[4] / Math.max(1, b[5]));
    rect(this.ctx, x - width / 2 - 1, top - 1, width + 2, 5, "#eadbc9");
    rect(this.ctx, x - width / 2, top, width, 3, "#592434");
    rect(this.ctx, x - width / 2, top, width * ratio, 3, "#a5e2a0");
  }
  body(b) {
    const [x, y] = this.xy(b[0], b[1]);
    const margin = Math.max(100, Number(b[8]) || 0);
    if (
      x < -margin ||
      x > this.width + margin ||
      y < -margin ||
      y > this.height + margin
    )
      return;
    const k = b[2],
      v = b[3] || 0,
      t = this.time,
      c = this.ctx;
    if (k === 0) {
      this.enemy(x, y, v, b);
      return;
    }
    if (k === 1 || k === 7) {
      this.projectile(x, y, v, b, k === 7);
      return;
    }
    const bob = this.options.reducedMotion
      ? 0
      : Math.sin(t * 3 + (b[7] || 0)) * 2;
    if (k === 2) {
      const r = Game.xp_visual_radius(b[4] >>> 0);
      const color = "#" + Game.xp_pile_color(b[4] >>> 0, v >>> 0).toString(16).padStart(6, "0");
      c.fillStyle = color + "35";
      c.beginPath();
      c.arc(x, y, r + 6, 0, TAU);
      c.fill();
      c.fillStyle = color;
      c.beginPath();
      c.moveTo(x, y - r + bob);
      c.lineTo(x + r * 0.7, y + bob);
      c.lineTo(x, y + r + bob);
      c.lineTo(x - r * 0.7, y + bob);
      c.fill();
      rect(c, x - 1, y - r + 1 + bob, 1, 2, "#e4ffff");
    }
    if (k === 3) {
      this.shadow(x, y, 5, 2);
      rect(c, x - 4, y - 6 + bob, 8, 7, "#a46b28");
      rect(c, x - 3, y - 7 + bob, 6, 6, "#edc363");
      rect(c, x - 1, y - 6 + bob, 1, 4, "#fff1b0");
    }
    if (k === 4) {
      this.shadow(x, y, 7, 3);
      rect(c, x - 6, y - 7 + bob, 12, 7, "#a53348");
      rect(c, x - 4, y - 10 + bob, 8, 9, "#e76c75");
      rect(c, x - 2, y - 8 + bob, 4, 6, "#ffe4b5");
      rect(c, x - 3, y - 5 + bob, 6, 2, "#ffe4b5");
    }
    if (k === 9) {
      this.relic(x, y, v);
      return;
    }
    if (k === 5) {
      this.shadow(x, y, 13, 4);
      c.fillStyle = "#f6cc5c18";
      c.beginPath();
      c.arc(x, y - 7, 25, 0, TAU);
      c.fill();
      rect(c, x - 12, y - 15, 24, 16, "#583b34");
      rect(c, x - 11, y - 14, 22, 6, "#a77e40");
      rect(c, x - 12, y - 8, 24, 2, "#edce7b");
      rect(c, x - 9, y - 15, 2, 16, "#d0aa63");
      rect(c, x + 7, y - 15, 2, 16, "#d0aa63");
      rect(c, x - 2, y - 9, 4, 6, "#ffe7a0");
    }
  }
  relic(x, y, variant) {
    const c = this.ctx,
      col = ["#edce8b", "#b7a1ed", "#b8db85", "#9ddfec", "#f4a06d"][
        variant % 5
      ];
    const bob = this.options.reducedMotion ? 0 : Math.sin(this.time * 2) * 2;
    this.shadow(x, y, 17, 5);
    c.save();
    c.translate(x, y);
    rect(c, -16, -3, 32, 6, "#2e3940");
    rect(c, -12, -8, 24, 6, "#6d7470");
    rect(c, -10, -10, 20, 2, "#b4aa86");
    const glow = c.createRadialGradient(0, -25, 2, 0, -25, 34);
    glow.addColorStop(0, col + "55");
    glow.addColorStop(1, col + "00");
    c.fillStyle = glow;
    c.fillRect(-36, -60, 72, 70);
    c.translate(0, bob);
    c.fillStyle = col;
    c.beginPath();
    c.moveTo(0, -42);
    c.lineTo(11, -27);
    c.lineTo(0, -13);
    c.lineTo(-11, -27);
    c.closePath();
    c.fill();
    c.fillStyle = "#fff7d3";
    c.beginPath();
    c.moveTo(0, -39);
    c.lineTo(3, -27);
    c.lineTo(0, -17);
    c.lineTo(-3, -27);
    c.closePath();
    c.fill();
    c.strokeStyle = col;
    c.lineWidth = 2;
    c.beginPath();
    c.moveTo(-16, -31);
    c.lineTo(-20, -27);
    c.lineTo(-16, -23);
    c.moveTo(16, -31);
    c.lineTo(20, -27);
    c.lineTo(16, -23);
    c.stroke();
    c.restore();
  }
  relicCompass() {
    const frame = this.frame;
    if (
      frame.relicCollected ||
      !Number.isFinite(frame.relicX) ||
      !Number.isFinite(frame.relicY)
    )
      return;
    const c = this.ctx,
      [targetX, targetY] = this.xy(frame.relicX, frame.relicY);
    const dx = targetX - this.width / 2,
      dy = targetY - this.height / 2,
      distance = Math.hypot(dx, dy);
    const onScreen =
      targetX >= 45 &&
      targetX <= this.width - 45 &&
      targetY >= 120 &&
      targetY <= this.height - 110;
    let x = targetX,
      y = Math.max(110, targetY - 58);
    c.save();
    if (!onScreen) {
      const scale = Math.min(
        Math.max(25, this.width / 2 - 45) / Math.max(0.001, Math.abs(dx)),
        Math.max(25, this.height / 2 - 120) / Math.max(0.001, Math.abs(dy)),
      );
      x = this.width / 2 + dx * scale;
      y = this.height / 2 + dy * scale;
      c.translate(x, y);
      c.rotate(Math.atan2(dy, dx));
      c.fillStyle = "#f5dc9b";
      c.beginPath();
      c.moveTo(12, 0);
      c.lineTo(-8, -7);
      c.lineTo(-4, 0);
      c.lineTo(-8, 7);
      c.closePath();
      c.fill();
      c.rotate(-Math.atan2(dy, dx));
      c.translate(-x, -y);
      x = Math.max(
        110,
        Math.min(this.width - 110, x - (dx / Math.max(1, distance)) * 30),
      );
      y = Math.max(
        110,
        Math.min(this.height - 110, y - (dy / Math.max(1, distance)) * 30),
      );
    }
    if (!onScreen && this.width < 480) {
      x = this.width / 2;
      y = 88;
    }
    const label =
      "Stage relic" + (onScreen ? "" : ` · ${Math.round(distance)} units`);
    c.font = "600 12px system-ui";
    c.textAlign = "center";
    const width = c.measureText(label).width + 20;
    x = Math.max(width / 2 + 8, Math.min(this.width - width / 2 - 8, x));
    c.fillStyle = "#101722e8";
    c.fillRect(x - width / 2, y - 12, width, 25);
    c.strokeStyle = "#d6bd7855";
    c.strokeRect(x - width / 2, y - 12, width, 25);
    c.fillStyle = "#f5dc9b";
    c.fillText(label, x, y + 5);
    c.restore();
  }
  observedPlayer(player, multiplayer) {
    if (!multiplayer) {
      this.player(player.px, player.py, player.character);
      return;
    }
    const c = this.ctx, [x, y] = this.xy(player.px, player.py),
      own = player.id === (this.frame.ownPlayerId ?? 0),
      color = own ? "#f3dfb0" : "#9ce5fa";
    c.save();
    if (player.hp === 0) c.globalAlpha = 0.35;
    this.player(player.px, player.py, player.character);
    c.globalAlpha = 1;
    c.font = "bold 10px monospace"; c.textAlign = "center";
    c.fillStyle = "#10131d"; c.fillRect(x - 23, y - 48, 46, 14);
    c.fillStyle = player.hp === 0 ? "#b5a5af" : color;
    c.fillText(player.hp === 0 ? `P${player.id + 1} fallen` : own ? "YOU" : `P${player.id + 1}`, x, y - 38);
    if (player.maxHp > 0 && player.hp > 0) {
      c.fillStyle = "#11121a"; c.fillRect(x - 17, y - 32, 34, 4);
      c.fillStyle = color;
      c.fillRect(x - 16, y - 31, 32 * Math.max(0, Math.min(1, player.hp / player.maxHp)), 2);
    }
    c.restore();
  }
  player(wx, wy, character = 0) {
    const [x, y] = this.xy(wx, wy),
      c = this.ctx,
      t = this.time,
      step = this.options.reducedMotion ? 0 : Math.sin(t * 9) * 1.5;
    c.fillStyle = "#e9d4a10c";
    c.beginPath();
    c.arc(x, y - 6, 65, 0, TAU);
    c.fill();
    this.shadow(x, y, 12, 4);
    drawSurvivor(c, character, x, y, step);
    // Small foot ring keeps the player readable under a dense horde.
    c.strokeStyle = "#eedfaf88";
    c.beginPath();
    c.ellipse(x, y + 2, 15, 6, 0, 0, TAU);
    c.stroke();
  }
  enemy(x, y, v, b) {
    const c = this.ctx,
      boss = v >= 20,
      type = v % 10,
      r = boss ? 1.9 : 1,
      seed = b[7] || 0,
      t = this.time,
      walk = this.options.reducedMotion ? 0 : Math.sin(t * 7 + seed) * 2;
    this.shadow(x, y, 10 * r, 4 * r);
    const chargePeriods = {
      4: 150,
      12: 210,
      19: 170,
      20: 180,
      23: 165,
      25: 360,
      28: 240,
    };
    const chargePeriod = chargePeriods[v],
      chargePhase = (b[6] || 0) % (chargePeriod || 1);
    if (chargePeriod && chargePhase >= 90 && chargePhase < 120) {
      c.save();
      c.strokeStyle = "#f2b785";
      c.globalAlpha = 0.65;
      c.lineWidth = 2;
      c.setLineDash([4, 4]);
      c.beginPath();
      c.arc(x, y - 8, 18 * r, 0, TAU);
      c.stroke();
      c.beginPath();
      c.moveTo(x, y - 8);
      c.lineTo(this.width / 2, this.height / 2 - 8);
      c.stroke();
      c.restore();
    }
    c.save();
    c.translate(Math.round(x), Math.round(y));
    c.scale(r, r);
    const skin = [
      "#8c9890",
      "#d6cfb5",
      "#8596b9",
      "#a46f79",
      "#b4a47d",
      "#92a1b4",
      "#b87555",
      "#a39cbe",
      "#708f73",
      "#c0a29b",
    ][type];
    if (type === 2 || type === 7) {
      c.fillStyle = skin;
      c.globalAlpha = 0.8;
      c.beginPath();
      c.moveTo(-9, 0);
      c.lineTo(-8, -15);
      c.quadraticCurveTo(0, -30, 8, -15);
      c.lineTo(10, 0);
      c.lineTo(4, -3);
      c.lineTo(0, 1);
      c.lineTo(-4, -3);
      c.fill();
      c.globalAlpha = 1;
      rect(c, -5, -18, 3, 3, "#effaff");
      rect(c, 3, -18, 3, 3, "#effaff");
    } else if (type === 3) {
      c.fillStyle = "#583b60";
      c.beginPath();
      c.moveTo(-3, -10);
      c.lineTo(-19, -15 - walk * 2);
      c.lineTo(-13, -3);
      c.lineTo(-5, -4);
      c.lineTo(0, 1);
      c.lineTo(5, -4);
      c.lineTo(13, -3);
      c.lineTo(19, -15 + walk * 2);
      c.lineTo(3, -10);
      c.fill();
      rect(c, -4, -12, 8, 10, skin);
      rect(c, -3, -10, 2, 2, "#ffb27f");
      rect(c, 2, -10, 2, 2, "#ffb27f");
    } else {
      rect(c, -6, -4, 4, 5 + walk, "#34313a");
      rect(c, 2, -4, 4, 5 - walk, "#34313a");
      rect(
        c,
        -8,
        -17,
        16,
        14,
        type === 1 ? "#625d56" : ["#4d5351", "#67605a", "#3e4557"][type % 3],
      );
      rect(c, -11, -15 + walk, 4, 12, skin);
      rect(c, 7, -15 - walk, 4, 12, skin);
      rect(c, -7, -27, 14, 12, skin);
      rect(c, -8, -24, 16, 5, skin);
      rect(c, -5, -23, 3, 3, type === 1 ? "#272b30" : "#ef977c");
      rect(c, 2, -23, 3, 3, type === 1 ? "#272b30" : "#ef977c");
      rect(c, -3, -17, 6, 2, "#3b3138");
      if (type === 1) {
        rect(c, -4, -12, 8, 2, skin);
        rect(c, -1, -16, 2, 13, skin);
      }
      if (type === 4 || type === 9) {
        rect(c, -10, -19, 20, 9, "#70686c");
        rect(c, -8, -30, 16, 6, "#70686c");
        rect(c, -5, -31, 10, 2, "#b2a48f");
      }
    }
    if (boss) {
      c.strokeStyle = "#d7a5a0";
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(-9, -28);
      c.lineTo(-12, -36);
      c.lineTo(-4, -30);
      c.moveTo(9, -28);
      c.lineTo(12, -36);
      c.lineTo(4, -30);
      c.stroke();
    }
    c.restore();
    if (boss || b[4] < b[5]) {
      const width = boss ? 48 : 22;
      rect(c, x - width / 2, y - 33 * r, width, 3, "#100e16");
      rect(
        c,
        x - width / 2,
        y - 33 * r,
        width * Math.max(0, b[4] / Math.max(1, b[5])),
        2,
        boss ? "#e3a376" : "#c56c78",
      );
    }
  }
  projectile(x, y, v, b, hostile) {
    const c = this.ctx,
      id = v % 24,
      col = hostile ? "#f97678" : COLORS[id];
    const radius = Math.max(1, Number(b[8]) || 5),
      age = Number(b[6]) || 0;
    const area =
      !hostile &&
      ([4, 5, 7, 9, 11, 20, 22].includes(id) ||
        ([14, 17].includes(id) && radius > 30));
    c.save();
    c.translate(x, y);
    c.fillStyle = col;
    c.strokeStyle = col;
    c.lineWidth = 1.5;
    if (area) {
      const spent = (id === 14 && age > 30) || (id === 17 && age > 20);
      if (spent) {
        c.strokeStyle = "#7e787259";
        c.setLineDash([3, 8]);
      }
      c.globalAlpha = spent ? 0.12 : id === 11 ? 0.035 : 0.11;
      c.beginPath();
      c.arc(0, 0, radius, 0, TAU);
      c.fill();
      c.globalAlpha = spent ? 0.3 : 0.48;
      c.beginPath();
      c.arc(0, 0, Math.max(1, radius - 1), 0, TAU);
      c.stroke();
      c.globalAlpha = spent ? 0.12 : 0.65;
      // All glyphs lie inside the authoritative collision circle.
      if (id === 9) {
        c.rotate(this.options.reducedMotion ? 0 : this.time * 0.25);
        c.strokeRect(
          -radius * 0.48,
          -radius * 0.48,
          radius * 0.96,
          radius * 0.96,
        );
      } else if (id === 20) {
        for (let i = 0; i < 3; i++) {
          c.beginPath();
          c.arc(
            0,
            0,
            radius * (0.25 + i * 0.22),
            this.time + i,
            this.time + i + Math.PI,
          );
          c.stroke();
        }
      } else if (id === 22) {
        c.beginPath();
        c.moveTo(-radius * 0.4, 0);
        c.lineTo(radius * 0.4, 0);
        c.moveTo(0, -radius * 0.4);
        c.lineTo(0, radius * 0.4);
        c.stroke();
      } else if (id === 5) {
        c.beginPath();
        c.moveTo(-radius * 0.2, -radius * 0.7);
        c.lineTo(radius * 0.2, -radius * 0.05);
        c.lineTo(-radius * 0.15, 0);
        c.lineTo(radius * 0.15, radius * 0.65);
        c.stroke();
      } else {
        for (let i = 0; i < 4; i++) {
          const a = (i * TAU) / 4 + this.time * 0.4;
          c.beginPath();
          c.arc(
            Math.cos(a) * radius * 0.65,
            Math.sin(a) * radius * 0.65,
            2,
            0,
            TAU,
          );
          c.fill();
        }
      }
      c.restore();
      return;
    }
    const r = radius,
      a = (this.options.reducedMotion ? 0 : age * 0.15) + (b[7] || 0);
    const key = shotIdentity(b);
    const previous = this.shotPositions.get(key);
    const moved = previous && (previous.x !== b[0] || previous.y !== b[1]);
    const heading = moved
      ? Math.atan2(b[1] - previous.y, b[0] - previous.x)
      : previous?.angle || 0;
    this.shotPositions.set(key, { x: b[0], y: b[1], angle: heading });
    c.rotate([1, 10, 13, 18].includes(id) || hostile ? heading : a);
    c.shadowColor = col;
    c.shadowBlur = hostile ? 4 : 5;
    if (hostile) {
      c.beginPath();
      c.arc(0, 0, r, 0, TAU);
      c.fill();
    } else if ([1, 10, 13, 18].includes(id)) {
      c.beginPath();
      c.moveTo(r, 0);
      c.lineTo(-r, -Math.min(3, r * 0.35));
      c.lineTo(-r * 0.65, 0);
      c.lineTo(-r, Math.min(3, r * 0.35));
      c.closePath();
      c.fill();
    } else if ([2, 12, 15].includes(id)) {
      c.lineWidth = 3;
      c.beginPath();
      c.arc(0, 0, r * 0.83, -1.2, 1.2);
      c.stroke();
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(-r * 0.6, 0);
      c.lineTo(r * 0.75, 0);
      c.stroke();
    } else if ([3, 8, 19].includes(id)) {
      c.lineWidth = Math.min(5, r * 0.25);
      c.beginPath();
      c.arc(0, 0, r * 0.75, 0, TAU);
      c.stroke();
      c.beginPath();
      c.moveTo(-r * 0.65, 0);
      c.lineTo(r * 0.65, 0);
      c.moveTo(0, -r * 0.65);
      c.lineTo(0, r * 0.65);
      c.stroke();
    } else if (id === 16) {
      c.fillStyle = "#e4c45c";
      c.fillRect(-r * 0.65, -r * 0.4, r * 1.3, r * 0.8);
      c.fillStyle = "#312f39";
      c.fillRect(-1, -r * 0.45, 2, r * 0.9);
      c.fillStyle = "#d9f4eaaa";
      c.fillRect(-r * 0.6, -r * 0.8, r * 0.5, r * 0.45);
      c.fillRect(r * 0.1, -r * 0.8, r * 0.5, r * 0.45);
    } else if (id === 21) {
      c.fillStyle = "#8ee4d9";
      c.beginPath();
      c.moveTo(0, -r);
      c.lineTo(r * 0.7, 0);
      c.lineTo(0, r);
      c.lineTo(-r * 0.7, 0);
      c.closePath();
      c.fill();
      c.fillStyle = "#fff1b5";
      c.fillRect(-2, -2, 4, 4);
    } else if (id === 23) {
      c.beginPath();
      c.moveTo(0, -r);
      c.lineTo(r, 0);
      c.lineTo(0, r);
      c.lineTo(-r, 0);
      c.closePath();
      c.fill();
    } else {
      c.beginPath();
      c.arc(0, 0, r, 0, TAU);
      c.fill();
      c.fillStyle = "#ffffffb0";
      c.fillRect(
        -Math.min(2, r * 0.3),
        -r * 0.6,
        Math.min(3, r * 0.4),
        Math.min(3, r * 0.4),
      );
    }
    c.restore();
  }
  effect(b, under) {
    // Legacy hit particles are cosmetic points, never additional damage areas.
    if (under) return;
    const c = this.ctx,
      [x, y] = this.xy(b[0], b[1]),
      r = Math.min(6, Math.max(1, Number(b[8]) || 3));
    c.save();
    c.strokeStyle = COLORS[(b[3] || 0) % 24];
    c.globalAlpha = 0.5;
    c.beginPath();
    c.moveTo(x - r, y);
    c.lineTo(x + r, y);
    c.moveTo(x, y - r);
    c.lineTo(x, y + r);
    c.stroke();
    c.restore();
  }
  damage(bodies, dt) {
    const c = this.ctx,
      next = new Map();
    for (const b of bodies) {
      if (b[2] !== 0) continue;
      const key = `${b[3]}:${b[7]}`,
        old = this.previous.get(key);
      if (old && old.hp > b[4] && this.labels.length < 65)
        this.labels.push({
          x: b[0],
          y: b[1] - 28,
          value: Math.round(old.hp - b[4]),
          life: 0.65,
        });
      next.set(key, { hp: b[4] });
    }
    this.previous = next;
    c.font = "bold 12px monospace";
    c.textAlign = "center";
    this.labels = this.labels.filter((l) => {
      l.life -= Math.min(0.05, dt);
      if (l.life <= 0) return false;
      const [x, y] = this.xy(l.x, l.y);
      c.globalAlpha = Math.min(1, l.life * 3);
      c.strokeStyle = "#15121d";
      c.lineWidth = 3;
      c.strokeText(l.value, x, y - (0.65 - l.life) * 25);
      c.fillStyle = "#ffdfb1";
      c.fillText(l.value, x, y - (0.65 - l.life) * 25);
      return true;
    });
    c.globalAlpha = 1;
    c.lineWidth = 1;
  }
}
