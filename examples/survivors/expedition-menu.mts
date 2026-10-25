import { displayText, at, defined } from "./host-values.mts"
import type { Profile, Setup, SetupKind, MenuState } from "./profile.mts"
import { survivorColor, survivorSvg } from "./survivor-art.mts"
import { startControl } from "./menu-controls.mts"
import { CHARACTERS, STAGES, ARCANA, RUN_MODES, WEAPONS } from "./content.mts"
import { isUnlocked, purchaseStatus } from "./progression.mts"
interface SelectionItem {
  id: number
  name: string
  description: string
  icon?: string
  weapon?: number
  hint?: string
  cost?: number
}
const kinds: SetupKind[] = ["character", "stage", "arcana", "mode"]

const catalog: Record<SetupKind, readonly SelectionItem[]> = {
  character: CHARACTERS,
  stage: STAGES,
  arcana: ARCANA,
  mode: RUN_MODES
}
const labels = { character: "Survivor", stage: "Stage", arcana: "Arcana", mode: "Mode" }
const esc = (value: unknown) =>
  displayText(value).replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] ?? c
  )
export function portrait(id = 0, size = "large") {
  return `<div class="pixel-portrait portrait-${size}" style="--survivor:${survivorColor(id)}" aria-label="${esc((CHARACTERS[id] || at(CHARACTERS, 0)).name)}">${survivorSvg(id)}</div>`
}
export function stageArt(id = 0) {
  return `<div class="stage-art stage-art-${id}" aria-hidden="true"><div class="moon"></div><div class="ridge ridge-back"></div><div class="ridge"></div><div class="ground"></div><div class="tomb tomb-one"></div><div class="tomb tomb-two"></div><div class="tree tree-one"></div><div class="tree tree-two"></div><span class="stage-art-coordinate">${esc(at(STAGES, id).name.toUpperCase())}</span></div>`
}
function icon(kind: SetupKind, item: SelectionItem) {
  if (kind === "character") return portrait(item.id, "small")
  return `<span class="choice-glyph" aria-hidden="true">${esc(kind === "arcana" ? item.icon : kind === "stage" ? ["☾", "▤", "♧", "❄", "♨"][item.id] : ["◷", "◑", "∞", "⚔"][item.id])}</span>`
}
function unlocked(profile: Profile, kind: SetupKind, id: number) {
  return isUnlocked(profile, kind, id)
}
function inspector(profile: Profile, pending: MenuState["pendingUnlock"], kind: SetupKind) {
  if (!pending || pending.kind !== kind) return ""
  const item = catalog[kind].find((x) => x.id === pending.id)
  if (!item) return ""
  const status = purchaseStatus(profile, kind, item.id)
  const owned = status.owned
  const eligible = status.eligible
  const buyable = kind === "character" || kind === "stage"
  return `<section class="unlock-inspector banner-panel" data-unlock-details tabindex="-1" aria-label="${esc(item.name)} unlock details"><div class="banner-heading"><span class="eyebrow">${owned ? "Available" : "Unlock " + labels[kind].toLowerCase()}</span><h3>${esc(item.name)}</h3></div><p>${esc(item.description)}</p>${kind === "character" ? `<p>Starting weapon: ${esc(at(WEAPONS, item.weapon ?? 0).name)}</p>` : ""}${item.hint ? `<p class="requirement">${eligible ? "✓ Requirement met: " : "Requirement: "}${esc(item.hint)}</p>` : ""}${buyable ? `<div class="purchase-line"><span>Price <strong>${item.cost} gold</strong> · Your balance <strong>${profile.gold} gold</strong></span><button class="primary" data-buy-kind="${kind}" data-buy-id="${item.id}" ${status.canBuy ? "" : "disabled"}>${owned ? "Unlocked" : "Buy " + item.name + " · " + item.cost + " gold"}</button></div>${!owned && !status.affordable ? `<p class="requirement">Earn ${status.missingGold} more gold to buy this ${labels[kind].toLowerCase()}.</p>` : ""}` : "<p>Unlock this mode by completing its requirement.</p>"}</section>`
}
function picker(state: MenuState, kind: SetupKind) {
  return `<div class="choice-list" role="group" aria-label="Choose ${labels[kind].toLowerCase()}">${catalog[kind]
    .map((item) => {
      const open = unlocked(state.profile, kind, item.id)
      const selected = open && state[kind] === item.id
      const inspecting = state.pendingUnlock?.kind === kind && state.pendingUnlock.id === item.id
      return `<button class="choice ${selected ? "is-selected" : ""} ${open ? "" : "is-locked"} ${inspecting ? "is-inspecting" : ""}" data-${kind}="${item.id}" aria-pressed="${selected}">${icon(kind, item)}<span class="choice-copy"><strong>${esc(item.name)}</strong><small>${esc(kind === "character" ? at(WEAPONS, item.weapon ?? 0).name : item.description)}</small>${!open ? `<span class="locked-badge">${kind === "mode" ? "Locked · View requirement" : "Locked · " + item.cost + " gold"}${inspecting ? " · Inspecting" : ""}</span>` : ""}</span><span class="choice-check" aria-hidden="true">${selected ? "✓" : open ? "+" : "◇"}</span></button>`
    })
    .join("")}</div>${inspector(state.profile, state.pendingUnlock, kind)}`
}
export function renderRunCard({ character = 0, stage = 0, arcana = 0, mode = 0 }: Partial<Setup>) {
  const c = CHARACTERS[character] || at(CHARACTERS, 0)
  const destination = STAGES[stage] || at(STAGES, 0)
  const charm = ARCANA[arcana] || at(ARCANA, 0)
  const runMode = RUN_MODES[mode] || at(RUN_MODES, 0)
  return `<section class="a-run-card" aria-label="Current run"><div class="a-survivor">${portrait(c.id)}<div><span class="eyebrow">${esc(c.title)}</span><h2>${esc(c.name)}</h2><p>${esc(at(WEAPONS, c.weapon).name)}</p></div></div><div class="a-stage">${stageArt(destination.id)}<div class="a-stage-caption"><span class="eyebrow">Destination</span><strong>${esc(destination.name)}</strong></div></div><div class="a-run-strip"><span>${esc(charm.icon)} ${esc(charm.name)}</span><span>${["◷", "◑", "∞", "⚔"][runMode.id]} ${esc(runMode.name)} <i>·</i> ${runMode.durationLabel}</span></div></section>`
}
export function renderRunSelectors(state: MenuState, selectedKinds: SetupKind[] = kinds, staticPickers = false) {
  const selected = Object.fromEntries(
    selectedKinds.map((kind) => [kind, catalog[kind].find((item) => item.id === state[kind]) || catalog[kind][0]])
  )
  return `<div class="selection-rows">${selectedKinds.map((kind) => `<section class="selection-item"><button class="selection-row" data-menu-panel="${kind}" aria-expanded="${state.openPanel === kind}"><span>${labels[kind]}</span><strong class="selected-choice">${icon(kind, defined(selected[kind]))}<span>${esc(defined(selected[kind]).name)}</span></strong><span class="change-label">${state.openPanel === kind ? "Close −" : "Change +"}</span></button>${state.openPanel === kind || staticPickers ? `<div class="inline-picker" ${state.openPanel === kind ? "" : "hidden"}>${picker(state, kind)}</div>` : ""}</section>`).join("")}</div>`
}
export function renderCoopSetup(state: MenuState, guest = false) {
  return `<div class="expedition">${guest ? `<div class="coop-survivor-preview"><div>${portrait(state.character)}</div><div><p class="eyebrow">Your survivor</p><h2>${esc(at(CHARACTERS, state.character).name)}</h2><p>${esc(at(WEAPONS, at(CHARACTERS, state.character).weapon).name)}</p></div></div>` : renderRunCard(state)}<div class="a-loadout-heading"><h2>${guest ? "Your loadout" : "Run setup"}</h2><span class="muted">${guest ? "Bring your own survivor" : "Choose your next expedition"}</span></div>${renderRunSelectors(state, guest ? ["character", "arcana"] : kinds)}</div>`
}
export function renderExpedition({
  profile,
  character,
  stage,
  arcana,
  mode,
  openPanel = null,
  pendingUnlock = null,
  staticPickers = false
}: MenuState) {
  const state = { profile, character, stage, arcana, mode, openPanel, pendingUnlock }
  return `<div class="expedition"><div class="a-heading"><div><p class="eyebrow">Your next run</p><h1>Ready to play</h1></div><button id="start-top" class="primary start-button">${startControl}</button></div>${renderRunCard(state)}<div class="a-loadout-heading"><h2>Run setup</h2><span class="muted">Choose your next expedition</span></div>${renderRunSelectors(state, kinds, staticPickers)}</div>`
}
export function renderExpeditionAction({ character = 0, stage = 0 }: Partial<Setup>) {
  return `<div class="a-bottom"><span class="muted">${esc(at(CHARACTERS, character).name)} <span aria-hidden="true">·</span> ${esc(at(STAGES, stage).name)}</span><button id="start" class="primary start-button">${startControl}</button></div>`
}
