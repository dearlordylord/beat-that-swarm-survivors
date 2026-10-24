// Build-time export only. Authored game content lives in menu-catalog.bend.
import { writeFile } from 'node:fs/promises';
import Catalog from './dist/menu-catalog.mjs';
const data = JSON.parse(Catalog.json());
const header = '// Generated from menu-catalog.bend by generate-menu-content.mjs. Do not edit.\n';
await writeFile(new URL('./content.mjs', import.meta.url), header + Object.entries(data)
  .map(([name, value]) => `export const ${name} = ${JSON.stringify(value, null, 2)};\n`).join('\n'));
