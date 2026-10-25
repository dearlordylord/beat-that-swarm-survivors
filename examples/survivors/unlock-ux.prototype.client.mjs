// Disposable UI scenarios only; no game engine, storage, or profile mutations.
import { CHARACTERS, WEAPONS, STAGES, ARCANA, RUN_MODES } from './content.mjs';
import { portrait, renderRunCard } from './prototype-menu.mjs';
import { startControl } from './menu-controls.mjs';
const names={A:'Inline accordion',B:'Side-by-side dossier',C:'Anchored card preview',D:'Two-column row accordion'};
let variant=new URLSearchParams(location.search).get('variant')||'A';
if(!names[variant])variant='A';
let equipped=0, viewed=1, gold=400, scenario='fresh', owned=new Set([0]),notice='';
const stats=()=>scenario==='fresh'?{kills:72}: {kills:3000,survive:120,evolutions:1,bosskills:2,wins:1,weapons:10};
const eligible=c=>!c.condition||(stats()[c.condition.stat]||0)>=c.condition.value;
const canBuy=c=>!owned.has(c.id)&&eligible(c)&&gold>=c.cost;
const row=c=>`<button class="choice proto-choice ${owned.has(c.id)?'':'is-locked'} ${equipped===c.id?'is-equipped':''} ${viewed===c.id?'is-viewed':''}" data-character="${c.id}" aria-expanded="${viewed===c.id}" ${viewed===c.id?'aria-controls="survivor-details"':''}>${portrait(c.id,'small')}<span class="choice-copy"><strong>${c.name}</strong><small>${WEAPONS[c.weapon].name}</small><span class="proto-badges"><span>${equipped===c.id?'✓ Equipped':owned.has(c.id)?'Available · Equip':'♙ Locked · '+c.cost+' gold'}</span>${viewed===c.id?'<b>Viewing details</b>':''}</span></span><span aria-hidden="true">${viewed===c.id?'−':'+'}</span></button>`;
function details(){
 if(viewed===null)return '';
 const c=CHARACTERS[viewed],met=eligible(c),isOwned=owned.has(c.id),current=c.condition?(stats()[c.condition.stat]||0):0;
 return `<section id="survivor-details" class="proto-details" aria-label="${c.name} details"><button class="proto-close" data-close aria-label="Close ${c.name} details">×</button><div class="proto-detail-head">${portrait(c.id,'small')}<div><span class="eyebrow">${isOwned?'Your survivor':'Locked survivor'}</span><h3>${c.name}</h3><small>${c.title}</small></div></div><p>${c.description}</p><p class="proto-weapon">Starting weapon <strong>${WEAPONS[c.weapon].name}</strong></p>${!isOwned?`<div class="proto-requirement"><strong>${met?'✓ Requirement met':'Unlock requirement'}</strong><p>${c.hint}</p><div class="proto-progress"><i style="width:${Math.min(100,current/c.condition.value*100)}%"></i></div><small>${Math.min(current,c.condition.value).toLocaleString()} / ${c.condition.value.toLocaleString()} ${c.condition.stat}</small></div><div class="proto-price"><span>Price <strong>${c.cost} gold</strong></span><span>Balance <strong>${gold} gold</strong></span></div><button class="proto-buy" data-buy="${c.id}" ${canBuy(c)?'':'disabled'}>Unlock ${c.name} · ${c.cost} gold</button><p class="proto-help">${!met?'Complete the requirement to unlock.':gold<c.cost?'Earn '+(c.cost-gold)+' more gold.':'Unlocks this survivor for future runs.'}</p>`:`<div class="proto-owned">✓ ${equipped===c.id?'Equipped for your next run':'Unlocked'}</div>`}<p class="proto-equipped-note">Next run: <strong>${CHARACTERS[equipped].name}</strong>${equipped!==c.id?' remains equipped.':'.'}</p></section>`;
}
function VariantA(){return `<div class="proto-accordion">${CHARACTERS.map(c=>`<div class="proto-entry">${row(c)}${viewed===c.id?details():''}</div>`).join('')}</div>`;}
function VariantB(){return `<div class="proto-split"><div class="proto-roster">${CHARACTERS.map(c=>`<div>${row(c)}<div class="proto-mobile-detail">${viewed===c.id?details().replaceAll('survivor-details','mobile-survivor-details'):''}</div></div>`).join('')}</div><aside class="proto-side">${details()||'<p class="proto-empty">Choose a locked survivor to view their unlock details.</p>'}</aside></div>`;}
function VariantC(){return `<div class="proto-grid">${CHARACTERS.map(c=>`<div class="proto-anchor ${viewed===c.id?'has-detail':''}">${row(c)}${viewed===c.id?details():''}</div>`).join('')}</div>`;}
// Keep both cards in their row, then insert one full-width detail panel.
function VariantD(){
 let rows='';
 for(let i=0;i<CHARACTERS.length;i+=2){
  const pair=CHARACTERS.slice(i,i+2);
  rows+=pair.map(row).join('');
  if(pair.some(c=>c.id===viewed))rows+=details().replace('class="proto-details"',`class="proto-details proto-row-details ${viewed===pair[1]?.id?'detail-right':''}"`);
 }
 return `<div class="proto-row-grid">${rows}</div>`;
}
function render(){
 document.querySelector('#wallet').textContent=`◈ ${gold} gold · Prototype balance`;
 document.querySelector('#menuContent').innerHTML=`<div class="expedition"><div class="a-heading"><div><p class="eyebrow">Your next run</p><h1>Ready to play</h1></div><button class="primary start-button" data-demo-start>${startControl}</button></div><div class="proto-run">${renderRunCard({character:equipped})}<span class="proto-run-tag">✓ Equipped for next run</span></div><div class="a-loadout-heading"><h2>Run setup</h2><span class="muted">Choose your next expedition</span></div><div class="selection-rows proto-selection"><div class="selection-row"><span>Survivor</span><strong class="selected-choice">${portrait(equipped,'small')}${CHARACTERS[equipped].name}</strong><span class="change-label">Choose survivor</span></div><div class="proto-picker variant-${variant}"><p class="proto-instruction">Choose an available survivor to equip. View a locked survivor to see how to unlock them.</p>${({A:VariantA,B:VariantB,C:VariantC,D:VariantD}[variant])()}</div>${[['Stage',STAGES[0].name],['Arcana',ARCANA[0].name],['Mode',RUN_MODES[0].name]].map(([k,v])=>`<div class="selection-row proto-static"><span>${k}</span><strong>${v}</strong><span class="change-label">Change +</span></div>`).join('')}</div><div class="proto-notice" role="status">${notice}</div></div>`;
 let debug=document.querySelector('#proto-debug');
 if(!debug){debug=document.createElement('div');debug.id='proto-debug';document.querySelector('#wallet').after(debug);}
 debug.innerHTML=`<label>Prototype scenario <select id="proto-scenario"><option value="fresh">Fresh · requirement unmet</option><option value="requirements">Requirements met · low gold</option><option value="afford">Can afford · ready to unlock</option></select></label><small>${variant} · Equipped: ${CHARACTERS[equipped].name} · Viewing: ${viewed===null?'none':CHARACTERS[viewed].name} · Gold: ${gold} · Eligible: ${viewed===null?'—':eligible(CHARACTERS[viewed])?'yes':'no'}</small>`;
 debug.querySelector('select').value=scenario;
 let switcher=document.querySelector('#proto-switcher');if(!switcher){switcher=document.createElement('nav');switcher.id='proto-switcher';document.body.append(switcher);}
 switcher.innerHTML=`<button data-cycle="-1" aria-label="Previous variant">←</button><span><small>LOCAL PROTOTYPE · ${variant==='D'?'REFINED A + C':'ALTERNATIVE'}</small><strong>${variant} · ${names[variant]}</strong></span><button data-cycle="1" aria-label="Next variant">→</button>`;
}
function cycle(delta){variant='ABCD'[('ABCD'.indexOf(variant)+delta+4)%4];const url=new URL(location);url.searchParams.set('variant',variant);history.replaceState({},'',url);render();}
document.addEventListener('click',e=>{
 const button=e.target.closest('button');if(!button)return;
 if(button.dataset.character!==undefined){const id=Number(button.dataset.character);if(owned.has(id))equipped=id;viewed=viewed===id?null:id;notice='';render();}
 else if(button.hasAttribute('data-close')){const id=viewed;viewed=null;render();document.querySelector(`[data-character="${id}"]`)?.focus({preventScroll:true});}
 else if(button.dataset.buy!==undefined){const c=CHARACTERS[Number(button.dataset.buy)];if(canBuy(c)){gold-=c.cost;owned.add(c.id);notice=`${c.name} unlocked. Select ${c.name} to equip for your next run.`;render();}}
 else if(button.dataset.cycle)cycle(Number(button.dataset.cycle));
 else if(button.hasAttribute('data-demo-start')){notice='Local menu prototype — no run started.';render();}
});
document.addEventListener('change',e=>{if(e.target.id==='proto-scenario'){scenario=e.target.value;gold=scenario==='fresh'?400:scenario==='requirements'?100:5000;owned=new Set([0]);equipped=0;viewed=1;notice='';render();}});
document.addEventListener('keydown',e=>{if(e.target.closest('input,textarea,select,[contenteditable]'))return;if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();cycle(e.key==='ArrowLeft'?-1:1);}if(e.key==='Escape'){const id=viewed;viewed=null;render();document.querySelector(`[data-character="${id}"]`)?.focus({preventScroll:true});}});
// Keep surrounding navigation visually real, but contained within this throwaway menu.
document.querySelector('#tabs').addEventListener('click',e=>{e.preventDefault();notice='Only survivor selection is interactive in this local prototype.';render();});
render();
