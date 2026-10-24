// Verify the real static build, including users with no JS and a slow game download.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = fileURLToPath(new URL('./dist/web/', import.meta.url));
const server = createServer(async (req, res) => {
  const name = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const target = path.resolve(root, '.' + (name === '/' ? '/index.html' : name));
  if (!target.startsWith(root)) return res.writeHead(403).end();
  try {
    const data = await readFile(target);
    res.setHeader('Content-Type', target.endsWith('.mjs') ? 'text/javascript' : target.endsWith('.css') ? 'text/css' : 'text/html');
    res.end(data);
  } catch { res.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const url = `http://127.0.0.1:${server.address().port}/`;
const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
try {
  const staticPage = await browser.newPage({ javaScriptEnabled: false });
  await staticPage.goto(url);
  assert.equal(await staticPage.locator('.selection-row').count(), 4);
  assert.equal(await staticPage.locator('[data-character]').count(), 8);
  assert.equal(await staticPage.locator('[data-stage]').count(), 5);
  assert.equal(await staticPage.locator('#start').isVisible(), true);
  assert.equal(await staticPage.locator('.a-survivor h2').textContent(), 'Mira');
  const html = await (await fetch(url)).text();
  for (const name of ['Mira', 'Corvin', 'Forgotten Graveyard', 'Ready to play']) assert.ok(html.includes(name), `Initial HTML includes ${name}`);
  await staticPage.close();

  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  let releaseGame;
  const gate = new Promise(resolve => { releaseGame = resolve; });
  await page.route('**/dist/game.mjs', async route => { await gate; await route.continue(); });
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  // A heavy module held indefinitely must not prevent actual menu interactions.
  await page.locator('[data-menu-panel="character"]').click();
  await page.locator('[data-character="1"]').click();
  await page.locator('[data-buy-kind="character"]').waitFor();
  assert.equal(await page.locator('[data-buy-kind="character"]').isDisabled(), true);
  await page.locator('[data-tab="settings"]').click();
  await page.locator('#volume').evaluate(input => { input.value = '0.6'; });
  await page.locator('#volume').dispatchEvent('input');
  await page.locator('[data-tab="expedition"]').click();
  await page.locator('#start').click();
  await page.waitForFunction(() => document.querySelector('#engineStatus').textContent.includes('Preparing'));
  assert.equal(await page.locator('#start').isDisabled(), true);
  assert.equal(await page.locator('#menu').isVisible(), true);
  releaseGame();
  await page.waitForFunction(() => Number(document.querySelector('#game').dataset.tick) >= 5);
  assert.deepEqual(errors, []);
  await page.close();
  console.log('PASS: static HTML without JavaScript; catalog, purchases and settings without simulation; Start waits and then runs.');
} finally {
  await browser.close();
  await new Promise(resolve => server.close(resolve));
}
