// Trusted data fixtures only; every transition and decision executes Bend.
import test from 'node:test';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const directory=process.env.COOP_MECHANICS_TEST_DIST;
if(!directory)throw Error('Run bash examples/survivors/check-coop-mechanics.sh');
const load=async name=>(await import(pathToFileURL(`${directory}/${name}.mjs`))).default;
const [C,G]=await Promise.all(['coop-core','game'].map(load));
const values=c=>Array.isArray(c.values)?c.values:values(c.carrier??c.state??c.inner);
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const out=[];for(;xs.$==='Con';xs=xs.tail)out.push(xs.head);return out;};
function fixture(){let state;const accept=result=>{assert.equal(result.$,'CorePacket',result.message);state=result.state;return result.frame?JSON.parse(result.frame):null;};accept(C.core_start(0,0,91));accept(C.core_configure(state,0,0,0));accept(C.core_join(state,1,0,0));return {get state(){return state;},call(name,...args){return accept(C[name](state,...args));},reject(name,...args){const before=JSON.stringify(state),r=C[name](state,...args);assert.equal(r.$,'CoreRejected');state=r.state;assert.equal(JSON.stringify(state),before);},frame(id=0){return this.call('core_observe',id);}};}
function record(f,id){return values(f.state.world.store.players).find(row=>row?.value?.id===id).value;}
function player(f,id,{x,y,hp,passives,arcana,invuln}={}){const r=record(f,id).run;if(x!==undefined)r.px=x;if(y!==undefined)r.py=y;if(hp!==undefined)r.hp=hp;if(passives)r.passives=list(passives);if(arcana!==undefined)r.arcana=arcana;if(invuln!==undefined)r.invuln=invuln;return r;}
function body(f,{seed=100,x=7200,y=7200,kind=4,variant=0,hp=0,maxHp=0,age=0,radius=6}={}){const store=f.state.world.store,b={$:'Body',x,y,kind,variant,hp,maxHp,age,seed,radius};values(store.bodies)[seed].value=b;values(store.vitals)[seed].value={$:'Vitals',health:hp,maximum:maxHp};values(store.statuses)[seed].value={$:'Status',slow:0,burn:0};f.state.world=G.prepare_movement_roster(f.state.world);return b;}
test('physical healing belongs only to collector; old distant heal and gold never auto-credit',()=>{
 const f=fixture();player(f,0,{x:6800,y:7200,hp:30});player(f,1,{x:7200,y:7200,hp:30});body(f);body(f,{seed:101,x:8000,kind:4,age:10000});body(f,{seed:102,x:8000,kind:3,age:10000});f.call('core_step',0,0,0,0);assert.equal(record(f,0).run.hp,30);assert.equal(record(f,1).run.hp,55);assert.equal(f.frame().gold,0);assert.equal(values(f.state.world.store.bodies)[101].value.kind,4);assert.equal(values(f.state.world.store.bodies)[102].value.kind,3);
});
test('eligible high-Magnet collector is not blocked by nearer ineligible player',()=>{
 const f=fixture(),passives=Array(18).fill(0);passives[8]=4;player(f,0,{x:7170,y:7200,hp:30});player(f,1,{x:7160,y:7200,hp:30,passives});body(f);f.call('core_step',0,0,0,0);assert.equal(record(f,0).run.hp,30);assert.equal(record(f,1).run.hp,55);
});
test('chest pauses exactly for its collector and rejects another player or duplicate choice',()=>{
 const f=fixture();player(f,0,{x:6800,y:7200});player(f,1,{x:7200,y:7200});body(f,{kind:5});f.call('core_step',0,0,0,0);const frame=f.frame(1);assert.equal(frame.phase,2);assert.deepEqual(frame.requiredPlayers,[1]);assert.equal(f.frame(0).choicePending,false);f.reject('core_choose',0,frame.roundId,0);const tick=frame.tick;f.call('core_step',1,0,1,0);assert.equal(f.frame().tick,tick);f.call('core_choose',1,frame.roundId,2);assert.equal(f.frame().phase,0);assert.equal(f.frame().gold,50);f.reject('core_choose',1,frame.roundId,2);
});
test('level pause waits for both choices and confirmed guest departure releases its barrier',()=>{
 const f=fixture();f.state.shared.xp=f.state.shared.xpNeed;f.call('core_step',0,0,0,0);let frame=f.frame();assert.deepEqual(frame.requiredPlayers,[0,1]);f.call('core_choose',0,frame.roundId,0);assert.equal(f.frame().phase,1);assert.deepEqual(f.frame().requiredPlayers,[1]);f.call('core_disconnect',1);assert.equal(f.frame().phase,0);assert.equal(f.frame().players.find(p=>p.id===1).connected,false);f.call('core_step',0,0,0,0);assert.equal(f.frame().tick,frame.tick+1);
});
test('host character death is final while host authority continues the surviving guest',()=>{
 const f=fixture();player(f,0,{x:7000,y:7200,hp:1});player(f,1,{x:9000,y:7200});body(f,{x:7000,y:7200,kind:0,variant:30,hp:10000000,maxHp:10000000,age:20,radius:20});f.call('core_step',0,0,0,0);let frame=f.frame();assert.equal(record(f,0).run.hp,0);assert.equal(frame.phase,0);assert.equal(frame.px,9000,'dead host camera follows living teammate in Bend');const tick=frame.tick;f.call('core_step',1,0,0,1);frame=f.frame();assert.equal(frame.tick,tick+1);assert.equal(record(f,0).run.hp,0);assert.ok(record(f,1).run.py>7200);f.call('core_disconnect',0);assert.equal(f.frame().phase,5);
});
test('one pickup gold credit uses collector Greed once and shared ledger is observed equally',()=>{
 const f=fixture(),passives=Array(18).fill(0);passives[15]=4;player(f,0,{x:6800,y:7200});player(f,1,{x:7200,y:7200,passives});body(f,{kind:3});body(f,{seed:101,kind:3});f.call('core_step',0,0,0,0);assert.equal(f.frame(0).gold,6,'two2coin pickups aggregate4 before160% multiplier');assert.equal(f.frame(1).gold,6);
});
test('boss resets from all prior kinds reject a candidate inside the second camera',()=>{
 for(const kind of [0,2,3,4,5,8]){const f=fixture();player(f,0,{x:7200,y:7200});player(f,1,{x:12000,y:12000});f.state.shared.tick=7199;f.state.shared.seed=19544;const anchor=record(f,0).run;const candidate=G.enemy_new_seed(0,12345,7200,anchor.px,anchor.py,21,0,0);player(f,1,{x:candidate.x,y:candidate.y});body(f,{seed:0,x:7200,y:7200,kind,age:5,hp:kind===0?100:0,maxHp:100});f.call('core_step',0,0,0,0);const slot=values(f.state.world.store.bodies)[0].value;assert.notEqual(slot.age,0,`kind${kind} must not become newborn on camera`);}
});
test('ordinary spawns and boss births are outside both finalized moving cameras',()=>{
 const f=fixture();player(f,0,{x:7200,y:7200});player(f,1,{x:7750,y:7200});for(let i=0;i<18;i++){f.call('core_step',1,0,-1,1);const frame=f.frame(),players=frame.players.filter(p=>p.alive&&p.connected);for(const b of frame.bodies.filter(b=>b[2]===0&&b[6]===0))for(const p of players){assert.ok(Math.abs(b[0]-p.px)>512+3*b[8]+24||Math.abs(b[1]-p.py)>512+3*b[8]+24,'newborn outside every actual camera');}}
});
test('sole surviving guest can allocate the full shared physical projectile pool',()=>{
 const f=fixture(),run={...record(f,1).run,tick:1},snapshots=[];
 const shotSlots=values(f.state.world.store.roles).flatMap((row,index)=>row?.value?.$==='PlayerProjectileSlot'?[index]:[]);
 for(const seed of shotSlots)if(seed%2===1)snapshots.push({$:'Snapshot',body:{$:'Body',x:7200,y:7200,kind:1,variant:0,hp:2,maxHp:2,age:1,seed,radius:5},motion:{...G.empty_motion(),life:100,pierce:1,ownerBase:0,logicalSlot:65536}});
 const plan=G.team_plan(list([{$:'PlayerView',id:1,run,dx:0,dy:0}]),list(snapshots));assert.ok(plan.count>0,'guest must use freeeven slots when everyoddslot isoccupied');
 const leaves=index=>index.$==='Empty'?[]:index.$==='Item'?[index]:[...leaves(index.zero),...leaves(index.one)];for(const entry of leaves(plan.assignments)){assert.equal(entry.key%2,0);assert.equal(Math.floor(entry.value.slot/65536),1,'source stays guest');}
});

test('last living guest departure aborts after host character death instead of issuing a bankable defeat',()=>{
 const f=fixture();player(f,0,{hp:0});f.state.shared.gold=17;const tick=f.frame().tick;f.call('core_disconnect',1);assert.equal(f.frame().phase,5);assert.equal(f.frame().gold,17,'abort retains diagnostic ledger, not terminalphase3/4 receipt');assert.equal(f.call('core_step',1,0,1,0).advanced,false);assert.equal(f.frame().tick,tick);f.call('core_disconnect',0);assert.equal(f.frame().phase,5,'later transport teardown cannot turn abort into bankable defeat');
});
test('transport teardown preserves completed defeat and victory receipts',()=>{
 for(const phase of [3,4])for(const departing of [0,1]){const f=fixture();f.state.shared.phase=phase;f.state.shared.gold=31;f.call('core_disconnect',departing);assert.equal(f.frame().phase,phase);assert.equal(f.frame().gold,31);f.call('core_disconnect',1-departing);assert.equal(f.frame().phase,phase);}
});

test('co-op offers never advertise Revival while solo still offers the upgrade',()=>{
 const f=fixture(),host=record(f,0).run;let selected=null;
 for(let seed=1;seed<4096;seed++)if(array(G.phase_offers(false,seed+34,host.weapons,host.passives)).some(o=>o.kind===1&&o.id===13)){selected=seed;break;}
 assert.notEqual(selected,null,'fixture must demonstrate an actual solo Revival offer');f.state.shared.seed=selected;f.state.shared.xp=f.state.shared.xpNeed;f.call('core_step',0,0,0,0);for(const id of [0,1]){const frame=f.frame(id);assert.equal(frame.phase,1);assert.ok(frame.offers.every(o=>!(o.kind===1&&o.id===13)),'Revival cannot be selected in final-death co-op');}
});
test('large co-op observations compose JSON without recursion over frame characters',()=>{
 const f=fixture(),roles=values(f.state.world.store.roles),bodies=values(f.state.world.store.bodies);
 // Trusted presentation snapshot covering the issued shared pools; no step is
 // performed on this fixture. Production observation still executes only Bend.
 const rows=roles.flatMap((row,seed)=>{
  const kind={EnemySlot:0,RelicSlot:9,PlayerProjectileSlot:1,HostileProjectileSlot:7,XpSlot:2}[row?.value?.$];
  return kind===undefined?[]:[{...bodies[seed].value,x:7200+(seed%64),y:7200+(seed%31),kind,variant:0,hp:100,maxHp:100,age:120,radius:10}];
 });
 f.state.bodies=list(rows);const r=C.core_observe(f.state,1);assert.equal(r.$,'CorePacket');assert.ok(r.frame.length>50000,'fixture must exceed a browser character-recursion stack');const frame=JSON.parse(r.frame);assert.equal(frame.bodies.length,rows.length);assert.equal(frame.ownPlayerId,1);assert.equal(frame.players.length,2);assert.deepEqual(frame.requiredPlayers,[]);
});
