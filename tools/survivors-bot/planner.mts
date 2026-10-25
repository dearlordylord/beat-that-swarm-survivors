import { at, defined } from "../../examples/survivors/host-values.mts"
import type { Frame, Goal, Mechanics, Point } from "./observations.mts"
interface PlannerOptions {
  cell: number
  worldSize: number | null
  maxExpanded: number
  maxCandidates: number
  replanTicks: number
}
interface Route {
  reachable: boolean
  waypoints: Point[]
  length: number
  risk: number
  expanded: number
  partial?: boolean
}
interface PoolCandidate {
  goal: Goal
  representatives?: Goal[]
  reward: number
  clusterId?: string
  priority: number
}
interface Candidate extends PoolCandidate, Route {
  etaTicks: number
  identity: string
  score: number
}
interface ResourceMemory {
  key: string
  goal: Goal
  value: number
  firstSeen: number
  lastSeen: number
}
interface Cluster {
  id: string
  reward: number
  members: ResourceMemory[]
  x: number
  y: number
  firstSeen: number
}
interface Memory {
  options: PlannerOptions
  objects: Record<string, ResourceMemory>
  clusters: Cluster[]
  candidates: Candidate[]
  current: Candidate | null
  lastPlan: number
  lastHp: number | null
  lastPosition: Point | null
  stuckSince: number | null
  reason: string
  lastObjectKeys?: string
}
interface HeapEntry {
  i: number
  f: number
}
const directions: [number, number][] = [
  [1, 0],
  [0, 1],
  [-1, 0],
  [0, -1],
  [1, 1],
  [-1, 1],
  [-1, -1],
  [1, -1]
]
// Pure, bounded spatial planning. The classifier is deliberately outside this module.
const distance = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.y - b.y)
const position = (f: Frame) => ({ x: f.px, y: f.py })
const identity = (g: Goal, tick: number) => {
  if (g.kind.startsWith("move_")) return g.kind
  if (g.kind === "approach_experience" && Number.isFinite(g.resource?.generation))
    return `${g.kind}:${g.id.split(":")[2]}:${defined(g.resource).generation}`
  const p = g.id.split(":")
  if (p.length < 6) return g.id
  return [g.kind, ...p.slice(2, 5), Number(p[3]) === 9 ? 0 : tick - Number(p[5])].join(":")
}
export function createPlanner(options: Partial<PlannerOptions> = {}): Memory {
  return {
    options: { cell: 60, worldSize: null, maxExpanded: 1200, maxCandidates: 8, replanTicks: 30, ...options },
    objects: {},
    clusters: [],
    candidates: [],
    current: null,
    lastPlan: -Infinity,
    lastHp: null,
    lastPosition: null,
    stuckSince: null,
    reason: "initial"
  }
}
class Heap {
  a: HeapEntry[] = []
  push(v: HeapEntry) {
    let i = this.a.length
    this.a.push(v)
    while (i) {
      const p = (i - 1) >> 1
      if (at(this.a, p).f <= v.f) break
      this.a[i] = at(this.a, p)
      i = p
    }
    this.a[i] = v
  }
  pop() {
    const first = this.a[0],
      v = this.a.pop()
    if (this.a.length && v) {
      let i = 0
      while (i * 2 + 1 < this.a.length) {
        let j = i * 2 + 1
        if (j + 1 < this.a.length && at(this.a, j + 1).f < at(this.a, j).f) j++
        if (at(this.a, j).f >= v.f) break
        this.a[i] = at(this.a, j)
        i = j
      }
      this.a[i] = v
    }
    return first
  }
}
function riskGrid(frame: Frame, options: Pick<PlannerOptions, "cell" | "worldSize">) {
  const cell = options.cell,
    worldSize = options.worldSize ?? frame.worldSize ?? 14400
  const margin = frame.worldMargin ?? 0,
    span = Math.min(3600, worldSize - 2 * margin),
    n = Math.ceil(span / cell)
  const origin = {
    x: Math.min(
      worldSize - margin - span,
      Math.max(margin, Math.floor(Math.max(0, frame.px - span / 2) / cell) * cell)
    ),
    y: Math.min(worldSize - margin - span, Math.max(margin, Math.floor(Math.max(0, frame.py - span / 2) / cell) * cell))
  }
  const risk = new Float64Array(n * n),
    blocked = new Uint8Array(n * n)
  for (const b of frame.bodies) {
    if (!((b[2] === 0 && b[4] > 0) || b[2] === 7)) continue
    const radius = (b[8] ?? 12) + (b[2] === 7 ? 12 : 18),
      reach = radius + 120
    for (
      let y = Math.max(0, Math.floor((b[1] - origin.y - reach) / cell));
      y <= Math.min(n - 1, Math.floor((b[1] - origin.y + reach) / cell));
      y++
    )
      for (
        let x = Math.max(0, Math.floor((b[0] - origin.x - reach) / cell));
        x <= Math.min(n - 1, Math.floor((b[0] - origin.x + reach) / cell));
        x++
      ) {
        const d = Math.hypot(origin.x + (x + 0.5) * cell - b[0], origin.y + (y + 0.5) * cell - b[1]),
          i = y * n + x
        // A cell intersecting contact space cannot serve as a safe corridor.
        if (d < radius + cell * 0.35) blocked[i] = 1
        risk[i] = at(risk, i) + Math.max(0, 1 - d / reach) * (b[2] === 7 ? 8 : 4)
      }
  }
  return { n, risk, blocked, cell, origin, span }
}
export function routePath(
  frame: Frame,
  target: Point,
  options: Partial<PlannerOptions> = {},
  suppliedGrid?: ReturnType<typeof riskGrid>
): Route {
  const o = { cell: 60, worldSize: frame.worldSize ?? 14400, maxExpanded: 1200, ...options },
    grid = suppliedGrid ?? riskGrid(frame, o),
    { n, cell, risk, blocked, origin, span } = grid
  const projected = {
    x: Math.max(origin.x, Math.min(origin.x + span, target.x)),
    y: Math.max(origin.y, Math.min(origin.y + span, target.y))
  }
  const index = (p: Point) =>
    Math.max(0, Math.min(n - 1, Math.floor((p.y - origin.y) / cell))) * n +
    Math.max(0, Math.min(n - 1, Math.floor((p.x - origin.x) / cell)))
  const start = index(position(frame)),
    end = index(projected),
    cost = new Float64Array(n * n).fill(Infinity),
    previous = new Int32Array(n * n).fill(-1),
    closed = new Uint8Array(n * n),
    heap = new Heap()
  const h = (i: number) => Math.hypot((i % n) - (end % n), Math.floor(i / n) - Math.floor(end / n))
  if (blocked[end] && end !== start)
    return { reachable: false, waypoints: [], length: Infinity, risk: Infinity, expanded: 0 }
  cost[start] = 0
  heap.push({ i: start, f: h(start) })
  let expanded = 0
  while (heap.a.length && expanded < o.maxExpanded) {
    const { i } = defined(heap.pop())
    if (closed[i]) continue
    closed[i] = 1
    expanded++
    if (i === end) {
      let cursor = i,
        indices = []
      while (cursor !== start) {
        indices.push(cursor)
        cursor = at(previous, cursor)
      }
      indices.reverse()
      const waypoints = indices.map((k) => ({
        x: origin.x + ((k % n) + 0.5) * cell,
        y: origin.y + (Math.floor(k / n) + 0.5) * cell
      }))
      waypoints.push({ ...projected })
      let length = 0,
        last = position(frame)
      for (const point of waypoints) {
        length += distance(last, point)
        last = point
      }
      return {
        reachable: true,
        waypoints,
        length: length + distance(projected, target),
        partial: distance(projected, target) > 0,
        risk: indices.reduce((s, k) => s + at(risk, k), 0) / Math.max(1, indices.length),
        expanded
      }
    }
    const x = i % n,
      y = Math.floor(i / n)
    for (const [dx, dy] of directions) {
      const nx = x + dx,
        ny = y + dy
      if (nx < 0 || ny < 0 || nx >= n || ny >= n) continue
      const j = ny * n + nx
      if (blocked[j] && j !== start) continue
      if (dx && dy && (blocked[y * n + nx] || blocked[ny * n + x])) continue
      const c = at(cost, i) + Math.hypot(dx, dy) * (1 + at(risk, j) * 2)
      if (c < at(cost, j)) {
        cost[j] = c
        previous[j] = i
        heap.push({ i: j, f: c + h(j) })
      }
    }
  }
  return { reachable: false, waypoints: [], length: Infinity, risk: Infinity, expanded }
}
function observe(memory: Memory, frame: Frame, catalog: Goal[], mechanics: Partial<Mechanics>) {
  const objects: Record<string, ResourceMemory> = {},
    xpBodies = new Map(frame.bodies.filter((b) => b[2] === 2).map((b) => [b[7], b]))
  for (const goal of catalog.filter((g) => g.kind === "approach_experience")) {
    const key = identity(goal, frame.tick),
      prior = memory.objects[key]
    const body = xpBodies.get(Number(goal.id.split(":")[2]))
    const value = Number.isFinite(goal.resource?.baseXp)
      ? defined(goal.resource).baseXp
      : Number.isFinite(goal.reward?.xp)
        ? defined(defined(goal.reward).xp)
        : Number.isFinite(goal.experience)
          ? defined(goal.experience)
          : (body?.[4] ?? 0) > 0
            ? defined(body)[4]
            : (mechanics.resourceRules?.xpDefaultValue ?? 1)
    objects[key] = { key, goal, value, firstSeen: prior?.firstSeen ?? frame.tick, lastSeen: frame.tick }
  }
  // Observation is omniscient: disappeared pickups are removed, never remembered as available.
  memory.objects = objects
  const clusters = new Map<string, Cluster>()
  for (const object of Object.values(objects)) {
    const p = object.goal.target,
      key = `${Math.floor(p.x / 120)}:${Math.floor(p.y / 120)}`
    let c = clusters.get(key)
    if (!c) clusters.set(key, (c = { id: key, reward: 0, members: [], x: 0, y: 0, firstSeen: object.firstSeen }))
    c.reward += object.value
    c.x += p.x * object.value
    c.y += p.y * object.value
    c.members.push(object)
    c.firstSeen = Math.min(c.firstSeen, object.firstSeen)
  }
  memory.clusters = [...clusters.values()].map((c) => ({ ...c, x: c.x / c.reward, y: c.y / c.reward }))
}
export function advisePlanner(memory: Memory, goalId: string) {
  const candidate = memory.candidates.find((c) => c.goal.id === goalId)
  if (!candidate) return false
  memory.current = candidate
  memory.reason = "advisory"
  return true
}
const availableGoalKinds = new Set([
  "move_north",
  "move_east",
  "move_south",
  "move_west",
  "approach_experience",
  "approach_chest",
  "approach_relic"
])
export function planMovement(memory: Memory, frame: Frame, catalog: Goal[], mechanics: Partial<Mechanics> = {}) {
  catalog = catalog.filter((goal) => availableGoalKinds.has(goal.kind))
  observe(memory, frame, catalog, mechanics)
  const here = position(frame),
    current = memory.current
  const currentGoal = current && catalog.find((g) => identity(g, frame.tick) === current.identity)
  const damaged = memory.lastHp !== null && frame.hp < memory.lastHp
  if (memory.lastPosition && distance(here, memory.lastPosition) > 12) {
    memory.lastPosition = here
    memory.stuckSince = frame.tick
  }
  if (!memory.lastPosition) {
    memory.lastPosition = here
    memory.stuckSince = frame.tick
  }
  const stuck = frame.tick - defined(memory.stuckSince) >= 120
  const invalid = !!current && !currentGoal
  const due = frame.tick - memory.lastPlan >= memory.options.replanTicks
  const objectKeys = Object.keys(memory.objects).join("|")
  let expanded = 0
  if (
    memory.lastPlan === -Infinity ||
    (!current && objectKeys !== memory.lastObjectKeys) ||
    invalid ||
    damaged ||
    stuck ||
    due
  ) {
    const grid = riskGrid(frame, memory.options),
      pool: PoolCandidate[] = []
    for (const cluster of memory.clusters) {
      const members = [...cluster.members].sort(
        (a, b) => distance(here, a.goal.target) - distance(here, b.goal.target) || a.goal.id.localeCompare(b.goal.id)
      )
      const member = at(members, 0)
      pool.push({
        goal: member.goal,
        representatives: members.slice(0, 3).map((m) => m.goal),
        reward: cluster.reward,
        clusterId: cluster.id,
        priority: cluster.reward / (60 + distance(here, member.goal.target))
      })
    }
    for (const goal of catalog.filter((g) => g.kind !== "approach_experience"))
      pool.push({
        goal,
        reward:
          goal.kind === "approach_chest"
            ? 14
            : goal.kind === "approach_relic"
              ? 9
              : goal.kind.startsWith("approach_")
                ? 5
                : 0.1,
        priority: 0
      })
    pool.sort(
      (a, b) =>
        b.priority - a.priority ||
        distance(here, a.goal.target) - distance(here, b.goal.target) ||
        a.goal.id.localeCompare(b.goal.id)
    )
    // Reserve routes for non-XP objectives and retreat, even under a large XP backlog.
    const selected: PoolCandidate[] = []
    const add = (p: PoolCandidate | undefined) => {
      if (p && !selected.includes(p) && selected.length < memory.options.maxCandidates) selected.push(p)
    }
    if (currentGoal)
      add(pool.find((p) => p.goal.id === currentGoal.id || p.representatives?.some((g) => g.id === currentGoal.id)))
    add(pool.find((p) => p.goal.kind.startsWith("approach_") && p.goal.kind !== "approach_experience"))
    add(pool.find((p) => p.goal.kind.startsWith("move_")))
    for (const p of pool) add(p)
    const candidates: Candidate[] = []
    for (const p of selected) {
      const remaining = memory.options.maxExpanded - expanded
      if (remaining <= 0) break
      const allowance = Math.min(
        remaining,
        Math.max(80, Math.floor(memory.options.maxExpanded / memory.options.maxCandidates))
      )
      let used = 0,
        route: Route | undefined,
        goal: Goal | undefined
      // A blocked nearest pile must not hide reachable siblings in the same cluster.
      for (const representative of p.representatives ?? [p.goal]) {
        if (used >= allowance) break
        const attempt = routePath(
          frame,
          representative.target,
          { ...memory.options, maxExpanded: allowance - used },
          grid
        )
        used += attempt.expanded
        if (attempt.reachable) {
          route = attempt
          goal = representative
          break
        }
      }
      expanded += used
      if (!route || !goal) continue
      const etaTicks = route.length / (2.5 * Math.max(0.1, mechanics.current?.speedMultiplier ?? 1))
      candidates.push({
        ...p,
        goal,
        ...route,
        etaTicks,
        identity: identity(goal, frame.tick),
        score: p.reward / (1 + etaTicks / 60) / (1 + route.risk * (frame.hp < frame.maxHp * 0.35 ? 4 : 1))
      })
    }
    if (stuck) for (const candidate of candidates) if (candidate.identity === current?.identity) candidate.score *= 0.2
    candidates.sort((a, b) => b.score - a.score || a.goal.id.localeCompare(b.goal.id))
    const retained = candidates.find((c) => c.identity === current?.identity),
      best = candidates[0]
    memory.current =
      retained && !damaged && !stuck && (!best || best.score < retained.score * 1.35) ? retained : (best ?? null)
    // Empty-world cardinal suggestions do not override weapon-aware combat steering.
    if (
      memory.current?.goal.kind.startsWith("move_") &&
      !damaged &&
      frame.hp >= frame.maxHp * 0.35 &&
      memory.reason !== "advisory"
    )
      memory.current = null
    memory.candidates = candidates
    memory.lastObjectKeys = objectKeys
    memory.lastPlan = frame.tick
    memory.reason = invalid ? "target-gone" : damaged ? "damage" : stuck ? "stuck" : current ? "periodic" : "initial"
    if (stuck) {
      memory.lastPosition = here
      memory.stuckSince = frame.tick
    }
  } else if (currentGoal) {
    defined(memory.current).goal = currentGoal
  }
  // Refresh snapshot-scoped IDs without replacing stable objectives or route memory.
  memory.candidates = memory.candidates.flatMap((c) => {
    const g = catalog.find((g) => identity(g, frame.tick) === c.identity)
    return g ? [{ ...c, goal: g }] : []
  })
  if (memory.current) {
    const fresh = memory.candidates.find((c) => c.identity === defined(memory.current).identity)
    memory.current = fresh ?? null
  }
  memory.lastHp = frame.hp
  if (memory.current) {
    while (memory.current.waypoints.length > 1 && distance(here, at(memory.current.waypoints, 0)) < 35)
      memory.current.waypoints.shift()
  }
  return {
    memory,
    candidates: memory.candidates,
    chosen: memory.current,
    target: memory.current?.waypoints[0] ?? null,
    reason: memory.reason,
    clusters: memory.clusters,
    search: { expanded, budget: memory.options.maxExpanded }
  }
}
