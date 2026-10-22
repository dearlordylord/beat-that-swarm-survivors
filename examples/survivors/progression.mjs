import {
  META_UPGRADES,
  CHARACTERS,
  STAGES,
  ACHIEVEMENTS,
  RUN_MODES,
  WEAPON_UNLOCKS,
} from "./content.mjs";
const KEY = "nightfall-survivors-v1";
const fresh = () => ({
  version: 1,
  gold: 0,
  meta: Array(10).fill(0),
  characters: [0],
  stages: [0],
  achievements: [],
  stats: {
    kills: 0,
    totalgold: 0,
    survive: 0,
    wins: 0,
    evolutions: 0,
    levels: 1,
    characters: 1,
    stages: 1,
    weapons: 0,
    revivals: 0,
    bosskills: 0,
    characterwins: 0,
    relics: 0,
  },
  collection: { weapons: [], evolutions: [], enemies: [] },
  stageRelics: [],
  wonCharacters: [],
  recorded: [],
  settings: {
    muted: false,
    volume: 0.35,
    reducedMotion: false,
    showDamage: true,
  },
});
export function loadProfile() {
  const base = fresh();
  try {
    const raw = JSON.parse(localStorage.getItem(KEY) || "null");
    if (!raw || raw.version !== 1) return base;
    for (const key of [
      "gold",
      "meta",
      "characters",
      "stages",
      "achievements",
      "stageRelics",
      "wonCharacters",
      "recorded",
    ])
      if (raw[key] !== undefined) base[key] = raw[key];
    Object.assign(base.stats, raw.stats || {});
    Object.assign(base.collection, raw.collection || {});
    Object.assign(base.settings, raw.settings || {});
    base.gold = Math.max(0, Math.floor(Number(base.gold) || 0));
    base.meta = META_UPGRADES.map((u, i) =>
      Math.max(
        0,
        Math.min(u.maxLevel, Math.floor(Number(base.meta?.[i]) || 0)),
      ),
    );
    for (const key of [
      "characters",
      "stages",
      "achievements",
      "stageRelics",
      "wonCharacters",
      "recorded",
    ])
      if (!Array.isArray(base[key])) base[key] = fresh()[key];
    base.characters = [
      ...new Set([
        0,
        ...base.characters.filter((i) => CHARACTERS.some((c) => c.id === i)),
      ]),
    ];
    base.stages = [
      ...new Set([
        0,
        ...base.stages.filter((i) => STAGES.some((c) => c.id === i)),
      ]),
    ];
    base.stageRelics = [
      ...new Set(
        base.stageRelics.filter((i) => Number.isInteger(i) && i >= 0 && i < 5),
      ),
    ];
    for (const key of Object.keys(base.stats))
      base.stats[key] = Math.max(0, Number(base.stats[key]) || 0);
    for (const key of ["weapons", "evolutions", "enemies"])
      base.collection[key] = Array.isArray(base.collection[key])
        ? [...new Set(base.collection[key].filter(Number.isInteger))]
        : [];
    return base;
  } catch {
    return base;
  }
}
export function saveProfile(profile) {
  try {
    localStorage.setItem(KEY, JSON.stringify(profile));
    return true;
  } catch {
    return false;
  }
}
export function upgradeCost(profile, id) {
  const item = META_UPGRADES.find((u) => u.id === id);
  return item
    ? Math.floor(item.costBase * (1 + (profile.meta[id] || 0) * 0.75))
    : Infinity;
}
export function buyUpgrade(profile, id) {
  const item = META_UPGRADES.find((u) => u.id === id),
    cost = upgradeCost(profile, id);
  if (!item || profile.meta[id] >= item.maxLevel || profile.gold < cost)
    return false;
  profile.gold -= cost;
  profile.meta[id]++;
  saveProfile(profile);
  return true;
}
export function metaCode(profile) {
  return (
    profile.meta.reduce(
      (code, level, i) => code + Math.min(7, level) * 2 ** (i * 3),
      0,
    ) >>> 0
  );
}
export function requirementsMet(profile, item) {
  return (
    !item.condition ||
    (profile.stats[item.condition.stat] || 0) >= item.condition.value
  );
}
export function allowedWeapons(profile) {
  let mask = 0xffffff;
  for (const item of WEAPON_UNLOCKS) {
    const open =
      item.stageRelic !== undefined
        ? profile.stageRelics.includes(item.stageRelic)
        : requirementsMet(profile, item);
    if (!open) mask &= ~(1 << item.id);
  }
  return mask >>> 0;
}
export function isUnlocked(profile, kind, id) {
  if (kind === "mode") {
    const item = RUN_MODES.find((x) => x.id === id);
    return !!item && requirementsMet(profile, item);
  }
  if (kind === "weapon") return !!(allowedWeapons(profile) & (1 << id));
  return (kind === "character" ? profile.characters : profile.stages).includes(
    id,
  );
}
export function unlock(profile, kind, id) {
  const catalog =
    kind === "character" ? CHARACTERS : kind === "stage" ? STAGES : [];
  const item = catalog.find((i) => i.id === id);
  if (
    !item ||
    !requirementsMet(profile, item) ||
    isUnlocked(profile, kind, id) ||
    profile.gold < item.cost
  )
    return false;
  profile.gold -= item.cost;
  (kind === "character" ? profile.characters : profile.stages).push(id);
  profile.stats.characters = profile.characters.length;
  profile.stats.stages = profile.stages.length;
  award(profile);
  saveProfile(profile);
  return true;
}
function award(profile) {
  const added = [];
  for (const a of ACHIEVEMENTS) {
    if (profile.achievements.includes(a.id)) continue;
    const conditions = a.conditions || {
      [a.condition.stat]: a.condition.value,
    };
    if (
      Object.entries(conditions).every(
        ([key, value]) => (profile.stats[key] || 0) >= value,
      )
    ) {
      profile.achievements.push(a.id);
      added.push(a.id);
    }
  }
  return added;
}
export function recordRun(profile, frame) {
  const signature = String(
    frame.runId ||
      `${frame.character}:${frame.stage}:${frame.tick}:${frame.kills}:${frame.gold}:${frame.phase}`,
  );
  if (profile.recorded.includes(signature)) return [];
  profile.recorded.push(signature);
  profile.recorded = profile.recorded.slice(-100);
  const gold = Math.max(0, Math.floor(frame.gold || 0));
  profile.gold += gold;
  const s = profile.stats;
  s.totalgold += gold;
  s.kills += frame.kills || 0;
  s.survive = Math.max(s.survive, (frame.tick || 0) / 60);
  s.levels = Math.max(s.levels, frame.level || 1);
  s.revivals += frame.revivalsUsed || 0;
  s.bosskills += frame.bossesKilled || 0;
  if (frame.phase === 4) {
    s.wins++;
    if (!profile.wonCharacters.includes(frame.character))
      profile.wonCharacters.push(frame.character);
  }
  if (frame.relicCollected === 1 && !profile.stageRelics.includes(frame.stage))
    profile.stageRelics.push(frame.stage);
  s.relics = profile.stageRelics.length;
  const used = [...(frame.usedWeapons || [])],
    evolved = [...(frame.evolvedWeapons || [])];
  (frame.weapons || []).forEach((level, id) => {
    if (level > 0 && !used.includes(id)) used.push(id);
    if (level >= 9 && !evolved.includes(id)) evolved.push(id);
  });
  for (const [key, ids] of [
    ["weapons", used],
    ["evolutions", evolved],
    ["enemies", frame.enemiesKilled || []],
  ])
    profile.collection[key] = [
      ...new Set([...profile.collection[key], ...ids]),
    ];
  s.evolutions += evolved.length;
  s.weapons = profile.collection.weapons.length;
  s.characters = profile.characters.length;
  s.stages = profile.stages.length;
  s.characterwins = profile.wonCharacters.length;
  const result = award(profile);
  saveProfile(profile);
  return result;
}
