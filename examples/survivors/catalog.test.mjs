import test from "node:test";
import assert from "node:assert/strict";
import {
  WEAPONS,
  PASSIVES,
  CHARACTERS,
  STAGES,
  ARCANA,
  META_UPGRADES,
  ENEMIES,
  ACHIEVEMENTS,
  COLLECTIONS,
  UNIONS,
  RUN_MODES,
  WEAPON_UNLOCKS,
  STAGE_RELICS,
} from "./content.mjs";
import { AudioEngine } from "./audio.mjs";
import { loadProfile, metaCode, recordRun } from "./progression.mjs";

test("complete catalog preserves stable dense IDs and valid evolution recipes", () => {
  for (const [name, catalog, count] of [
    ["weapons", WEAPONS, 24],
    ["passives", PASSIVES, 18],
    ["characters", CHARACTERS, 8],
    ["stages", STAGES, 5],
    ["arcana", ARCANA, 12],
    ["meta", META_UPGRADES, 10],
    ["enemies", ENEMIES, 31],
  ]) {
    assert.equal(catalog.length, count, name);
    assert.deepEqual(
      catalog.map((item) => item.id),
      Array.from({ length: count }, (_, id) => id),
      `${name} stable IDs`,
    );
    assert.equal(
      new Set(catalog.map((item) => item.name)).size,
      count,
      `${name} distinct names`,
    );
  }
  assert.equal(
    new Set(WEAPONS.map((item) => item.evolvedName)).size,
    WEAPONS.length,
  );
  for (const weapon of WEAPONS) {
    assert.ok(PASSIVES[weapon.passive], `${weapon.name} recipe passive exists`);
    assert.equal(weapon.evolutionRequires.weaponLevel, weapon.maxLevel);
    assert.ok(
      weapon.evolutionRequires.passiveLevel > 0 &&
        weapon.evolutionRequires.passiveLevel <=
          PASSIVES[weapon.passive].maxLevel,
    );
    assert.notEqual(weapon.description, weapon.evolvedDescription);
  }
  for (const character of CHARACTERS)
    assert.ok(WEAPONS[character.weapon], `${character.name} starter weapon`);
  assert.equal(ENEMIES.filter((enemy) => enemy.boss).length, 11);
  assert.ok(ENEMIES.every((enemy) => enemy.boss === enemy.id >= 20));
});

test("achievement conditions reference persisted numerical stats and collections cover the catalog", () => {
  const profile = loadProfile();
  assert.equal(ACHIEVEMENTS.length, 20);
  assert.equal(
    new Set(ACHIEVEMENTS.map((a) => a.id)).size,
    ACHIEVEMENTS.length,
  );
  for (const achievement of ACHIEVEMENTS) {
    assert.ok(
      achievement.conditions && Object.keys(achievement.conditions).length,
    );
    for (const [stat, threshold] of Object.entries(achievement.conditions)) {
      assert.equal(
        typeof profile.stats[stat],
        "number",
        `unknown achievement stat ${stat}`,
      );
      assert.ok(Number.isFinite(threshold) && threshold > 0);
    }
  }
  for (const [key, catalog] of [
    ["weapons", WEAPONS],
    ["evolutions", WEAPONS],
    ["enemies", ENEMIES],
  ]) {
    assert.deepEqual(
      COLLECTIONS[key].map((item) => item.id),
      catalog.map((item) => item.id),
    );
  }
});

test("all purchased meta ranks round-trip through the Bend three-bit encoding", () => {
  const profile = loadProfile();
  profile.meta = META_UPGRADES.map((item) => item.maxLevel);
  const code = metaCode(profile);
  assert.ok(Number.isInteger(code) && code >= 0 && code <= 0xffffffff);
  for (const item of META_UPGRADES) {
    assert.ok(
      item.maxLevel > 0 && item.maxLevel < 8,
      `${item.key} fits three bits`,
    );
    assert.equal(
      Math.floor(code / 2 ** (item.id * 3)) % 8,
      item.maxLevel,
      `${item.key} preserved`,
    );
    assert.ok(item.costBase > 0);
  }
});

test("a completed run awards achievements and only records its reward once", () => {
  const profile = loadProfile();
  const frame = {
    runId: "catalog-test",
    character: 0,
    stage: 0,
    phase: 4,
    tick: 36000,
    kills: 1000,
    gold: 1000,
    level: 50,
    revivalsUsed: 1,
    bossesKilled: 2,
    weapons: [9, 1],
    enemiesKilled: [0, 20],
  };
  const earned = recordRun(profile, frame);
  assert.ok(
    earned.includes("firstblood") &&
      earned.includes("dawn") &&
      earned.includes("evolve"),
  );
  assert.equal(profile.stats.wins, 1);
  assert.deepEqual(profile.collection.weapons, [0, 1]);
  assert.deepEqual(profile.collection.evolutions, [0]);
  assert.deepEqual(profile.collection.enemies, [0, 20]);
  assert.equal(profile.gold, 1000);
  assert.deepEqual(recordRun(profile, frame), []);
  assert.equal(profile.gold, 1000);
  assert.equal(profile.stats.wins, 1);
});

test("audio settings and events are safe before a gesture and without Web Audio", () => {
  const audio = new AudioEngine();
  assert.equal(audio.context, null);
  for (const event of [
    "shot",
    "hit",
    "kill",
    "level",
    "chest",
    "choose",
    "gameover",
    "victory",
  ])
    audio.event(event);
  audio.update({ tick: 60 });
  audio.setVolume(2);
  assert.equal(audio.volume, 1);
  audio.setVolume(-1);
  assert.equal(audio.volume, 0);
  audio.setMuted(true);
  audio.setEnabled(false);
  audio.stop();
  audio.unlock();
  assert.equal(audio.context, null);
});

test("union recipes retain a unique base and consume a valid distinct partner", () => {
  assert.deepEqual(
    UNIONS.map((item) => item.id),
    [0, 1, 2, 3, 4, 5],
  );
  assert.equal(new Set(UNIONS.map((item) => item.weapons[0])).size, 6);
  for (const union of UNIONS) {
    assert.equal(union.weapons.length, 2);
    assert.notEqual(union.weapons[0], union.weapons[1]);
    for (const id of union.weapons) assert.ok(WEAPONS[id]);
    assert.ok(WEAPONS[union.thirdWeapon]);
    assert.ok(
      !union.weapons.includes(union.thirdWeapon),
      "Union adds a third distinct behavior",
    );
  }
  assert.deepEqual(
    RUN_MODES.map((mode) => mode.id),
    [0, 1, 2, 3],
  );
});

test("weapon, evolution and union names are globally distinct", () => {
  const names = [
    ...WEAPONS.map((item) => item.name),
    ...WEAPONS.map((item) => item.evolvedName),
    ...UNIONS.map((item) => item.name),
  ];
  assert.equal(
    new Set(names.map((name) => name.toLocaleLowerCase())).size,
    names.length,
  );
  for (const name of names) assert.ok(name.trim().length > 0);
});

test("evolution and arcana crosslinks reference available gameplay content", () => {
  for (const weapon of WEAPONS) {
    assert.ok(
      WEAPONS[weapon.evolutionSecondary],
      `${weapon.name} evolution secondary exists`,
    );
    assert.notEqual(
      weapon.evolutionSecondary,
      weapon.id,
      `${weapon.name} gains a distinct secondary behavior`,
    );
  }
  const linked = ARCANA.filter((arcana) => arcana.synergy);
  assert.equal(linked.length, 6);
  const kinds = new Set();
  for (const arcana of linked) {
    const synergy = arcana.synergy;
    kinds.add(synergy.kind);
    assert.ok(
      synergy.weapons.length > 0,
      `${arcana.name} has affected weapons`,
    );
    assert.equal(new Set(synergy.weapons).size, synergy.weapons.length);
    for (const id of synergy.weapons)
      assert.ok(WEAPONS[id], `${arcana.name} weapon ${id} exists`);
    if (synergy.passive !== undefined) assert.ok(PASSIVES[synergy.passive]);
    if (synergy.healthPerKill !== undefined)
      assert.ok(synergy.healthPerKill > 0);
    if (synergy.baseStrength !== undefined)
      assert.ok(synergy.strength > synergy.baseStrength);
    if (synergy.durationMultiplier !== undefined)
      assert.ok(synergy.durationMultiplier > 1 && synergy.damageMultiplier > 1);
  }
  assert.equal(kinds.size, linked.length, "Crosslinks add six distinct rules");
});

test("unlock gates use persisted stats and each stage relic opens its designated weapon", () => {
  const profile = loadProfile();
  for (const catalog of [CHARACTERS, STAGES, RUN_MODES, WEAPON_UNLOCKS]) {
    for (const item of catalog) {
      if (item.condition) {
        assert.equal(
          typeof profile.stats[item.condition.stat],
          "number",
          `Unknown unlock stat ${item.condition.stat}`,
        );
        assert.ok(
          Number.isFinite(item.condition.value) && item.condition.value > 0,
        );
        assert.ok(item.hint.trim().length > 0);
      }
    }
  }
  assert.deepEqual(
    WEAPON_UNLOCKS.map((item) => item.id),
    [12, 14, 16, 17, 18, 22],
  );
  assert.equal(
    new Set(WEAPON_UNLOCKS.map((item) => item.id)).size,
    WEAPON_UNLOCKS.length,
  );
  assert.deepEqual(
    STAGE_RELICS.map((item) => item.id),
    STAGES.map((item) => item.id),
  );
  assert.equal(
    new Set(STAGE_RELICS.map((item) => item.weapon)).size,
    STAGES.length,
  );
  for (const relic of STAGE_RELICS) {
    assert.ok(STAGES[relic.id] && WEAPONS[relic.weapon]);
    assert.ok(relic.x > 20 && relic.x < 3580 && relic.y > 20 && relic.y < 3580);
    const gate = WEAPON_UNLOCKS.find((item) => item.stageRelic === relic.id);
    assert.equal(gate.id, relic.weapon);
    assert.ok(gate.hint.includes(relic.name));
  }
  for (const gate of WEAPON_UNLOCKS) {
    assert.ok(WEAPONS[gate.id]);
    assert.notEqual(
      Boolean(gate.condition),
      gate.stageRelic !== undefined,
      "One unlock rule per weapon",
    );
  }
  assert.ok(CHARACTERS.slice(1).every((item) => item.condition));
  assert.ok(STAGES.slice(1).every((item) => item.condition));
  assert.ok(RUN_MODES.slice(1).every((item) => item.condition));
  assert.deepEqual(
    RUN_MODES.map((item) => item.id),
    [0, 1, 2, 3],
  );
});
