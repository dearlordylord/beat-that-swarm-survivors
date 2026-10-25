# PLDB and methods for a bot improvement laboratory

Research date: 2026-10-25. This is research and a proposed adaptation, not an executed balance campaign. No classifier requests or optimizer installation were performed.

## What PLDB actually contributed

[PLDB](https://pldb.kirancodes.me/) indexes programming-language and software-engineering venues, including ASE/FSE/ICSE; it does not cover all game-AI literature. Its [public search API](https://pldb.kirancodes.me/api) supplied the discovery metadata retained in [the search receipt](balance-bots-pldb-search.json). Queries, result limits and total counts are recorded; only the first five results per query were inspected. This is a targeted source selection, not an exhaustive state-of-the-art survey or ranking.

The exact phrase `game balancing` found *Explaining the Behaviour of Game Agents Using Differential Comparison* (Castellano et al., ASE workshop 2022, [DOI](https://doi.org/10.1145/3551349.3560503)). Its indexed abstract concerns contrasting agents to expose distinctive behavior. The publisher refused full-text access (HTTP 403); no detailed algorithm or reproduced result from that paper is claimed here. Our proposed before/after decision comparison is our design, not a replication of its inaccessible method.

The broader game-testing query led to accessible primary work:

| Work | Supported finding | Adaptation for Survivors | Boundary |
| --- | --- | --- | --- |
| [MIMIC, ASE 2025, author paper](https://arxiv.org/html/2510.01635v1), [artifact](https://github.com/Mimic-Persona/MIMIC) | Personality-conditioned agents explore different strategies. The authors explicitly say traits were not independently validated against real player data; evaluated games were not time-sensitive RPG tasks. | Maintain distinct test policies instead of collapsing the roster into one strongest strategy. | Diversity is useful coverage, not evidence of human likeness; do not copy its per-action LLM execution into a real-time bulk bot. |
| [Wuji, ASE 2019, author implementation](https://github.com/NeteaseFuxiRL/wuji), [author PDF](https://nos.netease.com/mg-file/mg/neteasegamecampus/art_works/20200812/202008122020238586.pdf) | Combines game progress and exploration for bug discovery through evolutionary multi-objective optimization and RL. | Track coverage and exploit discovery separately from survival; a camping survivor can miss most mechanics. | This is game testing, not a proof of balance or a reason to add a DRL stack now. |
| [Reflexion, NeurIPS 2023 author paper](https://arxiv.org/abs/2303.11366) | Uses task feedback and retained textual reflection between trials, without updating model weights. | The assistant retains concrete failures, proposes a policy patch, and tests it against a frozen game. | A verbal retrospective is a hypothesis. Acceptance requires actual execution, not the model's explanation. |
| [Voyager, 2023 author paper](https://arxiv.org/abs/2305.16291) | Uses a reusable executable skill library and environment/error feedback to improve programs in Minecraft. | Preserve validated movement/XP-routing behaviors with counterexample fixtures and versioned policy code. | Its Minecraft results do not establish performance in a fast survivors game; use offline code improvement rather than LLM calls in every tick. |

## Methods for the experiment, not new gameplay dependencies

[NIST's randomized-block guidance](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm) holds nuisance factors constant within blocks. For our proposed comparisons, a block is a declared seed/setup/policy combination, with candidate order randomized where execution order affects measurements. Frames from one run are not independent replications. Seeds/configurations are the replication units.

[NIST's experimental-design catalogue](https://www.itl.nist.gov/div898/handbook/pri/section3/pri3.htm) includes factorial and response-surface designs. Start with causal ablations, then a small interaction check: baseline, lower early spawn budget A, lower crowd-damage term B, and A+B. This separates the compounded effects that a long sequence of one-factor edits can hide. Preserve a solo control when testing multiplayer scaling.

[Optuna's official multi-objective tutorial](https://optuna.readthedocs.io/en/stable/tutorial/20_recipes/002_multi_objective.html) exposes objective directions, Pareto candidates and constraints; it also warns that too many objectives make many trials non-dominated. If bounded sweeps become costly, use a pinned optional experiment supervisor to propose a small parameter vector. Keep most requirements as constraints, and inspect the tradeoffs among a few primary outcomes. The optimizer never decides that fun has been maximized. No Optuna integration has been implemented or benchmarked here.

[Targeted Property-Based Testing, ISSTA 2017](https://proper-testing.github.io/papers/issta2017.pdf) guides generated inputs using execution feedback. [Hypothesis's official `target` API](https://hypothesis.readthedocs.io/en/latest/reference/api.html#hypothesis.target) is a practical implementation of feedback-guided search. For Survivors, targeted scenario search could maximize sustained unavoidable contact, unreachable XP, routing oscillation, or unequal partner participation, then retain minimized failures. Its adversarial sample is deliberately biased: do not use it to estimate ordinary player death rates. Keep the representative evaluation cohort separate. These are optional test methods, not a proposal to move game logic out of Bend.

## Important original-game comparison

Poncle's current [online FAQ](https://poncle.games/vs-online-faq) explicitly answers **No** to whether enemies scale with player count. Its [local-co-op FAQ](https://poncle.games/coop-faq) instead mentions fewer weapon slots with larger parties. The developer's [2023 local-co-op explanation](https://news.xbox.com/en-us/2023/07/11/vampire-survivors-couch-co-op-mode/) describes alternating level-ups and a shared screen. These concern different modes and dates; the local FAQ also contains older online-availability text, so it must not override the dedicated online FAQ.

Our present game has simultaneous per-living-player upgrades, a shared progression state, independently moving cameras and doubled ordinary spawn budget for two living players. Consequently, neither `2× enemies` nor `1× enemies` is established as the correct setting by the original's rules alone. Include `1×`, intermediate scaling and current `2×` as explicit experimental candidates while keeping the current reward rules fixed. Do not silently import the original's weapon limits, level allocation or revive mechanics as part of a numerical balance change.
