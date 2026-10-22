import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';

// CLI validation only: invalid seeds must fail before loading a Bend bundle,
// creating a session or starting a native process.
for (const entry of ['run.mjs', 'visible.mjs']) {
  test(`${entry} documents seeded runs and rejects invalid U32 seeds before launch`, () => {
    const path = new URL(entry, import.meta.url);
    const help = spawnSync(process.execPath, [path.pathname, '--help'], { encoding: 'utf8', timeout: 3000 });
    assert.equal(help.status, 0);
    assert.match(help.stdout, /--seed 12345/);
    for (const seed of ['-1', '4294967296', 'NaN', '1.5', '0x10', '']) {
      const result = spawnSync(process.execPath, [path.pathname, '--seed', seed], { encoding: 'utf8', timeout: 3000 });
      assert.equal(result.status, 1, `Invalid seed ${JSON.stringify(seed)} must be rejected`);
      assert.equal(result.stdout, '', 'Validation must precede receipt/session creation');
    }
  });
}
