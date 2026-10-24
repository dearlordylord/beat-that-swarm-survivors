import { startControl } from "./menu-controls.mjs";
import { CHARACTERS, STAGES, ARCANA, RUN_MODES, WEAPONS } from './content.mjs';
import { isUnlocked, purchaseStatus } from './progression.mjs';

const catalog = { character: CHARACTERS, stage: STAGES, arcana: ARCANA, mode: RUN_MODES };
const labels = { character: 'Survivor', stage: 'Stage', arcana: 'Arcana', mode: 'Mode' };
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
function portrait(id=0,size='large'){
 const color=CHARACTERS[id]?.color||'#8dcaff';
 return `<div class="pixel-portrait portrait-${size}" style="--survivor:${color}" aria-label="${esc(CHARACTERS[id]?.name)}"><svg viewBox="0 0 32 40" aria-hidden="true" shape-rendering="crispEdges"><path fill="#101b1b" d="M7 37h20v3H7z"/><path fill="${color}" d="M10 12h12v4h3v7h3v14H5V23h3v-7h2z"/><path fill="#111d22" d="M11 13h10v10H11z"/><path fill="#e9cfad" d="M12 14h8v7h-8z"/><path fill="#243235" d="M13 16h2v2h-2zm5 0h2v2h-2z"/><path fill="${color}" d="M7 12h18v3H7zm3-4h13v4H10zm3-4h8v4h-8z"/><path fill="#f1e5ae" d="M4 23h3v12H4zm-1-4h5v4H3z"/><path fill="#182629" d="M13 24h6v3h-6zm0 10h5v3h-5z"/><path fill="#ecdeb7" d="M8 24h3v4H8z"/></svg></div>`;
}
function stageArt(id=0){return `<div class="stage-art stage-art-${id}" aria-hidden="true"><div class="moon"></div><div class="ridge ridge-back"></div><div class="ridge"></div><div class="ground"></div><div class="tomb tomb-one"></div><div class="tomb tomb-two"></div><div class="tree tree-one"></div><div class="tree tree-two"></div><span class="stage-art-coordinate">${esc(STAGES[id].name.toUpperCase())}</span></div>`;}

function icon(kind, item) {
  if (kind === 'character') return portrait(item.id, 'small');
  return `<span class="choice-glyph" aria-hidden="true">${esc(kind === 'arcana' ? item.icon : kind === 'stage' ? ['☾', '▤', '♧', '❄', '♨'][item.id] : ['◷', '◑', '∞', '⚔'][item.id])}</span>`;
}
function unlocked(profile, kind, id) {
  return isUnlocked(profile, kind, id);
}
function inspector(profile, pending, kind) {
  if (!pending || pending.kind !== kind) return '';
  const item = catalog[kind].find(x => x.id === pending.id);
  if (!item) return '';
  const status = purchaseStatus(profile, kind, item.id);
  const owned = status.owned;
  const eligible = status.eligible;
  const buyable = kind === 'character' || kind === 'stage';
  return `<section class="unlock-inspector" data-unlock-details tabindex="-1" aria-label="${esc(item.name)} unlock details"><span class="eyebrow">${owned ? 'Available' : 'Unlock '+labels[kind].toLowerCase()}</span><h3>${esc(item.name)}</h3><p>${esc(item.description)}</p>${kind === 'character' ? `<p>Starting weapon: ${esc(WEAPONS[item.weapon].name)}</p>` : ''}${item.hint ? `<p class="requirement">${eligible ? '✓ Requirement met: ' : 'Requirement: '}${esc(item.hint)}</p>` : ''}${buyable ? `<div class="purchase-line"><span>Price <strong>${item.cost} gold</strong> · Your balance <strong>${profile.gold} gold</strong></span><button class="primary" data-buy-kind="${kind}" data-buy-id="${item.id}" ${status.canBuy ? '' : 'disabled'}>${owned ? 'Unlocked' : 'Buy '+item.name+' · '+item.cost+' gold'}</button></div>${!owned && !status.affordable ? `<p class="requirement">Earn ${status.missingGold} more gold to buy this ${labels[kind].toLowerCase()}.</p>` : ''}` : '<p>Unlock this mode by completing its requirement.</p>'}</section>`;
}
function picker(state, kind) {
  return `<div class="choice-list" role="group" aria-label="Choose ${labels[kind].toLowerCase()}">${catalog[kind].map(item => {
    const open = unlocked(state.profile, kind, item.id);
    const selected = open && state[kind] === item.id;
    const inspecting = state.pendingUnlock?.kind === kind && state.pendingUnlock.id === item.id;
    return `<button class="choice ${selected ? 'is-selected' : ''} ${open ? '' : 'is-locked'} ${inspecting ? 'is-inspecting' : ''}" data-${kind}="${item.id}" aria-pressed="${selected}">${icon(kind, item)}<span class="choice-copy"><strong>${esc(item.name)}</strong><small>${esc(kind === 'character' ? WEAPONS[item.weapon].name : item.description)}</small>${!open ? `<span class="locked-badge">${kind === 'mode' ? 'Locked · View requirement' : 'Locked · '+item.cost+' gold'}${inspecting ? ' · Inspecting' : ''}</span>` : ''}</span><span class="choice-check" aria-hidden="true">${selected ? '✓' : open ? '+' : '◇'}</span></button>`;
  }).join('')}</div>${inspector(state.profile, state.pendingUnlock, kind)}`;
}

export function renderExpedition({ profile, character, stage, arcana, mode, openPanel = null, pendingUnlock = null, staticPickers = false }) {
  const state = { profile, character, stage, arcana, mode, openPanel, pendingUnlock };
  const selected = Object.fromEntries(Object.keys(catalog).map(kind => [kind, catalog[kind].find(item => item.id === state[kind]) || catalog[kind][0]]));
  const c = selected.character;
  const duration = selected.mode.durationLabel;
  return `<div class="expedition"><div class="a-heading"><div><p class="eyebrow">Your next run</p><h1>Ready to play</h1></div><button id="start-top" class="primary start-button">${startControl}</button></div><section class="a-run-card" aria-label="Current run"><div class="a-survivor">${portrait(c.id)}<div><span class="eyebrow">${esc(c.title)}</span><h2>${esc(c.name)}</h2><p>${esc(WEAPONS[c.weapon].name)}</p></div></div><div class="a-stage">${stageArt(selected.stage.id)}<div class="a-stage-caption"><span class="eyebrow">Destination</span><strong>${esc(selected.stage.name)}</strong></div></div><div class="a-run-strip"><span>${esc(selected.arcana.icon)} ${esc(selected.arcana.name)}</span><span>${['◷','◑','∞','⚔'][selected.mode.id]} ${esc(selected.mode.name)} <i>·</i> ${duration}</span></div></section><div class="a-loadout-heading"><h2>Run setup</h2><span class="muted">Choose your next expedition</span></div><div class="selection-rows">${Object.keys(catalog).map(kind => `<section class="selection-item"><button class="selection-row" data-menu-panel="${kind}" aria-expanded="${openPanel === kind}"><span>${labels[kind]}</span><strong class="selected-choice">${icon(kind, selected[kind])}<span>${esc(selected[kind].name)}</span></strong><span class="change-label">${openPanel === kind ? 'Close −' : 'Change +'}</span></button>${openPanel === kind || staticPickers ? `<div class="inline-picker" ${openPanel === kind ? '' : 'hidden'}>${picker(state, kind)}</div>` : ''}</section>`).join('')}</div></div>`;
}

export function renderExpeditionAction({ character = 0, stage = 0 }) {
  return `<div class="a-bottom"><span class="muted">${esc(CHARACTERS[character].name)} <span aria-hidden="true">·</span> ${esc(STAGES[stage].name)}</span><button id="start" class="primary start-button">${startControl}</button></div>`;
}
