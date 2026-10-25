// Diagnostics of the emitted Bend clock. The laws own the scheduling contract.
// Usage: bend coop-client-clock.bend -o /tmp/coop-client-clock.mjs
//        node coop-client-clock-check.mjs /tmp/coop-client-clock.mjs
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const {default:C}=await import(pathToFileURL(resolve(process.argv[2]??'examples/survivors/dist/coop-client-clock.mjs')));
let checks=0;
const check=(value,message)=>{assert.ok(value,message);checks++;};
const state=(lastAt,credit=0)=>({$:'State',lastAt,credit});
for(const [now,steps,remainder] of [[0,0,0],[16666,0,999960],[16667,1,20],[50000,3,0],[66666,3,999960],[66667,4,0],[1000000,4,0]]){
 const out=C.consume(C.fresh(0),now);
 check(out.steps===steps&&out.state.credit===remainder,`tick boundary ${now}`);
 check(out.state.lastAt===now,'retained timestamp');
}
for(const start of [0,4300000000000,Number.MAX_SAFE_INTEGER-2000]){
 const out=C.consume(state(start,999999),start+1000);
 check(out.steps===1&&out.state.credit===59999,'exact elapsed at large safe timestamp');
 const duplicate=C.consume(out.state,start+1000);
 check(duplicate.steps===0&&duplicate.state.credit===59999,'duplicate callback spends no elapsed twice');
 const old=C.consume(duplicate.state,start);
 check(old.steps===0&&old.state.lastAt===start+1000&&old.state.credit===59999,'old render timestamp cannot rewind');
}
const suspend=C.consume(C.fresh(0),Number.MAX_SAFE_INTEGER);
check(suspend.steps===4&&suspend.state.credit===0,'safe integer lifetime suspension caps before multiplication');
check(suspend.state.lastAt===Number.MAX_SAFE_INTEGER,'safe integer timestamp stays exact');
const malformed=C.consume(state(0,Number.MAX_SAFE_INTEGER),66667);
check(malformed.steps===4&&malformed.state.credit===999999,'prior debt is restricted to a fraction');
const blocked=C.discard(C.consume(C.fresh(0),10000).state);
check(blocked.credit===0&&blocked.lastAt===10000,'network block discards residue and keeps timestamp');
check(C.consume(blocked,10000).steps===0,'network retry does not replay consumed time');
for(const interval of [1000,10000,20000]){
 let s=C.fresh(0),steps=0;
 for(let now=interval;now<=1000000;now+=interval){const out=C.consume(s,now);s=out.state;steps+=out.steps;}
 check(steps===60&&s.credit===0,`sixty ticks in a continuously observed second at ${interval}us`);
}
let s=C.fresh(0),peak=0,scheduled=0;
for(let i=1;i<=20000;i++){
 const now=i%7===0?Math.max(0,peak-10000):peak+((i*7919)%5000);
 const out=C.consume(s,now);peak=Math.max(peak,now);scheduled+=out.steps;s=out.state;
 check(s.lastAt===peak,'one monotonic timestamp across interleaved callbacks');
 check(out.steps>=0&&out.steps<=4&&Number.isInteger(out.steps),'bounded whole-step budget');
 check(s.credit>=0&&s.credit<1000000&&Number.isInteger(s.credit),'reachable fractional-credit invariant');
 check(scheduled===Math.floor(peak*60/1000000),'interleaving preserves elapsed-time accounting');
}
console.log(JSON.stringify({status:'PASS',checks,interleavedCallbacks:20000,scope:'emitted Bend client clock diagnostics'}));
