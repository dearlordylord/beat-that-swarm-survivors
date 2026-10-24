# Adaptive chip-metal music

The shared score and arrangement decisions belong to [music.bend](../music.bend).
[game.bend](../game.bend) derives danger observations from simulation data outside
ECS advancement. Browser [audio.mjs](../audio.mjs) and native
[native_audio.bend](../native_audio.bend) own their transport and synthesis.
Timing constants, thresholds, voice budgets and queue policies belong in those
sources.

This separation keeps musical decisions shared while allowing each presentation
to use its own audio API. Already scheduled audio limits how quickly a newly
observed target can be heard; generation decisions and physical playback are
different boundaries.

[LAWS.bend](LAWS.bend) and [PROOF.bend](PROOF.bend) cover the small scheduling
core. Their scope excludes complete audio drivers, physical playback and
subjective musical quality. Browser scheduling and offline PCM checks likewise
do not establish a physical-speaker audition.

Historical receipts, source hashes, rejected mutants and listening sketches are
recorded under the adaptive-audio section of [VALIDATION.md](../VALIDATION.md).
