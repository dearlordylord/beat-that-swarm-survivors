// Moon Seal is fixed; compare three visual systems on all real menu screens.
// progression.mjs in this throwaway branch uses a memory-only sample save.
const names={A:'Lunar Stone',B:'Bone & Ink',C:'Crimson Velvet'};
let variant=new URL(location.href).searchParams.get('variant')?.toUpperCase()||'A';if(!names[variant])variant='A';
const menu=document.querySelector('#menu'),bar=document.querySelector('#theme-switcher'),preview=document.querySelector('#theme-preview');
// Three independent rows: scrolling menu, run action, comparison controls.
const scroll=document.createElement('div');scroll.id='menuScroll';
const wrap=menu.querySelector('.menu-wrap');wrap.before(scroll);scroll.append(wrap);
const dock=document.createElement('div');dock.id='menuDock';dock.className='expedition';
menu.append(dock,bar);
menu.dataset.controlStyle='C';document.body.dataset.moonTheme=variant;
const icon=path=>`<svg viewBox="0 0 16 16" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="${path}"/></svg>`;
const moon=icon('M11 1A7 7 0 1 0 15 12a6 6 0 0 1-4-11zm2 0h1v2h2v1h-2v2h-1V4h-2V3h2V1z');
const icons={expedition:icon('M11 1h4v4l-6 6 2 2-2 2-2-2-3 3-2-2 3-3-2-2 2-2 2 2 6-6V1z'),shop:icon('M5 1h6v1h2v2h1v8h-1v2h-2v1H5v-1H3v-2H2V4h1V2h2zm1 3v8h4v-2H8V8h2V6H8V4H6z'),collection:icon('M1 2h6l1 1 1-1h6v12H9l-1 1-1-1H1V2zm2 2v8h4V4H3zm6 0v8h4V4H9z'),achievements:icon('M4 1h8v2h3v5h-2v2h-2v2H9v2h3v2H4v-2h3v-2H5v-2H3V8H1V3h3V1zm-1 4v2h2V5H3zm9 0v2h1V5h-1z'),settings:icon('M6 0h4v3l2-1 3 3-1 2h2v4h-3l1 2-3 3-2-1v1H5v-3l-2 1-3-3 1-2H0V5h3L2 3l3-3 1 1V0zm0 5v5h4V5H6z')};
function decorate(){
 const expedition=menu.querySelector('#menuContent .expedition');
 const action=expedition?.querySelector('.a-bottom');
 if(action)dock.replaceChildren(action);
 if(!expedition&&dock.childElementCount)dock.replaceChildren();
 dock.hidden=!expedition;
for(const b of menu.querySelectorAll('.start-button')){if(b.dataset.moonReady)continue;b.dataset.moonReady='1';b.innerHTML=`<span class="cta-surface"><span class="cta-icon" aria-hidden="true">${moon}</span><span class="cta-label">Start Run</span><span class="cta-cap" aria-hidden="true"></span></span>`;b.setAttribute('aria-label','Start run');}for(const b of document.querySelectorAll('#tabs button')){if(!b.dataset.moonReady){b.dataset.moonReady='1';const label=b.textContent;b.innerHTML=`<span class="tab-surface"><span class="tab-icon" aria-hidden="true">${icons[b.dataset.tab]}</span><span class="tab-label">${label}</span><span class="tab-active-mark" aria-hidden="true"></span></span>`;}b.setAttribute('aria-pressed',String(b.classList.contains('active')));}renderBar();}
function renderBar(){const active=document.querySelector('#tabs .active')?.textContent||'Expedition';bar.innerHTML=`<div class="theme-note"><strong>Moon Seal · whole-menu studies</strong><small>Sample profile · memory only</small></div><div class="theme-choices"><button data-cycle="-1" aria-label="Previous menu theme">←</button>${Object.entries(names).map(([key,label])=>`<button data-theme="${key}" class="${key===variant?'selected':''}" aria-pressed="${key===variant}">${key}<span>${label}</span></button>`).join('')}<button data-cycle="1" aria-label="Next menu theme">→</button></div><output>${active}<small>${document.querySelector('#wallet')?.textContent||''}</small></output>`;}
function changeTheme(key){variant=key;document.body.dataset.moonTheme=key;const url=new URL(location.href);url.searchParams.set('variant',key);history.replaceState(null,'',url);renderBar();bar.querySelector(`[data-theme="${key}"]`)?.focus({preventScroll:true});}
bar.addEventListener('click',e=>{e.stopPropagation();const b=e.target.closest('button');if(!b)return;if(b.dataset.theme)changeTheme(b.dataset.theme);if(b.dataset.cycle){const keys=Object.keys(names);changeTheme(keys[(keys.indexOf(variant)+Number(b.dataset.cycle)+3)%3]);}});
// Start is a stub: keep this visual study from starting or saving a real run.
document.addEventListener('click',e=>{const b=e.target.closest('#menu .start-button');if(!b)return;e.preventDefault();e.stopImmediatePropagation();preview.innerHTML=`<button class="preview-close" aria-label="Close preview">×</button><small>MOON SEAL · ${names[variant]}</small><h2>Run preview</h2><p>${[...menu.querySelectorAll('.selected-choice')].map(n=>n.textContent.trim()).join(' · ')}</p><p>This prototype compares menus. Your real save is untouched.</p><button class="preview-close">Back to menu</button>`;preview.showModal();},true);
preview.addEventListener('click',e=>{if(e.target===preview||e.target.closest('.preview-close'))preview.close();});
document.addEventListener('keydown',e=>{if(menu.hidden||preview.open||e.target.closest('input,textarea,select,[contenteditable="true"]'))return;if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();e.stopImmediatePropagation();const keys=Object.keys(names);changeTheme(keys[(keys.indexOf(variant)+(e.key==='ArrowRight'?1:2))%3]);}},true);
new MutationObserver(records=>{if(records.some(record=>!bar.contains(record.target)))decorate();}).observe(menu,{childList:true,subtree:true});
await import('../browser.mjs');decorate();
const requestedScreen=new URL(location.href).searchParams.get('screen');
if(['expedition','shop','collection','achievements','settings'].includes(requestedScreen))document.querySelector(`#tabs [data-tab="${requestedScreen}"]`)?.click();
menu.addEventListener('click',e=>{const tab=e.target.closest('#tabs [data-tab]');if(!tab)return;const url=new URL(location.href);url.searchParams.set('screen',tab.dataset.tab);history.replaceState(null,'',url);});
