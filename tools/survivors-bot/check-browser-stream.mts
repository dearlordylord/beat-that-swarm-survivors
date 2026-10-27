import assert from "node:assert/strict"
import { chromium, type Page } from "playwright"
import { join } from "node:path"
import { tmpdir } from "node:os"
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
  const page = await context.newPage()
  const errors: string[] = []
  page.on("pageerror", (error) => errors.push(String(error)))
  const streamUrl = new URL(origin)
  streamUrl.searchParams.set("stream", "1")
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
  await page.locator("#start").click()
  const card = page.locator("#stream-announcement")
  await card.waitFor()
  await controls.waitForFunction(
    () => Number(document.querySelector("#stream-diagnostics")?.textContent?.match(/"tick":\s*(\d+)/)?.[1]) > 60
  )
  const first = await diagnostic(controls)
  assert.equal(first.run, 1)
  assert.equal(await card.getAttribute("data-character"), "1")
  assert.match(await card.innerText(), /Hearth Voyager/)
  const capture = process.env.STREAM_CHECK_CAPTURE ?? join(tmpdir(), "beat-stream-announcement.png")
  await page.screenshot({ path: capture })
  await controls.locator("#stream-pause").click()
  assert.equal((await diagnostic(controls)).paused, true)
  const paused = await diagnostic(controls)
  await page.waitForTimeout(500)
  assert.equal((await diagnostic(controls)).tick, paused.tick)
  await controls.locator("#stream-pause").click()
  await controls.waitForFunction(
    (tick) => Number(document.querySelector("#stream-diagnostics")?.textContent?.match(/"tick":\s*(\d+)/)?.[1]) > tick,
    paused.tick
  )
  await controls.locator("#stream-reload").click()
  await controls.waitForFunction(() =>
    /"status":\s*"active"/.test(document.querySelector("#stream-diagnostics")?.textContent ?? "")
  )
  assert.equal((await diagnostic(controls)).run, first.run)
  assert.equal((await diagnostic(controls)).session, first.session)
  assert.match(await controls.locator("#stream-status").innerText(), /audio running/)
  await page.waitForFunction(() =>
    document.querySelector("#stream-announcement")?.classList.contains("stream-announcement-compact")
  )
  assert.equal(await page.evaluate(() => localStorage.getItem("nightfall-survivors-v1")), saved)
  await controls.close({ runBeforeUnload: true })
  await page.locator("#stream-controls").waitFor()
  const secondPopup = page.waitForEvent("popup")
  await page.locator("#stream-detach").click()
  const second = await secondPopup
  await second.locator("#stream-stop").click()
  await card.waitFor({ state: "hidden" })
  await second.close({ runBeforeUnload: true })
  await page.goto(origin.href)
  await page.locator("#start").waitFor()
  assert.equal(await page.locator("#stream-controls").count(), 0)
  assert.equal(await page.locator("#stream-announcement").count(), 0)
  assert.deepEqual(errors, [])
  console.log(
    `PASS: detached controls, player Start, pause/resume, reload, audio, actual character card, compact card, profile isolation, close/reattach, second detach, stop and player mode. Screenshot: ${capture}`
  )
} finally {
  await browser.close()
}
