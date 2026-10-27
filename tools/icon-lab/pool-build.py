#!/usr/bin/env python3
"""Render Bend-authored shared relic icons and interface-size comparisons."""
import argparse
import copy
import hashlib
import io
import json
from pathlib import Path
import random
import shutil
import subprocess
import tempfile
import textwrap
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = json.loads((HERE/'pool-manifest.json').read_text())


def run(command):
    return subprocess.run(command, check=True, text=True, capture_output=True).stdout


def font(size):
    return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',size)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    assert not out.is_relative_to(ROOT), 'Generated images belong outside tracked source.'
    assert not out.exists() or not any(out.iterdir()), 'Use a fresh output folder.'
    out.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='nightfall-relic-icons-') as temp:
        c = Path(temp)/'icons.c'
        binary = Path(temp)/'icons'
        run(['bend',str(HERE/'pool-artwork.bend'),'-o',str(c)])
        run(['clang','-O0',str(c),'-o',str(binary),'-lm','-lpthread'])
        emitted = run([str(binary)])
    (out/'authored-sheet.svg').write_text(emitted)
    root = ET.fromstring(emitted)
    assert len(root)==18
    records=[]
    previews={}
    cards=[]
    sheet=Image.new('RGB',(1410,1210),'#18282f')
    d=ImageDraw.Draw(sheet)
    d.text((24,18),'Shared relic icons · existing 18 passive IDs · filled vector objects',font=font(24),fill='#f3e4c9')
    d.text((24,55),'Working names and icon study only. Effects and inventory IDs are unchanged.',font=font(17),fill='#c4d7dc')
    for item,group in zip(MANIFEST['items'],root):
        ident=int(group.attrib['data-id'])
        assert ident==item['id']
        svg=ET.Element('{http://www.w3.org/2000/svg}svg',{'viewBox':'0 0 32 32','width':'32','height':'32','aria-label':item['proposedName']})
        svg.append(copy.deepcopy(group))
        text=ET.tostring(svg)
        stem=f'passive-{ident}'
        (out/f'{stem}.svg').write_bytes(text)
        sizes={}
        for size in [16,20,24,32]:
            image=Image.open(io.BytesIO(cairosvg.svg2png(bytestring=text,output_width=size,output_height=size))).convert('RGBA')
            image.save(out/f'{stem}-{size}.png')
            previews[(ident,size)]=image
            bbox=image.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
            assert bbox is not None
            if size==32:
                assert bbox[0]>=2 and bbox[1]>=2 and bbox[2]<=30 and bbox[3]<=30,(ident,bbox)
            sizes[str(size)]={'opaque_bbox':bbox,'nonempty':True}
        x=24+(ident%3)*465
        y=105+(ident//3)*180
        d.text((x,y),f'{ident:02d} · {item["proposedName"]}',font=font(20),fill='#f3e4c9')
        d.text((x,y+29),item['currentName'],font=font(14),fill='#9eb2bd')
        enlarged=previews[(ident,32)].resize((64,64),Image.Resampling.NEAREST)
        sheet.paste(enlarged,(x,y+58),enlarged)
        for n,size in enumerate([16,20,24,32]):
            image=previews[(ident,size)]
            ix=x+90+n*47
            sheet.paste(image,(ix,y+74+(32-size)//2),image)
            d.text((ix,y+116),str(size),font=font(12),fill='#b4c9d0')
        hud=Image.new('RGB',(100,46),'#18282f')
        hd=ImageDraw.Draw(hud)
        for hx in [4,58]:
            hd.rectangle((hx,4,hx+33,37),fill='#151e29',outline='#6d6975')
            hd.text((hx+24,26),'V',font=font(9),fill='#fff0ce')
        hd.text((14,8),item['currentGlyph'],font=font(19),fill='#f3e4c9')
        hud.paste(previews[(ident,20)],(65,9),previews[(ident,20)])
        sheet.paste(hud,(x+300,y+65))
        d.text((x+303,y+116),'old / proposed',font=font(11),fill='#b4c9d0')
        for n,line in enumerate(textwrap.wrap(item['effect'],width=51)):
            d.text((x,y+139+n*17),line,font=font(13),fill='#b4c9d0')
        records.append({**item,'sizes':sizes,'svg_sha256':hashlib.sha256(text).hexdigest(),'review':'unreviewed'})
        cards.append(f'<article><h2>{ident:02d} {item["proposedName"]}</h2><p class="old">Current: {item["currentName"]}</p><img class="icon" src="{stem}.svg" alt="{item["proposedName"]}"><p>{item["effect"]}</p></article>')
    sheet.save(out/'comparison.png')
    blind=Image.new('RGB',(960,480),'#18282f')
    bd=ImageDraw.Draw(blind)
    order=list(range(18));random.Random(73).shuffle(order)
    for pos,ident in enumerate(order):
        x=25+(pos%6)*155;y=22+(pos//6)*150
        bd.text((x,y),str(pos+1),font=font(15),fill='#f3e4c9')
        large=previews[(ident,32)].resize((64,64),Image.Resampling.NEAREST)
        blind.paste(large,(x+15,y+27),large)
        blind.paste(previews[(ident,20)],(x+93,y+60),previews[(ident,20)])
    blind.save(out/'blind.png')
    (out/'blind-key.json').write_text(json.dumps(order)+'\n')
    (out/'validation.json').write_text(json.dumps({'scope':'Finite nonempty and safe-area checks for eighteen authored vector icons. No recognition, fidelity or accessibility guarantee.','items':records},indent=2)+'\n')
    source=out/'source';source.mkdir()
    for name in ['pool-artwork.bend','pool-build.py','pool-manifest.json','pool-README.md']:
        shutil.copy2(HERE/name,source/name)
    (out/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><title>Shared relic vector study</title><style>body{background:#18282f;color:#eee2ca;font:16px system-ui;margin:30px}a{color:#9dc9ff}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(245px,1fr));gap:14px}article{background:#151e29;padding:18px;border:1px solid #40515b}h2{font-size:19px}.old{font-size:13px;color:#9eb2bd}.icon{width:var(--size,32px);height:var(--size,32px)}button{padding:8px;margin:5px}img.sheet{max-width:100%}</style><h1>Shared relic vector study</h1><p>These are the existing 18 shared passive IDs. Proposed names and icons have not replaced game content. Each object is authored as vector geometry in Bend.</p><p>View icons at <button data-size="16">16px</button><button data-size="20">20px</button><button data-size="24">24px</button><button data-size="32">32px</button>. The comparison includes a rank-V overlay in a 34px HUD slot.</p><p><a href="comparison.png">Full interface comparison</a> · <a href="validation.json">Finite checks</a></p><div class="grid">'''+''.join(cards)+'''</div><h2>Comparison sheet</h2><img class="sheet" src="comparison.png" alt="All eighteen relic icons with current glyph and proposed image"><script>for(const b of document.querySelectorAll('[data-size]'))b.onclick=()=>document.documentElement.style.setProperty('--size',b.dataset.size+'px')</script></html>''')
    print(out/'index.html')

if __name__=='__main__':main()
