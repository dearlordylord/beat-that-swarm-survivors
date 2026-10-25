// Optional authoring tool; normal builds copy the checked-in PNGs and need no browser.
import { readFile, mkdir } from "node:fs/promises"
import { fileURLToPath } from "node:url"
import { portrait } from "./expedition-menu.mts"
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || "playwright")
const output = new URL("./social/", import.meta.url)
await mkdir(output, { recursive: true })
const screenshot =
  "data:image/png;base64," + (await readFile(new URL("gameplay-source.png", output))).toString("base64")
const moon =
  '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M16 2A10 10 0 1 0 22 17 9 9 0 0 1 16 2Z"/><path d="M20 1h1v3h3v1h-3v3h-1V5h-3V4h3Z"/></svg>'
const browser = await chromium.launch({ headless: true, args: ["--no-sandbox"] })
try {
  for (const coop of process.argv.includes("--coop-only") ? [true] : [false, true]) {
    const page = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 })
    await page.setContent(`<!doctype html><html><meta charset="utf-8"><style>
      *{box-sizing:border-box}body{margin:0;width:1200px;height:630px;overflow:hidden;background:#17131c;color:#f0e4ce;font-family:Georgia,'Times New Roman',serif}
      .card{position:relative;width:1200px;height:630px;isolation:isolate;background:radial-gradient(ellipse at 27% 5%,#59405155,transparent 65%),#17131c}
      .arena{position:absolute;inset:0 0 0 430px;background-image:url('${screenshot}');background-size:auto 770px;background-position:40% 48%;opacity:.5;filter:saturate(.65);z-index:-2}
      .veil{position:absolute;inset:0;background:linear-gradient(90deg,#211824 0%,#241a28f5 32%,#241a28bc 52%,#17131c30 76%),linear-gradient(0deg,#17131ce6,transparent 35%,transparent 75%,#17131c66);z-index:-1}
      .border{position:absolute;inset:25px;border:1px solid #8c704b88;box-shadow:inset 0 0 0 5px #17111b55}
      .corner{position:absolute;width:8px;height:8px;border:1px solid #ceb17a;background:#6c4d52;transform:rotate(45deg)}
      .corner.a{left:21px;top:21px}.corner.b{right:21px;top:21px}.corner.c{bottom:21px;left:21px}.corner.d{bottom:21px;right:21px}
      header{position:absolute;left:70px;right:70px;top:66px;display:flex;align-items:center;gap:15px;color:#d7bf8f;font:16px system-ui,sans-serif;letter-spacing:.14em;text-transform:uppercase}
      header>svg{height:32px;width:32px}header .mode{margin-left:auto;font:12px system-ui,sans-serif;letter-spacing:.14em;border:1px solid #9b805266;padding:9px 13px;background:#251c29b0}
      .copy{position:absolute;top:191px;left:72px;width:650px}
      h1{font-weight:400;letter-spacing:-3px;line-height:1;margin:0;color:#f4e5c7;font-size:92px;text-shadow:0 4px 25px #130b17}
      .sub{font-size:${coop ? "42" : "29"}px;margin-top:25px;letter-spacing:${coop ? "-.6" : "0"}px;color:#dfc7b7;line-height:1.25}
      .detail{font:21px/1.5 system-ui,sans-serif;color:#bcaac3;margin-top:16px}
      footer{position:absolute;bottom:63px;left:73px;right:70px;display:flex;align-items:center;color:#d6bf98;font:14px system-ui,sans-serif;letter-spacing:.03em}
      footer .line{width:45px;height:1px;background:#b99c70;margin-right:13px}footer .domain{margin-left:auto;color:#b3a0b7;font:12px monospace}
      .party{position:absolute;right:${coop ? "67" : "111"}px;bottom:112px;width:${coop ? "395" : "230"}px;height:320px;display:flex;align-items:flex-end;justify-content:center;gap:0}
      .ring{position:absolute;width:310px;height:310px;border-radius:50%;border:1px solid #bc9d5a55;box-shadow:inset 0 0 0 8px #17131c40,inset 0 0 0 9px #9b805126;left:50%;top:-1px;transform:translateX(-50%);background:radial-gradient(ellipse,#b19c6324,transparent 70%)}
      .ring:before,.ring:after{content:'';position:absolute;width:7px;height:7px;background:#ceb47e;transform:rotate(45deg);left:calc(50% - 3px);top:-4px}.ring:after{top:auto;bottom:-4px}
      .person{position:relative;width:${coop ? "177" : "215"}px;z-index:2;filter:drop-shadow(0 15px 8px #05060f80)}
      .person .pixel-portrait{height:${coop ? "235" : "270"}px;width:100%}.person svg{height:100%;width:100%;image-rendering:pixelated}
      .person:first-of-type{transform:${coop ? "translateY(6px)" : "none"}}
      .ground{position:absolute;width:350px;height:55px;bottom:-10px;left:50%;transform:translateX(-50%);border-radius:50%;background:#0b1016b0;border:1px solid #bba05b33}
    </style><div class="card"><div class="arena"></div><div class="veil"></div><div class="border"></div><i class="corner a"></i><i class="corner b"></i><i class="corner c"></i><i class="corner d"></i>
    <header>${moon}<span>Bendvy ECS example</span><span class="mode">${coop ? "CO-OP" : "SOLO + CO-OP"}</span></header>
    <div class="copy"><h1>Survivors</h1><div class="sub">${coop ? "Bring a friend." : "A Vampire Survivors clone."}</div><div class="detail">${coop ? "Survive together" : "Built with Bendvy. Play in your browser."}</div></div>
    <div class="party"><div class="ring"></div><div class="ground"></div><div class="person">${portrait(0)}</div>${coop ? `<div class="person">${portrait(1)}</div>` : ""}</div>
    <footer><span class="line"></span><span>${coop ? "Browser co-op · No installation" : "Entity Component System · Playable example"}</span><span class="domain">survivors.dearlordylord.com</span></footer></div></html>`)
    await page.evaluate(() => Promise.all([...document.images].map((img) => img.decode())))
    await page.screenshot({
      path: fileURLToPath(new URL(coop ? "survivors-coop-v2.png" : "survivors-v1.png", output)),
      type: "png"
    })
    await page.close()
  }
} finally {
  await browser.close()
}
console.log("Generated static social cards:1200x630 PNG")
