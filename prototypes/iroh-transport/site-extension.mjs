// Publish only the isolated lab route; preserve the previously published game byte-for-byte.
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFile, writeFile, readdir, mkdir, rm, copyFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('.', import.meta.url));
const output = path.join(root, 'dist/web'), route = 'labs/iroh/';
const [mode, siteArg] = process.argv.slice(2);
if (!['prepare', 'verify'].includes(mode) || !siteArg) throw Error('Usage: site-extension.mjs prepare|verify SITE_CHECKOUT');
const site = path.resolve(siteArg);
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const same = (a, b) => JSON.stringify(Object.entries(a).sort()) === JSON.stringify(Object.entries(b).sort());
const git = (cwd, args) => execFileSync('git', ['-C', cwd, ...args], { encoding: 'utf8' }).trim();
async function files(directory, prefix = '') {
  const result = {};
  for (const item of await readdir(directory, { withFileTypes: true })) {
    if (item.isSymbolicLink()) throw Error('Publication tree contains a symbolic link.');
    const name = prefix + item.name;
    if (item.isDirectory()) Object.assign(result, await files(path.join(directory, item.name), name + '/'));
    else result[name] = hash(await readFile(path.join(directory, item.name)));
  }
  return result;
}
async function copy(directory, destination, names) {
  for (const name of names) { const to = path.join(destination, name); await mkdir(path.dirname(to), { recursive: true }); await copyFile(path.join(directory, name), to); }
}
execFileSync(process.execPath, [path.join(root, 'receipt.mjs'), 'verify', output], { stdio: 'inherit' });
const build = JSON.parse(await readFile(path.join(output, 'build.json'), 'utf8'));
if (git(root, ['ls-remote', 'origin', 'refs/heads/' + build.branch]).split(/\s/)[0] !== build.revision) throw Error('Push the prototype branch before publishing.');
const hosting = JSON.parse(await readFile(path.join(site, '.openai/hosting.json'), 'utf8'));
if (hosting.static?.directory !== 'dist') throw Error('The lab requires this Site to serve dist.');
let manifest = JSON.parse(await readFile(path.join(site, 'SOURCE.json'), 'utf8'));
if (manifest.siteProjectId !== hosting.project_id) throw Error('Site identity differs from its existing release receipt.');
if (mode === 'prepare') {
  if (!same(await files(path.join(site, 'dist')), manifest.files)) throw Error('Existing Site assets were changed without a receipt.');
  const baseSiteCommit = git(site, ['rev-parse', 'HEAD']);
  const baseText = git(site, ['show', baseSiteCommit + ':SOURCE.json']);
  if (baseText !== (await readFile(path.join(site, 'SOURCE.json'), 'utf8')).trim()) throw Error('Open the published Site before preparing the extension.');
  const labFiles = await files(output);
  await rm(path.join(site, 'dist', route), { recursive: true, force: true });
  await copy(output, path.join(site, 'dist', route), Object.keys(labFiles));
  const source = path.join(site, 'source/iroh-transport');
  await rm(source, { recursive: true, force: true });
  await copy(root, source, Object.keys(build.files));
  manifest.files = Object.fromEntries(Object.entries(manifest.files).filter(([name]) => !name.startsWith(route)));
  Object.assign(manifest.files, Object.fromEntries(Object.entries(labFiles).map(([name, value]) => [route + name, value])));
  manifest.extensions ||= {};
  manifest.extensions.iroh = { route, sourceSnapshot: 'source/iroh-transport', baseSiteCommit, baseManifestSha256: hash(Buffer.from(baseText)), revision: build.revision, branch: build.branch, sourceFingerprint: build.sourceFingerprint, files: labFiles };
  await writeFile(path.join(site, 'SOURCE.json'), JSON.stringify(manifest, null, 2) + '\n');
}
const extension = manifest.extensions?.iroh;
if (!extension || extension.route !== route || !/^[0-9a-f]{40}$/.test(extension.baseSiteCommit)) throw Error('Missing prototype publication receipt.');
const baseText = git(site, ['show', extension.baseSiteCommit + ':SOURCE.json']);
if (hash(Buffer.from(baseText)) !== extension.baseManifestSha256) throw Error('Baseline manifest differs.');
const base = JSON.parse(baseText);
const production = list => Object.fromEntries(Object.entries(list).filter(([name]) => !name.startsWith(route)));
if (!same(production(base.files), production(manifest.files))) throw Error('The game asset receipt was changed by the prototype.');
for (const key of ['commit', 'branch', 'sourceFingerprint', 'sourceSnapshot', 'dirty']) if (manifest[key] !== base[key]) throw Error('The game provenance was changed: ' + key);
if (!same(await files(path.join(site, 'dist')), manifest.files)) throw Error('Site assets do not match their hashes.');
if (!same(await files(path.join(site, 'dist', route)), extension.files) || !same(extension.files, await files(output))) throw Error('Published lab differs from its build.');
if (!same(await files(path.join(site, extension.sourceSnapshot)), build.files)) throw Error('Prototype source snapshot differs from its receipt.');
if (extension.revision !== build.revision || extension.sourceFingerprint !== build.sourceFingerprint) throw Error('Prototype revision differs.');
console.log(JSON.stringify({ verified: true, route, prototypeRevision: build.revision, preservedGameRevision: manifest.commit, preservedGameAssets: Object.keys(production(manifest.files)).length }));
