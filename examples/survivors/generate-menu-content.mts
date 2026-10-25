import { object, parseJson } from "./host-values.mts"
import { writeFile } from "node:fs/promises"
import Catalog from "./dist/menu-catalog.mjs"
// Build-time export only. Authored game content lives in menu-catalog.bend.

const data = object(parseJson(Catalog.json()))
const header = "// Generated from menu-catalog.bend by generate-menu-content.mts. Do not edit.\n"
await writeFile(
  new URL("./content.mts", import.meta.url),
  header +
    Object.entries(data)
      .map(([name, value]) => `export const ${name} = ${JSON.stringify(value, null, 2)};\n`)
      .join("\n")
)
