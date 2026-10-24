import assert from "node:assert/strict";
import { createServer } from "node:http";
import { readFile, stat, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
for (const file of ["game.bend", "projectile.bend", "encounters.bend"])
  assert.ok(
    (await stat(new URL("./dist/game.mjs", import.meta.url))).mtimeMs >=
      (await stat(new URL(file, import.meta.url))).mtimeMs,
    "Rebuild stale " + file,
  );
const { chromium } = await import(
  process.env.PLAYWRIGHT_MODULE || "playwright"
);
const captureDir = process.env.NIGHTFALL_CAPTURE_DIR || fileURLToPath(new URL("./dist/browser-captures/", import.meta.url));
await mkdir(captureDir, { recursive: true });
const root = fileURLToPath(new URL(".", import.meta.url));
const server = createServer(async (req, res) => {
  const target = path.resolve(
    root,
    "." + decodeURIComponent(new URL(req.url, "http://localhost").pathname),
  );
  if (target !== root.slice(0, -1) && !target.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  const file =
    target === root.slice(0, -1) ? path.join(root, "index.html") : target;
  try {
    const data = await readFile(file);
    res.setHeader(
      "Content-Type",
      file.endsWith(".html")
        ? "text/html"
        : file.endsWith(".mjs")
          ? "text/javascript"
          : file.endsWith(".css")
            ? "text/css"
            : "application/octet-stream",
    );
    res.end(data);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
let browser;
try {
  browser = await chromium.launch({ headless: true, args: ["--no-sandbox"] });
  const page = await browser.newPage({
      viewport: { width: 1440, height: 1000 },
    }),
    errors = [];
  page.setDefaultTimeout(5000);
  page.setDefaultNavigationTimeout(5000);
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  await page.waitForSelector("#start");
  assert.equal(await page.locator("[data-character]").count(), 8);
  await page.locator('[data-tab="collection"]').click();
  assert.equal(await page.locator("[data-collection]").count(), 6);
  await page.locator('[data-collection="evolutions"]').click();
  assert.equal(await page.locator(".collection .card").count(), 24);
  await page.locator('[data-tab="expedition"]').click();
  await page.screenshot({ path: path.join(captureDir, "menu.png"), fullPage: true });
  await page.locator("#start").click();
  await page.waitForFunction(
    () => document.querySelector("#clock").textContent === "00:01",
  );
  const beforeX = Number(
    await page.locator("#game").getAttribute("data-player-x"),
  );
  await page.keyboard.down("KeyD");
  await page.waitForTimeout(350);
  await page.keyboard.up("KeyD");
  assert.ok(
    Number(await page.locator("#game").getAttribute("data-player-x")) > beforeX,
    "Keyboard input must move the Bend player",
  );
  await page.keyboard.press("KeyM");
  await page.locator("#worldmap").waitFor({ state: "visible" });
  assert.equal(Number(await page.locator("#worldmap").getAttribute("data-world-size")), 14400);
  assert.equal(await page.locator("#worldmap").getAttribute("data-relic"), "1");
  const mapTick = await page.locator("#game").getAttribute("data-tick");
  await page.waitForTimeout(100);
  assert.equal(await page.locator("#game").getAttribute("data-tick"), mapTick, "Map pauses simulation");
  await page.screenshot({ path: path.join(captureDir, "map.png") });
  await page.keyboard.press("KeyM");
  await page.locator("#worldmap").waitFor({ state: "hidden" });
  await page.locator("#pause").click();
  await page.locator("#worldmap").waitFor({ state: "visible" });
  assert.equal(await page.locator("#resume").count(), 1);
  assert.equal(await page.evaluate(() => document.activeElement.id), "resume");
  await page.keyboard.press("Shift+Tab");
  assert.equal(await page.evaluate(() => document.activeElement.id), "abandon");
  await page.keyboard.press("Tab");
  assert.equal(await page.evaluate(() => document.activeElement.id), "resume");
  const clock = await page.locator("#clock").textContent();
  await page.waitForTimeout(250);
  assert.equal(await page.locator("#clock").textContent(), clock);
  await page.locator("#resume").click();
  await page.screenshot({ path: path.join(captureDir, "game.png") });
  await page.locator("#pause").click();
  await page.locator("#abandon").click();
  await page.waitForSelector("#start");
  await page.reload();
  await page.waitForSelector("#start");
  // Explicit XP boundary fixture: keep the actual Bend game and browser UI,
  // seed XP at start to trigger real levels and exercise the deferred queue.
  const rewards = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  rewards.setDefaultTimeout(5000);
  rewards.on("pageerror", (e) => errors.push(e.message));
  await rewards.route("**/dist/game.mjs", async (route) => {
    const response = await route.fetch();
    const source = await response.text();
    assert.ok(source.includes("export default {"));
    await route.fulfill({ response, body: source.replace("export default {", "const fixtureGame = {") + `
export default { ...fixtureGame, start: (...args) => {
  const packet = fixtureGame.start(...args);
  packet.state.run.xp = 4 * packet.state.run.xpNeed;
  return packet;
} };` });
  });
  await rewards.goto(`http://127.0.0.1:${server.address().port}/`);
  await rewards.locator("#start").click();
  await rewards.waitForSelector("[data-choice]");
  const rewardTick = await rewards.locator("#game").getAttribute("data-tick");
  await rewards.waitForTimeout(200);
  assert.equal(await rewards.locator("#game").getAttribute("data-tick"), rewardTick,
    "Automatic reward panel pauses the battlefield without E");
  const choicesBeforeMapKey = await rewards.locator("[data-choice]").count();
  await rewards.keyboard.press("KeyM");
  assert.equal(await rewards.locator("[data-choice]").count(), choicesBeforeMapKey,
    "M preserves an open reward panel");
  assert.ok(await rewards.locator("#overlay").isVisible());
  assert.equal(await rewards.locator("#worldmap").count(), 0);
  assert.equal(await rewards.locator("#game").getAttribute("data-tick"), rewardTick);
  await rewards.keyboard.press("Escape");
  await rewards.waitForFunction(tick => Number(document.querySelector("#game").dataset.tick) > Number(tick), rewardTick);
  await rewards.keyboard.press("KeyE");
  await rewards.waitForSelector("[data-choice]");
  await rewards.locator("[data-choice]").first().click();
  assert.ok(await rewards.locator("#overlay").isVisible(), "Queued reward automatically opens after the first choice");
  await rewards.locator("[data-choice]").first().click();
  assert.ok(await rewards.locator("#overlay").isHidden(), "Choosing all earned rewards resumes combat");
  await rewards.close();
  const mobile = await browser.newPage({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
  });
  mobile.setDefaultTimeout(5000);
  mobile.setDefaultNavigationTimeout(5000);
  mobile.on("pageerror", (e) => errors.push(e.message));
  await mobile.goto(`http://127.0.0.1:${server.address().port}/`);
  await mobile.locator("#start").click();
  await mobile.waitForFunction(
    () => Number(document.querySelector("#game").dataset.tick) >= 10,
  );
  assert.ok(await mobile.locator("#joystick").isVisible());
  const joy = await mobile.locator("#joystick").boundingBox();
  const mobileX = Number(
    await mobile.locator("#game").getAttribute("data-player-x"),
  );
  const session = await mobile.context().newCDPSession(mobile);
  await session.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: joy.x + joy.width * 0.8, y: joy.y + joy.height * 0.5 }],
  });
  await mobile.waitForTimeout(250);
  await session.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  assert.ok(
    Number(await mobile.locator("#game").getAttribute("data-player-x")) >
      mobileX,
    "Touch joystick must move Bend player",
  );
  await mobile.screenshot({ path: path.join(captureDir, "mobile.png") });
  await mobile.close();
  assert.deepEqual(errors, []);
  console.log(
    "Browser menu, collection, gameplay, keyboard/touch movement, modal focus, automatic reward pause/choice, explicit defer/reopen, pause, abandon, reload pass.",
  );
} finally {
  await browser?.close();
  await new Promise((resolve) => server.close(resolve));
}
