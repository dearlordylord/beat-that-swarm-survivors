import assert from 'node:assert/strict';
import test from 'node:test';
import {execFileSync} from 'node:child_process';
import {readFileSync,mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import Core from '../dist/core.mjs';
import {ProtocolSession} from '../core-adapter.mjs';
const here=path.dirname(fileURLToPath(import.meta.url));
const native=path.resolve(here,'../dist/protocol-native');
const encodeNative=text=>execFileSync(native,['encode',text],{encoding:'utf8'}).replace(/\n$/,'');
const decodeNative=wire=>execFileSync(native,['decode',wire],{encoding:'utf8'}).replace(/\n$/,'');

test('public codec preserves scalar Unicode, separators and all allowed lengths',()=>{
  const a=new ProtocolSession(),b=new ProtocolSession();
  const texts=['hello','Привет, мир','😀|雪|é','line one\nline two','|'.repeat(256),'😀'.repeat(256)];
  let seed=73;
  const alphabet=['a','b','|',' ','é','雪','Ж','😀','\n'];
  for(let i=0;i<200;i++){
    let text='';seed=(Math.imul(seed,1664525)+1013904223)>>>0;
    const length=1+seed%256;
    for(let j=0;j<length;j++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;text+=alphabet[seed%alphabet.length];}
    texts.push(text);
  }
  texts.forEach((text,index)=>{
    const sent=a.send(text);assert.equal(sent.accepted,true);assert.equal(sent.seq,index+1);
    assert.ok(new TextEncoder().encode(sent.wire).length<=4096);
    const received=b.receive(sent.wire);assert.equal(received.accepted,true);assert.equal(received.text,text);assert.equal(received.seq,sent.seq);
  });
  assert.equal(b.snapshot().received,texts.length);
});

test('bad sends preserve all counters and the unconsumed sequence',()=>{
  const a=new ProtocolSession();
  for(const text of ['', 'a'.repeat(257),'😀'.repeat(257)]){
    const before=a.snapshot(),sent=a.send(text);assert.equal(sent.accepted,false);assert.equal(sent.wire,'');assert.deepEqual(a.snapshot(),before);
  }
  assert.equal(a.send('valid').seq,1);
});

test('malformed, zero, noncanonical, oversized and stale packets never deliver',()=>{
  const b=new ProtocolSession();
  const malformed=['','BIP2|1|hi','BIP1|','BIP1||x','BIP1|0|x','BIP1|-1|x','BIP1|+1|x','BIP1|01|x','BIP1|1.0|x','BIP1|1e2|x','BIP1|4294967296|x','BIP1|99999999999999999999|x','BIP1|1|','BIP1|1|'+'x'.repeat(257),'x'.repeat(5000)];
  for(const wire of malformed){const before=b.snapshot();const result=b.receive(wire);assert.equal(result.accepted,false,wire.slice(0,50));assert.equal(b.snapshot().received,before.received);assert.equal(b.snapshot().lastRemoteSeq,before.lastRemoteSeq);}
  assert.equal(b.receive('BIP1|1|one').accepted,true);
  assert.equal(b.receive('BIP1|1|duplicate').accepted,false);
  assert.equal(b.receive('BIP1|3|three').accepted,true);
  assert.equal(b.receive('BIP1|2|older').accepted,false);
  assert.equal(b.snapshot().lastRemoteSeq,3);assert.equal(b.snapshot().received,2);
});

test('the compiler String ABI normalizes invalid host UTF16 to scalar replacement',()=>{
  for(const text of ['\ud800','\udfff']){
    const sent=new ProtocolSession().send(text);assert.equal(sent.accepted,true);assert.equal(sent.text,'\ufffd');
    const received=new ProtocolSession().receive(sent.wire);assert.equal(received.accepted,true);assert.equal(received.text,sent.text);
  }
});

test('sequence exhaustion cannot wrap into a new valid session',()=>{
  const s={$:'State',nextSeq:4294967295,lastRemoteSeq:0,sent:0,received:0,rejected:0};
  const last=Core.send(s,'last');assert.equal(last.accepted,true);assert.equal(last.seq,4294967295);assert.equal(last.state.nextSeq,0);
  const denied=Core.send(last.state,'again');assert.equal(denied.accepted,false);assert.deepEqual(denied.state,last.state);
  const receiver=new ProtocolSession();assert.equal(receiver.receive(last.wire).accepted,true);assert.equal(receiver.receive(last.wire).accepted,false);
  receiver.reset();assert.deepEqual(receiver.snapshot(),{nextSeq:1,lastRemoteSeq:0,sent:0,received:0,rejected:0});assert.equal(receiver.receive('BIP1|1|new epoch').accepted,true);
});

test('native Bend C and emitted JS agree on real protocol bytes and refusal reasons',()=>{
  const cases=['hello','Привет|雪','😀'.repeat(256),'line1\nline2','x'.repeat(257),''];
  for(const text of cases){const a=new ProtocolSession(),sent=a.send(text);const expected=sent.accepted?sent.wire:'REJECT|'+sent.reason;assert.equal(encodeNative(text),expected);}
  for(const wire of ['BIP1|1|hello','BIP1|2147483648|雪😀','BIP1|4294967295|end','BIP2|1|bad','BIP1|01|bad','BIP1|1|','BIP1|4294967296|bad']){
    const result=new ProtocolSession().receive(wire);assert.equal(decodeNative(wire),result.accepted?`ACCEPT|${result.seq}|${result.text}`:'REJECT|'+result.reason);
  }
});

test('transition laws hold on finite arbitrary states before their universal gate',()=>{
  for(const n of [0,1,7,4294967295])for(const last of [0,1,2,4294967295]){
    const s={$:'State',nextSeq:n,lastRemoteSeq:last,sent:7,received:11,rejected:13};
    assert.deepEqual(Core.send_state(Core.send_decided(false,s,'x')),s);
    const denied=Core.receive_state(Core.receive_decided(false,s,99,'x'));assert.equal(denied.lastRemoteSeq,last);assert.equal(denied.received,s.received);
    assert.equal(Core.receive_state(Core.receive_decided(true,s,99,'x')).lastRemoteSeq,99);
  }
});

test('actual transition mutants fail the corresponding preserved proofs',()=>{
  const bend=process.env.BEND||'bend';
  const source=readFileSync(path.join(here,'protocol.bend'),'utf8');
  const variants=[
    ['send refusal mutates state','Send{state,False{},"",0,"",','Send{rejected(state),False{},"",0,"",'],
    ['receive refusal drops frontier','Receive{rejected(state),False{},seq,"",','Receive{fresh(),False{},seq,"",'],
    ['receive success installs wrong frontier','State{next,seq,sent,(received + 1 : U32),denied}','State{next,0,sent,(received + 1 : U32),denied}'],
  ];
  for(const [label,from,to] of variants){
    assert.ok(source.includes(from),label);
    const dir=mkdtempSync(path.join(tmpdir(),'bend-iroh-protocol-mutant-'));
    try {
      writeFileSync(path.join(dir,'protocol.bend'),source.replace(from,to));
      for(const file of ['LAWS.bend','PROOF.bend'])writeFileSync(path.join(dir,file),readFileSync(path.join(here,file)));
      let output='';try{output=execFileSync('bash',['-c','ulimit -t 10; exec "$@"','protocol-mutant',bend,path.join(dir,'PROOF.bend'),'--verdict'],{encoding:'utf8',timeout:60000,stdio:['ignore','pipe','pipe']});assert.fail(label+' unexpectedly passed');}
      catch(error){output=(error.stdout||'')+(error.stderr||'');assert.equal(error.status,1,label+': '+output);assert.match(output,/SOME PROOFS FAIL/);assert.match(output,/expected|Error:/);assert.doesNotMatch(output,/infrastructure|not found|unknown option/i);}
    }finally{rmSync(dir,{recursive:true,force:true});}
  }
});
