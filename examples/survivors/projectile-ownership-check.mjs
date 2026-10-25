#!/usr/bin/env node
// Exercise the actual scheduling/allocation/query path for both player sources.
import assert from 'node:assert/strict';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const {default:C}=await import(pathToFileURL(resolve(process.argv[2])));
const array=value=>{const rows=[];for(;value.$==='Con';value=value.tail)rows.push(value.head);assert.equal(value.$,'Nil');return rows};
let packet=C.core_join(C.core_start(0,0,100).state,1,0,0);
const seen=new Set();
for(let step=0;step<120;step++) {
  const state=packet.state;
  if(state.shared.phase===1||state.shared.phase===2) {
    for(const id of array(state.required))packet=C.core_choose(packet.state,id,packet.state.round,0);
  } else packet=C.core_step(state,1,0,0,1);
  assert.equal(packet.$,'CorePacket');
  for(const snapshot of array(packet.state.snapshots)) {
    if(snapshot.$!=='ProjectileSnapshot'||!snapshot.projectile.payload.active)continue;
    const shot=snapshot.projectile,trajectory=shot.trajectory;
    assert.ok(trajectory.logicalSlot<8,'spread slot is local, never a packed player identity');
    if(shot.side.$==='HostileShot')assert.deepEqual(trajectory.sourcePlayer,{$:'None'});
    else {
      assert.equal(trajectory.sourcePlayer.$,'Some');
      assert.ok([0,1].includes(trajectory.sourcePlayer.value));
      seen.add(trajectory.sourcePlayer.value);
      assert.equal(shot.identity%2,trajectory.sourcePlayer.value,'allocation keeps the established per-player parity');
      assert.equal(trajectory.weaponOwner,trajectory.sourcePlayer.value,'fixture starters preserve their distinct weapon ownership');
    }
  }
}
assert.deepEqual([...seen].sort(),[0,1]);
console.log('PASS actual projectile player identity, weapon ownership and local emission slots');
