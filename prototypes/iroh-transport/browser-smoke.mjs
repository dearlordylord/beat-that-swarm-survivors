// Real Iroh relays, two isolated browser contexts. No transport is mocked.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const url = process.env.IROH_LAB_URL || 'http://127.0.0.1:8797/';
const captures = process.env.IROH_LAB_CAPTURES || '/tmp/bend-iroh-browser-qa';
await mkdir(captures, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
const errors = [], sockets = [], applicationRequests = [];
async function page(label, viewport) {
  const context = await browser.newContext({ viewport }); const p = await context.newPage();
  p.on('pageerror', error => errors.push({ label, message: error.message }));
  p.on('websocket', socket => sockets.push({ label, url: socket.url() }));
  p.on('request', request => { if (new URL(request.url()).origin === new URL(url).origin) applicationRequests.push(new URL(request.url()).pathname); });
  await p.goto(url); await p.waitForFunction(() => !document.querySelector('#create').disabled);
  return p;
}
try {
  const host = await page('host', { width: 1440, height: 1000 });
  const guest = await page('guest', { width: 390, height: 844 });
  await host.locator('#create').click();
  await host.waitForFunction(() => document.querySelector('#invitation').value.length > 20, {}, { timeout: 45000 });
  const invite = await host.locator('#invitation').inputValue();
  // Self-connect refusal must leave the hosting endpoint available to a real guest.
  await host.locator('#join-invite').fill(invite); await host.locator('#join').click();
  await host.locator('#notice').waitFor({ state: 'visible' });
  assert.match(await host.locator('#notice').textContent(), /itself/);
  await guest.locator('#join-invite').fill(invite); await guest.locator('#join').click();
  const connected = p => p.waitForFunction(() => document.querySelector('#status').textContent.startsWith('Connected'), {}, { timeout: 45000 });
  await Promise.all([connected(host), connected(guest)]);
  const send = async (p, message) => { await p.locator('#message').fill(message); await p.locator('#send').click(); };
  await send(host, 'Hello | Привет 🌙');
  await guest.waitForFunction(() => document.querySelector('#received').textContent === '1');
  assert.equal(await guest.locator('.incoming .message-text').last().textContent(), 'Hello | Привет 🌙');
  await send(guest, 'Reply <img src=x onerror=alert(1)>');
  await host.waitForFunction(() => document.querySelector('#received').textContent === '1');
  assert.equal(await host.locator('.incoming img').count(), 0);
  // Burst exercises the serialized adapter and ordered delivery on actual Iroh streams.
  await host.evaluate(() => { for (let i = 0; i < 12; i++) { document.querySelector('#message').value = 'burst-' + i; document.querySelector('#message-form').requestSubmit(); } });
  await guest.waitForFunction(() => document.querySelector('#received').textContent === '13', {}, { timeout: 20000 });
  assert.deepEqual(await guest.locator('.incoming .message-text').allTextContents().then(rows => rows.slice(-12)), Array.from({ length: 12 }, (_, i) => 'burst-' + i));
  await send(host, 'x'.repeat(257));
  await host.locator('#notice').waitFor({ state: 'visible' });
  assert.equal(await guest.locator('#received').textContent(), '13');
  const before = JSON.parse(await guest.locator('#diagnostics').textContent()).endpoint;
  await guest.locator('#disconnect').click();
  await host.waitForFunction(() => document.querySelector('#status').textContent.startsWith('Peer disconnected'), {}, { timeout: 20000 });
  await guest.locator('#join-invite').fill(invite); await guest.locator('#join').click();
  await Promise.all([connected(host), connected(guest)]);
  await send(guest, 'New connection · sequence reset');
  await host.waitForFunction(() => document.querySelector('#received').textContent === '1');
  assert.equal(await host.locator('.incoming small').last().textContent(), 'RECEIVED #1');
  assert.notEqual(before, JSON.parse(await guest.locator('#diagnostics').textContent()).endpoint);
  assert.equal(await guest.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
  assert.equal(await host.evaluate(() => localStorage.length), 0);
  assert.equal(await guest.evaluate(() => localStorage.length), 0);
  assert.ok(sockets.length >= 3 && sockets.every(s => s.url.startsWith('wss://')));
  assert.ok(applicationRequests.every(p => !p.endsWith('/game.mjs')));
  assert.deepEqual(errors, []);
  await host.screenshot({ path: captures + '/host.png', fullPage: true });
  await guest.screenshot({ path: captures + '/guest.png', fullPage: true });
  const result = { pass: true, url, sockets, errors, host: JSON.parse(await host.locator('#diagnostics').textContent()), guest: JSON.parse(await guest.locator('#diagnostics').textContent()), applicationRequests: [...new Set(applicationRequests)] };
  await writeFile(captures + '/result.json', JSON.stringify(result, null, 2));
  console.log(JSON.stringify(result));
} finally { await browser.close(); }
