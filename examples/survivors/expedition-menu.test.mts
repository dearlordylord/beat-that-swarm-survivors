import { CHARACTERS, WEAPONS } from "./content.mts"
import { at } from "./host-values.mts"
import type { MenuState } from "./profile.mts"
import assert from "node:assert/strict"
import { test } from "node:test"
import { freshProfile } from "./progression.mts"
import { renderRunSelectors, renderCoopSetup } from "./expedition-menu.mts"

const state = (id: number): MenuState => ({
  profile: freshProfile(),
  character: 0,
  stage: 0,
  arcana: 0,
  mode: 0,
  openPanel: "character",
  pendingUnlock: { kind: "character", id }
})

await test("every locked survivor opens one full-width dossier beneath its own card pair", () => {
  for (let id = 1; id < 7; id++) {
    const html = renderRunSelectors(state(id), ["character"])
    const pairs = html.split(/<div class="choice-pair(?: details-right)?">/).slice(1)
    assert.equal(pairs.length, 4)
    const selectedPair = Math.floor(id / 2)
    for (let pair = 0; pair < 4; pair++) {
      assert.equal(at(pairs, pair).includes("data-unlock-details"), pair === selectedPair)
      assert(at(pairs, pair).includes(`data-character="${pair * 2}"`))
      if (pair * 2 + 1 < 7) assert(at(pairs, pair).includes(`data-character="${pair * 2 + 1}"`))
      else assert(!at(pairs, pair).includes('data-character="7"'))
    }
    const row = at(pairs, selectedPair)
    assert(row.indexOf("data-unlock-details") > row.indexOf(`data-character="${Math.min(selectedPair * 2 + 1, 6)}"`))
    assert.match(
      html,
      new RegExp(
        `is-inspecting[^>]*data-character="${id}" aria-pressed="false" aria-expanded="true" aria-controls="unlock-details-character-${id}"`
      )
    )
    assert.match(html, /data-character="0" aria-pressed="true"/)
    assert(!html.includes("remains equipped"))
    assert.equal((html.match(/data-close-unlock/g) || []).length, 1)
    assert(!html.includes("Inspecting"))
  }
})

await test("solo selectors and both co-op roles share the same pair layout", () => {
  for (const guest of [false, true]) {
    const html = renderCoopSetup(state(3), guest)
    assert.equal((html.match(/class="choice-pair/g) || []).length, 4)
    assert(html.includes("unlock-details-character-3"))
    assert.match(html, /data-character="0" aria-pressed="true"/)
  }
})

await test("closing the dossier leaves all seven choices and no stale detail controls", () => {
  const html = renderRunSelectors({ ...state(1), pendingUnlock: null }, ["character"])
  assert.equal((html.match(/data-character="/g) || []).length, 7)
  assert(!html.includes("data-unlock-details"))
  assert(!html.includes("aria-controls="))
})

await test("starting weapons are icons with accessible names in cards and dossiers", () => {
  const html = renderCoopSetup(state(5))
  assert(!html.includes("<p>Starting weapon:"))
  assert(
    html.includes(
      `class="starting-weapon" role="img" aria-label="Starting weapon: ${at(WEAPONS, 23).name}" tabindex="0"`
    )
  )
  assert(html.includes(`class="weapon-tooltip" aria-hidden="true">${at(WEAPONS, 23).name}</span>`))
  assert(
    html.includes(
      `class="starting-weapon" role="img" aria-label="Starting weapon: ${at(WEAPONS, 20).name}" tabindex="0"`
    )
  )
  assert.match(html, /data-icon="weapon\/23"/)
  assert.match(html, /data-icon="personal\/5"/)
})

await test("every selected survivor explains the automatic mechanic before starting", () => {
  for (const character of CHARACTERS) {
    const html = renderCoopSetup({ ...state(character.id), character: character.id, pendingUnlock: null })
    const card = html.slice(html.indexOf('<section class="a-run-card"'), html.indexOf("</section>"))
    assert(card.includes(character.description), `selected ${character.name} explains its mechanic`)
  }
})
