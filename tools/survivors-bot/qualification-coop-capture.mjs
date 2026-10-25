#!/usr/bin/env node
// Development-only baseline: retain complete actual Core state, including
// player-column values/stamps outside the pooled-actor range. No game rules.
import assert from 'node:assert/strict';
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

const [corePath, output] = process.argv.slice(2);
assert.ok(corePath && output, 'usage: qualification-coop-capture.mjs CORE.mjs OUTPUT.json');
const {default: Core} = await import(pathToFileURL(resolve(corePath)));
const rows = [];
const array = list => {
  const values=[];
  for (; list.$ === 'Con'; list=list.tail) values.push(list.head);
  assert.equal(list.$, 'Nil');
  return values;
};
function state(packet) {
  assert.equal(packet.$, 'CorePacket', JSON.stringify(packet.message));
  return packet.state;
}
function capture(label, current) {
  const loaded=Core.load_players(current.refs, {$:'Nil'}, current.world);
  current={...current, world:loaded.fst};
  // The generated tuple constructor uses fst/snd; capture those named facts
  // alongside the full state, preserving refs, allocator, clocks and stamps.
  const players=array(loaded.snd);
  assert.equal(players.length, 2);
  for (const player of players) assert.equal(player.$, 'PlayerRecord');
  const observed=Core.core_observe(current,0);
  current=state(observed);
  rows.push({label, tick:current.shared.tick, shared:current.shared,
    players, refs:array(current.refs), frame:JSON.parse(observed.frame),
    physical:JSON.parse(JSON.stringify(current))});
  return current;
}
let current=state(Core.core_start(0,0,100));
current=state(Core.core_join(current,1,0,0));
current=capture('joined',current);
for(let step=0;step<1200;step++) {
  if(current.shared.phase===1 || current.shared.phase===2) {
    for(const id of array(current.required)) current=state(Core.core_choose(current,id,current.round,0));
  } else if(current.shared.phase===0) {
    const dx=Math.floor(step/120)%2 ? -1 : 1;
    current=state(Core.core_step(current,dx,0,0,dx));
  } else break;
  if([119,599,1199].includes(step)) current=capture('step-'+(step+1),current);
}
current=capture('before-disconnect',current);
current=state(Core.core_disconnect(current,1));
current=capture('guest-disconnected',current);
assert.equal(rows.at(-1).players.find(p=>p.id===1).connected,false);
writeFileSync(output,JSON.stringify({scenario:'public-coop-seed100-1200',rows})+'\n');
console.log(JSON.stringify({status:'passed',checkpoints:rows.length,tick:current.shared.tick,
  playerIds:rows.at(-1).players.map(p=>p.id),actualPlayerColumn:true}));
