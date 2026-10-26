import { escapeHtml as esc, at, defined } from "./host-values.mts"
import { profileStat, type Profile, type Setup, type SetupKind, type MenuState } from "./profile.mts"
import { survivorColor, survivorSvg } from "./survivor-art.mts"
import { CHARACTERS, STAGES, ARCANA, RUN_MODES, WEAPONS } from "./content.mts"
import { isUnlocked, purchaseStatus } from "./progression.mts"
const startControl = `<span class="cta-surface"><span class="cta-icon" aria-hidden="true"><svg viewBox="0 0 16 16" width="20" height="20" fill="currentColor"><path d="M11 1A7 7 0 1 0 15 12a6 6 0 0 1-4-11zm2 0h1v2h2v1h-2v2h-1V4h-2V3h2V1z"/></svg></span><span class="cta-label">Start Run</span><span class="cta-cap" aria-hidden="true"></span></span>`
interface SelectionItem {
  id: number
  name: string
  description: string
  icon?: string
  weapon?: number
  hint?: string
  title?: string
  condition?: { value: number; stat: string }
  cost?: number
}
const catalog: Record<SetupKind, readonly SelectionItem[]> = {
  character: CHARACTERS,
  stage: STAGES,
  arcana: ARCANA,
  mode: RUN_MODES
}
const kinds: SetupKind[] = ["character", "stage", "arcana", "mode"]
const labels = { character: "Survivor", stage: "Stage", arcana: "Arcana", mode: "Mode" }
export function portrait(id = 0, size = "large") {
  return `<div class="pixel-portrait portrait-${size}" style="--survivor:${survivorColor(id)}" aria-label="${esc((CHARACTERS[id] || at(CHARACTERS, 0)).name)}">${survivorSvg(id)}</div>`
}
function stageArt(id = 0) {
  return `<div class="stage-art stage-art-${id}" aria-hidden="true"><div class="moon"></div><div class="ridge ridge-back"></div><div class="ridge"></div><div class="ground"></div><div class="tomb tomb-one"></div><div class="tomb tomb-two"></div><div class="tree tree-one"></div><div class="tree tree-two"></div><span class="stage-art-coordinate">${esc(at(STAGES, id).name.toUpperCase())}</span></div>`
}

function startingWeapon(id: number, focusable = true) {
  const weapon = at(WEAPONS, id)
  return `<span class="starting-weapon" role="img" aria-label="Starting weapon: ${esc(weapon.name)}"${focusable ? ' tabindex="0"' : ""} style="--weapon-color:${esc(weapon.color)}"><span aria-hidden="true">${esc(weapon.icon)}</span><span class="weapon-tooltip" aria-hidden="true">${esc(weapon.name)}</span></span>`
}

function icon(kind: SetupKind, item: SelectionItem) {
  if (kind === "character") return portrait(item.id, "small")
  return `<span class="choice-glyph" aria-hidden="true">${esc(kind === "arcana" ? item.icon : kind === "stage" ? ["☾", "▤", "♧", "❄", "♨"][item.id] : ["◷", "◑", "∞", "⚔"][item.id])}</span>`
}
function inspector(profile: Profile, pending: MenuState["pendingUnlock"], kind: SetupKind) {
  if (!pending || pending.kind !== kind) return ""
  const item = catalog[kind].find((x) => x.id === pending.id)
  if (!item) return ""
  const status = purchaseStatus(profile, kind, item.id)
  const owned = status.owned
  const eligible = status.eligible
  const buyable = kind === "character" || kind === "stage"
  const character = kind === "character"
  const condition = item.condition
  const current = condition ? Math.min(condition.value, profileStat(profile.stats, condition.stat)) : 0
  return `<section id="unlock-details-${kind}-${item.id}" class="unlock-inspector ${character ? "unlock-inspector--row" : "banner-panel"}" data-unlock-details tabindex="-1" aria-label="${esc(item.name)} unlock details">${character ? `<button class="unlock-close" data-close-unlock aria-label="Close ${esc(item.name)} details">×</button>` : ""}<div class="${character ? "unlock-heading" : "banner-heading"}">${character ? portrait(item.id, "small") : ""}<div><span class="eyebrow">${owned ? "Available" : "Locked " + labels[kind].toLowerCase()}</span><h3>${esc(item.name)}</h3>${character ? `<small>${esc(item.title)}</small>` : ""}</div></div><p>${esc(item.description)}</p>${character ? `<p class="starting-weapon-line">${startingWeapon(item.weapon ?? 0)}</p>` : ""}${item.hint ? `<div class="unlock-requirement"><p class="requirement">${eligible ? "✓ Requirement met: " : "Requirement: "}${esc(item.hint)}</p>${character && condition ? `<progress value="${current}" max="${condition.value}" aria-label="${esc(item.name)} unlock progress"></progress><small>${current.toLocaleString()} / ${condition.value.toLocaleString()}</small>` : ""}</div>` : ""}${buyable ? `<div class="purchase-line"><span>Price <strong>${item.cost} gold</strong> · Your balance <strong>${profile.gold} gold</strong></span><button class="primary" data-buy-kind="${kind}" data-buy-id="${item.id}" ${status.canBuy ? "" : "disabled"}>${owned ? "Unlocked" : "Unlock " + item.name + " · " + item.cost + " gold"}</button></div>${!owned && !eligible ? '<p class="requirement">Complete the requirement to unlock.</p>' : ""}${!owned && !status.affordable ? `<p class="requirement">Earn ${status.missingGold} more gold to buy this ${labels[kind].toLowerCase()}.</p>` : ""}` : "<p>Unlock this mode by completing its requirement.</p>"}</section>`
}
function picker(state: MenuState, kind: SetupKind) {
  const choices = catalog[kind].map((item) => {
    const open = isUnlocked(state.profile, kind, item.id)
    const selected = open && state[kind] === item.id
    const inspecting = state.pendingUnlock?.kind === kind && state.pendingUnlock.id === item.id
    return `<button class="choice ${selected ? "is-selected" : ""} ${open ? "" : "is-locked"} ${inspecting ? "is-inspecting" : ""}" data-${kind}="${item.id}" aria-pressed="${selected}"${!open ? ` aria-expanded="${inspecting}"${inspecting ? ` aria-controls="unlock-details-${kind}-${item.id}"` : ""}` : ""}>${icon(kind, item)}<span class="choice-copy"><strong>${esc(item.name)}</strong><small>${kind === "character" ? startingWeapon(item.weapon ?? 0, false) : esc(item.description)}</small>${selected && kind === "character" ? '<span class="equipped-badge">✓ Equipped</span>' : ""}${!open ? `<span class="locked-badge">${kind === "mode" ? "Locked · View requirement" : "Locked · " + item.cost + " gold"}</span>` : ""}${inspecting ? '<span class="viewing-badge">Viewing details</span>' : ""}</span><span class="choice-check" aria-hidden="true">${inspecting ? "−" : selected ? "✓" : open ? "+" : "◇"}</span></button>`
  })
  const details = inspector(state.profile, state.pendingUnlock, kind)
  if (kind !== "character")
    return `<div class="choice-list" role="group" aria-label="Choose ${labels[kind].toLowerCase()}">${choices.join("")}</div>${details}`
  let rows = ""
  for (let i = 0; i < choices.length; i += 2) {
    const pair = catalog["character"].slice(i, i + 2)
    const inspected = pair.findIndex((item) => state.pendingUnlock?.kind === kind && state.pendingUnlock.id === item.id)
    rows += `<div class="choice-pair${inspected === 1 ? " details-right" : ""}">${choices.slice(i, i + 2).join("")}${inspected >= 0 ? details : ""}</div>`
  }
  return `<div class="choice-list choice-list--character" role="group" aria-label="Choose survivor">${rows}</div>`
}

function renderRunCard({ character = 0, stage = 0, arcana = 0, mode = 0 }: Partial<Setup>) {
  const c = CHARACTERS[character] || at(CHARACTERS, 0)
  const destination = STAGES[stage] || at(STAGES, 0)
  const charm = ARCANA[arcana] || at(ARCANA, 0)
  const runMode = RUN_MODES[mode] || at(RUN_MODES, 0)
  return `<section class="a-run-card" aria-label="Current run"><div class="a-survivor">${portrait(c.id)}<div><span class="eyebrow">${esc(c.title)}</span><h2>${esc(c.name)}</h2><p>${startingWeapon(c.weapon)}</p></div></div><div class="a-stage">${stageArt(destination.id)}<div class="a-stage-caption"><span class="eyebrow">Destination</span><strong>${esc(destination.name)}</strong></div></div><div class="a-run-strip"><span>${esc(charm.icon)} ${esc(charm.name)}</span><span>${["◷", "◑", "∞", "⚔"][runMode.id]} ${esc(runMode.name)} <i>·</i> ${runMode.durationLabel}</span></div></section>`
}

export function renderRunSelectors(state: MenuState, selectedKinds: SetupKind[] = kinds, staticPickers = false) {
  const selected = Object.fromEntries(
    selectedKinds.map((kind) => [kind, catalog[kind].find((item) => item.id === state[kind]) || catalog[kind][0]])
  )
  return `<div class="selection-rows">${selectedKinds.map((kind) => `<section class="selection-item"><button class="selection-row" data-menu-panel="${kind}" aria-expanded="${state.openPanel === kind}"><span>${labels[kind]}</span><strong class="selected-choice">${icon(kind, defined(selected[kind]))}<span>${esc(defined(selected[kind]).name)}</span></strong><span class="change-label">${state.openPanel === kind ? "Close −" : "Change +"}</span></button>${state.openPanel === kind || staticPickers ? `<div class="inline-picker" ${state.openPanel === kind ? "" : "hidden"}>${picker(state, kind)}</div>` : ""}</section>`).join("")}</div>`
}
export function renderCoopSetup(state: MenuState, guest = false, room?: Pick<Setup, "stage" | "mode">) {
  const preview = guest && room ? { ...state, ...room } : state
  return `<div class="expedition">${renderRunCard(preview)}${guest ? `<p class="muted coop-room-settings" id="coop-room-settings">${room ? `Host's stage · ${esc(at(STAGES, room.stage).name)} · ${esc(at(RUN_MODES, room.mode).name)}` : "Connecting to the host's room…"}<br />The host chooses the stage and mode.</p>` : ""}<div class="a-loadout-heading"><h2>${guest ? "Your loadout" : "Run setup"}</h2><span class="muted">${guest ? "Bring your own survivor" : "Choose your next expedition"}</span></div>${renderRunSelectors(state, guest ? ["character", "arcana"] : kinds)}</div>`
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
