// Actual mobile pointer events + actual Iroh game. Inspect sent Bend commands;
// do not substitute a transport or invent a simulated world.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const { chromium }=await import(process.env.PLAYWRIGHT_MODULE||'playwright');
const base=process.env.COOP_URL||'https://survivors.dearlordylord.com/coop.html';
const output=process.env.COOP_QA_DIR||'/tmp/survivors-touch';
await mkdir(output,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
const results=[],errors=[];
try{
 const host=await browser.newPage({viewport:{width:1280,height:800}});
 const mobile=await browser.newPage({viewport:{width:390,height:844},hasTouch:true,isMobile:true});
 for(const page of [host,mobile])page.on('pageerror',error=>errors.push(error.message));
 await mobile.route('**/coop-transport.mjs',async route=>{
  const response=await route.fetch();const source=await response.text();const marker='  send(payload) {';
  assert.ok(source.includes(marker),'actual transport instrumentation target');
  await route.fulfill({response,body:source.replace(marker,marker+`\n    if(typeof payload==='string'&&payload.includes('|T|')){const fields=payload.split('|');(globalThis.__touchCommands ||= []).push({x:Number(fields.at(-2))-1,y:Number(fields.at(-1))-1,at:performance.now()});}`)});
 });
 await host.goto(base);await host.locator('#coop-host').click();
 await host.waitForFunction(()=>document.querySelector('#coop-invite-link').value.includes('join='),null,{timeout:60000});
 const invitation=await host.locator('#coop-invite-link').inputValue();
 await mobile.goto(invitation);await mobile.locator('#coop-join').click();
 await mobile.locator('#coop-play').waitFor({state:'visible',timeout:60000});
 const pad=mobile.locator('#coop-touch');assert.equal(await pad.isVisible(),true);
 const rect=await pad.boundingBox(),cx=rect.x+rect.width/2,cy=rect.y+rect.height/2;
 const client=await mobile.context().newCDPSession(mobile);
 const cases=[
  {name:'right with thumb offset',dx:36,dy:4,x:1,y:0},
  {name:'down',dx:-3,dy:36,x:0,y:1},
  {name:'left',dx:-36,dy:-4,x:-1,y:0},
  {name:'up',dx:4,dy:-36,x:0,y:-1},
  {name:'down-right',dx:26,dy:26,x:1,y:1},
  {name:'down-left',dx:-26,dy:26,x:-1,y:1},
  {name:'up-left',dx:-26,dy:-26,x:-1,y:-1},
  {name:'up-right',dx:26,dy:-26,x:1,y:-1},
  {name:'neutral centre',dx:3,dy:-2,x:0,y:0},
 ];
 for(const item of cases){
  const count=await mobile.evaluate(()=>globalThis.__touchCommands?.length||0);
  await client.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:cx+item.dx,y:cy+item.dy,id:1}]});
  await mobile.waitForTimeout(130);
  const rows=await mobile.evaluate(count=>(globalThis.__touchCommands||[]).slice(count),count);
  await client.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  assert.ok(rows.length>=2,'multiple actual input ticks after '+item.name);
  const actual=rows.at(-1);results.push({name:item.name,expected:{x:item.x,y:item.y},actual,samples:rows.length});
  assert.deepEqual({x:actual.x,y:actual.y},{x:item.x,y:item.y},item.name);
  await mobile.waitForTimeout(80);
  const released=await mobile.evaluate(()=>globalThis.__touchCommands.at(-1));
  assert.deepEqual({x:released.x,y:released.y},{x:0,y:0},'release must stop movement');
 }
 assert.deepEqual(errors,[]);await writeFile(output+'/result.json',JSON.stringify({pass:true,results,errors},null,2));
 console.log('PASS mobile co-op: 4cardinals,4diagonals,neutral centre and release; actual touch events and sent Iroh commands');
}catch(error){await writeFile(output+'/failure.json',JSON.stringify({message:error.message,results,errors},null,2));throw error;}
finally{await browser.close();}
