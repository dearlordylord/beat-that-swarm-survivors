import { list, rows as array, number } from "./host-values.mts"
import type { Frame, Body } from "./frame.mts"
import Playback from "./dist/coop-playback.mjs"
import Wire from "./dist/coop-playback-wire.mjs"
import Contacts from "./dist/coop-contact-playback.mjs"
import HitJournal from "./dist/coop-hit-journal.mjs"
import HitEffects from "./dist/coop-hit-effects.mjs"
// Browser data adapter. Bend owns admission, clocks, lifetimes and interpolation.

const micros = (now: number) => {
  const value = Math.floor(now * 1000)
  if (!Number.isSafeInteger(value) || value < 0) throw Error("Invalid local presentation clock.")
  return value
}
export class ObservationPresentation {
  state!: BendABI.CoopPlayback.State
  frames!: Map<number, Frame>
  metadata!: Map<number, Map<string, Body>>
  currentSample!: BendABI.CoopPlayback.Sample | null
  journal!: BendABI.CoopHitJournal.State
  contacts!: BendABI.CoopContactPlayback.Prepared
  effects!: BendABI.CoopHitEffects.State
  constructor() {
    this.reset()
  }
  reset() {
    this.state = Playback.fresh()
    this.frames = new Map()
    this.metadata = new Map()
    this.currentSample = null
    this.journal = HitJournal.fresh(0)
    this.contacts = Contacts.prepare(this.journal)
    this.effects = HitEffects.fresh()
  }
  push(frame: Frame, receivedAt = performance.now()) {
    if (!frame.combatForecast || !Number.isInteger(frame.observationSeq))
      throw Error("The authoritative frame is missing its combat state or observation identity.")
    if (!this.frames.size) this.state = Playback.fresh_for(frame.ownPlayerId ?? 0)
    const extras: BendABI.CoopPlayback.Actor[] = []
    for (const body of frame.bodies || []) {
      const projected = Wire.extra_actor(body[7], body[2], body[3], body[0], body[1], body[6], body[4], frame.tick)
      if (projected.$ === "Some") extras.push(projected.value)
    }
    const projected = Wire.project(frame.combatForecast, number(frame.observationSeq), micros(receivedAt), list(extras))
    if (!Playback.accepts(this.state, projected)) return
    const metadata = new Map((frame.bodies || []).map((body) => [body[7], body]))
    const bodies = array(projected.bodies).map((actor) => {
      const body = metadata.get(actor.key)
      if (!body) throw Error("An authoritative actor has no render metadata.")
      const result: Body = [...body]
      result[0] = actor.x
      result[1] = actor.y
      result[9] = actor.generation
      result[10] = actor.owner
      result[11] = frame.tick
      return result
    })
    this.frames.set(number(frame.observationSeq), { ...frame, bodies })
    this.metadata.set(number(frame.observationSeq), new Map(bodies.map((body) => [`${body[7]}:${body[9]}`, body])))
    this.state = Playback.push(this.state, projected)
    const retained = new Set(array(Playback.observations(this.state)))
    for (const observation of this.frames.keys())
      if (!retained.has(observation)) {
        this.frames.delete(observation)
        this.metadata.delete(observation)
      }
    if (frame.contactJournal) {
      this.effects = HitEffects.receive(this.effects, frame.contactJournal)
      this.journal = frame.contactJournal
      this.contacts = Contacts.prepare(this.journal)
    }
  }
  sample(now = performance.now()) {
    this.state = Playback.advance(this.state, micros(now))
    const selected = Playback.sample(this.state)
    if (selected.$ !== "Some") return null
    const corrected = Contacts.project(this.state, selected.value, this.contacts)
    const sample = corrected.sample,
      source = this.frames.get(sample.baseObservation)
    this.currentSample = sample
    this.effects = HitEffects.advance(this.effects, this.journal, sample)
    if (!source) throw Error("The selected authoritative frame is no longer retained.")
    const playerPositions = new Map(array(sample.players).map((actor) => [actor.key, actor]))
    const players = source.players?.map((player) => {
      const point = playerPositions.get(player.id)
      return point ? { ...player, px: point.x, py: point.y } : player
    })
    const bodies = array(sample.bodies).map((point) => {
      const body = this.metadata.get(sample.baseObservation)?.get(`${point.key}:${point.generation}`)
      if (!body) throw Error("A displayed actor has no retained lifetime metadata.")
      const result: Body = [...body]
      result[0] = point.x
      result[1] = point.y
      return result
    })
    const own = playerPositions.get(source.ownPlayerId ?? 0)
    return {
      ...source,
      tick: sample.tick,
      ...(players ? { players } : {}),
      bodies,
      combatImpacts: array(HitEffects.render(this.effects, sample)),
      px: own?.x ?? source.px,
      py: own?.y ?? source.py,
      remotePresentation: {
        sampledAt: now,
        sourceTick: source.tick,
        tick: sample.tick,
        fraction: sample.fraction,
        alpha: sample.alpha,
        baseObservation: sample.baseObservation,
        nextObservation: sample.nextObservation,
        retainedFrames: this.frames.size,
        recovered: this.state.recovered,
        buffering: Playback.is_buffering(this.state)
      }
    }
  }
  bodyMetadata(seed: number, generation: string) {
    for (const metadata of this.metadata.values()) {
      const body = metadata.get(`${seed}:${generation}`)
      if (body) return body
    }
    return null
  }
}
