import { test } from 'node:test';
import assert from 'node:assert/strict';
import { CoopTransport, MAX_FRAME_BYTES } from './coop-transport.mjs';
async function fixture(send = async () => {}) {
  let emit; const events = [], writes = [];
  const channel = await CoopTransport.create(event => events.push(event), { transportFactory: async callback => {
    emit = callback;
    return { endpointId: () => 'local', invitation: () => 'ticket', join: async () => {}, close() {},
      send: async bytes => { writes.push([...bytes]); await send(bytes); } };
  }});
  emit({ type: 'connected', peerId: 'remote' });
  return { channel, emit, events, writes };
}
const deferred = () => { let resolve; const promise = new Promise(r => resolve = r); return { promise, resolve }; };
test('serialized sends preserve bytes at enqueue time and authenticated receive identity', async () => {
  const wait = deferred(); const { channel, emit, events, writes } = await fixture(() => wait.promise);
  const bytes = new Uint8Array([1]);
  const first = channel.send(bytes); bytes[0] = 9;
  const second = channel.send('B');
  await Promise.resolve(); assert.deepEqual(writes, [[1]]);
  emit({ type: 'message', peerId: 'intruder', bytes });
  emit({ type: 'message', peerId: 'remote', bytes: new Uint8Array([7]) });
  assert.equal(events.filter(e => e.type === 'message').length, 1);
  wait.resolve(); await Promise.all([first, second]);
  assert.deepEqual(writes, [[1], [66]]); assert.equal(channel.snapshot().pendingBytes, 0);
});
test('disconnect invalidates queued writes and their accounting cannot corrupt new epoch', async () => {
  const wait = deferred(); const { channel, emit, writes } = await fixture(() => wait.promise);
  const first = channel.send('old1').catch(e => e.message);
  const second = channel.send('old2').catch(e => e.message);
  await Promise.resolve(); emit({ type: 'disconnected' }); emit({ type: 'connected', peerId: 'new' });
  const third = channel.send('new'); wait.resolve();
  assert.match(await first, /changed/); assert.match(await second, /changed/); await third;
  assert.deepEqual(writes.map(b => new TextDecoder().decode(new Uint8Array(b))), ['old1', 'new']);
  assert.equal(channel.snapshot().pendingSends, 0);
});
test('frame and aggregate byte bounds reject before allocation/send; close is final', async () => {
  const wait = deferred(); const { channel, writes } = await fixture(() => wait.promise);
  await assert.rejects(channel.send(new Uint8Array(MAX_FRAME_BYTES + 1)), /1 MiB/);
  const sends = Array.from({ length: 4 }, () => channel.send(new Uint8Array(MAX_FRAME_BYTES)).catch(() => {}));
  await assert.rejects(channel.send(new Uint8Array([1])), /queue is full/);
  channel.close(); wait.resolve(); await Promise.all(sends);
  assert.equal(writes.length, 1); assert.equal(channel.snapshot().pendingBytes, 0);
  await assert.rejects(channel.send('after'), /No peer/);
});
test('a failed write does not poison subsequent writes in same connection', async () => {
  let n = 0; const { channel } = await fixture(async () => { if (++n === 1) throw Error('write failed'); });
  await assert.rejects(channel.send('one'), /write failed/);
  assert.equal((await channel.send('two')).byteLength, 3);
});
