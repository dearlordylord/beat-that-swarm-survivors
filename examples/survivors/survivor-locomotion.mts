type Gait = { x: number; y: number; tick: number; distance: number; frame: number }

export class SurvivorLocomotion {
  private readonly players = new Map<number, Gait>()

  frame(id: number, x: number, y: number, tick: number, enabled: boolean) {
    const previous = this.players.get(id)
    if (previous && previous.tick === tick && enabled) return previous.frame
    const travel = previous ? Math.hypot(x - previous.x, y - previous.y) : 0
    const continuous = previous && tick > previous.tick && tick - previous.tick <= 12 && travel <= 48
    const moving = enabled && continuous && travel > 0.01
    const distance = moving ? previous.distance + travel : 0
    const frame = moving ? Math.floor(distance / 18) % 8 : -1
    this.players.set(id, { x, y, tick, distance, frame })
    return frame
  }

  retain(ids: ReadonlySet<number>) {
    for (const id of this.players.keys()) if (!ids.has(id)) this.players.delete(id)
  }
}
