// Five throwaway menu concepts on the existing game route. No saved profile writes.
import {renderA,renderB} from './variants-ab.mjs';
import {renderC,renderD} from './variants-cd.mjs';
import {renderE} from './variant-e.mjs';
import {chosen,summary,esc,available,catalog} from './common.mjs';
const names={A:'Ready to play',B:'Build bench',C:'Guided setup',D:'Expedition board',E:'Run recipes'};
const renders={A:renderA,B:renderB,C:renderC,D:renderD,E:renderE};
let variant=new URL(location.href).searchParams.get('variant')?.toUpperCase()||'A';if(!renders[variant])variant='A';
const s={character:0,stage:0,arcana:9,mode:0,firstRun:true,panel:null,category:'character',wizard:false,step:0,recipe:'steady',lockedCategory:null,edit:false,owned:{character:[0],stage:[0],mode:[0]},gold:0,previewEligible:false,profileMode:'first'};
const app=document.querySelector('#app'),bar=document.querySelector('#prototype-bar'),dialog=document.querySelector('#preview');let beforeDialog=null;
function render(focus=null){document.body.className="menu-prototype";document.body.dataset.variant=variant;app.innerHTML=renders[variant](s);const c=chosen(s);bar.innerHTML=`<div class="prototype-run"><span><strong>${esc(c.character.name)}</strong><span class="prototype-summary"> · ${esc(c.stage.name)} · ${esc(c.arcana.name)}</span></span><button class="primary" data-action="start" data-placement="bottom">Start run <span aria-hidden="true">↗</span></button></div><div class="prototype-compare"><div class="prototype-caption"><strong>Menu concepts</strong><small>Prototype · no saved changes</small></div><div class="variant-switcher"><button data-cycle="-1" aria-label="Previous menu concept">←</button>${Object.keys(names).map(v=>`<button data-variant="${v}" aria-label="${v}: ${names[v]}" aria-pressed="${v===variant}" class="${v===variant?'selected':''}">${v}</button>`).join('')}<button data-cycle="1" aria-label="Next menu concept">→</button></div><label class="profile-switch"><span>Preview profile</span><select id="profile-mode"><option value="first" ${s.profileMode==='first'?'selected':''}>First run</option><option value="purchase" ${s.profileMode==='purchase'?'selected':''}>Purchase preview · 1000 gold</option><option value="returning" ${!s.firstRun?'selected':''}>Returning · all unlocked</option></select></label></div><output class="prototype-state">${variant} · ${names[variant]} · ${esc(c.mode.name)} · ${s.panel?`Editing ${s.panel}`:s.wizard?`Setup step ${s.step+1}/4`:'Ready'} <button data-action="state">View state</button></output>`;if(focus)document.querySelector(focus)?.focus({preventScroll:true});}
function switchVariant(v){variant=v;const url=new URL(location.href);url.searchParams.set('variant',v);history.replaceState(null,'',url);render(`[data-variant="${v}"]`);window.scrollTo(0,0);}
function modal(title,body){beforeDialog=document.activeElement;dialog.innerHTML=`<button class="dialog-close" data-action="close" aria-label="Close preview">×</button><span class="eyebrow">MENU PROTOTYPE</span><h2>${title}</h2>${body}<div class="dialog-actions"><button class="quiet" data-action="close">Back to menu</button></div>`;dialog.showModal();dialog.querySelector('[data-action="close"]').focus();}
dialog.addEventListener('close',()=>beforeDialog?.focus({preventScroll:true}));
dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});
document.addEventListener('click',e=>{const b=e.target.closest('button');if(!b||b.disabled)return;
 if(b.dataset.variant){switchVariant(b.dataset.variant);return;}
 if(b.dataset.cycle){const keys=Object.keys(names);switchVariant(keys[(keys.indexOf(variant)+Number(b.dataset.cycle)+5)%5]);return;}
 if(b.dataset.pick){const cat=b.dataset.pick,id=Number(b.dataset.id);if(!available(s,cat,id))return;s[cat]=id;s.recipe='custom';s.panel=null;render(`[data-pick="${cat}"][data-id="${id}"]`);return;}
 if(b.dataset.categoryTab){s.category=b.dataset.categoryTab;s.lockedCategory=null;render(`[data-category-tab="${s.category}"]`);return;}
 if(b.dataset.wizardStep!==undefined){s.step=Number(b.dataset.wizardStep);s.wizard=true;render(`[data-wizard-step="${s.step}"]`);return;}
 if(b.dataset.recipe){s.recipe=b.dataset.recipe;s.character=0;s.stage=0;s.mode=0;s.arcana={steady:9,fast:1,loot:6}[s.recipe];render(`[data-recipe="${s.recipe}"]`);return;}
 if(b.dataset.inspect){const kind=b.dataset.inspect,item=catalog[kind][Number(b.dataset.id)];const eligible=!item.condition||s.previewEligible;const purchasable=kind==='character'||kind==='stage';modal(esc(item.name),`<p>${esc(item.description)}</p><div class="purchase-facts"><strong>${item.cost?`${item.cost} gold`:'Progress unlock'}</strong><span>Balance: ${s.gold} gold</span></div><p class="muted">${eligible?'Requirement met':esc(item.hint||'Unlock through progression.')}</p>${purchasable?`<button class="primary" data-proto-buy="${kind}" data-id="${item.id}" ${!eligible||s.gold<item.cost?'disabled':''}>Buy · ${item.cost} gold</button>`:''}<p class="prototype-notice">Purchase preview only. Changes stay in this page.</p>`);return;}
 if(b.dataset.protoBuy){const kind=b.dataset.protoBuy,id=Number(b.dataset.id),item=catalog[kind][id];if(available(s,kind,id)||(!s.previewEligible&&item.condition)||s.gold<item.cost)return;s.gold-=item.cost;s.owned[kind].push(id);s[kind]=id;s.recipe='custom';s.panel=null;dialog.close();render();return;}
 if(b.dataset.utility){const title=b.dataset.utility==='progress'?'Progress':b.textContent.trim();modal(esc(title),`<p class="muted">${s.firstRun?'Fresh profile · 0 gold':'Returning profile preview · all choices available'}</p><p>This concept focuses on starting a run. Secondary screens keep their existing purpose.</p><p class="prototype-notice">No purchases or progress changes in this prototype.</p>`);return;}
 switch(b.dataset.action){
 case 'start':modal('Run preview',`${summary(s)}<p class="prototype-notice">This is a menu preview; it does not start a real run or write your save.</p><a class="primary game-link" href="https://nightfall-survivors-bendvy.leafyyew32.chatgpt.site" target="_blank" rel="noopener noreferrer">Open current game ↗</a>`);break;
 case 'panel':s.panel=s.panel===b.dataset.category?null:b.dataset.category;s.lockedCategory=null;render(`[data-action="panel"][data-category="${b.dataset.category}"]`);break;
 case 'unlocks':s.lockedCategory=s.lockedCategory===b.dataset.category?null:b.dataset.category;render(`[data-action="unlocks"][data-category="${b.dataset.category}"]`);break;
 case 'customize':s.wizard=!s.wizard;render('[data-action="customize"]');break;
 case 'next':if(s.step===3)s.wizard=false;else s.step++;render();break;
 case 'back':s.step=Math.max(0,s.step-1);render();break;
 case 'edit':s.edit=!s.edit;render('[data-action="edit"]');break;
 case 'close':dialog.close();break;
 case 'state':modal('Preview state',`<pre>${esc(JSON.stringify({variant,...s},null,2))}</pre>`);break;
 }
});
document.addEventListener('change',e=>{if(e.target.id==='profile-mode'){s.profileMode=e.target.value;s.firstRun=e.target.value!=='returning';s.previewEligible=e.target.value==='purchase';s.gold=s.previewEligible?1000:0;s.owned={character:[0],stage:[0],mode:[0]};s.character=0;s.stage=0;s.mode=0;s.panel=null;s.lockedCategory=null;render('#profile-mode');}});
document.addEventListener('keydown',e=>{if(dialog.open||e.target.closest('input,textarea,select,[contenteditable="true"]'))return;if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();const keys=Object.keys(names);switchVariant(keys[(keys.indexOf(variant)+(e.key==='ArrowRight'?1:4))%5]);}});
render();
