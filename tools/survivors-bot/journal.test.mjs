import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { once } from 'node:events';
import { parseJournal, readJournal, createJournalServer } from './journal.mjs';

test('completed corrupt lines are reported; incomplete append is ignored until newline', () => {
  const input = '{"type":"start"}\nnot json\n{"type":"decision"';
  assert.deepEqual(parseJournal(input), { records: [{type:'start'}], errors:[{line:2,message:'Invalid completed journal record'}], incompleteTail:true });
  assert.deepEqual(parseJournal('{"type":"decision"}\n').records, [{type:'decision'}]);
  assert.equal(parseJournal('[]\n').errors.length,1);
});

test('latest read and explicit receipt selection work without URL-controlled paths', async () => {
  const directory = await mkdtemp(join(tmpdir(),'nightfall-journal-'));
  try {
    assert.equal((await readJournal({directory})).waiting,true);
    await writeFile(join(directory,'run-one.jsonl'),'{"type":"start","mode":"heuristic"}\n');
    await writeFile(join(directory,'ignore.txt'),'private');
    const journal=await readJournal({directory});
    assert.equal(journal.file,'run-one.jsonl');
    assert.equal(journal.records[0].mode,'heuristic');
    assert.equal((await readJournal({receipt:join(directory,'run-one.jsonl')})).records.length,1);
  } finally { await rm(directory,{recursive:true,force:true}); }
});

test('HTTP is read-only, serves no arbitrary files, and returns safe missing-file error', async () => {
  const server=createJournalServer({receipt:join(tmpdir(),'absent-nightfall-journal-test.jsonl')});
  server.listen(0,'127.0.0.1');await once(server,'listening');
  const url=`http://127.0.0.1:${server.address().port}`;
  try {
    const page=await fetch(url+'/');assert.equal(page.status,200);
    assert.match(page.headers.get('content-security-policy'),/frame-ancestors 'none'/);
    const html=await page.text();assert.ok(html.includes('textContent'));assert.ok(!html.includes('innerHTML'));
    assert.equal((await fetch(url+'/api/journal?receipt=/etc/passwd')).status,404);
    assert.equal((await fetch(url+'/../../etc/passwd')).status,404);
    assert.equal((await fetch(url+'/api/journal',{method:'POST'})).status,405);
    const unavailable=await fetch(url+'/api/journal');assert.equal(unavailable.status,503);
    assert.deepEqual(await unavailable.json(),{error:'Journal unavailable or exceeds viewer limit'});
  } finally { server.closeAllConnections(); await new Promise(resolve=>server.close(resolve)); }
});
