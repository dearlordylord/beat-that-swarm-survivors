// Each negative control must still typecheck, then fail the actual kernel proof.
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdtemp,mkdir,rm} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {dirname,join} from 'node:path';
import {tmpdir} from 'node:os';
import {fileURLToPath} from 'node:url';
const app=dirname(fileURLToPath(import.meta.url));
const files=['arena.bend','player-movement.bend','coop-session.bend','coop-prediction.bend','coop-prediction-LAWS.bend','coop-prediction-PROOF.bend','coop-prediction-counter-PROOF.bend','spawn-policy.bend','viewport.bend','prediction-spawn.bend','prediction-spawn-LAWS.bend','prediction-spawn-PROOF.bend'];
const sources=Object.fromEntries(await Promise.all(files.map(async name=>[name,await readFile(join(app,name),'utf8')])));
const mutants=[
 ['admit duplicate observation','coop-prediction.bend','case State{_,_,_,_,_,_,prior}: U32.is_gt(observation,prior)','case State{_,_,_,_,_,_,prior}: U32.is_ge(observation,prior)','L.reconciliation_exact'],
 ['wait for authority instead of local step','coop-prediction.bend','tick_allowed(Bool.and(enabled,U32.is_lt(age,horizon())),state)','tick_allowed(False{},state)','L.tick_exact'],
 ['stale neutral direction replaces actual input','coop-prediction.bend','Segment{seq,x,y,0,0} <> List.take','Segment{seq,1,1,0,0} <> List.take','command_selected_same'],
 ['drop all pending history','coop-prediction.bend','case row <> rest: acknowledged_row(seq,consumed,expired,row,acknowledge(rest,seq,consumed,expired))','case row <> rest: []','L.acknowledgment_exact'],
 ['older cumulative receipt undoes consumption','coop-prediction.bend','+consumed = U32.max(prior,reported)','+consumed = reported','ack_row_same'],
 ['expired held input survives','coop-prediction.bend','Bool.pick(Bool,expired,U32.is_gt(id,seq),U32.is_ge(id,seq))','U32.is_ge(id,seq)','ack_row_same'],
 ['replay pending segments in reverse order','coop-prediction.bend','replay(List.reverse(&2,Segment,segments),distance,Replay{M.Point{x,y},horizon()})','replay(segments,distance,Replay{M.Point{x,y},horizon()})','history_same'],
 ['ignore prediction replay budget','coop-prediction.bend','U32.min(budget,remaining(steps,consumed))','remaining(steps,consumed)','replay_segment_same'],
 ['never advance the prediction age','coop-prediction.bend','State{x,y,distance,enabled,segments,(age + 1 : U32),observation}','State{x,y,distance,enabled,segments,age,observation}','tick_selected_same'],
 ['allow prediction during pause or death','coop-prediction.bend','Bool.and(connected,Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)))','True{}','L.prediction_gate_exact'],
 ['consume the wrong movement sequence','coop-session.bend','U32.is_eq(prior,seq),U32.min((steps + 1 : U32),65535),1','True{},U32.min((steps + 1 : U32),65535),1','receipt_lane_same'],
 ['prediction doubles shared movement speed','player-movement.bend','x + dx * distance / length','x + dx * distance * 2.0 / length','L.shared_movement_exact'],
 ['remove camera prediction padding','prediction-spawn.bend','(radius + U32.to_f32(M.horizon()) * F32.abs(distance) / 3.0 + 1.0 : F32)','radius','L.padding_exact'],
 ['guard without placement padding','prediction-spawn.bend','S.admissible(x,y,px,py,padded_radius(radius,distance))','S.admissible(x,y,px,py,radius)','L.admission_exact'],
 ['place enemies without admission padding','prediction-spawn.bend','S.choose(seed,tick,px,py,padded_radius(radius,distance))','S.choose(seed,tick,px,py,radius)','L.placement_exact'],
];
const folder=await mkdtemp(join(tmpdir(),'bendvy-prediction-mutants-'));
const run=(args)=>spawnSync('bash',['-c','ulimit -t 10; exec "$@"','prediction-mutant',process.env.BEND||'bend',...args],{encoding:'utf8',timeout:60000});
try{
 for(const [i,[name,module,before,after,proof]]of mutants.entries()){
  assert.ok(sources[module].includes(before),`Mutation target disappeared: ${name}`);
  const directory=join(folder,String(i));await mkdir(directory);
  for(const file of files)await writeFile(join(directory,file),file===module?sources[file].replace(before,after):sources[file]);
  const typed=run([join(directory,module)]);
  assert.equal(typed.status,0,`${name}: mutation must typecheck\n${typed.stdout}\n${typed.stderr}`);
  const proofFile=module==='prediction-spawn.bend'?'prediction-spawn-PROOF.bend':'coop-prediction-PROOF.bend';
  const checked=run([join(directory,proofFile),'--verdict']);
  assert.equal(checked.status,1,`${name}: expected proof rejection, not survival/timeout\n${checked.stdout}\n${checked.stderr}`);
  const output=checked.stdout+checked.stderr;
  assert.match(output,/SOME PROOFS FAIL/);assert.ok(output.includes(`Location: ${proof}`),`${name}: rejected in unexpected proof location\n${output}`);
  assert.doesNotMatch(output,/TODO|not a valid proof yet|no such file|consumed more than once/);
  console.log(`KILLED ${name} (${proof})`);
 }
}finally{await rm(folder,{recursive:true,force:true});}
