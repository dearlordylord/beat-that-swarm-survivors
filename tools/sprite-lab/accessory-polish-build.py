#!/usr/bin/env python3
"""Render a reversible accessory identity study from Bend-authored geometry."""
import argparse, hashlib, importlib.util, io, json, shutil, sys
from pathlib import Path
import xml.etree.ElementTree as ET
sys.dont_write_bytecode = True
from PIL import Image, ImageDraw, ImageFont
import cairosvg
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('accessory_export',HERE/'accessories-build.py')
export=importlib.util.module_from_spec(spec);spec.loader.exec_module(export)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',required=True,type=Path);out=ap.parse_args().output
    if out.exists() and any(out.iterdir()):raise ValueError('Use a fresh output directory')
    out.mkdir(parents=True,exist_ok=True)
    refs=Path('/workspace/survivors-accessory-lab/references')
    for ref in json.loads((HERE/'accessory-references.json').read_text()):
        assert hashlib.sha256((refs/(ref['name']+'.gif')).read_bytes()).hexdigest()==ref['sha256']
    root=ET.fromstring(export.emit('accessory-polish-generate.bend'));assert len(root)==18
    sheet=Image.new('RGB',(1140,1110),'#23343c');d=ImageDraw.Draw(sheet)
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',18)
    small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)
    d.text((20,10),'Accessory polish prototypes. D remains selected. E and F are unreviewed.',font=font,fill='white')
    checks=[]
    for col,(hero,name) in enumerate([(3,'MANG'),(0,'KOYA'),(4,'CHIMMY')]):
        x=col*380
        ref=Image.open(refs/(name.lower()+'.gif')).convert('RGBA');ref=ref.crop(ref.getbbox());ref.thumbnail((140,150))
        sheet.paste(ref,(x+120,45),ref);d.text((x+145,205),name,font=font,fill='white')
        for v,label in enumerate(['D / selected baseline','E / identity anchors','F / expression variant']):
            index=(v*3+col)*2
            icon,palette,svg=export.raster(root[index],(16,18));probe,_,_=export.raster(root[index],(32,36))
            assert probe.getbbox()[2]<=16 and probe.getbbox()[3]<=18
            icon,_=export.export.pixel_layers(icon,palette);icon.save(out/f'icon-{hero}-{v}.png')
            rgba,palette,svg=export.raster(root[index+1],(64,80))
            selected=Image.open(Path('/workspace/survivors-bts-game-art')/f'character-{hero}.png').convert('RGBA')
            for box in [(0,0,64,38),(0,38,32,80),(32,74,64,80)]:
                assert rgba.crop(box).tobytes()==selected.crop(box).tobytes(), 'Human outside accessory changed'
            native,layers=export.export.pixel_layers(rgba.resize((32,40),Image.Resampling.NEAREST),palette)
            if v==0:
                expected=Image.open(Path('/workspace/survivors-bts-game-art')/f'character-{hero}-native.png').convert('RGBA')
                assert native.tobytes()==expected.tobytes(), 'Selected baseline drift'
            path=''.join(f'<path fill="{color}" d="{path}"/>' for color,path in layers)
            game=Image.open(io.BytesIO(cairosvg.svg2png(bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 40" width="24" height="30">{path}</svg>'.encode()))).convert('RGBA')
            native.save(out/f'hero-{hero}-{v}.png');game.save(out/f'gameplay-{hero}-{v}.png');(out/f'hero-{hero}-{v}.svg').write_bytes(svg)
            y=245+v*275;d.text((x+15,y),label,font=font,fill='white')
            for im,pos,scale in [(icon,(x+15,y+35),6),(native,(x+140,y+35),3),(game,(x+260,y+65),1),(game,(x+300,y+45),2)]:
                im=im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST);sheet.paste(im,pos,im)
            d.text((x+15,y+165),'16x18 icon / 32x40 hero / actual24x30 + 2x',font=small,fill='#c8d8df')
            checks.append({'hero':hero,'variant':v,'bounds16x18':True,'outside_accessory_unchanged':True,'selected_baseline_exact':v==0})
    sheet.save(out/'comparison.png')
    source=out/'source';source.mkdir()
    for file in ['accessory-polish-art.bend','accessory-polish-generate.bend','accessory-polish-build.py','theme-artwork.bend','artwork.bend','model.bend','accessories-native.bend','accessories.bend']:
        shutil.copy2(HERE/file,source/file)
    report={'status':'unreviewed prototypes; selected D unchanged','checks':checks,'references_sha256_verified':True,'source_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in source.iterdir()}}
    (out/'validation.json').write_text(json.dumps(report,indent=2))
    (out/'index.html').write_text('''<!doctype html><meta charset="utf-8"><title>Accessory polish</title><style>body{background:#23343c;color:white;font:18px system-ui;max-width:1200px;margin:24px auto}img{max-width:100%;image-rendering:pixelated}a{color:#aee}</style><h1>Accessory polish prototypes</h1><p>The selected D baseline stays in the game. E and F test clearer reference identity inside the same footprint and mount. Geometry is authored in Bend.</p><p>MANG now places the pink heart on the turquoise mask and gives the muzzle a purple lower silhouette. KOYA gains rounder ear steps and a dark border around the purple nose. CHIMMY retains the hood and floppy ears while testing a smaller tongue and smile.</p><img src="comparison.png"><p>Native32x40 and actual24x30 figures are shown separately. No independent review or gameplay recognition claim yet.</p><a href="validation.json">Finite checks and source hashes</a>''')
    print(out/'index.html')
if __name__=='__main__':main()
