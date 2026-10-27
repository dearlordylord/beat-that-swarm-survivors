#!/usr/bin/env python3
"""Compile Bend icon geometry and present reversible interface-size studies."""
import argparse
import copy
import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = json.loads((HERE/'manifest.json').read_text())
HEROES = [hero['key'] for hero in MANIFEST['heroes']]
NAMES = [hero['displayName'] for hero in MANIFEST['heroes']]
LABELS = [[hero['icons'][kind]['label'] for kind in ['trinket','attack']] for hero in MANIFEST['heroes']]
INTENTS = [[hero['icons'][kind]['intent'] for kind in ['trinket','attack']] for hero in MANIFEST['heroes']]
ACCENTS = ['#8faadb','#f0d990','#ef7f83','#f1bf55','#c7bddf','#d7a78e','#eaca70']


def luminance(hex_color):
    values = [int(hex_color[i:i+2],16)/255 for i in [1,3,5]]
    linear = [c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in values]
    return sum(c*w for c,w in zip(linear,[.2126,.7152,.0722]))


def contrast(a,b):
    high,low = sorted([luminance(a),luminance(b)],reverse=True)
    return (high+.05)/(low+.05)



def run(command):
    return subprocess.run(command, check=True, text=True, capture_output=True).stdout


def font(size):
    return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', size)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--iteration', type=int, default=1)
    args = parser.parse_args()
    assert args.iteration > 0
    out = args.output.resolve()
    assert not out.is_relative_to(ROOT), 'Generated artwork stays outside tracked source.'
    assert not out.exists() or not any(out.iterdir()), 'Use a fresh iteration folder.'
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='nightfall-icons-') as temp:
        c = Path(temp)/'icons.c'
        binary = Path(temp)/'icons'
        run(['bend', str(HERE/'artwork.bend'), '-o', str(c)])
        run(['clang', '-O0', str(c), '-o', str(binary), '-lm', '-lpthread'])
        emitted = run([str(binary)])
    (out/'authored-sheet.svg').write_text(emitted)
    root = ET.fromstring(emitted)
    assert len(root) == 28
    records = []
    previews = {}
    for group in root:
        hero = int(group.attrib['data-hero'])
        kind = int(group.attrib['data-kind'])
        style = int(group.attrib['data-style'])
        key = f'{HEROES[hero]}-{"trinket" if kind == 0 else "attack"}'
        variant = 'a' if style == 0 else 'b'
        stem = f'{key}-{variant}'
        svg = ET.Element('{http://www.w3.org/2000/svg}svg', {'viewBox': '0 0 32 32', 'width': '32', 'height': '32', 'aria-label': LABELS[hero][kind]})
        svg.append(copy.deepcopy(group))
        text = ET.tostring(svg)
        (out/f'{stem}.svg').write_bytes(text)
        checks = {}
        for size in [16, 20, 24, 32]:
            image = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=text, output_width=size, output_height=size))).convert('RGBA')
            image.save(out/f'{stem}-{size}.png')
            previews[(hero,kind,style,size)] = image
            opaque = image.getchannel('A').point(lambda x: 255 if x >= 128 else 0)
            bbox = opaque.getbbox()
            assert bbox is not None, f'{stem}: empty icon'
            if size == 32:
                assert bbox[0] >= 2 and bbox[1] >= 2 and bbox[2] <= 30 and bbox[3] <= 30, f'{stem}: safe area {bbox}'
            checks[str(size)] = {'opaque_bbox': bbox, 'nonempty': True}
        records.append({'key': key, 'variant': variant, 'label': LABELS[hero][kind], 'intent': INTENTS[hero][kind], 'status': 'unreviewed prototype', 'accent_contrast_on_hud': round(contrast(ACCENTS[hero],'#151e29'),2), 'sizes': checks, 'sha256': hashlib.sha256(text).hexdigest()})
    sheet = Image.new('RGB', (1300, 1075), '#18282f')
    draw = ImageDraw.Draw(sheet)
    draw.text((22,16), 'Icon study · A filled objects / B etched objects · vector source, no letter glyphs', font=font(21), fill='#f3e4c9')
    draw.text((22,46), 'Proposed personal trinkets are concepts for innate motifs, not existing inventory items.', font=font(15), fill='#b4c9d0')
    for hero, name in enumerate(NAMES):
        y = 90+hero*138
        draw.text((22,y+5), name, font=font(20), fill='#f3e4c9')
        for style in [0,1]:
            for kind in [0,1]:
                x = 145+(style*2+kind)*285
                draw.text((x,y), ('A · ' if style == 0 else 'B · ')+LABELS[hero][kind], font=font(15), fill='#d8e6e8')
                enlarged = previews[(hero,kind,style,32)].resize((64,64),Image.Resampling.NEAREST)
                sheet.paste(enlarged,(x,y+25),enlarged)
                offset = x+85
                for size in [16,20,24,32]:
                    image = previews[(hero,kind,style,size)]
                    sheet.paste(image,(offset,y+42-size//2),image)
                    draw.text((offset,y+73),str(size),font=font(11),fill='#9ab1bc')
                    offset += size+11
    sheet.save(out/'comparison.png')
    blind = Image.new('RGB',(7*100,2*115),'#18282f')
    d = ImageDraw.Draw(blind)
    order = [(4,1),(0,0),(6,1),(1,0),(3,1),(2,0),(5,1),(2,1),(6,0),(4,0),(0,1),(5,0),(1,1),(3,0)]
    for index,(hero,kind) in enumerate(order):
        x,y=(index%7)*100,(index//7)*115
        im=previews[(hero,kind,0,32)].resize((64,64),Image.Resampling.NEAREST)
        blind.paste(im,(x+18,y+8),im)
        d.text((x+43,y+82),str(index+1),font=font(14),fill='white')
    blind.save(out/'blind.png')
    source=out/'source'; source.mkdir()
    for name in ['artwork.bend','build.py','README.md','manifest.json','reviews.json']:
        file = HERE/name
        if file.is_file(): shutil.copy2(file,source/name)
    report={'iteration':args.iteration,'status':'unreviewed prototypes','source_sha256':hashlib.sha256((HERE/'artwork.bend').read_bytes()).hexdigest(),'scope':'Finite output checks establish populated 32x32 vector canvases and a two-unit safe area. Primary accent contrast is measured against the dark HUD background; it does not establish contrast of every detail or antialiased pixel. These checks do not establish recognition, reference fidelity or aesthetic acceptance.','icons':records,'blind_order':[{'number':i+1,'key':f'{HEROES[h]}-{"trinket" if k==0 else "attack"}'} for i,(h,k) in enumerate(order)]}
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    cards=''
    for hero,name in enumerate(NAMES):
        cards+=f'<section><h2>{name}</h2><div class="items">'
        for kind in [0,1]:
            key=f'{HEROES[hero]}-{"trinket" if kind==0 else "attack"}'
            cards+=f'<article><h3>{LABELS[hero][kind]}</h3><p>{INTENTS[hero][kind]}</p><div class="icons">'
            for size in [16,20,24,32]:
                cards+=f'<figure><img data-key="{key}" src="{key}-a.svg" width="{size}" height="{size}"><figcaption>{size}px</figcaption></figure>'
            cards+=f'</div><div class="hud"><span class="slot"><img data-key="{key}" src="{key}-a.svg" width="20" height="20"></span><span class="slot large"><img data-key="{key}" src="{key}-a.svg" width="24" height="24"></span><span>{"Proposed personal trinket" if kind==0 else "Personal attack"}</span></div></article>'
        cards+='</div></section>'
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>Survivor icon lab</title><style>body{margin:32px auto;max-width:1150px;background:#101c24;color:#eee5d1;font:16px system-ui;padding:0 20px}button{padding:12px;background:#263e49;color:#fff;border:1px solid #6b8390;border-radius:6px;cursor:pointer}button[aria-pressed=true]{border-color:#e4c66d;color:#ffeaa0}nav{position:sticky;top:0;background:#101c24ed;padding:12px 0;z-index:1}.items{display:grid;grid-template-columns:1fr 1fr;gap:20px}article{background:#182a32;border:1px solid #354b55;padding:20px;border-radius:8px}article p{min-height:40px;color:#b5c7cb}.icons{display:flex;align-items:center;gap:24px;min-height:75px}figure{margin:0;text-align:center}figcaption{color:#91a7b2;font-size:12px;margin-top:8px}.hud{display:flex;gap:16px;align-items:center;border-top:1px solid #354b55;margin-top:18px;padding-top:16px;font-size:13px;color:#b5c7cb}.slot{display:inline-flex;width:34px;height:34px;align-items:center;justify-content:center;background:#151e29;border:1px solid #656270}.slot.large{width:38px;height:36px}a{color:#b7dfff}h2{margin-top:40px}@media(max-width:700px){.items{grid-template-columns:1fr}.icons{gap:16px}}</style><h1>Personal icon studies</h1><p>Fourteen concepts in two vector treatments. The seven trinket objects are proposed innate motifs, not existing pool items. Names are provisional; existing gameplay remains unchanged.</p><nav><button data-style="a" aria-pressed="true">A · Filled objects</button> <button data-style="b" aria-pressed="false">B · Etched objects</button> <a href="comparison.png">Comparison sheet</a> · <a href="validation.json">Finite checks</a></nav>'''+cards+'''<script>for(const button of document.querySelectorAll('button[data-style]'))button.onclick=()=>{const style=button.dataset.style;document.body.dataset.selectedStyle=style;for(const image of document.querySelectorAll('[data-key]'))image.src=`${image.dataset.key}-${style}.svg`;for(const candidate of document.querySelectorAll('button[data-style]'))candidate.setAttribute('aria-pressed',String(candidate===button))};</script></html>'''
    (out/'index.html').write_text(page)
    print(out/'index.html')


if __name__ == '__main__': main()
