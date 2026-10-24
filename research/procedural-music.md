# Procedural music: current implementation and next experiments

Historical baseline before adaptive chip-metal delivery. The implemented follow-up is documented in [music/README.md](../examples/survivors/music/README.md).

Assessed 2026-10-24 against the current Survivors example and installed Bend 2.0.38. This is source research; no listening comparison, synthesis benchmark or implementation was performed.

## What exists

The browser uses [audio.mjs](../examples/survivors/audio.mjs), a handwritten Web Audio synthesizer. It has no music file or generative model. `AudioEngine.update(frame)` repeats a fixed 16-note pitch pattern from a 110 Hz root, advances every 0.38 seconds, adds two bass tones every four steps and a higher accent at step 6 of each eight-step group. The pitch sequence repeats every **6.08 seconds**; stereo pan continues varying beyond that repeat. Triangle and sine oscillators have short gain envelopes. There is no drum part, chord progression or section arrangement.

The `frame` argument is unused inside the sequencer: enemies, stage and bosses do not change the score. [browser.mjs](../examples/survivors/browser.mjs) calls it from active, unpaused gameplay, outside the open reward panel. The same engine synthesizes hit/kill/level/chest/choice/heal/end cues. Music and effects share a 24-voice ceiling, so a scheduled note can be omitted under saturation. It schedules 0.2 seconds ahead, at most three steps per update, and resets a badly late clock; frame stalls therefore create a scheduling risk, not a measured audio defect. MDN documents look-ahead audio scheduling separately from animation drawing in its [sequencer example](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Advanced_techniques).

Native [native_audio.bend](../examples/survivors/native_audio.bend) has **no background score**. [native.bend](../examples/survivors/native.bend) selects at most one cue per update, prioritizing damage, then level, then kill. The synthesizer produces a decaying sine with nominal frequencies 220/880/660 Hz respectively.

There is an existing channel-format mismatch: native `emit` writes 441 scalar values. Installed `base.bend` exposes `Audio.open(rate)` and `Audio.write(audio, List<F32>)`; the imported `effs/audio.c` explicitly consumes interleaved **L,R stereo**, queues `n/2` frames and drops an odd trailing sample. Thus this output is **220 stereo frames, approximately 4.99 ms at 44.1 kHz**, rather than 10 ms of mono. Alternating samples also approximately doubles each channel's oscillator frequency. A future common synth must produce complete stereo pairs. The effect has a 4,096-frame ring, pads underruns with silence, returns queued frame count and drops writes that do not fit. Current code ignores that count.

Installed effect source: `/home/node/.bend/bend2/effs/audio.c`, especially `io_ring_write` and `audio_write_run`; SHA-256: `f0fac2bee02918b4958ad1e7508945824fcd98ce9a2e7ede657304c4f8905b85`.

## Recommended small investigation

Keep composition separate from playback: a pure Bend function can generate bar-indexed note events from stage, seed and intensity. Phrase structure and instrumentation should be deliberate; random notes alone are not a useful musical target. Retain one motif while varying harmony, bass, percussion and sparse counter-melodies over longer sections. Treat this as a proposal, not a demonstrated quality result.

Two implementation boundaries are viable:

- **Shared score, separate instruments:** Bend emits identical note events; Web Audio renders browser voices, while a Bend PCM mixer serves native `Audio.write`. Smaller first migration, but timbres and mixes may differ.
- **Shared score and PCM synth:** Bend renders complete stereo blocks used by both hosts. This gives stronger sound parity but requires measured render cost, explicit queue accounting and smoothing at block boundaries. Existing APIs suffice; no Bend runtime or WASM work is required by this design proposal.

Precompute/cache instrument samples or bars and keep composition out of the ECS tick. Full bars need not be queued at once: native output must feed bounded blocks into its small ring. Browser buffers can be prepared before playback; [OfflineAudioContext](https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext) renders an audio graph into an AudioBuffer. Neither approach has been benchmarked here.

Compare three short listening sketches before changing the game: (1) a 45–60 second arranged version of the current motif, (2) the same theme with percussion/bass layers entering on bar boundaries as pressure rises, (3) the same composition using synthetic versus small sampled instruments. Judge repetition, energy, transition quality and whether hit/XP cues stay readable at matched loudness. Then test pause/resume, reward interruptions, dense-frame stalls, stereo correctness and native queue underruns. These experiments would inform the choice; no preference is established yet.
