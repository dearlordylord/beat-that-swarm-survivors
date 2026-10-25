interface Point {
  x: number
  y: number
}
interface ViewerGoal {
  target: Point
  [key: string]: unknown
}
interface ViewerFrame {
  tick: number
  px: number
  py: number
  hp?: number
  level?: number
  kills?: number
  bodies: [number, number, number, number, number][]
}
interface Candidate {
  id: string
  offerIndex?: number
  goal?: ViewerGoal
  description?: string
  effect?: unknown
  offer?: unknown
}
interface ViewerRequest {
  decisionSeq?: number
  kind?: string
  candidates?: Candidate[]
  snapshot?: { facts?: { tick?: number } }
}
interface ViewerResult {
  source?: string
  reason?: string
  selected?: number | ViewerGoal | null
  response?: { model?: string; latencyMs?: number }
}
interface JournalRecord {
  type: string
  frame?: ViewerFrame
  tick?: number
  hp?: number
  level?: number
  kills?: number
  request?: ViewerRequest
  result?: ViewerResult
  decisionSeq?: number
  fromTick?: number
  toTick?: number
  delta?: Record<string, number>
  [key: string]: unknown
}
interface JournalPayload {
  file?: string
  records?: JournalRecord[]
  errors?: unknown[]
  waiting?: boolean
}
function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}
const finite = (value: unknown): value is number => typeof value === "number" && Number.isFinite(value)
const string = (value: unknown): value is string => typeof value === "string"
const optional = <T,>(value: unknown, guard: (value: unknown) => value is T) => value === undefined || guard(value)
const numbers = (value: Record<string, unknown>, keys: string[]) => keys.every((key) => optional(value[key], finite))
function goal(value: unknown): value is ViewerGoal {
  return object(value) && object(value.target) && finite(value.target.x) && finite(value.target.y)
}
function candidate(value: unknown): value is Candidate {
  return (
    object(value) &&
    string(value.id) &&
    optional(value.offerIndex, finite) &&
    optional(value.goal, goal) &&
    optional(value.description, string)
  )
}
function request(value: unknown): value is ViewerRequest {
  if (!object(value) || !numbers(value, ["decisionSeq"]) || !optional(value.kind, string)) return false
  if (value.candidates !== undefined && (!Array.isArray(value.candidates) || !value.candidates.every(candidate)))
    return false
  if (
    value.snapshot !== undefined &&
    (!object(value.snapshot) ||
      (value.snapshot.facts !== undefined &&
        (!object(value.snapshot.facts) || !numbers(value.snapshot.facts, ["tick"]))))
  )
    return false
  return true
}
function result(value: unknown): value is ViewerResult {
  if (!object(value) || !optional(value.source, string) || !optional(value.reason, string)) return false
  if (value.selected !== undefined && value.selected !== null && !finite(value.selected) && !goal(value.selected))
    return false
  return (
    value.response === undefined ||
    (object(value.response) && optional(value.response.model, string) && numbers(value.response, ["latencyMs"]))
  )
}
function frame(value: unknown): value is ViewerFrame {
  return (
    object(value) &&
    finite(value.tick) &&
    finite(value.px) &&
    finite(value.py) &&
    numbers(value, ["hp", "level", "kills"]) &&
    Array.isArray(value.bodies) &&
    value.bodies.every((body) => Array.isArray(body) && [0, 1, 2, 3, 4].every((index) => finite(body[index])))
  )
}
function journalRecord(value: unknown): value is JournalRecord {
  return (
    object(value) &&
    string(value.type) &&
    optional(value.frame, frame) &&
    optional(value.request, request) &&
    optional(value.result, result) &&
    numbers(value, ["tick", "hp", "level", "kills", "decisionSeq", "fromTick", "toTick"]) &&
    (value.delta === undefined || (object(value.delta) && Object.values(value.delta).every(finite)))
  )
}
function parsePayload(value: unknown): JournalPayload {
  if (
    !object(value) ||
    !optional(value.file, string) ||
    (value.records !== undefined && (!Array.isArray(value.records) || !value.records.every(journalRecord))) ||
    (value.errors !== undefined && !Array.isArray(value.errors)) ||
    (value.waiting !== undefined && typeof value.waiting !== "boolean")
  )
    throw new TypeError("Invalid journal response")
  return value
}
function required<T>(value: T | undefined | null): T {
  if (value === undefined || value === null) throw new Error("Missing journal view value")
  return value
}
function $(id: "map"): HTMLCanvasElement
function $(id: "pick"): HTMLSelectElement
function $(id: string): HTMLElement
function $(id: string): HTMLElement {
  return required(document.getElementById(id))
}
const text = <K extends keyof HTMLElementTagNameMap>(tag: K, value: unknown, parent: HTMLElement, cls?: string) => {
  const e = document.createElement(tag)
  const rendered = String(value)
  e.textContent = value === null || value === undefined ? "" : rendered
  if (cls) e.className = cls
  parent.append(e)
  return e
}
let paused = false,
  payload: JournalPayload | undefined,
  count: number | string = -1,
  selected = "latest"
$("pause").onclick = () => {
  paused = !paused
  $("pause").textContent = paused ? "Resume display" : "Pause display"
  if (!paused && payload) render(payload)
}
$("pick").onchange = () => {
  selected = $("pick").value
  count = -1
  if (payload) render(payload)
}
function frameOf(records: JournalRecord[], tick = Infinity) {
  for (let i = records.length - 1; i >= 0; i--) {
    const r = required(records[i])
    if (["frame", "observation"].includes(r.type) && r.frame && r.frame.tick <= tick) return r.frame
  }
  return null
}
function selectedCandidate(d: Pick<JournalRecord, "request" | "result">) {
  const r = d.request,
    result = d.result
  if (!r || !result) return null
  return r.candidates?.find((c) =>
    r.kind === "upgrade" ? c.offerIndex === result.selected : JSON.stringify(c.goal) === JSON.stringify(result.selected)
  )
}
function draw(frame: ViewerFrame | null, decision: JournalRecord | undefined) {
  const canvas = $("map"),
    ctx = required(canvas.getContext("2d"))
  ctx.clearRect(0, 0, 640, 640)
  if (!frame) return
  const scale = 640 / 3600
  ctx.strokeStyle = "#233041"
  for (let p = 0; p <= 3600; p += 600) {
    ctx.beginPath()
    ctx.moveTo(p * scale, 0)
    ctx.lineTo(p * scale, 640)
    ctx.moveTo(0, p * scale)
    ctx.lineTo(640, p * scale)
    ctx.stroke()
  }
  const colors: Partial<Record<number, string>> = {
    0: "#f47579",
    2: "#75bfff",
    1: "#d3b266",
    5: "#ffd36e",
    7: "#eeeeee",
    9: "#c398ff",
    10: "#70ddf4",
    11: "#75d692"
  }
  for (const b of frame.bodies || []) {
    if (b[2] === 0 && b[4] <= 0) continue
    ctx.fillStyle = colors[b[2]] || "#61738b"
    ctx.beginPath()
    ctx.arc(b[0] * scale, b[1] * scale, [5, 9, 10, 11].includes(b[2]) ? 4 : 2, 0, Math.PI * 2)
    ctx.fill()
  }
  ctx.fillStyle = "#fff"
  ctx.beginPath()
  ctx.arc(frame.px * scale, frame.py * scale, 5, 0, Math.PI * 2)
  ctx.fill()
  const selected = decision?.result?.selected,
    goal = selectedCandidate(decision || {})?.goal || (typeof selected === "object" ? selected : null)
  if (goal?.target) {
    ctx.strokeStyle = "#f7cf73"
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.arc(goal.target.x * scale, goal.target.y * scale, 9, 0, Math.PI * 2)
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(frame.px * scale, frame.py * scale)
    ctx.lineTo(goal.target.x * scale, goal.target.y * scale)
    ctx.stroke()
  }
}
function render(data: JournalPayload) {
  const records = data.records || [],
    decisions = records.filter((r) => r.type === "decision"),
    pending = records.filter((r) => r.type === "decision-request"),
    last = decisions.at(-1)
  $("receipt").textContent = data.file || "No journal yet"
  $("connection").textContent = data.errors?.length
    ? "Journal contains invalid records"
    : data.waiting
      ? "Waiting for a run"
      : "Live · updates every 500 ms"
  $("connection").className = data.errors?.length ? "error" : ""
  const signature = (data.file || "") + ":" + decisions.length
  if (count !== signature) {
    count = signature
    const old = selected
    $("pick").replaceChildren()
    const opt = document.createElement("option")
    opt.value = "latest"
    opt.textContent = "Follow latest"
    $("pick").append(opt)
    decisions.forEach((d, i) => {
      const o = document.createElement("option")
      o.value = String(i)
      o.textContent = `#${d.request?.decisionSeq ?? i + 1} ${d.request?.kind || "decision"}`
      $("pick").append(o)
    })
    selected = old === "latest" || Number(old) >= decisions.length ? "latest" : old
    $("pick").value = selected
  }
  const active = selected === "latest" ? last : decisions[Number(selected)],
    frame = frameOf(records, selected === "latest" ? Infinity : (active?.request?.snapshot?.facts?.tick ?? -1))
  $("stats").replaceChildren()
  const summary = records.findLast((r) => r.type === "summary")
  const status: Pick<JournalRecord, "tick" | "hp" | "level" | "kills"> = frame || summary || {}
  const metrics: [string, unknown][] = [
    ["Time", status.tick === undefined ? "—" : (status.tick / 60).toFixed(1) + "s"],
    ["HP", status.hp ?? "—"],
    ["Level", status.level ?? "—"],
    ["Kills", status.kills ?? "—"]
  ]
  for (const [label, value] of metrics) {
    const box = text("div", "", $("stats"))
    text("strong", value, box)
    text("small", label, box)
  }
  $("maplabel").textContent = frame
    ? `Actual observation · tick ${frame.tick}${selected === "latest" ? "" : " · at or before selected decision"}`
    : selected === "latest"
      ? "No position telemetry in this receipt. Decisions below are available."
      : "Historical decision selected. Raw context below; map does not substitute current positions."
  draw(frame, active)
  $("movement").textContent = JSON.stringify(records.filter((r) => r.type === "movement-intent").slice(-8), null, 2)
  $("provenance").textContent = JSON.stringify(
    records.filter((r) => ["provenance", "start"].includes(r.type)),
    null,
    2
  )
  $("outcome").textContent = summary ? JSON.stringify(summary, null, 2) : "Run is open. No terminal result recorded."
  $("decisions").replaceChildren()
  const inFlight = pending.at(-1),
    waiting = inFlight && !decisions.some((d) => d.request?.decisionSeq === inFlight.request?.decisionSeq)
  const shown =
    selected === "latest" ? [...(waiting ? [inFlight] : []), ...decisions.slice(-12).reverse()] : active ? [active] : []
  for (const d of shown) {
    const a = text("article", "", $("decisions")),
      r = d.request || {},
      result = d.result || {},
      chosen = selectedCandidate(d)
    text("h2", `#${r.decisionSeq ?? "?"} · ${r.kind || "decision"}`, a)
    text("div", `${result.source || "Inference in flight"}${result.reason ? " · " + result.reason : ""}`, a, "tag")
    if (result.response)
      text("p", `${result.response.model || "provider"} · ${Math.round(result.response.latencyMs || 0)} ms`, a)
    for (const c of r.candidates || []) {
      const node = text("div", "", a, "candidate" + (c === chosen ? " selected" : ""))
      text("strong", (c === chosen ? "✓ " : "") + c.id, node)
      text("div", c.description || JSON.stringify(c.effect || c.goal || c.offer), node)
    }
    const outcomes = records.filter((o) => o.type === "outcome" && o.decisionSeq === r.decisionSeq)
    if (outcomes.length) {
      text("h3", "Observed after this decision", a)
      text(
        "p",
        "Measured changes over the run. Other actions and combat continue during each interval; these numbers do not establish that this decision caused the change.",
        a
      )
      const table = text("table", "", a),
        head = text("tr", "", text("thead", "", table))
      for (const label of ["Interval", "HP Δ", "Kills Δ", "Gold Δ", "Level Δ"]) text("th", label, head)
      const body = text("tbody", "", table),
        signed = (n: unknown) => (finite(n) ? (n > 0 ? "+" : "") + n : "—")
      for (const outcome of outcomes) {
        const row = text("tr", "", body),
          delta = outcome.delta || {}
        text(
          "td",
          `${((required(outcome.toTick) - required(outcome.fromTick)) / 60).toFixed(1)}s · ticks ${outcome.fromTick}–${outcome.toTick}`,
          row
        )
        for (const key of ["hp", "kills", "gold", "level"]) text("td", signed(delta[key]), row)
      }
      const evidence = text("details", "", a)
      text("summary", "Measured intervals and qualifications", evidence)
      text("pre", JSON.stringify(outcomes, null, 2), evidence)
    } else if (d.type === "decision") text("p", "No post-decision interval recorded yet.", a)
    const details = text("details", "", a)
    text("summary", "Actual decision context, response and validation result", details)
    text("pre", JSON.stringify(d, null, 2), details)
  }
  if (!shown.length) text("p", "Waiting for the first decision.", $("decisions"))
}
async function poll() {
  try {
    const response = await fetch("/api/journal")
    if (!response.ok) throw new Error("Unavailable")
    payload = parsePayload(await response.json())
    if (!paused) render(payload)
  } catch {
    $("connection").textContent = "Disconnected · retrying"
    $("connection").className = "error"
  }
  setTimeout(poll, 500)
}
void poll()
