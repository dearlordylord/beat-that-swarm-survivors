// Display-only interpolation of received Bend observations. No prediction or simulation.
const DELAY_MS = 50;
const MAX_DISTANCE = 192;
const mix = (from, to, alpha) => from + (to - from) * alpha;
const near = (ax, ay, bx, by, distance) =>
  [ax, ay, bx, by].every(Number.isFinite) && Math.hypot(ax - bx, ay - by) <= distance;

function bodyIdentity(body) {
  if (!Array.isArray(body) || !Number.isFinite(body[7])) return null;
  // The current observation packs x,y,kind,variant,hp,maxHp,age,seed,radius.
  // Accept a future explicit generation without treating a recycled slot as its predecessor.
  return `${body[2]}:${body[3]}:${body[7]}:${body[9] ?? body.generation ?? ''}`;
}
function uniqueIndex(rows, identity) {
  const index = new Map();
  for (const row of rows) {
    const key = identity(row);
    if (key !== null) index.set(key, index.has(key) ? null : row);
  }
  return index;
}
export function interpolateObservations(previous, current, amount, maxDistance = MAX_DISTANCE) {
  const alpha = Math.max(0, Math.min(1, Number.isFinite(amount) ? amount : 1));
  if (!previous || alpha === 1 || previous.runId !== current.runId || previous.stage !== current.stage
      || previous.ownPlayerId !== current.ownPlayerId || !(current.tick > previous.tick)) return current;
  const result = { ...current };
  if (near(previous.px, previous.py, current.px, current.py, maxDistance)) {
    result.px = mix(previous.px, current.px, alpha);
    result.py = mix(previous.py, current.py, alpha);
  }
  if (Array.isArray(current.players)) {
    const oldPlayers = uniqueIndex(previous.players || [], player => player.id ?? null);
    const newPlayers = uniqueIndex(current.players, player => player.id ?? null);
    result.players = current.players.map(player => {
      const old = oldPlayers.get(player.id);
      if (!old || !newPlayers.get(player.id) || old.character !== player.character || (old.hp === 0) !== (player.hp === 0)
          || !near(old.px, old.py, player.px, player.py, maxDistance)) return player;
      return { ...player, px: mix(old.px, player.px, alpha), py: mix(old.py, player.py, alpha) };
    });
  }
  if (Array.isArray(current.bodies)) {
    const oldBodies = uniqueIndex(previous.bodies || [], bodyIdentity);
    const newBodies = uniqueIndex(current.bodies, bodyIdentity);
    result.bodies = current.bodies.map(body => {
      const key = bodyIdentity(body), old = oldBodies.get(key);
      if (!old || !newBodies.get(key) || (Number.isFinite(old[6]) && Number.isFinite(body[6]) && body[6] < old[6])
          || !near(old[0], old[1], body[0], body[1], maxDistance)) return body;
      const row = body.slice(); row[0] = mix(old[0], body[0], alpha); row[1] = mix(old[1], body[1], alpha);
      return row;
    });
  }
  return result;
}

export class ObservationPresentation {
  constructor({ delayMs = DELAY_MS, maxDistance = MAX_DISTANCE } = {}) {
    this.delayMs = Math.max(0, Math.min(DELAY_MS, delayMs));
    this.maxDistance = maxDistance;
    this.reset();
  }
  reset() { this.observations = []; }
  push(frame, receivedAt = performance.now()) {
    const last = this.observations.at(-1);
    if (last && (frame.runId !== last.frame.runId || frame.stage !== last.frame.stage
        || frame.ownPlayerId !== last.frame.ownPlayerId || frame.tick < last.frame.tick || receivedAt < last.receivedAt))
      this.reset();
    this.observations.push({ frame, receivedAt });
    // A short bounded display history; no full-world rollback state is retained.
    if (this.observations.length > 8) this.observations.shift();
  }
  sample(now = performance.now()) {
    if (!this.observations.length) return null;
    const target = now - this.delayMs;
    let previous = this.observations[0];
    if (target <= previous.receivedAt) return previous.frame;
    for (let index = 1; index < this.observations.length; index++) {
      const current = this.observations[index];
      if (target <= current.receivedAt) {
        const span = current.receivedAt - previous.receivedAt;
        const alpha = span > 0 ? (target - previous.receivedAt) / span : 1;
        return interpolateObservations(previous.frame, current.frame, alpha, this.maxDistance);
      }
      previous = current;
    }
    return previous.frame; // No extrapolation when observations stop arriving.
  }
}
