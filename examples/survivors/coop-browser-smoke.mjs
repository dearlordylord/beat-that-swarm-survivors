// Real browser-hosted game over real Iroh relays; no simulated transport.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const base = process.env.COOP_URL || 'http://127.0.0.1:8786/coop.html';
const output = process.env.COOP_QA_DIR || '/tmp/bendvy-coop-browser-qa';
await mkdir(output,{recursive:true});
const browser = await chromium.launch({headless:true,args:['--no-sandbox']});
const errors = [];
let host, guest, workerFailure;
const failedWorker = new Promise(resolve => { workerFailure = resolve; });
const healthy = promise => Promise.race([promise, failedWorker.then(error => { throw Error(error.stack || error.message); })]);
const waitHost = (...args) => healthy(host.waitForFunction(...args));
const pageState = async page => page && !page.isClosed() ? page.evaluate(() => ({
  visible: document.visibilityState,
  status: document.querySelector('#coop-play-status')?.textContent,
  frame: globalThis.__coopLatest,
  stack: globalThis.__coopStack,
})).catch(() => null) : null;
try {
  const hostContext = await browser.newContext({viewport:{width:1280,height:800}});
  const guestContext = await browser.newContext({viewport:{width:1280,height:800}});
  await hostContext.addInitScript(() => {
    const NativeWorker = globalThis.Worker;
    globalThis.__coopFrames = [];
    globalThis.Worker = class extends NativeWorker {
      constructor(...args) {
        super(...args);
        this.addEventListener('message',event => {
          if (event.data.type === 'frame') {
            globalThis.__coopLatest = event.data.frame;
            globalThis.__coopFrames.push({tick:event.data.frame.tick,phase:event.data.frame.phase});
          }
          if (event.data.type === 'error') {
            globalThis.__coopError = event.data.message;
            globalThis.__coopStack = event.data.stack;
            globalThis.__coopWorkerFailed?.(event.data).catch(() => {});
          }
        });
      }
    };
  });
  host = await hostContext.newPage(); guest = await guestContext.newPage();
  await host.exposeFunction('__coopWorkerFailed', details => workerFailure(details));
  for (const [name,page] of [['host',host],['guest',guest]]) {
    page.on('pageerror',error => errors.push(`${name}: ${error.message}`));
    page.on('console',message => { if (message.type() === 'error') errors.push(`${name}: ${message.text()}`); });
  }
  await host.goto(base);
  await host.locator('#coop-host').click();
  await waitHost(() => document.querySelector('#coop-invite-link')?.value.includes('join='),null,{timeout:120000});
  const invitation = await host.locator('#coop-invite-link').inputValue();
  await guest.goto(invitation);
  await guest.locator('#coop-join').click();
  await waitHost(() => globalThis.__coopLatest?.players?.length === 2 && globalThis.__coopLatest.tick > 5,null,{timeout:120000});
  await guest.locator('#coop-play').waitFor({state:'visible'});
  const initial = await host.evaluate(() => globalThis.__coopLatest);
  let timing = null;
  const probeMs = Number(process.env.COOP_TIMING_MS || 0);
  if (probeMs > 0) {
    const began = Date.now();
    await healthy(host.waitForTimeout(probeMs));
    const after = await host.evaluate(() => globalThis.__coopLatest);
    timing = {wallMs:Date.now()-began,ticks:after.tick-initial.tick,phase:after.phase,
      simHz:1000*(after.tick-initial.tick)/(Date.now()-began),
      frameBytes:new TextEncoder().encode(JSON.stringify(after)).byteLength,
      hostVisibility:await host.evaluate(() => document.visibilityState),
      guestVisibility:await guest.evaluate(() => document.visibilityState)};
    console.log('Diagnostic browser progress: '+JSON.stringify(timing));
  }
  await guest.locator('#coop-game').focus();
  await guest.keyboard.down('ArrowRight');
  await waitHost(x => globalThis.__coopLatest?.players.find(player => player.id === 1)?.px > x + 5,
    initial.players.find(player => player.id === 1).px,{timeout:15000});
  await guest.keyboard.up('ArrowRight');
  const moved = await host.evaluate(() => globalThis.__coopLatest);
  assert.equal(moved.players.length,2);
  assert.ok(moved.tick > initial.tick);
  await guest.locator('#coop-map-toggle').click();
  const mapTick = moved.tick;
  await waitHost(tick => globalThis.__coopLatest?.tick > tick + 5,mapTick,{timeout:15000});
  await host.screenshot({path:`${output}/host.png`});
  await guest.screenshot({path:`${output}/guest.png`});
  await guest.locator('#coop-map-close').click();
  await guest.locator('#coop-leave').click();
  await waitHost(() => globalThis.__coopLatest?.players?.find(player => player.id === 1)?.connected === false,
    null,{timeout:15000});
  const departed = await host.evaluate(() => globalThis.__coopLatest);
  await host.locator('#coop-game').focus();
  await host.keyboard.down('ArrowLeft');
  await waitHost(x => globalThis.__coopLatest?.players.find(player => player.id === 0)?.px < x - 5,
    departed.players.find(player => player.id === 0).px,{timeout:15000});
  await host.keyboard.up('ArrowLeft');
  assert.equal(await host.evaluate(() => globalThis.__coopError),undefined);
  assert.deepEqual(errors,[]);
  await writeFile(`${output}/result.json`,JSON.stringify({pass:true,initial,moved,departed,timing,errors},null,2));
  console.log(`PASS real browser co-op: shared world, guest input, nonpausing map, host survives guest departure. ${output}`);
} catch (error) {
  await writeFile(`${output}/failure.json`,JSON.stringify({message:error.message,errors,host:await pageState(host),guest:await pageState(guest)},null,2));
  await host?.screenshot({path:`${output}/host-failure.png`}).catch(() => {});
  await guest?.screenshot({path:`${output}/guest-failure.png`}).catch(() => {});
  throw error;
} finally { await browser.close(); }
