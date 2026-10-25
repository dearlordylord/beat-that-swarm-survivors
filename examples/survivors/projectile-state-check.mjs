#!/usr/bin/env node
import assert from 'node:assert/strict';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const {default:S}=await import(pathToFileURL(resolve(process.argv[2])));
const nil={$:'Nil'};
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const space=(age=0)=>({$:'Spatial',x:100,y:100,age,radius:5});
const trajectory=(life=10,pierce=2)=>({$:'Trajectory',vx:10,vy:0,life,pierce,visited:nil,ownerBase:7,logicalSlot:65538});
const state=(age=0,life=10,pierce=2)=>({$:'State',spatial:space(age),identity:650,side:{$:'PlayerShot'},payload:{$:'ShotPayload',weapon:1,damage:17,active:true},trajectory:trajectory(life,pierce)});
const input={$:'StepInput',px:100,py:100,tx:200,ty:100,reflect:false};
let cases=0;
for(const identity of [0,512,1023,1055,4294967295]) {
  const born=S.created(identity,{$:'PlayerShot'},1,17,7,65538,{$:'Shot',x:100,y:100,vx:10,vy:0,radius:5,life:10,pierce:2});
  assert.equal(born.identity,identity);assert.equal(born.spatial.age,0);
  assert.deepEqual(born.trajectory.visited,nil);assert.equal(born.trajectory.ownerBase,7);
  assert.equal(born.trajectory.logicalSlot,65538);assert.equal(born.payload.damage,17);cases++;
}
for(const age of [0,1,100,4294967295]) {
  const moved=S.step(state(age),input,nil).projectile;
  assert.equal(moved.spatial.age,(age+1)>>>0);assert.equal(moved.identity,650);
  assert.equal(moved.payload.damage,17);assert.equal(moved.trajectory.ownerBase,7);
  assert.equal(moved.trajectory.logicalSlot,65538);assert.equal(moved.trajectory.life,9);cases++;
}
const pierced=S.step(state(),input,list([40])).projectile;
assert.equal(pierced.trajectory.pierce,1);assert.deepEqual(pierced.trajectory.visited,list([40]));cases++;
const spent=S.step(state(0,10,1),input,list([40])).projectile;
assert.equal(spent.payload.active,false);assert.equal(spent.identity,650);
assert.deepEqual(spent.trajectory.visited,nil);assert.equal(spent.trajectory.life,0);cases++;
const expired=S.step(state(0,1,2),input,nil).projectile;
assert.equal(expired.payload.active,false);assert.equal(expired.identity,650);cases++;
const reborn=S.created(expired.identity,{$:'PlayerShot'},3,29,2,131073,{$:'Shot',x:9,y:8,vx:0,vy:0,radius:5,life:20,pierce:9999});
assert.equal(reborn.payload.damage,29);assert.equal(reborn.spatial.age,0);
assert.deepEqual(reborn.trajectory.visited,nil);assert.equal(reborn.trajectory.ownerBase,2);cases++;
const boundary=S.hostile_step(state(),116,100);
assert.equal(boundary.contactDamage,0);assert.equal(S.hostile_step(state(),115,100).contactDamage,1);cases++;
console.log(`PASS explicit projectile lifecycle: ${cases} birth, ownership, pierce, expiry, reuse and hostile-contact cases`);
