# Balance intent

Early physical XP should give the player a usable build before enemies become
hard to kill. Later progression should preserve meaningful choices without
repeated interruptions. Movement, build choices and encounter pressure should
matter throughout a run. This is a tuning goal, not numerical parity with
Vampire Survivors.

Authoritative tuning lives in [game.bend](game.bend), [encounters.bend](encounters.bend)
and [projectile.bend](projectile.bend). Allocation and admission limits live in
[pools.bend](pools.bend). Do not copy their values or formulas into this document.

The map excludes rescue wisps and ward towers. Their historical damage and
rewards must not be used to judge the current starter weapon or progression.

Reproducible diagnostics, source bindings and complete-run observations are
recorded in [VALIDATION.md](VALIDATION.md). Earlier actor-assisted or differently
tuned runs qualify only their recorded source versions. Bot observations do not
establish human difficulty, enjoyable balance or fresh-profile win rates.

## Further evaluation

Compare movement policies and focused versus mixed builds while keeping fresh
and purchased profiles separate. Observe survival, contact pressure, enemy
density, progression, evolution timing and rewards. Hold out scenarios from
tuning; assess readability, fairness and useful feedback separately through
human playtesting. A correctness proof or a successful controller cannot replace
that evaluation.
