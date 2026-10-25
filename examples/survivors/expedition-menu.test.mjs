import assert from 'node:assert/strict';
import { test } from 'node:test';
import { freshProfile } from './progression.mjs';
import { renderRunSelectors, renderCoopSetup } from './expedition-menu.mjs';

const state = id => ({profile:freshProfile(),character:0,stage:0,arcana:0,mode:0,
  openPanel:'character',pendingUnlock:{kind:'character',id}});

test('every locked survivor opens one full-width dossier beneath its own card pair', () => {
  for (let id = 1; id < 8; id++) {
    const html = renderRunSelectors(state(id), ['character']);
    const pairs = html.split(/<div class="choice-pair(?: details-right)?">/).slice(1);
    assert.equal(pairs.length, 4);
    const selectedPair = Math.floor(id / 2);
    for (let pair = 0; pair < 4; pair++) {
      assert.equal(pairs[pair].includes('data-unlock-details'), pair === selectedPair);
      assert(pairs[pair].includes(`data-character="${pair * 2}"`));
      assert(pairs[pair].includes(`data-character="${pair * 2 + 1}"`));
    }
    const row = pairs[selectedPair];
    assert(row.indexOf('data-unlock-details') > row.indexOf(`data-character="${selectedPair * 2 + 1}"`));
    assert.match(html, new RegExp(`is-inspecting[^>]*data-character="${id}" aria-pressed="false" aria-expanded="true" aria-controls="unlock-details-character-${id}"`));
    assert.match(html, /data-character="0" aria-pressed="true"/);
    assert.match(html, /Next run: <strong>Mira<\/strong> remains equipped/);
    assert.equal((html.match(/data-close-unlock/g) || []).length, 1);
    assert(!html.includes('Inspecting'));
  }
});

test('solo selectors and both co-op roles share the same pair layout', () => {
  for (const guest of [false, true]) {
    const html = renderCoopSetup(state(3), guest);
    assert.equal((html.match(/class="choice-pair/g) || []).length, 4);
    assert(html.includes('unlock-details-character-3'));
    assert.match(html, /data-character="0" aria-pressed="true"/);
  }
});

test('closing the dossier leaves all eight choices and no stale detail controls', () => {
  const html = renderRunSelectors({...state(1),pendingUnlock:null}, ['character']);
  assert.equal((html.match(/data-character="/g) || []).length, 8);
  assert(!html.includes('data-unlock-details'));
  assert(!html.includes('aria-controls='));
});
