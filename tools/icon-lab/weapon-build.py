#!/usr/bin/env python3
"""Export the Bend-authored 24-weapon icon study without changing game content."""
import argparse
import copy
import hashlib
import html
import io
import json
from pathlib import Path
import random
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
STARTERS = {20:0,21:1,14:2,22:3,8:4,23:5,1:6}


def run(args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def font(size):
    return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', size)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--iteration', type=int, default=1)
    parser.add_argument('--check', action='store_true', help='Compare current geometry hashes with the recorded manifest')
    args = parser.parse_args()
    out = args.output.resolve()
    assert not out.is_relative_to(ROOT)
    assert not out.exists() or not any(out.iterdir()), 'Use a fresh iteration folder'
    out.mkdir(parents=True, exist_ok=True)
    weapons = json.loads((HERE/'study-matrix.json').read_text())['catalog']['weapons']
    assert [w['id'] for w in weapons] == list(range(24))
    with tempfile.TemporaryDirectory(prefix='nightfall-weapon-icons-') as temp:
        c = Path(temp)/'weapon-icons.c'
        binary = Path(temp)/'weapon-icons'
        run(['bend', str(HERE/'weapon-artwork.bend'), '-o', str(c)])
        run(['clang', '-O0', str(c), '-o', str(binary), '-lm', '-lpthread'])
        emitted = run([str(binary)])
    (out/'authored-sheet.svg').write_text(emitted)
    root = ET.fromstring(emitted)
    assert len(root) == 24
    previews = {}
    records = []
    for group, weapon in zip(root, weapons):
        ident = int(group.attrib['data-id'])
        assert ident == weapon['id']
        svg = ET.Element('{http://www.w3.org/2000/svg}svg', {'viewBox':'0 0 32 32','width':'32','height':'32','aria-label':weapon['proposedName']})
        svg.append(copy.deepcopy(group))
        data = ET.tostring(svg)
        (out/f'weapon-{ident}.svg').write_bytes(data)
        sizes = {}
        for size in [16,20,24,32]:
            image = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=data,output_width=size,output_height=size))).convert('RGBA')
            image.save(out/f'weapon-{ident}-{size}.png')
            previews[(ident,size)] = image
            bbox = image.getchannel('A').point(lambda a: 255 if a>=128 else 0).getbbox()
            assert bbox is not None
            if size ==32: assert bbox[0]>=2 and bbox[1]>=2 and bbox[2]<=30 and bbox[3]<=30, (ident,bbox)
            sizes[str(size)] = {'nonempty':True,'opaque_bbox':bbox}
        records.append({'key':f'weapon/{ident}','id':ident,'currentName':weapon['name'],'proposedName':weapon['proposedName'],'oldGlyph':weapon['icon'],'mechanic':weapon['description'],'starterHero':STARTERS.get(ident),'svgSha256':hashlib.sha256(data).hexdigest(),'sizes':sizes})
    sheet = Image.new('RGB',(1560,1360),'#18282f')
    d = ImageDraw.Draw(sheet)
    d.text((22,16),'24 existing weapon icons · original glyph / vector proposal / interface sizes',font=font(22),fill='#f3e4c9')
    d.text((22,48),'Bend geometry. Stable weapon IDs and mechanics. Names are working proposals, not trademark-cleared.',font=font(15),fill='#b4c9d0')
    for w in weapons:
        ident=w['id']; x=20+(ident%3)*520; y=88+(ident//3)*158
        d.text((x,y),f'{ident:02} · {w["proposedName"]}',font=font(19),fill='#f3e4c9')
        d.text((x,y+25),w['name'],font=font(13),fill='#a8c0ca')
        d.text((x+8,y+54),w['icon'],font=font(27),fill=w['color'])
        im=previews[(ident,32)].resize((64,64),Image.Resampling.NEAREST);sheet.paste(im,(x+48,y+48),im)
        offset=x+132
        for size in [16,20,24,32]:
            im=previews[(ident,size)];sheet.paste(im,(offset,y+72-size//2),im);d.text((offset,y+100),str(size),font=font(12),fill='#a8c0ca');offset+=size+15
        d.rectangle((x+348,y+50,x+382,y+84),fill='#151e29',outline='#656270')
        im=previews[(ident,20)];sheet.paste(im,(x+355,y+57),im);d.text((x+371,y+76),'8',font=font(10),fill='#fff0ce')
        text=w['description']
        if len(text)>65: text=text[:62]+'...'
        d.text((x,y+130),text,font=font(12),fill='#c6d6dc')
    sheet.save(out/'comparison.png')
    order=list(range(24));random.Random(713).shuffle(order)
    blind=Image.new('RGB',(6*100,4*108),'#18282f'); bd=ImageDraw.Draw(blind)
    for index, ident in enumerate(order):
        x=(index%6)*100;y=(index//6)*108;im=previews[(ident,32)].resize((64,64),Image.Resampling.NEAREST);blind.paste(im,(x+18,y+5),im);bd.text((x+43,y+78),str(index+1),font=font(14),fill='white')
    blind.save(out/'blind.png')
    manifest={'status':'Unreviewed vector prototypes. Production names, glyphs, mechanics and IDs unchanged.','iteration':args.iteration,'canvas':32,'style':'A filled objects','sizes':[16,20,24,32],'sourceSha256':{name:hashlib.sha256((HERE/name).read_bytes()).hexdigest() for name in ['weapon-artwork.bend','artwork.bend']},'icons':records,'blindOrder':[{'number':i+1,'weapon':ident} for i,ident in enumerate(order)],'scope':'Finite output checks cover nonempty and two-unit-safe-area renders. They do not establish semantic recognition, aesthetics, full accessibility or trademark clearance.'}
    (out/'validation.json').write_text(json.dumps(manifest,indent=2)+'\n')
    if args.check:
        prior = json.loads((HERE/'weapon-manifest.json').read_text())
        assert prior['sourceSha256'] == manifest['sourceSha256'], 'Weapon or shared geometry source changed'
        assert [i['svgSha256'] for i in prior['icons']] == [i['svgSha256'] for i in manifest['icons']], 'Weapon vector output changed'
    else:
        (HERE/'weapon-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    source=out/'source';source.mkdir()
    for name in ['weapon-artwork.bend','weapon-build.py','weapon-README.md','artwork.bend','manifest.json']:
        if (HERE/name).is_file():shutil.copy2(HERE/name,source/name)
    cards=''
    for w in weapons:
        ident=w['id'];cards+=f'<article><h2>{ident:02} · {html.escape(w["proposedName"])}</h2><p class="old">Current: {html.escape(w["name"])} · <span class="glyph">{html.escape(w["icon"])}</span></p><div class="sizes">'
        for size in [16,20,24,32]:cards+=f'<figure><img src="weapon-{ident}.svg" width="{size}" height="{size}"><figcaption>{size}px</figcaption></figure>'
        cards+=f'</div><p>{html.escape(w["description"])}</p><div class="mock"><span class="slot"><img src="weapon-{ident}.svg" width="20" height="20"><b>8</b></span><span>34px HUD with rank overlay</span></div><a href="weapon-{ident}.svg">Open vector SVG</a></article>'
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>Weapon vector icon study</title><style>body{margin:32px auto;padding:0 20px;max-width:1200px;background:#101c24;color:#eee5d1;font:16px system-ui}a{color:#b7dfff}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}article{background:#182a32;border:1px solid #354b55;padding:18px;border-radius:8px}h2{font-size:18px}.old,figcaption{color:#9db6c0;font-size:13px}.sizes{display:flex;align-items:center;gap:22px;min-height:70px}figure{margin:0;text-align:center}.mock{display:flex;align-items:center;gap:12px;margin:18px 0;font-size:12px;color:#9db6c0}.slot{position:relative;display:inline-flex;width:34px;height:34px;align-items:center;justify-content:center;background:#151e29;border:1px solid #656270}.slot b{position:absolute;right:2px;bottom:1px;font-size:10px;color:#fff0ce}.glyph{font-size:20px}@media(max-width:900px){.grid{grid-template-columns:repeat(2,1fr)}}@media(max-width:600px){.grid{grid-template-columns:1fr}}</style><h1>24 existing weapon icons</h1><p>Vector proposals for the existing weapon pool. Seven starter attacks reuse the same reviewed personal icon geometry. Existing mechanics, IDs and production glyphs are unchanged. Working names are not trademark-cleared.</p><p><a href="comparison.png">Comparison sheet</a> · <a href="validation.json">Finite checks</a></p><div class="grid">'''+cards+'</div></html>'
    (out/'index.html').write_text(page)
    print(out/'index.html')


if __name__=='__main__':main()
