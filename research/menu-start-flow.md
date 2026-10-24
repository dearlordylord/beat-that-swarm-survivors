# Main menu: selected concept and unlock flow

Five menu structures were discussed with Astra and prototyped on the existing game route: ready-to-play inline setup, build bench, optional wizard, expedition board and run recipes. The user selected A (ready to play), then requested that locked catalog items remain visible, purchases be explicit, and each collapsed choice show both its icon and selected name.

The five throwaway concepts are captured outside main on local branch `prototype/survivors-menu-options`, commit `7fa3ad6`, worktree `../bendvy-menu-options`. They use in-memory sample profiles and are not game authority. The main branch contains the rewritten production A renderer only (`expedition-menu.mjs`, `menu-a.css`), with real profile/progression operations retained in the existing browser host.

Survivor, Stage, Arcana and Mode retain compact collapsed rows. Opening a category exposes all its items, including locked items, without a second View unlocks disclosure. Inspecting a locked survivor/stage never equips it or spends gold. The inspector displays catalog price, balance, requirements and an explicit Buy action. Actual `unlock` validates affordability/requirements and saves the purchase. Progress-only modes display their real requirements and have no invented gold purchase. Existing selected configuration/defaults and combat rules remain unchanged.

Start is available near the top and in a persistent bottom bar. Header GitHub links point to the example and Bendvy. Both collapsed and expanded views retain selected icons; prototype controls are not shipped.

Actual Chromium smoke covers all eight survivor cards and five stage cards, four selected icons, disabled fresh-profile purchases, no spend on inspection, exact character/stage purchase prices, persistence after reload, and the existing collection/gameplay/map/reward/pause/touch flows. Test saves are isolated browser fixtures. Prototype and production snapshots are archived in `../../bend-games/research/survivors-menu-concepts-20261024/`.
