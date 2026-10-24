import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFile, writeFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('.', import.meta.url));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const sorted = value => JSON.stringify(Object.entries(value).sort());
async function filesAt(directory, source = false, prefix = '') {
  const files = {};
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const name = prefix + entry.name;
    if (source && ['dist', 'target', 'node_modules'].includes(entry.name)) continue;
    if (!source && name === 'build.json') continue;
    if (entry.isSymbolicLink()) throw Error('Artifact symlinks are not supported.');
    if (entry.isDirectory()) Object.assign(files, await filesAt(path.join(directory, entry.name), source, name + '/'));
    else files[name] = hash(await readFile(path.join(directory, entry.name)));
  }
  return files;
}
async function sourceState() {
  const files = await filesAt(root, true);
  const git = args => execFileSync('git', ['-C', root, ...args], { encoding: 'utf8' }).trim();
  return { revision: git(['rev-parse', 'HEAD']), branch: git(['branch', '--show-current']),
    dirty: Boolean(git(['status', '--porcelain', '--', '.'])), sourceFingerprint: hash(sorted(files)), files };
}
const [mode, output, beforePath] = process.argv.slice(2);
const current = await sourceState();
if (mode === 'capture') {
  await writeFile(output, JSON.stringify(current));
} else if (mode === 'finalize') {
  const before = JSON.parse(await readFile(beforePath, 'utf8'));
  if (JSON.stringify(before) !== JSON.stringify(current)) throw Error('Prototype sources changed during build. Rebuild before publishing.');
  const assets = await filesAt(output);
  await writeFile(path.join(output, 'build.json'), JSON.stringify({ ...current, assets,
    prototype: 'bend-iroh-transport', iroh: '1.4.1', browserPath: 'relay', builtAt: new Date().toISOString() }, null, 2) + '\n');
} else if (mode === 'verify') {
  const receipt = JSON.parse(await readFile(path.join(output, 'build.json'), 'utf8'));
  for (const key of ['revision', 'branch', 'sourceFingerprint']) if (receipt[key] !== current[key]) throw Error('Stale prototype source: ' + key);
  if (receipt.dirty || current.dirty) throw Error('Commit prototype sources and rebuild before publishing.');
  if (sorted(receipt.files) !== sorted(current.files)) throw Error('Prototype input hash mismatch.');
  if (sorted(receipt.assets) !== sorted(await filesAt(output))) throw Error('Prototype output hash mismatch.');
  console.log(JSON.stringify({ verified: true, prototype: receipt.prototype, revision: receipt.revision, sourceFingerprint: receipt.sourceFingerprint }));
} else throw Error('Usage: receipt.mjs capture FILE | finalize OUTPUT BEFORE | verify OUTPUT');
