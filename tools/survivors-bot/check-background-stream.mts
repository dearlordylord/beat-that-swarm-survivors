import assert from "node:assert/strict"
import { chromium, type Page } from "playwright"
import { freshProfile } from "../../examples/survivors/progression.mts"
import { object, number, boolean } from "../../examples/survivors/host-values.mts"

const origin = new URL(process.argv[2] ?? "http://127.0.0.1:8812/")
const executablePath = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE
const browser = await chromium.launch({
  headless: true,
  ...(executablePath ? { executablePath } : {}),
  args: ["--no-sandbox"]
})
async function diagnostic(page: Page) {
  const value = await page.locator("#stream-diagnostics").textContent()
  assert(value)
  const parsed: unknown = JSON.parse(value)
  const row = object(parsed)
  return { tick: number(row.tick), run: number(row.run), session: number(row.session), paused: boolean(row.paused) }
}
try {
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 } })
  await context.addInitScript(() => {
    const request = window.requestAnimationFrame.bind(window)
    const pending: FrameRequestCallback[] = []
    window.requestAnimationFrame = (callback) =>
      request((now) => {
        if (document.hidden) pending.push(callback)
        else callback(now)
      })
    document.addEventListener("visibilitychange", () => {
      if (!document.hidden) for (const callback of pending.splice(0)) request(callback)
    })
  })
  const page = await context.newPage()
  const errors: string[] = []
  page.on("pageerror", (error) => errors.push(String(error)))
  const streamUrl = new URL(origin)
  streamUrl.searchParams.set("stream", "1")
  streamUrl.searchParams.set("between", "0")
  await page.goto(streamUrl.href)
  await page.locator("#stream-start").waitFor()
  const profile = freshProfile()
  await page.evaluate((profile) => {
    localStorage.setItem(
      "nightfall-survivors-v1",
      JSON.stringify({ ...profile, characters: [0, 1], stats: { ...profile.stats, levels: 20 } })
    )
  }, profile)
  await page.reload()
  await page.locator('[data-menu-panel="character"]').click()
  await page.locator('[data-character="1"]').click()
  const saved = await page.evaluate(() => localStorage.getItem("nightfall-survivors-v1"))
  const popup = page.waitForEvent("popup")
  await page.locator("#stream-detach").click()
  const controls = await popup
  await controls.waitForLoadState()
  controls.on("pageerror", (error) => errors.push(String(error)))
  assert.equal(await page.locator("#stream-controls").count(), 0)
  assert.equal(await controls.locator("#stream-next").isDisabled(), true)
  await page.locator("#start").click()
  const card = page.locator("#stream-announcement")
  await card.waitFor()
  const beforeHidden = await diagnostic(controls)
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", { configurable: true, value: true })
    document.dispatchEvent(new Event("visibilitychange"))
  })
  await controls.waitForFunction(
    (tick) => Number(document.querySelector("#stream-diagnostics")?.textContent?.match(/"tick":\s*(\d+)/)?.[1]) > tick,
    beforeHidden.tick
  )
  assert.equal((await diagnostic(controls)).paused, false)
  await controls.locator("#stream-pause").click()
  const hiddenPaused = await diagnostic(controls)
  assert.equal(hiddenPaused.paused, true)
  await page.waitForTimeout(500)
  assert.equal((await diagnostic(controls)).tick, hiddenPaused.tick)
  await page.evaluate(() => {
    Reflect.deleteProperty(document, "hidden")
    document.dispatchEvent(new Event("visibilitychange"))
  })
  assert.equal((await diagnostic(controls)).paused, true)
  await controls.locator("#stream-pause").click()
  for (let index = 0; index < 3; ++index) {
    await page.evaluate(() => {
      Object.defineProperty(document, "hidden", { configurable: true, value: true })
      document.dispatchEvent(new Event("visibilitychange"))
    })
    const tick = (await diagnostic(controls)).tick
    await controls.waitForFunction(
      (tick) =>
        Number(document.querySelector("#stream-diagnostics")?.textContent?.match(/"tick":\s*(\d+)/)?.[1]) > tick,
      tick
    )
    await page.evaluate(() => {
      Reflect.deleteProperty(document, "hidden")
      document.dispatchEvent(new Event("visibilitychange"))
    })
    assert.equal((await diagnostic(controls)).paused, false)
  }
  assert.equal(await page.evaluate(() => localStorage.getItem("nightfall-survivors-v1")), saved)
  await controls.locator("#stream-stop").click()
  await controls.close({ runBeforeUnload: true })
  await page.goto(origin.href)
  await page.locator("#start").click()
  await page.locator("#hud").waitFor()
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", { configurable: true, value: true })
    document.dispatchEvent(new Event("visibilitychange"))
  })
  assert.equal(await page.locator("#resume").isVisible(), true)
  assert.deepEqual(errors, [])
  console.log(
    "PASS: hidden stream ticks without RAF, manual pause stays paused across visibility changes, repeated clock handoffs, ordinary player hidden pause"
  )
} finally {
  await browser.close()
}
