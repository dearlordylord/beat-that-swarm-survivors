import type { chromium } from "playwright"
import { object } from "../../examples/survivors/host-values.mts"

export async function loadChromium(): Promise<Pick<typeof chromium, "launch">> {
  const specifier = process.env.PLAYWRIGHT_MODULE
  if (!specifier) return (await import("playwright")).chromium
  const imported: unknown = await import(specifier)
  const candidate = object(object(imported).chromium)
  const launch = candidate.launch
  if (typeof launch !== "function") throw new TypeError("Playwright override must export chromium.launch")
  // The override is a Playwright library installation; check the consumed entry
  // point before applying that library's published ABI to its returned objects.
  return { launch: (launch as typeof chromium.launch).bind(candidate) }
}
