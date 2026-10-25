import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { test } from "node:test"
import { chromium } from "playwright"
import ts from "typescript-compiler-api"

await test("a reward activates once with a second finger while movement stays held", async () => {
  const executablePath = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH
  const browser = await chromium.launch({ ...(executablePath ? { executablePath } : {}) })
  try {
    const page = await browser.newPage({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true })
    await page.setContent(`<style>
      #joystick{position:absolute;left:20px;top:700px;width:100px;height:100px;touch-action:none}
      #offers{position:absolute;left:150px;top:20px;width:220px;height:400px;overflow:auto}
      button{display:block;width:200px;height:140px} .space{height:1000px}
      </style><div id="joystick"></div><div id="offers"></div><output id="count">0</output>`)
    const source = await readFile(new URL("./dom.mts", import.meta.url), "utf8")
    const compiled = ts.transpileModule(source, {
      compilerOptions: { target: ts.ScriptTarget.ES2023, module: ts.ModuleKind.ESNext }
    }).outputText
    await page.addScriptTag({
      type: "module",
      content: `${compiled}
        const offers = document.querySelector('#offers');
        const render = () => offers.innerHTML = '<button data-choice="0"><span>Reward</span></button><div class="space"></div>';
        render();
        enableSecondaryRewardTouch(offers);
        offers.addEventListener('click', event => {
          const button = event.target.closest('button');
          if (!button || button.disabled) return;
          const count = document.querySelector('#count');
          count.textContent = String(Number(count.textContent) + 1);
          if (offers.dataset.pending === 'true') button.disabled = true;
          else render();
        });`
    })
    const cdp = await page.context().newCDPSession(page)
    type Point = { id: number; x: number; y: number }
    const thumb: Point = { id: 1, x: 70, y: 750 }
    const finger: Point = { id: 2, x: 250, y: 90 }
    const touch = (type: "touchStart" | "touchMove" | "touchEnd" | "touchCancel", touchPoints: Point[]) =>
      cdp.send("Input.dispatchTouchEvent", { type, touchPoints })
    const count = async () => Number(await page.locator("#count").textContent())

    await touch("touchStart", [thumb])
    await touch("touchStart", [thumb, finger])
    await touch("touchEnd", [finger])
    assert.equal(await count(), 1, "one second-finger tap selects exactly one stacked reward")
    await touch("touchEnd", [])
    assert.equal(await count(), 1, "releasing movement does not select the next stacked reward")

    await touch("touchStart", [thumb])
    await touch("touchStart", [thumb, finger])
    const outside = { ...finger, x: 380, y: 600 }
    await touch("touchMove", [thumb, outside])
    await touch("touchEnd", [outside])
    await touch("touchEnd", [])
    assert.equal(await count(), 1, "dragging off a captured card does not choose it")

    await touch("touchStart", [thumb])
    await touch("touchStart", [thumb, finger])
    await touch("touchCancel", [])
    assert.equal(await count(), 1, "cancelling a touch does not choose a reward")

    await touch("touchStart", [thumb])
    await touch("touchStart", [thumb, finger])
    await touch("touchMove", [thumb, { ...finger, y: 30 }])
    await touch("touchEnd", [{ ...finger, y: 30 }])
    await touch("touchEnd", [])
    assert.equal(await count(), 1, "scrolling the reward panel does not choose a reward")

    await touch("touchStart", [thumb])
    await touch("touchStart", [thumb, finger])
    await touch("touchMove", [thumb, { ...finger, x: finger.x + 30 }])
    await touch("touchMove", [thumb, finger])
    await touch("touchEnd", [finger])
    await touch("touchEnd", [])
    assert.equal(await count(), 1, "a drag remains cancelled after returning to its starting point")

    await page.locator("#offers").evaluate((offers) => {
      offers.scrollTop = 0
      offers.dataset.pending = "true"
    })
    await touch("touchStart", [thumb])
    await touch("touchStart", [thumb, finger])
    await touch("touchEnd", [finger])
    assert.equal(await count(), 2, "co-op pending choice is sent once")
    await page.locator("button").dispatchEvent("click")
    await touch("touchEnd", [])
    assert.equal(await count(), 2, "a later compatibility click cannot resend a pending choice")

    await page.locator("button").evaluate((button) => {
      button.removeAttribute("disabled")
    })
    await page.locator("button").tap()
    assert.equal(await count(), 3, "a primary touch still selects once")
    await page.locator("button").evaluate((button) => {
      button.removeAttribute("disabled")
    })
    await page.locator("button").focus()
    await page.keyboard.press("Enter")
    assert.equal(await count(), 4, "keyboard activation still selects once")
    await page.locator("button").evaluate((button) => {
      button.removeAttribute("disabled")
    })
    await page.mouse.click(finger.x, finger.y)
    assert.equal(await count(), 5, "mouse activation still selects once")
  } finally {
    await browser.close()
  }
})
