import assert from 'node:assert/strict';
import G from './dist/game.mjs';
const M=name=>G['music:'+name];
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const out=[];for(;xs.$==='Con';xs=xs.tail)out.push(xs.head);return out;};
assert.equal(M('bpm')(),132);assert.equal(M('sample_rate')(),22050);
const body=(kind,x=7200,y=7200,variant=0)=>({$:'Body',kind,x,y,variant,hp:20,maxHp:20,age:1,seed:0,radius:12});
const danger=(hp,rows)=>G.music_danger(hp,100,7200,7200,list(rows));
assert.equal(danger(100,[]),0);
assert.ok(danger(20,[])>danger(90,[]),'Low HP increases perceived danger');
assert.ok(danger(100,[body(0,7250)])>danger(100,[body(0,7450)]),'Near enemy is more dangerous');
assert.ok(danger(100,[body(0,7250,7200,25)])>danger(100,[body(0,7250)]),'Nearby boss weighs more');
assert.ok(danger(100,[body(7,7250)])>danger(100,[body(7,7500)]),'Incoming close projectiles matter');
assert.equal(danger(100,[body(2),body(5),body(9),body(1)]),0,'Pickups and friendly weapons are not enemies');
assert.ok(danger(100,[body(0,7250,7200,30)])>=750,'Lethal Reaper proximity reaches the highest danger band');
assert.ok(danger(100,[body(7,7250,7200,30)])>=750,'Lethal incoming shots weigh more than ordinary projectiles');
assert.equal(danger(0,Array.from({length:500},()=>body(0))),1000);
let sampled=0;for(let i=0;i<8;i++)sampled=M('smooth')(sampled,1000);
assert.ok(sampled>=990);const decay=M('smooth')(sampled,0);assert.ok(decay<sampled&&decay>0);
assert.equal(M('target_band')(0,280),0);assert.equal(M('target_band')(1,280),1,'Threshold hysteresis prevents chattering');
let active=0,latest=0;
for(let step=1;step<16;step++) {
 latest=step%2?3:0;
 active=M('commit')(step,active,latest);
 assert.equal(active,0,'Pending transitions must not become an event queue');
}
latest=0;assert.equal(M('commit')(16,active,latest),0,'Superseded high danger does not play later');
assert.equal(M('commit')(16,active,3),3);
let total=0;
for(let stage=0;stage<5;stage++)for(let band=0;band<4;band++)for(let step=0;step<2048;step++) {
 const notes=array(M('notes')(step,stage,band));assert.ok(notes.length<=10);
 for(const n of notes) {
  assert.ok(n.voice>=0&&n.voice<=6);assert.ok(n.pitch>=0&&n.pitch<=127);
  assert.ok(n.length>=1&&n.length<=4);assert.ok(n.accent>0&&n.accent<=1000);
  const hz=M('frequency')(n.pitch);assert.ok(Number.isFinite(hz)&&hz>15&&hz<8000);
 }
 total+=notes.length;
}
const events=band=>Array.from({length:64},(_,i)=>array(M('notes')(i,0,band))).flat();
assert.ok(events(3).length>events(0).length*1.5,'High danger adds rhythmic and melodic layers');
assert.ok(events(3).filter(n=>n.voice===3).length>events(0).filter(n=>n.voice===3).length,'High danger intensifies kick pattern');
assert.ok(events(3).some(n=>n.voice===2),'High danger includes lead counter melody');
console.log(`PASS shared chip-metal music: danger, latest-target/hysteresis and ${total} note events across all stages/bands`);

// Ordinary sustained pressure needs seconds, while emergencies bypass the ramp.
let envelope=0, band=0;
for(let i=0;i<20;i++) { envelope=M('smooth')(envelope,800);band=M('target_band')(band,envelope); }
assert.equal(band,0,'Two seconds of ordinary pressure do not jump to heavy music');
for(let i=0;i<50;i++) { envelope=M('smooth')(envelope,800);band=M('target_band')(band,envelope); }
assert.equal(band,2,'Sustained danger eventually reaches the heavy arrangement');
assert.equal(M('target_band')(0,M('smooth')(0,950)),3,'Critical threat bypasses ordinary delay');
assert.equal(M('target_band')(0,danger(50,[])),0,'Half health alone does not force combat music');
assert.equal(M('target_band')(0,danger(100,Array.from({length:60},()=>body(0,7450)))),0,'A distant crowd alone does not force combat music');
const themes=new Set();
for(let seed=0;seed<128;seed++) for(let phrase=0;phrase<24;phrase++) {
 const step=phrase*512,theme=M('composition')(step,seed); themes.add(theme);
 assert.ok(theme>=0&&theme<4);
 assert.equal(M('composition')(step+511,seed),theme,'Theme stays fixed for the complete phrase');
 assert.notEqual(M('composition')(step+512,seed),theme,'Adjacent phrases never repeat a theme');
}
assert.equal(themes.size,4);
const signatures=[];
for(let theme=0;theme<4;theme++) {
 const signature=Array.from({length:128},(_,step)=>array(M('theme_notes')(step,0,2,theme)));
 signatures.push(JSON.stringify(signature));
 const low=Array.from({length:128},(_,step)=>array(M('theme_notes')(step,0,0,theme))).flat();
 const high=Array.from({length:128},(_,step)=>array(M('theme_notes')(step,0,3,theme))).flat();
 assert.ok(high.length>low.length*1.5,`Theme ${theme} retains its tension dimension`);
}
assert.equal(new Set(signatures).size,4,'Four distinct musical scores');
console.log('PASS four themes, seeded phrase changes, sustained ordinary pressure and emergency response');
