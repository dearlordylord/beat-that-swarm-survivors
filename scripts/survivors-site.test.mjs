import assert from 'node:assert/strict';
import test from 'node:test';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { chmod, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { prepareSite, verifySite } from './survivors-publication.mjs';
const exec = promisify(execFile);
const git = (repo, args) => exec('git', ['-C', repo, ...args]);
async function put(root, name, text, mode) {
  const file = path.join(root, name); await mkdir(path.dirname(file), { recursive: true }); await writeFile(file, text); if (mode) await chmod(file, mode);
}
async function fixture() {
  const root = await mkdtemp(path.join(os.tmpdir(), 'survivors-publication-test-'));
  const repo = path.join(root, 'repo'), origin = path.join(root, 'origin.git'), site = path.join(root, 'site');
  await mkdir(repo); await mkdir(site); await exec('git', ['init', '--bare', '--initial-branch=master', origin]); await git(repo, ['init', '-b', 'master']);
  await git(repo, ['config', 'user.name', 'Publication Fixture']); await git(repo, ['config', 'user.email', 'fixture@example.invalid']);
  await put(repo, '.gitignore', '**/node_modules/\n**/dist/\n');
  await put(repo, 'examples/survivors/game.bend', 'current-game');
  await put(repo, 'examples/survivors/content.mjs', 'stale generated data excluded');
  await put(repo, 'examples/survivors/build-web.sh', '#!/bin/bash\nset -euo pipefail\ncd "$(dirname "$0")"\nmkdir -p dist/web\ncp game.bend dist/web/index.html\ncp game.bend dist/web/game.mjs\n');
  await put(repo, 'examples/survivors/web/package.json', '{"name":"fixture","private":true,"version":"1.0.0","dependencies":{}}');
  await put(repo, 'examples/survivors/web/package-lock.json', '{"name":"fixture","version":"1.0.0","lockfileVersion":3,"requires":true,"packages":{"":{"name":"fixture","version":"1.0.0"}}}');
  await put(repo, 'bendhub-dependencies.json', '{"bendVersion":"2.0.38","packages":{}}');
  await put(repo, 'LICENSE-MIT', 'fixture license');
  await put(repo, 'examples/common.sh', '# fixture common'); await put(repo, 'examples/run-bounded.mjs', '// fixture bounded');
  await git(repo, ['add', '.']); await git(repo, ['commit', '-m', 'fixture']); await git(repo, ['remote', 'add', 'origin', origin]); await git(repo, ['push', '-u', 'origin', 'master']);
  await put(site, '.openai/hosting.json', '{"project_id":"fixture","static":{"directory":"dist"}}');
  await put(site, 'dist/index.html', 'previous-site'); await put(site, 'dist/old.mjs', 'old-asset');
  await put(site, 'SOURCE.json', '{"old":true}');
  const bend = path.join(root, 'bend'); await put(root, 'bend', '#!/bin/sh\n[ "$1" = version ] || exit 2\necho "bend 2.0.38"\n', 0o755);
  return { root, repo, site, bend, options: { repo, siteCheckout: site, quiet: true } };
}
async function usingFixture(fn) {
  const f = await fixture(), oldBend = process.env.BEND; process.env.BEND = f.bend;
  try { await fn(f); } finally { if (oldBend === undefined) delete process.env.BEND; else process.env.BEND = oldBend; await rm(f.root, { recursive: true, force: true }); }
}
test('fresh immutable build captures dirty and untracked inputs, complete hashes and version; generated catalog is not an input', async () => usingFixture(async f => {
  await put(f.repo, 'examples/survivors/game.bend', 'dirty-current-game'); await put(f.repo, 'examples/survivors/favicon.svg', '<svg/>');
  const output = await prepareSite(f.options); assert.equal(output.branch, 'master'); assert.equal(output.dirty, true);
  assert.equal(await readFile(path.join(f.site, 'dist/index.html'), 'utf8'), 'dirty-current-game');
  await assert.rejects(readFile(path.join(f.site, 'dist/old.mjs')), { code: 'ENOENT' });
  const source = JSON.parse(await readFile(path.join(f.site, 'SOURCE.json'), 'utf8'));
  assert.ok(source.sourceFiles['examples/survivors/favicon.svg']); assert.equal(source.sourceFiles['examples/survivors/content.mjs'], undefined);
  assert.equal(await readFile(path.join(f.site, 'source/survivors/examples/survivors/game.bend'), 'utf8'), 'dirty-current-game');
  assert.equal(await readFile(path.join(f.site, '.openai/hosting.json'), 'utf8'), '{"project_id":"fixture","static":{"directory":"dist"}}');
  assert.equal((await verifySite(f.options)).verified, true);
  await put(f.repo, 'examples/survivors/content.mjs', 'generated changes are not source changes');
  assert.equal((await verifySite(f.options)).verified, true);
}));
test('changed, deleted or newly authored source invalidates a previously prepared site', async () => usingFixture(async f => {
  await prepareSite(f.options);
  await put(f.repo, 'examples/survivors/game.bend', 'newer-game'); await assert.rejects(verifySite(f.options), /Sources changed/);
  await put(f.repo, 'examples/survivors/game.bend', 'current-game'); await rm(path.join(f.repo, 'examples/common.sh')); await assert.rejects(verifySite(f.options), /Sources changed/);
  await put(f.repo, 'examples/common.sh', '# fixture common'); await put(f.repo, 'examples/survivors/new-rule.bend', 'new'); await assert.rejects(verifySite(f.options), /Sources changed/);
}));
test('tampered, additional or missing asset and snapshot bytes are rejected', async () => usingFixture(async f => {
  await prepareSite(f.options);
  await put(f.site, 'dist/game.mjs', 'tampered'); await assert.rejects(verifySite(f.options), /assets differ/);
  await put(f.site, 'dist/game.mjs', 'current-game'); await put(f.site, 'dist/extra.mjs', 'extra'); await assert.rejects(verifySite(f.options), /assets differ/);
  await rm(path.join(f.site, 'dist/extra.mjs')); await rm(path.join(f.site, 'dist/game.mjs')); await assert.rejects(verifySite(f.options), /assets differ/);
  await put(f.site, 'dist/game.mjs', 'current-game'); await put(f.site, 'source/survivors/examples/survivors/game.bend', 'tampered'); await assert.rejects(verifySite(f.options), /snapshot differs/);
}));
test('non-master, unpublished and stale master revisions are refused', async () => usingFixture(async f => {
  await git(f.repo, ['checkout', '-b', 'feature']); await assert.rejects(prepareSite(f.options), /requires the master/);
  await git(f.repo, ['checkout', 'master']); await put(f.repo, 'examples/survivors/game.bend', 'unpublished'); await git(f.repo, ['add', '.']); await git(f.repo, ['commit', '-m', 'ahead']);
  await assert.rejects(prepareSite(f.options), /differs from origin\/master/);
  await git(f.repo, ['push', 'origin', 'master']); await prepareSite(f.options);
  await git(f.repo, ['reset', '--hard', 'HEAD~1']); await assert.rejects(verifySite(f.options), /differs from origin\/master/);
}));
test('failed build preserves every previous Site file and canonical source remains unchanged', async () => usingFixture(async f => {
  await put(f.repo, 'examples/survivors/build-web.sh', 'exit 17\n');
  await assert.rejects(prepareSite(f.options), /previous Site files were preserved/);
  assert.equal(await readFile(path.join(f.site, 'dist/index.html'), 'utf8'), 'previous-site');
  assert.equal(await readFile(path.join(f.site, 'SOURCE.json'), 'utf8'), '{"old":true}');
  assert.equal(await readFile(path.join(f.repo, 'examples/survivors/content.mjs'), 'utf8'), 'stale generated data excluded');
}));
test('source changes during build, symbolic links and overlapping destinations are refused', async () => usingFixture(async f => {
  await put(f.repo, 'examples/survivors/build-web.sh', `#!/bin/bash\nset -euo pipefail\ncd "$(dirname "$0")"\nmkdir -p dist/web\ncp game.bend dist/web/index.html\nprintf newer > '${path.join(f.repo, 'examples/survivors/game.bend')}'\n`);
  await assert.rejects(prepareSite(f.options), /Sources changed/);
  assert.equal(await readFile(path.join(f.site, 'dist/index.html'), 'utf8'), 'previous-site');
  await rm(path.join(f.repo, 'examples/survivors/game.bend')); await symlink(path.join(f.site, 'dist/index.html'), path.join(f.repo, 'examples/survivors/game.bend'));
  await assert.rejects(prepareSite(f.options), /Symbolic links/);
  await assert.rejects(prepareSite({ repo: f.repo, siteCheckout: f.repo, quiet: true }), /separate directories/);
}));
test('symbolic links in build output or the Site destination are refused', async () => usingFixture(async f => {
  await put(f.repo, 'examples/survivors/build-web.sh', `#!/bin/bash\nset -euo pipefail\ncd "$(dirname "$0")"\nmkdir -p dist/web\nln -s '${path.join(f.site, 'dist/index.html')}' dist/web/index.html\n`);
  await assert.rejects(prepareSite(f.options), /Symbolic link/);
  assert.equal(await readFile(path.join(f.site, 'dist/index.html'), 'utf8'), 'previous-site');
  const external = path.join(f.root, 'external'); await mkdir(external); await symlink(external, path.join(f.site, 'source'));
  await assert.rejects(prepareSite(f.options), /Symbolic link in Site destination/);
}));
test('guard binds the static publishing root and Site identity and serializes preparations', async () => usingFixture(async f => {
  await put(f.site, '.openai/hosting.json', '{"project_id":"fixture","static":{"directory":"other"}}');
  await assert.rejects(prepareSite(f.options), /static.directory set to dist/);
  await put(f.site, '.openai/hosting.json', '{"project_id":"fixture","static":{"directory":"dist"}}');
  await mkdir(path.join(f.site, '.survivors-publication.lock'));
  await assert.rejects(prepareSite(f.options), /Another publication/);
  await rm(path.join(f.site, '.survivors-publication.lock'), { recursive: true });
  await prepareSite(f.options);
  await put(f.site, '.openai/hosting.json', '{"project_id":"another-site","static":{"directory":"dist"}}');
  await assert.rejects(verifySite(f.options), /different Site project/);
}));
test('Iroh transport source is captured and invalidates a prepared co-op publication', async () => usingFixture(async f => {
  const source = 'prototypes/iroh-transport/transport/src/lib.rs';
  await put(f.repo, source, '// transport revision one');
  await prepareSite(f.options);
  const receipt = JSON.parse(await readFile(path.join(f.site, 'SOURCE.json'), 'utf8'));
  assert.ok(receipt.sourceFiles[source]);
  assert.equal(await readFile(path.join(f.site, 'source/survivors', source), 'utf8'), '// transport revision one');
  await put(f.repo, source, '// transport revision two');
  await assert.rejects(verifySite(f.options), /Sources changed/);
}));
