import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const {default:R}=await import(pathToFileURL(resolve(process.argv[2]??'examples/survivors/dist/offline-risk-grid.mjs')));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const body=(seed,x,y,kind=0,hp=100,radius=12)=>({$:'Body',seed,x,y,kind,variant:0,hp,maxHp:hp,age:0,radius});
const bodies=[body(1,241,241),body(2,270,270,7,1,8),body(3,30,30,0,0),body(4,3590,3590,0,100,30),body(5,1800,1800,2,40),body(6,31,35,0,1,18)];
const reference=(index)=>{
 const x=(index%60+.5)*60,y=(Math.floor(index/60)+.5)*60;let risk=0,blocked=false;
 for(const b of bodies){if(!((b.kind===0&&b.hp>0)||b.kind===7))continue;const r=b.radius+(b.kind===7?12:18),reach=r+120,d=Math.hypot(x-b.x,y-b.y);blocked||=d<r+21;risk+=Math.max(0,1-d/reach)*(b.kind===7?8:4);}
 return {risk,blocked};
};
let grid=R.build(list(bodies));
const frozen=R.snapshot(list(bodies));
for(let i=0;i<3600;i++){
 const result=R.sample(grid,i);grid=result.fst;const actual=result.snd,expected=reference(i);
 assert.deepEqual(R.lookup(frozen,i),actual,`frozen cell ${i}`);
 assert.equal(actual.blocked===true,expected.blocked,`blocked cell ${i}`);
 assert.ok(Math.abs(actual.risk-expected.risk)<0.00001,`risk cell ${i}: ${actual.risk} vs ${expected.risk}`);
}
console.log('Native risk grid: all 3600 cells match hostile/contact geometry, dead enemy exclusion, projectile risk, overlapping accumulation, world edges and resource exclusion');
