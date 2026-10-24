# Adaptive chip-metal music

`../music.bend` owns the common 132 BPM score, MIDI pitches, four arrangement bands, smoothing, hysteresis and latest-target bar commitment. `game.bend` observes nearby enemies (weighted by type and proximity), hostile projectiles and the player's health. Audio observations happen outside ECS advancement.

The score combines a square bass, short pulse riffs/power fifths, a lead, kick, snare, noise hats and crashes. Stage transposition and a longer verse/lead form vary the motif. Rising danger adds subdivisions, denser kicks and lead layers. This is procedural composition and synthesis, not a neural music service or a prerecorded track.

There is one replaceable target band, never a queue of transitions. On a bar boundary, the hosts use the latest available world observation, including a fresh boundary observation. Separate rising/falling thresholds and a slower release avoid chatter. The small core laws prove latest-target selection and retention between boundaries; a mutant that retains the old band is rejected. They do not prove the complete audio drivers or musical quality.

Browser `audio.mjs` schedules the shared notes with Web Audio on an independent 25 ms timer, preserving the musical position through pause/reward/mute. It delays scheduling a new bar until within 30 ms. Music and effects have separate voice budgets; browser instrument synthesis remains JavaScript.

Native `native_audio.bend` renders bounded interleaved stereo blocks at 22,050 Hz, with ten voices, into the existing Bend Audio effect. The target queue is 3,072 frames (about 139 ms). New bar decisions wait until no more than 1,024 frames (46 ms) remain queued. Already queued sound cannot be cancelled by this API, so latest-target means latest at generation, with that bounded playback horizon. Native silence/pause does not keep filling the ring. Ordinary pause retains the musical cursor; a new run resets it. Short event cues remain available while a reward pauses music.

Validation receipts and three eight-second listening sketches are in `../../../../bend-games/research/adaptive-chip-metal-20261024/`. Offline Web Audio rendering verifies nonzero, unclipped output and relative density; it is not a physical-speaker audition. The native synthesis fixture exercises stereo packing, lifetime/cap/clock/queue rules and a ten-voice pure-synthesis benchmark. It does not open an audio device. No new Bend runtime, WASM backend or ECS behavior is required.
