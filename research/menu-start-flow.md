# Main menu: selected concept and unlock flow

Five menu structures were discussed with Astra and prototyped on the existing game route: ready-to-play inline setup, build bench, optional wizard, expedition board and run recipes. The user selected A (ready to play), then requested that locked catalog items remain visible, purchases be explicit, and each collapsed choice show both its icon and selected name.

The five throwaway concepts are captured outside main on local branch `prototype/survivors-menu-options`, commit `7fa3ad6`, worktree `../bendvy-menu-options`. They use in-memory sample profiles and are not game authority. The main branch contains the rewritten production A renderer only (`expedition-menu.mjs`, `menu-a.css`), with real profile/progression operations retained in the existing browser host.

The production interaction rules belong to
[`expedition-menu.mjs`](../examples/survivors/expedition-menu.mjs), the presentation
to [`menu-a.css`](../examples/survivors/menu-a.css), and purchase authority to
[`menu-progression.bend`](../examples/survivors/menu-progression.bend).
The design separates browsing from spending and keeps the selected loadout
visible, so an inspection action cannot become an accidental purchase.

Actual Chromium smoke covers all eight survivor cards and five stage cards, four selected icons, disabled fresh-profile purchases, no spend on inspection, exact character/stage purchase prices, persistence after reload, and the existing collection/gameplay/map/reward/pause/touch flows. Test saves are isolated browser fixtures. Prototype and production snapshots are archived in `../../bend-games/research/survivors-menu-concepts-20261024/`.
