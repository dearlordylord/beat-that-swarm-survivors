# Browser combat audio

The browser synthesizer had a `shot` instrument but no caller. Its `hit` sound
only observed loss of the player's own HP. There was no sound for a projectile
birth, damage to an enemy or a blast-radius expansion.

`audio-events.bend` now owns cosmetic sound selection for solo and co-op:

- New player shots, hostile shots and area effects have distinct instruments.
- Body lifetime includes slot, kind, weapon variant and explicit generation or
  birth tick. Repeated observations of the same tick cannot replay births.
- Solo enemy HP reductions produce impacts; radius expansion produces a blast.
- Co-op impacts use the existing confirmed contact effects at the displayed
  contact time. A paint coalesces newly due contacts to one newest contact tick;
  targets in the same large blast do not each create an oscillator.
- Player hurt, healing, kills, XP/gold pickup, reward rounds and run outcomes
  follow the observed state changes. Join/rejoin and tick-zero configuration
  establish a silent baseline. UI choices keep their explicit button sound.
- Muting still advances the cosmetic ledger. Unmuting does not replay a backlog.

JavaScript only projects observations and synthesizes the selected sounds.
Music and SFX have independent voice limits (32 and 24) and separate mix gains.
An explicit gesture also resumes an interrupted audio context. The iPhone's
silent switch remains respected; no audio-session override was introduced.

## Validation

The 56 Bend laws cover public dispatch and the birth/impact admission boundaries;
six type-correct semantic mutants are rejected. Runtime cases include repeated
and stale snapshots, pooled-slot reuse, joining with bullets already alive,
silent health configuration, reward deduplication and repeated confirmed hits.

Chromium OfflineAudioContext rendered all 14 instruments to nonzero PCM without
individual waveform clipping. The browser mixer respected both voice limits,
cleared all sources on reset and exercised interrupted-context resume dispatch.

Real browser runs exercised solo and two peers over Iroh. Solo produced shots,
kills, hurt, pickup and defeat; both co-op peers produced shots, confirmed
impacts, kills, hurt, pickup and a level-up. Browser errors were absent. A
1,000-row observation probe measured 0.27 ms median and 1.27 ms p95 on the test
machine; this is an audio-observation cost, not a cross-device frame-rate claim.

The tests establish signal generation and integration, not audibility through a
particular physical speaker. The user independently confirmed music on iPhone
after switching off the phone's silent mode.
