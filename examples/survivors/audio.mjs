// Original procedural score. No audio is created until an explicit user gesture.
export class AudioEngine {
  constructor() {
    this.context = null;
    this.master = null;
    this.enabled = true;
    this.muted = false;
    this.volume = 0.42;
    this.voices = 0;
    this.nextNote = 0;
    this.step = 0;
    this.lastEvent = new Map();
    this.nodes = new Set();
  }
  unlock() {
    if (!this.enabled) return;
    try {
      if (!this.context) {
        const C = globalThis.AudioContext || globalThis.webkitAudioContext;
        if (!C) return;
        this.context = new C();
        this.master = this.context.createGain();
        this.master.connect(this.context.destination);
        this._gain();
        this.nextNote = this.context.currentTime + 0.1;
      }
      if (this.context.state === "suspended")
        this.context.resume().catch(() => {});
    } catch {}
  }
  _gain() {
    if (this.master && this.context)
      this.master.gain.setTargetAtTime(
        this.enabled && !this.muted
          ? Math.max(0, Math.min(1, this.volume)) * 0.45
          : 0,
        this.context.currentTime,
        0.035,
      );
  }
  setMuted(value) {
    this.muted = Boolean(value);
    this._gain();
  }
  setVolume(value) {
    this.volume = Math.max(0, Math.min(1, Number(value) || 0));
    this._gain();
  }
  setEnabled(value) {
    this.enabled = Boolean(value);
    this._gain();
    if (!this.enabled) this.stop();
  }
  _tone(
    frequency,
    duration,
    gain = 0.08,
    type = "sine",
    delay = 0,
    pan = 0,
    slide = 0,
  ) {
    const c = this.context;
    if (!c || !this.enabled || this.muted || this.voices >= 24) return;
    this.voices++;
    const osc = c.createOscillator(),
      env = c.createGain(),
      panner = c.createStereoPanner?.();
    const t = c.currentTime + delay;
    osc.type = type;
    osc.frequency.setValueAtTime(Math.max(20, frequency), t);
    if (slide)
      osc.frequency.exponentialRampToValueAtTime(
        Math.max(20, slide),
        t + duration,
      );
    env.gain.setValueAtTime(0.0001, t);
    env.gain.exponentialRampToValueAtTime(Math.max(0.0002, gain), t + 0.008);
    env.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    osc.connect(env);
    if (panner) {
      panner.pan.value = Math.max(-0.8, Math.min(0.8, pan));
      env.connect(panner);
      panner.connect(this.master);
    } else env.connect(this.master);
    this.nodes.add(osc);
    osc.onended = () => {
      this.voices = Math.max(0, this.voices - 1);
      this.nodes.delete(osc);
      osc.disconnect();
      env.disconnect();
      panner?.disconnect();
    };
    osc.start(t);
    osc.stop(t + duration + 0.015);
  }
  event(name, x = 0) {
    if (!this.context || !this.enabled || this.muted) return;
    const now = this.context.currentTime,
      limits = { shot: 0.065, hit: 0.08, kill: 0.09 };
    if (now - (this.lastEvent.get(name) ?? -99) < (limits[name] ?? 0.08))
      return;
    this.lastEvent.set(name, now);
    const pan = Math.max(-1, Math.min(1, Number(x) || 0));
    switch (name) {
      case "shot":
        this._tone(640, 0.065, 0.022, "triangle", 0, pan, 250);
        break;
      case "hit":
        this._tone(120, 0.09, 0.055, "sawtooth", 0, pan, 45);
        break;
      case "kill":
        this._tone(390, 0.075, 0.03, "triangle", 0, pan, 630);
        break;
      case "level":
        [0, 3, 7, 10, 12].forEach((n, i) =>
          this._tone(220 * 2 ** (n / 12), 0.35, 0.09, "triangle", i * 0.075),
        );
        break;
      case "chest":
        [0, 7, 12, 15, 19, 24].forEach((n, i) =>
          this._tone(196 * 2 ** (n / 12), 0.48, 0.08, "sine", i * 0.085),
        );
        break;
      case "choose":
        this._tone(440, 0.12, 0.055, "triangle");
        this._tone(660, 0.2, 0.04, "sine", 0.07);
        break;
      case "gameover":
        [0, -3, -7, -12].forEach((n, i) =>
          this._tone(220 * 2 ** (n / 12), 0.75, 0.09, "triangle", i * 0.2),
        );
        break;
      case "victory":
        [0, 3, 7, 12, 15, 19, 24].forEach((n, i) =>
          this._tone(220 * 2 ** (n / 12), 0.65, 0.09, "triangle", i * 0.12),
        );
        break;
      case "heal":
        this._tone(520, 0.25, 0.05, "sine", 0, 0, 850);
        break;
    }
  }
  update(frame) {
    if (
      !this.context ||
      !this.enabled ||
      this.muted ||
      this.context.state !== "running"
    )
      return;
    const c = this.context;
    if (this.nextNote < c.currentTime - 0.5)
      this.nextNote = c.currentTime + 0.05;
    const scale = [0, 3, 5, 7, 10, 12, 10, 7, 5, 3, 0, -5, 0, 7, 10, 5];
    let guard = 0;
    while (this.nextNote < c.currentTime + 0.2 && guard++ < 3) {
      const i = this.step++;
      const delay = Math.max(0, this.nextNote - c.currentTime);
      this._tone(
        110 * 2 ** (scale[i % scale.length] / 12),
        0.68,
        0.026,
        "triangle",
        delay,
        Math.sin(i * 0.7) * 0.5,
      );
      if (i % 4 === 0) {
        this._tone(55, 0.98, 0.045, "sine", delay);
        this._tone(82.407, 0.9, 0.012, "sine", delay + 0.03);
      }
      if (i % 8 === 6)
        this._tone(
          440 * 2 ** (scale[i % scale.length] / 12),
          0.5,
          0.012,
          "sine",
          delay + 0.18,
        );
      this.nextNote += 0.38;
    }
  }
  stop() {
    for (const n of this.nodes) {
      try {
        n.stop();
      } catch {}
    }
    this.nodes.clear();
    this.nextNote = (this.context?.currentTime ?? 0) + 0.1;
    this.step = 0;
  }
}
