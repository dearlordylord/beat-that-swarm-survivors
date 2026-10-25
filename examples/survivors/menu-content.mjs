import { WEAPONS, PASSIVES, STAGES, META_UPGRADES, ENEMIES, ACHIEVEMENTS, UNIONS, WEAPON_UNLOCKS, STAGE_RELICS } from './content.mjs';
import { renderExpedition } from './expedition-menu.mjs';
import { isUnlocked, upgradeStatus } from './progression.mjs';

export const MENU_TABS = ['expedition', 'shop', 'collection', 'achievements', 'settings'];

// The same presentation is rendered at build time and refreshed with a saved
// profile in the browser. Eligibility, prices and catalogues still come from Bend.
export function renderMenuContent(tab, { profile, character, stage, arcana, mode, openPanel = null, pendingUnlock = null, staticPickers = false }, collectionTab = 'weapons') {
  let html = "";
  if (tab === "expedition") {
    html = renderExpedition({ profile, character, stage, arcana, mode, openPanel, pendingUnlock, staticPickers });
  } else if (tab === "shop") {
    html =
      '<div class="section-title">Power that outlives the night</div><div class="grid shop">' +
      META_UPGRADES.map((u) => {
        const { rank, cost, maxed, canBuy } = upgradeStatus(profile, u.id);
        return `<article class="card banner-panel"><div class="banner-heading"><h3>${u.name}</h3></div><p>${u.description}</p><span class="progress">${"◆".repeat(rank)}${"◇".repeat(u.maxLevel - rank)}</span><button data-upgrade="${u.id}" ${canBuy ? "" : "disabled"}>${maxed ? "Fully upgraded" : `Upgrade · ${cost} ◈`}</button></article>`;
      }).join("") +
      "</div>";
  } else if (tab === "collection") {
    html =
      '<div class="collection-tabs">' +
      [
        ["weapons", `Weapons · ${WEAPONS.length}`],
        ["evolutions", `Evolutions · ${WEAPONS.length}`],
        ["unions", `Unions · ${UNIONS.length}`],
        ["passives", `Relics · ${PASSIVES.length}`],
        ["enemies", `Bestiary · ${ENEMIES.length}`],
        ["artifacts", `Artifacts · ${STAGE_RELICS.length}`],
      ]
        .map(
          ([id, name]) =>
            `<button data-collection="${id}" class="${collectionTab === id ? "primary" : ""}">${name}</button>`,
        )
        .join("") +
      '</div><div class="grid collection">';
    let list =
      collectionTab === "artifacts"
        ? STAGE_RELICS
        : collectionTab === "unions"
          ? UNIONS
          : collectionTab === "passives"
            ? PASSIVES
            : collectionTab === "enemies"
              ? ENEMIES
              : WEAPONS;
    html +=
      list
        .map(
          (i) =>
            `<article class="card banner-panel"><div class="banner-heading"><span class="icon" style="color:${i.color || "var(--gold)"}">${i.icon || (i.boss ? "♜" : "♟")}</span><h3>${collectionTab === "evolutions" ? i.evolvedName : i.name}</h3></div><p>${collectionTab === "evolutions" ? i.evolvedDescription : i.description || (i.boss ? "Lord of the night" : "Creature of the night")}</p>${collectionTab === "artifacts" ? `<p class="recipe">${profile.stageRelics.includes(i.id) ? "Recovered" : "Find in " + STAGES[i.id].name} · unlocks ${WEAPONS[i.weapon].name}</p>` : ""}${collectionTab === "weapons" && !isUnlocked(profile, "weapon", i.id) ? `<p class="recipe">Locked · ${WEAPON_UNLOCKS.find((w) => w.id === i.id)?.hint || ""}</p>` : ""}${collectionTab === "unions" ? `<p class="recipe">${i.weapons.map((id) => WEAPONS[id].name + " VIII").join(" + ")}<br>→ ${i.name}</p>` : ""}${collectionTab === "weapons" || collectionTab === "evolutions" ? `<p class="recipe">${i.name} VIII + ${PASSIVES[i.passive].name}<br>→ ${i.evolvedName}</p>` : ""}</article>`,
        )
        .join("") + "</div>";
  } else if (tab === "achievements") {
    html =
      '<div class="section-title">A chronicle of your nights</div><div class="grid">' +
      ACHIEVEMENTS.map(
        (a) =>
          `<article class="card banner-panel ${profile.achievements.includes(a.id) ? "achieved" : ""}"><div class="banner-heading"><h3>${profile.achievements.includes(a.id) ? "◆" : "◇"} ${a.name}</h3></div><p>${a.description}</p><small>${profile.achievements.includes(a.id) ? "Completed" : "Still to come"}</small></article>`,
      ).join("") +
      "</div>";
  } else {
    html = `<div class="settings banner-panel"><div class="banner-heading"><h2>Settings</h2></div><label class="setting"><div>Music and sound<span>Adaptive chip-metal · responds to nearby danger</span></div><input id="sound" type="checkbox" ${!profile.settings.muted ? "checked" : ""}></label><label class="setting"><div>Volume</div><input id="volume" type="range" min="0" max="1" step=".05" value="${profile.settings.volume}" style="width:160px"></label><label class="setting"><div>Reduced motion<span>Disable decorative animation</span></div><input id="motion" type="checkbox" ${profile.settings.reducedMotion ? "checked" : ""}></label><label class="setting"><div>Damage numbers<span>Show damage above enemies</span></div><input id="damage" type="checkbox" ${profile.settings.showDamage ? "checked" : ""}></label><p>Progress saves automatically in this browser.</p></div>`;
  }
  return html;
}
