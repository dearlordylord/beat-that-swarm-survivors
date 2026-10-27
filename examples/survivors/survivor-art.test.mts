import assert from "node:assert/strict"
import { test } from "node:test"
import { survivorSvg, drawSurvivor } from "./survivor-art.mts"

await test("portraits and Canvas use the same distinct art for all seven survivors", () => {
  let compiled = 0
  const previousPath = globalThis.Path2D
  Object.defineProperty(globalThis, "Path2D", {
    configurable: true,
    writable: true,
    value: class {
      path: string
      constructor(path: string) {
        this.path = path
        compiled++
      }
    }
  })
  try {
    const portraits = new Set()
    for (let id = 0; id < 7; id++) {
      const svg = survivorSvg(id)
      portraits.add(svg)
      const expected = [...svg.matchAll(/<path fill="([^"]+)" d="([^"]+)"\/>/g)].map(([, color, path]) => [color, path])
      const actual: [string, string][] = []
      const context = {
        fillStyle: "",
        save() {},
        restore() {},
        translate() {},
        scale() {},
        fill(path: { path: string }) {
          actual.push([this.fillStyle, path.path])
        }
      }
      Reflect.apply(drawSurvivor, undefined, [context, id, 100, 100])
      assert.deepEqual(actual, expected)
      const count = compiled
      Reflect.apply(drawSurvivor, undefined, [context, id, 110, 105])
      assert.equal(compiled, count, "movement reuses cached paths")
    }
    assert.equal(portraits.size, 7)
    assert.equal(survivorSvg(99), survivorSvg(0))
  } finally {
    globalThis.Path2D = previousPath
  }
})

await test("walking changes the Canvas pose while portraits and stopped art stay selected", () => {
  const previousPath = globalThis.Path2D
  let compiled = 0
  Object.defineProperty(globalThis, "Path2D", {
    configurable: true,
    writable: true,
    value: class {
      path: string
      constructor(path: string) {
        this.path = path
        compiled++
      }
    }
  })
  try {
    for (let id = 0; id < 7; id++) {
      const actual: string[] = []
      const context = {
        fillStyle: "",
        save() {},
        restore() {},
        translate() {},
        scale() {},
        fill(path: { path: string }) {
          actual.push(this.fillStyle + path.path)
        }
      }
      const pose = (frame: number) => {
        actual.length = 0
        Reflect.apply(drawSurvivor, undefined, [context, id, 100, 100, frame])
        return actual.join("|")
      }
      const portrait = survivorSvg(id)
      const idle = pose(-1)
      const moving = new Set(Array.from({ length: 8 }, (_, frame) => pose(frame)))
      assert.ok(moving.size >= 4, "a complete cycle has distinct foot poses")
      assert.ok([...moving].some((frame) => frame !== idle))
      const count = compiled
      pose(3)
      assert.equal(compiled, count, "walking paths are cached")
      assert.equal(pose(-1), idle, "stopping restores selected idle")
      assert.equal(survivorSvg(id), portrait, "walking does not change portraits")
    }
  } finally {
    globalThis.Path2D = previousPath
  }
})
