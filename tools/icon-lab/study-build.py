#!/usr/bin/env python3
"""Present sourced character proposals and reviewed Bend-authored icon catalogs."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

def esc(value):
    return html.escape(str(value), quote=True)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path('/workspace/survivors-ability-study'))
    parser.add_argument('--personal', type=Path, default=Path('/workspace/survivors-icon-lab/iteration-03'))
    parser.add_argument('--relics', type=Path, default=Path('/workspace/survivors-relic-icons/iteration-02'))
    parser.add_argument('--weapons', type=Path, default=Path('/workspace/survivors-weapon-icons/iteration-02'))
    args = parser.parse_args()
    out = args.output.resolve()
    assert not out.is_relative_to(ROOT), 'Generated previews belong outside tracked source'
    out.mkdir(parents=True, exist_ok=True)
    data = json.loads((HERE/'study-matrix.json').read_text())
    current = json.loads(subprocess.run(['node', '--input-type=module', '-e', 'import {CHARACTERS,WEAPONS,PASSIVES,ARCANA} from "./examples/survivors/content.mts"; process.stdout.write(JSON.stringify({characters:CHARACTERS,weapons:WEAPONS,passives:PASSIVES,arcana:ARCANA}));'], cwd=ROOT, check=True, capture_output=True, text=True).stdout)
    # The study preserves its research baseline after approved production changes.
    for kind in ['weapons','passives','arcana']:
        assert [item['id'] for item in data['catalog'][kind]] == [item['id'] for item in current[kind]], f'{kind}: stable IDs changed'
    assets = out/'assets'
    for directory in ['personal','relics','weapons']:
        (assets/directory).mkdir(parents=True, exist_ok=True)
    for path in args.personal.glob('*.svg'):
        if path.name != 'authored-sheet.svg':
            shutil.copy2(path, assets/'personal'/path.name)
    for item in data['catalog']['passives']:
        shutil.copy2(args.relics/f'passive-{item["id"]}.svg', assets/'relics'/f'passive-{item["id"]}.svg')
    for item in data['catalog']['weapons']:
        shutil.copy2(args.weapons/f'weapon-{item["id"]}.svg', assets/'weapons'/f'weapon-{item["id"]}.svg')
    research = out/'research'
    research.mkdir(exist_ok=True)
    for path in (ROOT/'docs/design/character-studies').glob('*.md'):
        shutil.copy2(path, research/path.name)
    source = out/'source'
    source.mkdir(exist_ok=True)
    for path in HERE.iterdir():
        if path.suffix in ['.bend','.py','.json','.md']:
            shutil.copy2(path, source/path.name)
    (out/'matrix.json').write_text(json.dumps(data,indent=2)+'\n')
    def icon(path, label, classes='icon'):
        return f'<img class="{classes}" src="assets/{path}" alt="{esc(label)}">'
    def personal(row, kind):
        key = row[f'{kind}Icon']
        return f'<img class="icon personal" data-key="{key}" src="assets/personal/{key}-a.svg" alt="{esc(row["trinket"] if kind=="trinket" else row["attack"])}">'
    table = []
    details = []
    for row in data['characters']:
        partner = data['catalog']['passives'][row['currentPassiveId']]
        desired = data['catalog']['passives'][row['desiredPassive']]
        name = f'<strong class="hero-name" data-original="{esc(row["nickname"])}" data-familiar="{esc(row["handle"])}">{esc(row["nickname"])}</strong><small>{esc(row["reference"])} reference · {esc(row["handle"])}</small>'
        recipe = icon(f'relics/passive-{partner["id"]}.svg',partner['proposedName'])+f'<strong>{esc(partner["proposedName"])}</strong><small>Current passive/{partner["id"]}. {esc(partner["description"])}</small>'
        table.append(f'<tr><td>{name}<small>Alternate: {esc(" / ".join(row["alternatives"]))}</small></td><td>{personal(row,"trinket")}<strong>{esc(row["trinket"])}</strong><small>Personal motif, not an inventory item.</small></td><td>{personal(row,"attack")}<strong>{esc(row["attack"])}</strong><small>weapon/{row["weaponId"]}. {esc(row["tooltip"])}</small></td><td><strong>{esc(row["innate"])}</strong><small>{esc(row["innateTooltip"])}</small></td><td>{recipe}</td><td><a href="#proposal-{row["key"]}">{esc(row["mechanic"])}</a><small>Approved for implementation.</small></td></tr>')
        change = f'Optional recipe change: passive/{row["currentPassiveId"]} → passive/{row["desiredPassive"]}, {desired["proposedName"]}. This changes balance and unlock requirements.' if row['recipeChanges'] else 'Keep the current evolution partner.'
        details.append(f'<article id="proposal-{row["key"]}" class="proposal"><span class="tag">Prototype priority {row["priority"]}</span><h3>{esc(row["reference"])} · {esc(row["mechanic"])}</h3><p>{esc(row["feel"])}</p><p>{esc(row["proposal"])}</p><p class="muted">Required Bend state. {esc(row["state"])}</p><p>{esc(change)}</p><p><a href="{esc(row["source"])}">Primary creative reference</a> · <a href="{esc(row["nicknameSource"])}">Nickname usage evidence</a> · <a href="research/{esc(row["study"])}">Full research</a></p></article>')
    catalogs = []
    for kind, folder, prefix in [('weapons','weapons','weapon'),('passives','relics','passive')]:
        cards=[]
        for item in data['catalog'][kind]:
            image=icon(f'{folder}/{prefix}-{item["id"]}.svg',item['proposedName'])
            recipe=''
            if kind=='weapons':
                partner=data['catalog']['passives'][item['passive']]
                recipe=f'<small>Research evolution partner: {esc(partner["proposedName"])} · passive/{partner["id"]}</small>'
            cards.append(f'<article class="catalog-card"><div class="card-top"><span class="old-glyph" aria-label="Current glyph">{esc(item["icon"])}</span><span class="slot">{image}<b class="rank">5</b></span>{image}<span class="tag">{prefix}/{item["id"]}</span></div><h3>{esc(item["proposedName"])}</h3><small>Research name: {esc(item["name"])}</small><p>{esc(item.get("proposedDescription",item["description"]))}</p>{recipe}</article>')
        catalogs.append(f'<section id="{kind}" class="catalog-panel"{" hidden" if kind=="passives" else ""}><div class="catalog-grid">{"".join(cards)}</div></section>')
    hud_parts = []
    for item in data['catalog']['weapons'][:6]:
        image = icon('weapons/weapon-%s.svg' % item['id'], item['proposedName'])
        hud_parts.append(f'<span class="slot" title="{esc(item["proposedName"])}">{image}<b class="rank">8</b></span>')
    for item in data['catalog']['passives'][:6]:
        image = icon('relics/passive-%s.svg' % item['id'], item['proposedName'])
        hud_parts.append(f'<span class="slot" title="{esc(item["proposedName"])}">{image}<b class="rank">5</b></span>')
    hud = ''.join(hud_parts)
    css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#101c24;color:#eee5d1;font:16px/1.5 system-ui;--icon-size:24px}main{max-width:1440px;margin:auto;padding:30px 24px}a{color:#b8d9f0}h1{font-size:32px;margin:0}h2{margin-top:44px}h3{font-size:18px;margin:8px 0}.muted,small{color:#b4c4ca}small{display:block;font-size:12px;line-height:1.5;margin:4px 0}.intro{max-width:1000px}.notice{padding:14px 18px;background:#24333d;border-left:3px solid #cdbb88}.controls{display:flex;flex-wrap:wrap;gap:10px;align-items:center;padding:14px 0}.controls label{margin-right:20px}button,select{font:inherit;color:inherit;background:#263e49;border:1px solid #6b8390;border-radius:5px;padding:8px 12px;cursor:pointer}button[aria-pressed=true]{border-color:#f0d990;color:#f0d990}.tag{display:inline-block;font-size:11px;color:#d4c7a4;background:#23333a;padding:3px 7px;border-radius:3px}.table-wrap{overflow-x:auto}table{border-collapse:collapse;width:100%;min-width:1120px}th,td{padding:14px;text-align:left;vertical-align:top;border-bottom:1px solid #3a4d57}th{font-size:12px;color:#b8c8cf;background:#1a2c35}td{max-width:240px}td strong{display:block;font-size:14px}img.icon{width:var(--icon-size);height:var(--icon-size);object-fit:contain;vertical-align:middle;margin:2px 8px 7px 0}.slot{position:relative;display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;background:#151e29;border:1px solid #656270;flex:none}.slot img.icon{width:20px!important;height:20px!important;margin:0}.rank{position:absolute;right:1px;bottom:0;font:10px monospace;color:#fff;background:#151e29db;line-height:11px}.hud{display:flex;flex-wrap:wrap;gap:7px;padding:20px;background:#0c131b;border:1px solid #394954;width:max-content;max-width:100%}.catalog-grid,.proposal-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:18px}.catalog-card,.proposal{background:#182a32;border:1px solid #354b55;padding:18px;border-radius:7px;scroll-margin-top:18px}.catalog-card p{font-size:14px;min-height:46px}.card-top{display:flex;gap:15px;align-items:center;min-height:42px}.old-glyph{display:flex;align-items:center;justify-content:center;width:34px;height:34px;border:1px dashed #66727a;font-size:21px;color:#aeb4b9}.proposal-grid{margin-top:20px}.proposal{font-size:14px}.proposal p{margin:10px 0}.research-links{display:flex;gap:20px;flex-wrap:wrap}details{margin:20px 0}summary{cursor:pointer;color:#d9c994}.not-drawn{color:#aebac1;font-size:13px}.preview-compare img{max-width:100%;height:auto}.status{font-size:13px;color:#d5caa6}@media(max-width:650px){main{padding:20px 12px}h1{font-size:25px}.catalog-grid,.proposal-grid{grid-template-columns:1fr}.controls label{margin-right:0}}'''
    script='''document.getElementById('size').onchange=e=>document.body.style.setProperty('--icon-size',e.target.value+'px');document.getElementById('names').onchange=e=>document.querySelectorAll('.hero-name').forEach(x=>x.textContent=x.dataset[e.target.value]);document.querySelectorAll('[data-style]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-style]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));document.querySelectorAll('img.personal').forEach(x=>x.src='assets/personal/'+x.dataset.key+'-'+b.dataset.style+'.svg')});document.querySelectorAll('[data-catalog]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-catalog]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));document.querySelectorAll('.catalog-panel').forEach(x=>x.hidden=x.id!==b.dataset.catalog)});'''
    text=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Character names, icons and ability study</title><style>{css}</style><main><span class="tag">Local mod design study · 2026-10-26</span><h1>Character names, relics and attacks</h1><p class="intro">A sourced naming matrix, 24 base attack icons, 18 shared relic icons, and seven personal object motifs. All vectors are authored in Bend. This gallery preserves the research baseline. The live mod now uses the approved selection as implementation progresses.</p><p class="notice">These are working names. No candidate has trademark clearance. Familiar fan handles have documented usage; original epithets have untested fan recognition. Personal objects below are innate motifs, not seven new inventory items.</p><p><a href="http://192.168.155.16:8812/">Play the current mod</a> · <a href="matrix.json">Machine-readable matrix</a> · <a href="CHARACTER_ABILITY_MATRIX.md">Full design notes</a></p><div class="controls"><label>Names <select id="names"><option value="original">Original game epithets</option><option value="familiar">Familiar fan handles, status unknown</option></select></label><label>Icon size <select id="size"><option>16</option><option>20</option><option selected>24</option><option>32</option></select> px</label><button data-style="a" aria-pressed="true">A · Filled</button><button data-style="b" aria-pressed="false">B · Etched, comparison only</button></div><p class="status">Independent visual recommendation: filled A. Labelled 20/24px readability reviewed. 16px is a fallback with reduced object detail. A recognisable object is not proof of fan recognition.</p><div class="table-wrap"><table><thead><tr><th>Name candidate / familiar reference</th><th>Personal object motif</th><th>Research attack, selected wording</th><th>Innate</th><th>Research evolution relic</th><th>Approved mechanic</th></tr></thead><tbody>{''.join(table)}</tbody></table></div><h2>Icons in a real-size loadout</h2><p>34×34 slots, 20px icons, rank overlay. Vector source remains scalable; increasing the table size does not change this HUD test.</p><div class="hud">{hud}</div><h2>Existing shared item catalog</h2><p>The old glyph appears beside the proposed icon. The old glyphs and recipes below describe the research baseline. The live mod can use the approved recipe changes. Shared relics are available across characters.</p><div class="controls"><button data-catalog="weapons" aria-pressed="true">24 base attacks</button><button data-catalog="passives" aria-pressed="false">18 shared relics</button></div>{''.join(catalogs)}<h2>Seven approved abilities</h2><p>All seven mechanics are approved for implementation. The numerical limits below are starting balance hypotheses, not playtest results.</p><div class="proposal-grid">{''.join(sorted(details,key=lambda s:int(s.split('Prototype priority ')[1][0])))}</div><h2>Evidence and next scope</h2><div class="research-links"><a href="research/rm-jin.md">RM and Jin</a><a href="research/suga-jhope.md">SUGA and j-hope</a><a href="research/jimin-v-jungkook.md">Jimin, V and Jung Kook</a></div><p>For example, JOONIE is also used by an <a href="https://www.joonie.kr/">active unrelated brand</a>. That is a collision observation, not a legal decision about a game. <a href="https://www.uspto.gov/trademarks/search/comprehensive-clearance-search-similar-trademarks">USPTO search guidance</a> and <a href="https://www.wipo.int/en/web/global-brand-database/index">WIPO database scope</a> explain the limits of a web-only screen.</p><p class="not-drawn">Twelve arcana have draft wording in matrix.json but no new icon set in this study. Permanent upgrades, unions, stage relics and distinct evolution artwork remain later scope. This gallery is a historical design comparison. See the local game for the installed selection.</p></main><script>{script}</script></html>'''
    (out/'index.html').write_text(text)
    report={'scope':'Prototype presentation only','personalIteration':args.personal.name,'relicIteration':args.relics.name,'weaponIteration':args.weapons.name,'stableCatalogIdsValidated':True,'catalogContext':'Preserved research baseline; approved production wording and recipes can differ','assets':{str(p.relative_to(out)):hashlib.sha256(p.read_bytes()).hexdigest() for p in assets.rglob('*.svg')}}
    (out/'build.json').write_text(json.dumps(report,indent=2)+'\n')
    doc=ROOT/'docs/design/CHARACTER_ABILITY_MATRIX.md'
    if doc.exists():shutil.copy2(doc,out/doc.name)
    implementation=ROOT/'docs/design/SEVEN_MECHANICS_IMPLEMENTATION.md'
    if implementation.exists():shutil.copy2(implementation,out/implementation.name)
    print(out/'index.html')

if __name__=='__main__':
    main()
