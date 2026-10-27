#!/usr/bin/env python3
"""Compare Bend accessories in isolation and on the native/gameplay sprite grid."""
import argparse, copy, hashlib, io, json, re, shutil, tempfile, sys
from pathlib import Path
import xml.etree.ElementTree as ET
sys.dont_write_bytecode=True
from PIL import Image, ImageDraw, ImageFont
import cairosvg
from build import HERE, NS, run

import importlib.util
spec=importlib.util.spec_from_file_location('theme_export',HERE/'theme-build.py')
export=importlib.util.module_from_spec(spec);spec.loader.exec_module(export)
NAMES=['KOYA','RJ','SHOOKY','MANG','CHIMMY','TATA','COOKY']
def emit(entry):
    with tempfile.TemporaryDirectory(prefix='accessory-study-') as s:
        c,b=Path(s)/'art.c',Path(s)/'art'
        run(['bend',str(HERE/entry),'-o',str(c)])
        run(['clang','-O0',str(c),'-o',str(b),'-lm','-lpthread'])
        return run([str(b)]).stdout

def raster(group,size):
    group=copy.deepcopy(group);group.attrib.pop('transform',None)
    root=ET.Element(NS+'svg',{'viewBox':f'0 0 {size[0]} {size[1]}','width':str(size[0]),'height':str(size[1])});root.append(group)
    svg=ET.tostring(root)
    image=Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg))).convert('RGBA')
    palette=sorted(set(tuple(bytes.fromhex(c)) for c in re.findall(r'#([0-9a-fA-F]{6})',svg.decode())))
    return image,palette,svg

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True,type=Path);args=parser.parse_args();out=args.output
    if out.exists() and any(out.iterdir()):raise ValueError('Use a fresh output directory')
    out.mkdir(parents=True,exist_ok=True)
    reference_root=Path('/workspace/survivors-accessory-lab/references')
    for reference in json.loads((HERE/'accessory-references.json').read_text()):
        actual=hashlib.sha256((reference_root/(reference['name']+'.gif')).read_bytes()).hexdigest()
        assert actual==reference['sha256'], 'Reference content changed: '+reference['name']
    root=ET.fromstring(emit('accessories-integrated.bend'));icons=ET.fromstring(emit('accessories-generate.bend'));nativeicons=ET.fromstring(emit('accessories-native-generate.bend'))
    assert len(root)==28 and len(icons)==14
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
    sheet=Image.new('RGB',(1400,1650),'#23343c');d=ImageDraw.Draw(sheet)
    d.text((15,8),'ACCESSORIES: official reference / emblem / plush. Native and actual 0.75 gameplay scale.',font=font,fill='white')
    blind=Image.new('RGB',(980,690),'#23343c');bd=ImageDraw.Draw(blind);order=[3,0,6,1,5,2,4]
    gameblind=Image.new('RGB',(980,400),'#23343c');gd=ImageDraw.Draw(gameblind)
    checks=[]
    for id,name in enumerate(NAMES):
        x=id*200
        ref=Image.open(Path('/workspace/survivors-accessory-lab/references')/(name.lower()+'.gif')).convert('RGBA');ref=ref.crop(ref.getbbox());ref.thumbnail((125,135));sheet.paste(ref,(x+35,40),ref);d.text((x+30,180),name,font=font,fill='white')
        for variant in range(4):
            icon,palette,svg=raster(nativeicons[id] if variant==3 else icons[id*2+min(variant,1)],(16,18) if variant==3 else (12,14))
            probe,_,_=raster(nativeicons[id] if variant==3 else icons[id*2+min(variant,1)],(32,36))
            bounds=probe.getbbox();limit=(16,18) if variant==3 else (12,14)
            assert bounds and bounds[2]<=limit[0] and bounds[3]<=limit[1], 'Accessory exceeds its grid'
            icon,_=export.pixel_layers(icon,palette)
            icon.save(out/f'icon-{id}-{variant}.png')
            rgba,palette,svg=raster(root[variant*7+id],(64,80))
            baseline=Image.open(Path('/workspace/survivors-bts-art')/f'character-{id}.png').convert('RGBA')
            assert rgba.crop((0,0,64,38)).tobytes()==baseline.crop((0,0,64,38)).tobytes(), 'Hero head changed'
            for eye_x in (25,37):
                assert all(rgba.getpixel((x,y))==(16,23,41,255) for y in range(27,35) for x in range(eye_x,eye_x+3)), 'Hero eye occluded'
            (out/f'character-{id}-{variant}.svg').write_bytes(svg)
            native,layers=export.pixel_layers(rgba.resize((32,40),Image.Resampling.NEAREST),palette)
            native.save(out/f'character-{id}-{variant}.png')
            path=''.join(f'<path fill="{color}" d="{path}"/>' for color,path in layers)
            game=Image.open(io.BytesIO(cairosvg.svg2png(bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 40" width="24" height="30">{path}</svg>'.encode()))).convert('RGBA')
            game.save(out/f'gameplay-{id}-{variant}.png')
            y=220+variant*350
            sheet.paste(icon.resize((96,112),Image.Resampling.NEAREST),(x+10,y),icon.resize((96,112),Image.Resampling.NEAREST))
            sheet.paste(icon,(x+135,y+40),icon)
            d.text((x+110,y+65),'16x18' if variant==3 else '12x14',font=font,fill='#c8d8df')
            sheet.paste(native.resize((96,120),Image.Resampling.NEAREST),(x+8,y+135),native.resize((96,120),Image.Resampling.NEAREST))
            sheet.paste(game,(x+125,y+180),game)
            sheet.paste(game.resize((48,60),Image.Resampling.NEAREST),(x+145,y+160),game.resize((48,60),Image.Resampling.NEAREST))
            d.text((x+3,y+266),['A / head emblem','B / compact plush','C / larger plush','D / native grid'][variant],font=font,fill='#c8d8df')
            j=order.index(id);bx=j*140
            bd.text((bx+10,5),chr(65+j),font=font,fill='white')
            blind.paste(icon.resize((72,84),Image.Resampling.NEAREST),(bx+10,35+variant*160),icon.resize((72,84),Image.Resampling.NEAREST))
            blind.paste(game,(bx+100,60+variant*160),game)
            gd.text((bx+5,variant*95+5),chr(65+j),font=font,fill='white')
            gameblind.paste(game,(bx+12,variant*95+35),game)
            gameblind.paste(game.resize((48,60),Image.Resampling.NEAREST),(bx+65,variant*95+25),game.resize((48,60),Image.Resampling.NEAREST))
            checks.append({'id':id,'variant':variant,'icon_pixels':sum(a>0 for *rgb,a in icon.get_flattened_data()),'head_unchanged':True,'eyes_visible':True,'grid_bounds':limit})
    sheet.save(out/'comparison.png');blind.save(out/'recognition-blind.png');gameblind.save(out/'gameplay-blind.png')
    sources=out/'source';sources.mkdir()
    for name in ['accessories.bend','accessories-native.bend','accessories-native-generate.bend','accessories-generate.bend','accessories-integrated.bend','accessories-build.py','theme-artwork.bend','artwork.bend','model.bend']:shutil.copy2(HERE/name,sources/name)
    (out/'build.json').write_text(json.dumps({'blind_order':order,'checks':checks,'source_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sources.iterdir()}},indent=2))
    (out/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>Accessory study</title><style>body{background:#23343c;color:white;font:18px system-ui}img{max-width:100%;image-rendering:pixelated}a{color:#aee}</style><h1>Accessory study</h1><p>A: head emblem. B: compact plush. C: larger plush. Small figures use the actual24x30 gameplay scale.</p><img src="comparison.png"><p><a href="recognition-blind.png">Unlabelled recognition study</a></p>')
    print(out/'index.html')
if __name__=='__main__':main()
