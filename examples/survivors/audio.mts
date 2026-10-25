import { at } from "./host-values.mts"
import type { Frame } from "./frame.mts"
import Game from "./dist/game.mjs"
import Sounds from "./dist/audio-events.mjs"
// Separate mix levels keep short combat transients audible beside chip music.
const MUSIC_LEVEL = 4
const SFX_LEVEL = 2
// Bend owns composition and threat decisions; this adapter schedules and synthesizes.
// No AudioContext is created until an explicit user gesture.
export class AudioEngine {
  context!: AudioContext | null
  master!: GainNode | null
  enabled!: boolean
  muted!: boolean
  volume!: number
  voices!: number
  musicVoices!: number
  sfxVoices!: number
  timer!: ReturnType<typeof setTimeout> | null
  playing!: boolean
  frame!: Frame | null
  danger!: number
  targetBand!: number
  activeBand!: number
  lastDanger!: number
  noiseBuffer!: AudioBuffer | null
  scheduled!: { step: number; time: number }[]
  nextNote!: number
  step!: number
  musicSeed!: number
  lastEvent!: Map<string, number>
  nodes!: Map<AudioScheduledSourceNode, "sfx" | "music">
  soundState!: BendABI.AudioEvents.State
  constructor() {
    this.context = null
    this.master = null
    this.enabled = true
    this.muted = false
    this.volume = 0.42
    this.voices = 0
    this.musicVoices = 0
    this.sfxVoices = 0
    this.timer = null
    this.playing = false
    this.frame = null
    this.danger = 0
    this.targetBand = 0
    this.activeBand = 0
    this.lastDanger = -Infinity
    this.noiseBuffer = null
    this.scheduled = []
    this.nextNote = 0
    this.step = 0
    this.musicSeed = (Math.random() * 0x100000000) >>> 0
    this.lastEvent = new Map()
    this.nodes = new Map()
    this.soundState = Sounds.fresh()
  }
  unlock() {
    if (!this.enabled) return
    try {
      if (!this.context) {
        const C = globalThis.AudioContext || globalThis.webkitAudioContext
        if (!C) return
        this.context = new C()
        this.master = this.context.createGain()
        this.master.connect(this.context.destination)
        this._gain()
        this.nextNote = this.context.currentTime + 0.1
      }
      if (this.context.state === "suspended" || this.context.state === "interrupted")
        this.context.resume().catch((error) => console.warn("Could not resume game audio:", error))
    } catch {}
  }
  _gain() {
    if (this.master && this.context)
      this.master.gain.setTargetAtTime(
        this.enabled && !this.muted ? Math.max(0, Math.min(1, this.volume)) * 0.45 : 0,
        this.context.currentTime,
        0.035
      )
  }
  setMuted(value: boolean) {
    this.muted = Boolean(value)
    this._gain()
    if (this.muted) this.stop()
  }
  setVolume(value: number) {
    this.volume = Math.max(0, Math.min(1, Number(value) || 0))
    this._gain()
  }
  setEnabled(value: boolean) {
    this.enabled = Boolean(value)
    this._gain()
    if (!this.enabled) this.stop()
  }
  _tone(
    frequency: number,
    duration: number,
    gain = 0.08,
    type: OscillatorType = "sine",
    delay = 0,
    pan = 0,
    slide = 0,
    bus: "sfx" | "music" = "sfx"
  ) {
    gain *= bus === "music" ? MUSIC_LEVEL : SFX_LEVEL
    const c = this.context
    if (!c || !this.master || !this.enabled || this.muted || this[`${bus}Voices`] >= (bus === "music" ? 32 : 24)) return
    this.voices++
    this[`${bus}Voices`]++
    const osc = c.createOscillator(),
      env = c.createGain(),
      panner = c.createStereoPanner?.()
    const t = c.currentTime + delay
    osc.type = type
    osc.frequency.setValueAtTime(Math.max(20, frequency), t)
    if (slide) osc.frequency.exponentialRampToValueAtTime(Math.max(20, slide), t + duration)
    env.gain.setValueAtTime(0.0001, t)
    env.gain.exponentialRampToValueAtTime(Math.max(0.0002, gain), t + 0.008)
    env.gain.exponentialRampToValueAtTime(0.0001, t + duration)
    osc.connect(env)
    if (panner) {
      panner.pan.value = Math.max(-0.8, Math.min(0.8, pan))
      env.connect(panner)
      panner.connect(this.master)
    } else env.connect(this.master)
    this.nodes.set(osc, bus)
    osc.onended = () => {
      if (this.nodes.delete(osc)) {
        this.voices = Math.max(0, this.voices - 1)
        this[`${bus}Voices`] = Math.max(0, this[`${bus}Voices`] - 1)
      }
      osc.disconnect()
      env.disconnect()
      panner?.disconnect()
    }
    osc.start(t)
    osc.stop(t + duration + 0.015)
  }
  event(name: string, x = 0) {
    if (!this.context || !this.enabled || this.muted) return
    const now = this.context.currentTime,
      limits: Partial<Record<string, number>> = {
        shot: 0.065,
        impact: 0.055,
        hit: 0.08,
        kill: 0.09,
        hostile: 0.12,
        cast: 0.14,
        explosion: 0.14,
        pickup: 0.09
      }
    if (now - (this.lastEvent.get(name) ?? -99) < (limits[name] ?? 0.08)) return
    this.lastEvent.set(name, now)
    const pan = Math.max(-1, Math.min(1, Number(x) || 0))
    switch (name) {
      case "shot":
        this._tone(780, 0.07, 0.09, "square", 0, pan, 260)
        break
      case "impact":
        this._tone(230, 0.065, 0.095, "sawtooth", 0, pan, 70)
        break
      case "hostile":
        this._tone(180, 0.11, 0.055, "square", 0, pan, 90)
        break
      case "cast":
        this._tone(330, 0.15, 0.075, "triangle", 0, pan, 880)
        break
      case "explosion":
        this._noise(0.2, 0.18, 0, 1800, false, "sfx")
        this._tone(100, 0.2, 0.12, "sine", 0, pan, 30)
        break
      case "pickup":
        this._tone(920, 0.055, 0.05, "triangle", 0, pan, 1400)
        break
      case "hit":
        this._tone(120, 0.09, 0.055, "sawtooth", 0, pan, 45)
        break
      case "kill":
        this._tone(390, 0.075, 0.03, "triangle", 0, pan, 630)
        break
      case "level":
        ;[0, 3, 7, 10, 12].forEach((n, i) => this._tone(220 * 2 ** (n / 12), 0.35, 0.09, "triangle", i * 0.075))
        break
      case "chest":
        ;[0, 7, 12, 15, 19, 24].forEach((n, i) => this._tone(196 * 2 ** (n / 12), 0.48, 0.08, "sine", i * 0.085))
        break
      case "choose":
        this._tone(440, 0.12, 0.055, "triangle")
        this._tone(660, 0.2, 0.04, "sine", 0.07)
        break
      case "gameover":
        ;[0, -3, -7, -12].forEach((n, i) => this._tone(220 * 2 ** (n / 12), 0.75, 0.09, "triangle", i * 0.2))
        break
      case "victory":
        ;[0, 3, 7, 12, 15, 19, 24].forEach((n, i) => this._tone(220 * 2 ** (n / 12), 0.65, 0.09, "triangle", i * 0.12))
        break
      case "heal":
        this._tone(520, 0.25, 0.05, "sine", 0, 0, 850)
        break
    }
  }
  _noise(
    duration: number,
    gain: number,
    delay: number,
    cutoff: number,
    highpass = false,
    bus: "sfx" | "music" = "music"
  ) {
    gain *= bus === "music" ? MUSIC_LEVEL : SFX_LEVEL
    const c = this.context
    if (!c || !this.master || this[`${bus}Voices`] >= (bus === "music" ? 32 : 24) || this.muted || !this.enabled) return
    if (!this.noiseBuffer) {
      this.noiseBuffer = c.createBuffer(1, c.sampleRate, c.sampleRate)
      const data = this.noiseBuffer.getChannelData(0)
      let word = 0x12345678
      for (let i = 0; i < data.length; i++) {
        word ^= word << 13
        word ^= word >>> 17
        word ^= word << 5
        data[i] = Math.round((((word >>> 0) / 0xffffffff) * 2 - 1) * 15) / 15
      }
    }
    const source = c.createBufferSource(),
      filter = c.createBiquadFilter(),
      env = c.createGain()
    source.buffer = this.noiseBuffer
    filter.type = highpass ? "highpass" : "lowpass"
    filter.frequency.value = cutoff
    const start = c.currentTime + delay
    env.gain.setValueAtTime(Math.max(0.0002, gain), start)
    env.gain.exponentialRampToValueAtTime(0.0001, start + duration)
    source.connect(filter)
    filter.connect(env)
    env.connect(this.master)
    this.voices++
    this[`${bus}Voices`]++
    this.nodes.set(source, bus)
    source.onended = () => {
      if (this.nodes.delete(source)) {
        this.voices--
        this[`${bus}Voices`]--
      }
      source.disconnect()
      filter.disconnect()
      env.disconnect()
    }
    source.start(start)
    source.stop(start + duration + 0.01)
  }
  _note(note: BendABI.Music.Note, delay: number) {
    const frequency = Game["music:frequency"](note.pitch),
      duration = Math.max(0.025, note.length * Game["music:step_seconds"]() * 0.9),
      accent = Math.max(0, Math.min(1000, note.accent)) / 1000,
      level = 0.5 + accent * 0.5
    switch (note.voice) {
      case 0:
        this._tone(frequency, duration, 0.055 * level, "square", delay, -0.1, 0, "music")
        break
      case 1:
        this._tone(frequency, duration * 0.82, 0.045 * level, "square", delay, 0.18, 0, "music")
        break
      case 2:
        this._tone(frequency, duration, 0.045 * level, "triangle", delay, -0.2, 0, "music")
        break
      case 3:
        this._tone(150, 0.11, 0.2 * level, "sine", delay, 0, 38, "music")
        break
      case 4:
        this._noise(0.12, 0.12 * level, delay, 7000)
        this._tone(180, 0.055, 0.045 * level, "triangle", delay, 0, 75, "music")
        break
      case 5:
        this._noise(0.035, 0.055 * level, delay, 6500, true)
        break
      case 6:
        this._noise(0.38, 0.08 * level, delay, 4500, true)
        break
    }
  }
  _playSounds(result: BendABI.AudioEvents.Out) {
    this.soundState = result.state
    for (let rows = result.events; rows.$ === "Con"; rows = rows.tail)
      this.event(Sounds.name(rows.head.kind), rows.head.pan)
  }
  observe(frame: Frame) {
    let rows: BendList<BendABI.AudioEvents.Body> = { $: "Nil" }
    for (let i = (frame.bodies?.length || 0) - 1; i >= 0; i--) {
      const body = at(frame.bodies, i)
      rows = {
        $: "Con",
        head: {
          $: "Body",
          seed: body[7] >>> 0,
          kind: body[2] >>> 0,
          variant: body[3] >>> 0,
          age: body[6] >>> 0,
          hp: body[4] >>> 0,
          x: Math.fround(body[0]),
          radius: Math.fround(body[8]),
          generation: typeof body[9] === "string" ? body[9] : ""
        },
        tail: rows
      }
    }
    this._playSounds(
      Sounds.observe(
        this.soundState,
        {
          $: "Meta",
          run: frame.runId || "",
          tick: frame.tick >>> 0,
          phase: frame.phase >>> 0,
          round: (frame.roundId ?? 0) >>> 0,
          hp: frame.hp >>> 0,
          kills: frame.kills >>> 0,
          gold: frame.gold >>> 0,
          xp: frame.xp >>> 0,
          level: frame.level >>> 0,
          px: Math.fround(frame.px),
          confirmed: frame.coop === true
        },
        rows
      )
    )
  }
  impacts(frame: Frame) {
    if (!frame.combatImpacts?.length) return
    let rows: BendList<BendABI.AudioEvents.Impact> = { $: "Nil" }
    for (let i = frame.combatImpacts.length - 1; i >= 0; i--) {
      const hit = at(frame.combatImpacts, i)
      rows = { $: "Con", head: { $: "Impact", tick: hit.tick >>> 0, x: Math.fround(hit.x) }, tail: rows }
    }
    this._playSounds(Sounds.impacts(this.soundState, rows))
  }
  _refreshDanger(now: number, force = false) {
    if (!this.frame || (!force && now - this.lastDanger < 0.1)) return
    const frame = this.frame
    let bodies: BendList<BendABI.Game.Body> = { $: "Nil" }
    for (let i = (frame.bodies?.length || 0) - 1; i >= 0; i--) {
      const b = at(frame.bodies, i)
      if (b[2] !== 0 && b[2] !== 7) continue
      bodies = {
        $: "Con",
        head: {
          $: "Body",
          x: b[0],
          y: b[1],
          kind: b[2],
          variant: b[3],
          hp: b[4],
          maxHp: b[5],
          age: b[6],
          seed: b[7],
          radius: b[8]
        },
        tail: bodies
      }
    }
    const raw = Game.music_danger(frame.hp, frame.maxHp, frame.px, frame.py, bodies)
    this.danger = Game["music:smooth"](this.danger, raw)
    this.targetBand = Game["music:target_band"](this.targetBand, this.danger)
    this.lastDanger = now
  }
  _schedule() {
    const c = this.context
    if (!this.playing || !this.frame || !c || c.state !== "running" || !this.enabled || this.muted) return
    const now = c.currentTime
    this.scheduled = this.scheduled.filter((note) => note.time > now)
    this._refreshDanger(now)
    if (this.nextNote < now - 0.03) this.nextNote = now + 0.04
    let guard = 0
    while (this.nextNote < now + 0.16 && guard++ < 4) {
      // A future bar must not commit a stale target from the look-ahead window.
      if (this.step % 16 === 0 && this.nextNote > now + 0.03) break
      if (this.step % 16 === 0) this._refreshDanger(now, true)
      this.activeBand = Game["music:commit"](this.step >>> 0, this.activeBand, this.targetBand)
      let notes = Game["music:notes_seed"](this.step >>> 0, this.frame.stage >>> 0, this.activeBand, this.musicSeed)
      while (notes.$ === "Con") {
        this._note(notes.head, Math.max(0, this.nextNote - now))
        notes = notes.tail
      }
      this.scheduled.push({ step: this.step, time: this.nextNote })
      this.step = (this.step + 1) >>> 0
      this.nextNote += Game["music:step_seconds"]()
    }
  }
  update(frame: Frame, playing = true) {
    this.frame = frame
    if (!playing || !this.context || !this.enabled || this.muted || this.context.state !== "running") {
      this.stop()
      return
    }
    if (!this.playing) {
      this.playing = true
      this.nextNote = this.context.currentTime + 0.04
      this.timer = globalThis.setInterval(() => this._schedule(), 25)
      const timer: unknown = this.timer
      if (typeof timer === "object" && timer !== null && "unref" in timer && typeof timer.unref === "function")
        timer.unref()
    }
  }
  stop(reset = false) {
    this.playing = false
    const unplayed = this.scheduled.find((note) => note.time > (this.context?.currentTime ?? 0))
    if (!reset && unplayed) this.step = unplayed.step
    this.scheduled = []
    if (this.timer !== null) globalThis.clearInterval(this.timer)
    this.timer = null
    for (const [node, bus] of this.nodes) {
      if (!reset && bus !== "music") continue
      try {
        node.stop()
      } catch {}
      if (this.nodes.delete(node)) {
        this.voices = Math.max(0, this.voices - 1)
        this[`${bus}Voices`] = Math.max(0, this[`${bus}Voices`] - 1)
      }
    }
    this.nextNote = (this.context?.currentTime ?? 0) + 0.04
    if (reset) {
      this.soundState = Sounds.fresh()
      this.lastEvent.clear()
      this.musicSeed = (Math.random() * 0x100000000) >>> 0
      this.step = 0
      this.danger = 0
      this.targetBand = 0
      this.activeBand = 0
      this.lastDanger = -Infinity
    }
  }
}
