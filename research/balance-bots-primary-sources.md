# Bot-assisted balance research for Survivors

**Status:** Research snapshot, 2026-10-25. Primary sources checked on this date.
**Scope:** Offline balancing of a fixed game build and fixed runtime difficulty. The findings below do not authorize or recommend runtime dynamic difficulty adjustment (DDA).

## Recommendation in brief

Use bots to answer narrow, repeatable questions about a frozen game revision: which spawn, enemy, XP, or upgrade parameters produce the intended survival and pressure distributions across seeds, starting profiles, party sizes, and play styles? Keep the game parameters fixed during each run. Tune the bots in a separate phase against a frozen game. Reserve a final seed set that neither the bot improver nor the game-parameter search sees. Then inspect the promising candidates in actual human play; bot survival and kill counts are not measures of enjoyment.

The most useful pattern is not an optimizer by itself. It is a loop that combines (1) an explicit design target, (2) a declared population of player proxies, (3) simulation-based candidate search, (4) held-out runs and uncertainty reporting, and (5) human observation to catch goals the metrics and bots miss.

## What the sources establish

### Pressure has a time shape, and that is distinct from difficulty

Michael Booth’s [Valve AIIDE 2009 slides on the Left 4 Dead AI systems](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf) describe a build-up, sustained peak, fade, and relax cycle. Threat population is high during the build-up; after a team-intensity peak, major threats are suppressed, and a quieter period begins when the existing engagement has settled. The presentation explicitly says the Director changes **frequency/pacing**, not difficulty amplitude. Its intensity estimate combined per-survivor signals and tracked the maximum across the four-person team. This is a useful model for thinking about a pressure *curve* and team-level telemetry, not a prescription to copy its numbers or make Nightfall adapt spawns during a run.

Booth’s [GDC 2009 cooperative-design slides](https://steamcdn-a.akamaihd.net/apps/valve/2009/GDC2009_ReplayableCooperativeGameDesign_Left4Dead.pdf) add relevant production evidence: Valve used Survivor bots to assume a baseline four-player team during game tuning. The talk also treats the whole Survivor team as the player. This supports building full-party test scenarios for our co-op mode. It does **not** provide a general formula for how enemy count or health should scale with player count; the talk describes one four-player FPS with strong cooperation mechanics.

**Takeaway for Survivors:** Define a fixed, designer-approved pressure schedule by elapsed game time. Measure realized pressure and player consequences in time buckets. For co-op, report both per-player and team-level observations. Compare solo and two-player runs as separate conditions; discover the scaling from evidence instead of assuming “twice the players means twice the enemies.”

### Choose the objective before choosing the search algorithm

Zook, Fruchter, and Riedl’s [FDG 2014 paper, “Automatic Playtesting for Game Parameter Tuning via Active Learning”](https://www.fdg2014.org/proceedings.html) is directly about selecting a **fixed design** after mechanics have been chosen. It formalizes designer goals as objectives and uses active learning to select the next parameter settings to test. Its shoot-’em-up study uses human playtest results; it is not an argument that a simulation score fully represents players. The paper contrasts fixed-design tuning with prior DDA work.

Hernandez et al.’s [2020 IEEE Conference on Games paper, “Metagame Autobalancing for Competitive Multiplayer Games”](https://ieee-cog.org/2020/papers/paper_100.pdf) represents high-level strategies as a population of agents, defines a designer target over their outcomes, then searches bounded game parameters using simulation and a black-box optimizer (TPE/Optuna in their implementation). They explicitly allow some parameters to be fixed and note that simulation, policies, and optimizer choices all introduce stochasticity. Their example is a competitive two-player game, so its win-rate target is not the right objective for a PvE survivors game. The useful generalization is to specify a target over diverse player styles and meaningful outcomes—e.g. survival-time bands, XP collection, or build viability—rather than “maximize bot score.”

The same paper is also a warning against trusting an optimizer’s best number: its own optimized settings produced degenerate effects such as very short fights and an ability that was almost permanently active. The authors recommend inspecting how the resulting agents actually behave, and note that their MCTS proxy tended toward very offensive early play and defensive late play. An optimizer can satisfy a badly chosen metric in ways the designer did not intend.

### Bot performance is not player enjoyment, and one “smart” bot is not a population

Pfau et al.’s [2020 IEEE CoG paper, “Dungeons & Replicants”](https://ieee-cog.org/2020/papers/paper_152.pdf) gives a concrete example of bots modeled from player actions: it trains player-specific behavior models using six months of contextual action data from 213 Aion players, then uses those replicas to detect PvE and PvP balance differences. The paper argues that optimal or super-human agents do not represent a human player population. Its evidence comes from a particular MMORPG dataset and combat setup, not from survivors gameplay; reproducing this method would require our own suitable player traces.

Ambinder’s [Valve GDC 2009 playtesting slides](https://cdn.akamai.steamstatic.com/apps/valve/2009/GDC2009_ValvesApproachToPlaytesting.pdf) describe different evidence sources for different questions: gameplay observation and verbal reports for interaction and player intent, telemetry for behavior and comparisons, and surveys for standardized subjective ratings. The talk notes that aggregate stats can hide extremes and lose context, while observation also needs careful interpretation. For our use, bot metrics can establish whether a run reaches a declared survival/pressure target; they cannot establish that the target is fun or that a player felt challenged in the desired way.

**Takeaway for Survivors:** Start with several deterministic, interpretable policy variants (for example, cautious survival, XP-seeking, and aggressive clearing) and treat them as test conditions, not as equally human-like personas. Keep classifier-assisted play out of bulk evaluation: the current classifier alias is mutable, its calls are costly, and identical seeds do not make its decisions repeatable. It can help explore an individual choice or visible run, but it is not a stable baseline bot. If we later capture player traces, use them to design better player proxies rather than claiming a heuristic is “human.”

### Held-out seeds catch a real failure mode

Cobbe et al.’s [ICML 2020 Procgen paper](https://proceedings.mlr.press/v119/cobbe20a/cobbe20a.pdf) studies generalization in procedurally generated game environments. It shows agents can overfit to their training levels and reports a large train/test gap when the training episodes use a fixed level sequence while test sequences are randomized. Their exact environment and learned agents differ from Nightfall, but the experimental lesson transfers: if the same seeds are used to choose every new parameter set and bot policy, the “winner” may be fitted to those trajectories.

Agarwal et al.’s [NeurIPS 2021 paper, “Deep Reinforcement Learning at the Edge of the Statistical Precipice”](https://proceedings.neurips.cc/paper_files/paper/2021/file/f514cec81cb148559cf475e7426eed5e-Paper.pdf) addresses uncertainty in game-agent results: a few runs and point estimates can mislead, and it recommends interval estimates and robust aggregate reporting. It is a deep-RL evaluation paper rather than a game-balance recipe, so its statistics should be adapted rather than imported wholesale.

**Takeaway for Survivors:** Use a fixed development seed cohort for paired candidate comparisons and a separate locked holdout cohort for final confirmation. Show distributions and uncertainty, not only a mean or a best run. Since the run can stop at a requested horizon without death or victory, report completed runs and bounded/censored observations separately; do not call a run that is still alive at the time cap a “win.”

## A practical protocol for our game

### 1. Freeze and identify the experiment

Record the game source/binary hash, BendHub dependency identity, parameter vector, bot-policy versions, seed list, starting profile, character, game mode, horizon, and completion status. Bulk comparisons should use the deterministic native Bend batch path with no classifier calls. Each pair of candidates should use the same development seeds and conditions so the comparison is not confounded by a different seed sample.

Today, the documented native batch is deterministic and emits one end-of-run summary per seed. It records values such as tick, phase/outcome, HP, level, XP, kills, gold, choices and remaining XP, but not a time series ([`offline-batch.bend`](../examples/survivors/offline-batch.bend#L50)). The bot guide labels the current policy as `bend-resource-memory-v1` and says classifier responses are external, non-deterministic inputs ([bot guide](../tools/survivors-bot/README.md)). This is enough for broad end-state comparisons; it is not enough to describe a pressure curve within a run.

### 2. Define what “balanced” means for each mode

Write the target before tuning. Do not infer a numeric target from a handful of existing runs. For each elapsed-time bucket, collect or derive:

- **Threat exposure:** living enemies near the player, arrivals/spawns by enemy type, and hostile projectile density. An alive-count alone can miss intense pressure when weapons kill quickly.
- **Player cost:** HP loss per second, time spent at low HP, invulnerability/revival use, and death tick. In co-op, include both per-player values and team outcomes.
- **Growth/economy:** XP created and collected, XP left behind, level-up/choice timing, and weapon/passive rank/evolution progress.
- **Run outcome:** reach the selected milestone, die, or stop at the bounded horizon. Keep fresh and advanced profiles separate.

Instrument time-bucket samples in the Bend run path if a pressure curve is required; retain a compact set of samples rather than serializing the complete world. This is a measurement addition, not a new game mechanic. Do not use bot kills alone as a difficulty score: an aggressive policy can kill more while taking more damage or abandoning XP.

For single-player and two-player co-op, define separate target ranges and regression guards. The co-op matrix should include at least different player counts, character pairings, and policy pairings. Shared XP and joint level-up pacing mean that a two-player result cannot be inferred by multiplying a solo score. The Valve case study supports full-team bot test runs; it does not imply a particular multiplier for our game.

### 3. Keep the game and bot tuning axes separate

First freeze the policy roster and tune one small group of game parameters—e.g. spawn schedule/weighting—against those same policies. Next freeze the accepted game and change one bot policy parameter or behavior. Evaluate the new bot against the unchanged game and the other policy variants. If bot and game parameters both change in the same loop, a higher score cannot tell us whether the game improved or the bot merely adapted to it. This separation is an inference from the parameterized-environment and policy-population setup in the autobalancing paper; it is a control needed for interpretable results.

Do not make a learning agent part of the required bulk suite yet. The current Bend bots are deterministic controllers, and the optional Jev classifier only advises decisions; neither mechanism learns a better bot after a run. A separate “bot improver” can review receipts, identify a failure mode, propose one policy change, and compare it against the frozen roster. That is a human-reviewed iteration loop, not autonomous self-improvement.

### 4. Tune co-op as its own target, not as a solo multiplier

For each game parameter candidate, run both solo and co-op conditions on matched seed sets. In co-op, include policy combinations that expose asymmetric behavior: both players cautious, one XP collector plus one aggressive clearer, and two XP collectors competing for the same drops. Track each player’s XP/level participation as well as the shared run outcome. The goal is to find whether an adjustment improves a team outcome without making one player irrelevant or changing the intended shared-XP experience. The actual acceptance ranges must be chosen by the game designer and human playtests; the papers do not supply a universal co-op scaling equation.

### 5. Search only after the target and measurements are stable

Start with a small bounded sweep or paired one-factor comparisons to confirm the metrics respond to a parameter. Then use an automated black-box search (the cited papers demonstrate active learning and TPE as examples) only for parameters with a clear, bounded effect. Preserve the evaluated candidate table, objective components, failed/timed-out runs, and all parameter bounds. Inspect a few actual traces for every candidate the search favors. Do not let the search alter character rules, unlocks, or other protected parts of the game unless those are explicitly included in the design question.

For each candidate, show the pressure curve by time bucket with seed-level spread, death/survival distribution, and XP progression. Compare the same controller roster on the development seeds, then confirm the selected candidate on held-out seeds that were not used to choose it. If several candidates are tried against the holdout set, that set has become another tuning set; reserve a new final cohort for the final check.

### 6. Human review closes the loop

Select a small number of candidates from the bot campaign and play them directly, ideally with both solo and co-op sessions. Record a concrete design hypothesis first—for example, “pressure should rise by the first boss window but retain enough recovery space for players who actively collect XP.” Observe whether the run feels too quiet, unfair, or recovery-starved; ask a short, consistent challenge/agency question afterward. Keep telemetry and subjective feedback side by side rather than using one to stand in for the other.

## Limits and implications

- The studies provide methods and failure warnings, not a proven balance target for our exact Vampire Survivors-style game.
- The currently documented native batch reports terminal summaries, so it cannot yet quantify pressure-by-time without additional sampling.
- The visible decision journal is an observation tool; its short runs do not establish full-run balance or classifier superiority.
- Existing bot observations are omniscient and the policy roster is not a measured sample of human players. Treat results as “this policy did X,” not “players will do X.”
- Automated game tuning can find metric exploits. Require design review, policy-matrix regressions, and human play before accepting a parameter change.
- No runtime DDA is proposed. Left 4 Dead is a useful pacing example, but this plan evaluates a fixed spawn/difficulty schedule offline.

## Primary sources used

1. Michael Booth, [“The AI Systems of Left 4 Dead,” Valve / AIIDE 2009 slides](https://www.valvesoftware.com/en/publications) ([direct PDF](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)). Primary production account of the Director and pressure phases; not a peer-reviewed comparative study.
2. Michael Booth, [“Replayable Cooperative Game Design: Left 4 Dead,” Valve / GDC 2009 slides](https://steamcdn-a.akamaihd.net/apps/valve/2009/GDC2009_ReplayableCooperativeGameDesign_Left4Dead.pdf). Primary production account including full-team Survivor bots for tuning; one game and four-player FPS context.
3. Mike Ambinder, [“Valve’s Approach to Playtesting: The Application of Empiricism,” Valve / GDC 2009 slides](https://cdn.akamai.steamstatic.com/apps/valve/2009/GDC2009_ValvesApproachToPlaytesting.pdf). Primary production account of observation, telemetry, design experiments, and surveys.
4. Alexander Zook, Eric Fruchter, and Mark O. Riedl, [“Automatic Playtesting for Game Parameter Tuning via Active Learning,” FDG 2014](https://www.fdg2014.org/proceedings.html) ([author PDF](https://sites.cc.gatech.edu/fac/riedl/pubs/zook-fdg14.pdf)). Fixed-design parameter tuning and human-in-the-loop active learning in a shoot-’em-up.
5. Daniel Hernandez et al., [“Metagame Autobalancing for Competitive Multiplayer Games,” IEEE CoG 2020](https://ieee-cog.org/2020/papers/paper_100.pdf). Bounded simulation-based parameter search against designer-defined agent-outcome targets; competitive game and MCTS-specific behavior limits transfer.
6. Johannes Pfau et al., [“Dungeons & Replicants: Automated Game Balancing via Deep Player Behavior Modeling,” IEEE CoG 2020](https://ieee-cog.org/2020/papers/paper_152.pdf). Player-specific proxies trained from six months of contextual Aion actions from 213 players; domain and available-data limitations apply.
7. Karl Cobbe et al., [“Leveraging Procedural Generation to Benchmark Reinforcement Learning,” ICML 2020 / PMLR 119](https://proceedings.mlr.press/v119/cobbe20a.html) ([paper PDF](https://proceedings.mlr.press/v119/cobbe20a/cobbe20a.pdf)). Evidence for train/test seed separation and generalization checks in generated environments.
8. Rishabh Agarwal et al., [“Deep Reinforcement Learning at the Edge of the Statistical Precipice,” NeurIPS 2021](https://proceedings.neurips.cc/paper_files/paper/2021/file/f514cec81cb148559cf475e7426eed5e-Paper.pdf). Evaluation uncertainty and aggregate metrics; its recommendations concern RL experiments and should be adapted to run-level game outcomes.
