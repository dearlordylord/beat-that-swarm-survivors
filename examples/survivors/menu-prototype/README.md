# Survivors menu concepts — throwaway prototype

Question: how can a new player start immediately while a returning player can adjust a run without scanning four large catalogs?

Five structurally different concepts were designed with an Astra consultation:

- A — Ready to play: current run card and inline changes.
- B — Build bench: category workspace and run receipt.
- C — Guided setup: ready defaults with an optional wizard.
- D — Expedition board: stage-led selection with equipment slots.
- E — Run recipes: three starting styles with optional changes.

Verdict: the user selected A. Follow-up decisions: locked items remain alongside unlocked items (no View unlocks disclosure); inspecting a locked choice shows price/requirements and an explicit Buy button; every collapsed Survivor/Stage/Arcana/Mode row shows its selected icon and name. Prototype purchases affect memory only. The purchase-preview profile supplies hypothetical eligibility/gold for inspecting that flow.

The prototype uses Living Tree as a proposed beginner preset. Production adoption retains the existing actual configuration/defaults and real saved profile; the prototype is not the game authority. The production menu is rewritten separately in expedition-menu.mjs and menu-a.css, without prototype controls.

Run from this worktree root:

```sh
python3 -m http.server 8791 --bind 0.0.0.0 --directory examples/survivors
```

Open `http://<workspace-ip>:8791/?variant=A` through E. Bottom controls and arrow keys switch concepts; profile controls are examples, not saved progress. Start displays a run preview, with a separate link to the current game.

Captured on branch `prototype/survivors-menu-options`, outside main. No profile persistence or production mutations.
