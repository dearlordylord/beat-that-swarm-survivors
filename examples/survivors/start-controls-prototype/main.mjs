// Throwaway controls on the actual menu A route: ?variant=A, B or C.
// Fresh in-memory state only. No game startup or profile mutations.
import {renderExpedition} from '../expedition-menu.mjs';
import {CHARACTERS,STAGES,ARCANA,RUN_MODES} from '../content.mjs';
const names={A:'Iron Gate',B:'Cartridge Arcade',C:'Moon Seal'};
const sections={expedition:'Expedition',shop:'Legacy',collection:'Collection',achievements:'Achievements',settings:'Settings'};
let variant=new URL(location.href).searchParams.get('variant')?.toUpperCase()||'C';if(!names[variant])variant='C';
let section='expedition',openPanel=null,pendingUnlock=null,character=0,stage=0,arcana=0,mode=0;
const profile={gold:0,characters:[0],stages:[0],stats:{},settings:{}};
const menu=document.querySelector('#menu'),content=document.querySelector('#menuContent'),bar=document.querySelector('#control-switcher'),dialog=document.querySelector('#control-preview');
const svg=path=>`<svg viewBox="0 0 16 16" width="20" height="20" aria-hidden="true" fill="currentColor"><path d="${path}"/></svg>`;
const icons={
 sword:svg('M11 1h4v4l-6 6 2 2-2 2-2-2-3 3-2-2 3-3-2-2 2-2 2 2 6-6V1z'),
 coin:svg('M5 1h6v1h2v2h1v8h-1v2h-2v1H5v-1H3v-2H2V4h1V2h2zm1 3v8h4v-2H8V8h2V6H8V4H6z'),
 book:svg('M1 2h6l1 1 1-1h6v12H9l-1 1-1-1H1V2zm2 2v8h4V4H3zm6 0v8h4V4H9z'),
 trophy:svg('M4 1h8v2h3v5h-2v2h-2v2H9v2h3v2H4v-2h3v-2H5v-2H3V8H1V3h3V1zm-1 4v2h2V5H3zm9 0v2h1V5h-1z'),
 gear:svg('M6 0h4v3l2-1 3 3-1 2h2v4h-3l1 2-3 3-2-1v1H5v-3l-2 1-3-3 1-2H0V5h3L2 3l3-3 1 1V0zm0 5v5h4V5H6z'),
 play:svg('M3 1h2v1h2v2h2v2h2v1h2v2h-2v1H9v2H7v2H5v1H3V1z'),
 moon:svg('M11 1A7 7 0 1 0 15 12a6 6 0 0 1-4-11zm2 0h1v2h2v1h-2v2h-1V4h-2V3h2V1z')
};
const tabIcons={expedition:icons.sword,shop:icons.coin,collection:icons.book,achievements:icons.trophy,settings:icons.gear};
function decorate(){
 for(const b of content.querySelectorAll('.start-button')){b.innerHTML=`<span class="cta-surface"><span class="cta-icon" aria-hidden="true">${variant==='B'?icons.play:variant==='C'?icons.moon:icons.sword}</span><span class="cta-label">Start Run</span><span class="cta-cap" aria-hidden="true"></span></span>`;b.setAttribute('aria-label','Start run');}
 document.querySelector('#tabs').innerHTML=Object.entries(sections).map(([key,label])=>`<button data-tab="${key}" class="${section===key?'active':''}" aria-pressed="${section===key}"><span class="tab-surface"><span class="tab-icon" aria-hidden="true">${tabIcons[key]}</span><span class="tab-label">${label}</span><span class="tab-active-mark" aria-hidden="true"></span></span></button>`).join('');
}
function render(){menu.dataset.controlStyle=variant;document.querySelector('#wallet').textContent='◇ 0 · legacy gold';content.innerHTML=renderExpedition({profile,character,stage,arcana,mode,openPanel,pendingUnlock});decorate();bar.innerHTML=`<div class="comparison-label"><strong>Start & navigation</strong><span>Prototype · ${variant}: ${names[variant]}</span></div><div class="comparison-choices"><button data-cycle="-1" aria-label="Previous concept">←</button>${Object.entries(names).map(([key,label])=>`<button data-style="${key}" class="${variant===key?'current':''}" aria-pressed="${variant===key}" title="${label}">${key}<span>${label}</span></button>`).join('')}<button data-cycle="1" aria-label="Next concept">→</button></div><output>Tab: ${sections[section]} <span>· try hover / press / keyboard focus</span></output>`;}
function changeStyle(key){variant=key;const url=new URL(location.href);url.searchParams.set('variant',key);history.replaceState(null,'',url);render();bar.querySelector(`[data-style="${key}"]`)?.focus({preventScroll:true});}
function preview(){dialog.innerHTML=`<button class="close-preview" aria-label="Close preview">×</button><small>CONTROL PREVIEW</small><h2>Ready for the next run.</h2><p>${CHARACTERS[character].name} · ${STAGES[stage].name}<br>${ARCANA[arcana].name} · ${RUN_MODES[mode].name}</p><p class="preview-note">This prototype compares menu controls. No run or purchase is made.</p><button class="close-preview back-preview">Back to menu</button>`;dialog.showModal();}
document.addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;
 if(b.dataset.style){changeStyle(b.dataset.style);return;}
 if(b.dataset.cycle){const keys=Object.keys(names);changeStyle(keys[(keys.indexOf(variant)+Number(b.dataset.cycle)+3)%3]);return;}
 if(b.dataset.tab){section=b.dataset.tab;decorate();const output=bar.querySelector('output');output.innerHTML=`Tab: ${sections[section]} <span>· navigation appearance preview</span>`;return;}
 if(b.dataset.menuPanel){openPanel=openPanel===b.dataset.menuPanel?null:b.dataset.menuPanel;pendingUnlock=null;render();return;}
 if(b.id==='start'||b.id==='start-top'){preview();return;}
 if(b.classList.contains('close-preview')){dialog.close();return;}
 for(const kind of ['character','stage','mode'])if(b.dataset[kind]!==undefined){const id=Number(b.dataset[kind]);if(id===0){if(kind==='character')character=id;else if(kind==='stage')stage=id;else mode=id;openPanel=null;pendingUnlock=null;}else pendingUnlock={kind,id};render();return;}
 if(b.dataset.arcana!==undefined){arcana=Number(b.dataset.arcana);openPanel=null;pendingUnlock=null;render();}
});
document.addEventListener('keydown',e=>{if(dialog.open||e.target.closest('input,textarea,select,[contenteditable="true"]'))return;if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();const keys=Object.keys(names);changeStyle(keys[(keys.indexOf(variant)+(e.key==='ArrowRight'?1:2))%3]);}});
dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});
render();
