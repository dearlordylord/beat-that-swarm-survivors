# Independent review of the balance and bot plan

Date: 2026-10-25. Reviewed the updated [main plan](survivors-balance-improvement-plan.md), four supporting notes (`engine-audit`, `primary-sources`, `local-history`, `pldb-methods`) and relevant parts of the current Bend Core. This is a research-protocol review: no new runs, dependency installations or game changes were performed.

**Verdict:** the narrow first experiment is feasible. It addresses the clarified user request to reduce monster counts for two players. A complete improvement system, new personas and attribution of all damage are not prerequisites. ×1.25 remains a candidate, not a confirmed result. The boundaries below are mandatory before accepting a result; they do not block preparing a minimal pilot.

## What must be clarified before selecting a multiplier

### 1. Check the shared Core, not similarity of final counters

The plan correctly requires the real `CoopCore`, the second player joining before the first step, independent controller memory and real offers. When extracting a quiet path, equivalence criteria must cover canonical state after each identical input: ECS components, personal records, RNG/clock, projectile owners, pickups, reward queues and round/required/offers. Equal final HP, kills and phase are insufficient: hidden-state differences can surface later.

The minimum implementation must reuse one typed transition, separating packaging/cosmetic data afterward. Quiet/public checks with fixed commands include both players moving, a natural level-up with both decisions, physical pickup, death and the 2→1 transition. This validates extraction of execution, not a new alternative simulator. Do not fix the controller or randomness ordering simultaneously, or the baseline has already changed.

### 2. Freeze the effect and acceptance rules before comparing four options

Reducing admission budget does not guarantee a proportional reduction in observed enemy counts: discrete admission, kills, the 500 cap and progression intervene. The first experiment's main results are actual ordinary-population time series and player outcomes under fixed policies. XP/levels, death times and the 2→1 transition are constraints, not results assumed unchanged in advance.

Before choosing a winner, declare preferences: the required density reduction, unacceptable progression loss or disappearance of threat, and what needs human review. Numerical thresholds may be set using baseline and design review **before** examining candidate results. Do not choose the metric after ×1.25 happens to look better on it.

The multiplier applies beyond the first 120 seconds. A small full-run baseline/selected-candidate control must therefore precede release, even if a broad full-run campaign remains a later stage. This control can reveal obvious loss of late progression; it does not establish statistical quality across the whole late game. The first 120 seconds suffice for cost piloting and early diagnosis.

### 3. Track context use jointly across both loops

Separating bot/game experiments is correct, but holdout independence must apply to the **combined artifact**: game/config hash + roster hashes + setup/metrics/selection rules. A seed previously used by Codex to improve a bot or choose a scenario is no longer fresh confirmation of subsequent balance with that bot.

Keep a simple log of cohort use by both loops. Freeze one candidate after development/validation, then open the final cohort. Comparing finalists and selecting a winner on that cohort is selection again, not independent confirmation of the winner. Human review can also influence selection: after such a change, repeat independent confirmation or explicitly label the cohort as used. One preselected finalist suffices for the first cycle, without a complex optimizer.

### 4. Preserve and explicitly measure player asymmetry

Source inspection confirms an important interaction: [spawn-view selection](../examples/survivors/game.bend#L1532) uses `seed % 2`, while [earned_xp](../examples/survivors/game.bend#L1140) includes personal Growth, **Curse14**, meta and **Arcana5**. [CoopCore.credit_xp](../examples/survivors/coop-core.bend#L378) applies these bonuses to the physical collector, then credits the result to shared XP. Personal parameters influence both the generated threat and shared progression speed.

For unequal characters/policies/Curse, declare both A/B and B/A arrangements. This is especially important before judging fairness of the second-player role. A minimal pilot may start with an identical pair; a mirrored unequal pair is a small follow-up control, not a requirement to build the entire roster immediately. XP changes after reducing population are part of the total balance effect: the XP formula is preserved, but its inputs change. Do not silently compensate with a new XP bonus in the same first experiment.

Product solo is needed as a regression check, but solo and single-player `CoopCore` do not have identical rules: co-op suppresses revive and excludes Revival from offers ([finalization](../examples/survivors/coop-core.bend#L394), [make_offers](../examples/survivors/coop-core.bend#L421)); solo has [revival_available](../examples/survivors/game.bend#L1147). To isolate player-count effects, Core1↔Core2 under shared setup is useful. For the first four-multiplier comparison, Core2 against Core2 suffices; do not attribute every difference from solo solely to the population multiplier.

## Methodological corrections without expanding the first stage

- **Paired seeds.** The main plan correctly limits the promise of common random numbers. In `local-history`, “made the paired comparison unfair” is too strong: RNG divergence does not invalidate outcome differences from the same initial seed. It removes the guarantee of identical events and may weaken variance reduction. Do not change RNG before the first experiment. When repeating a seed across setups/policies, do not treat those rows as fully independent; estimate uncertainty accounting for grouping by seed. Repeating one deterministic run checks reproducibility, not statistical sample size. [NIST](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) supports blocking conditions but does not establish that the proposed 32/16/32 sample sizes suffice.
- **Damage telemetry later.** “Applied damage by source” does not yet define attribution under overkill, invulnerability, shared armor/crowd bonuses and healing in the same step. [heal_after_damage](../examples/survivors/game.bend#L1168) already shows why HP differences are not damage. Initially, exact total requested damage, HP loss, effective healing and max-HP transitions suffice. Allocating HP loss across sources later requires an explicit convention, not inference from a cosmetic hit journal. This does not block the narrow population pilot.
- **Pressure is not human tension.** Population, HP, safe exits and survival are diagnostic indicators. A bot can survive better by avoiding interesting combat or XP; progression/engagement constraints and human play are therefore needed. Mobile review must assess threat readability, pickup opportunities and control, not merely confirm attractive charts. Without calibration against people, do not call a cautious/oracle bot a model of an ordinary player.
- **Bot/game arms race.** Retaining old policies and separate loops already protects against direct overfitting. Balance criteria must additionally remain design decisions: improved bot quality does not automatically change target human mortality. Updating goals is a separately declared decision, not an optimizer's response to an overly high bot score.
- **Sources and completeness.** The PLDB note accurately describes a targeted review, not an exhaustive state of the art. The approaches found do not justify requiring DRL, constant LLM calls or an installed optimizer for the first cycle. The checked [poncle online FAQ](https://poncle.games/vs-online-faq) does say enemies do not scale by player count; this disproves the necessity of our ×2, but not the optimality of ×1 for our progression. The final `local-history` paragraph about four or five policies before the first change should be treated as a later stage: the updated main plan reasonably narrowed the start.

## Minimal first cycle

1. Freeze the current game, one existing controller in two independent instances, explicit setup/seeds and offer-selection rules. Establish quiet/public Core equivalence and minimal population/HP/XP/level/phase/cost samples.
2. Run a small baseline pilot with a predeclared wall-time budget. Record exact run counts: for example, 4 seeds × 2 setups means 8 runs **per arm**, not across the entire solo/coop/four-multiplier matrix. Choose the next series size from measured cost.
3. Freeze panels and acceptance rules; compare ×2/×1.5/×1.25/×1, changing only the ordinary budget for two living players. Preserve rules for 0/1 living players, rounding and cap; do not alter existing HP/XP/damage/pauses or delete enemies already spawned.
4. Select one finalist using development/validation and mobile play; check fresh contexts, the 2→1 transition, solo regression and a small full run. Publish distributions and limits, not a promise of proven “fun.”
5. Then separately develop attribution, bounded observations, different policies and Codex retrospectives.

The research plan permits this start without a large laboratory. Acceptance of a particular multiplier remains open until execution: current documents and this review are not results of a new balance experiment.
