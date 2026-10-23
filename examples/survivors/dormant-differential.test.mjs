import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const [bp,cp]=process.argv.slice(2);
const [{default:B},{default:C}]=await Promise.all([import(pathToFileURL(bp)),import(pathToFileURL(cp))]);
const ns=m=>m.dormant?'':'game.';
const list=a=>a.reduceRight((tail,head)=>({$: 'Con',head,tail}),{$:'Nil'});
const plain=x=>x&&typeof x==='object'?Object.fromEntries(Object.entries(x).map(([k,v])=>[k,k==='$'?v.split('.').at(-1):plain(v)])):x;
const run=(m,tick,mode,arcana,rank,stage,character)=>({$:ns(m)+'Run',phase:0,tick,px:1800,py:1800,hp:100,maxHp:100,xp:0,xpNeed:100,level:1,kills:0,gold:0,character,weapons:list(Array(24).fill(0)),passives:list(Array(18).fill(rank)),invuln:0,seed:12345,stage,arcana,meta:0,revivals:0,bosses:0,mode,rerolls:0,banishes:0,skips:0,bannedWeapons:0,bannedPassives:0,enemyKinds:list([]),relicCollected:0});
const ticks=[0,1,5,6,59,60,1799,1800,7199,7200,14399,14400,35999,36000,4294967291,4294967295];
let checks=0;const hash=createHash('sha256');
for(const tick of ticks)for(const mode of [0,1,2,3])for(const [arcana,rank,stage,character] of [[0,0,0,0],[5,5,2,6],[4,2,1,7]])for(let seed=0;seed<512;seed++){
 const body=m=>({$:ns(m)+'Body',x:1700.25,y:1820.5,kind:8,variant:seed%31,hp:0,maxHp:100,age:seed===511?4294967295:seed,seed,radius:0});
 const expected=plain(B[ns(B)+'dormant'](body(B),run(B,tick,mode,arcana,rank,stage,character)));
 const actual=plain(C[ns(C)+'dormant'](body(C),run(C,tick,mode,arcana,rank,stage,character)));
 assert.deepEqual(actual,expected,JSON.stringify({tick,mode,arcana,rank,stage,character,seed}));hash.update(JSON.stringify(actual));checks++;
}
console.log(JSON.stringify({checks,sha256:hash.digest('hex')}));
