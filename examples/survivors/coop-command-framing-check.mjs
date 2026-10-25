// Execute the actual browser command producers with only their IO boundaries stubbed.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const ClientDelivery = (await import(pathToFileURL(resolve(process.argv[2])))).default;
const source = await readFile(new URL('./coop-browser.mjs',import.meta.url),'utf8');
const functionSource = (name,next) => {
  const start = source.indexOf(`function ${name}(`);
  const end = source.indexOf(`function ${next}(`,start);
  assert.ok(start >= 0 && end > start, `actual browser ${name} producer exists`);
  return source.slice(start,end);
};
const commands = wire => {
  const decoded = ClientDelivery.decode(wire);
  assert.equal(decoded.$,'Some','actual producer emits a canonical composite');
  assert.equal(decoded.value.receipt.$,'None');
  const rows = [];
  for(let row = decoded.value.commands;row.$ === 'Con';row = row.tail) rows.push(row.head);
  return rows;
};
const command = role => new Function('ClientDelivery','role',`
  let sequence=0,sessionId=7,tick=19,prediction=null;
  const sentCommandTimes=new Map();
  ${functionSource('command','signalConnection')}
  return command;
`)(ClientDelivery,role);

const hostWrites=[];
const hostSend = new Function('command','postCommand',`
  const role='host',worker={},ui={};
  ${functionSource('sendAction','flushClientDelivery')}
  return sendAction;
`)(command('host'),(wire,peer) => { hostWrites.push({wire,peer});return true; });
assert.equal(hostSend({$:'Movement',x:2,y:1}),true);
assert.equal(hostSend({$:'Choice',round:3,index:1}),true);
assert.deepEqual(hostWrites.map(row => row.peer),[0,0]);
assert.deepEqual(hostWrites.map(row => commands(row.wire)[0]),[
  {$:'Command',session:7,player:0,seq:1,intendedTick:19,action:{$:'Movement',x:2,y:1}},
  {$:'Command',session:7,player:0,seq:2,intendedTick:19,action:{$:'Choice',round:3,index:1}},
]);

const guestWrites=[];
const setup = {character:2,arcana:3,meta:4,allowedWeapons:5};
const guestAction = new Function('command','transport','selectedSetup',`
  const epoch=1,connectionEpoch=2,connected=true,sendControl=async()=>{};
  const transportFailure=error=>{throw error;};
  ${functionSource('connectionAction','armConnectionDeadline')}
  return connectionAction;
`)(command('guest'),{send:async wire=>{guestWrites.push(wire);}},setup);
guestAction({$:'HelloAckAndSetup',version:1,token:42});
await new Promise(resolve => setImmediate(resolve));
assert.equal(guestWrites.length,1);
assert.deepEqual(commands(guestWrites[0]),[
  {$:'Command',session:7,player:1,seq:1,intendedTick:19,action:{$:'Setup',...setup}},
]);
console.log(JSON.stringify({status:'PASS',hostCommands:2,guestSetup:1,scope:'actual browser producers and emitted delivery codec; IO is stubbed'}));
