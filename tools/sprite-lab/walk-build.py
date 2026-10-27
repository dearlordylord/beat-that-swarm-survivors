#!/usr/bin/env python3
"""Export the shared Bend walk rig for all seven selected survivors."""
import argparse
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
NAMES = ['RM', 'Jin', 'SUGA', 'j-hope', 'Jimin', 'V', 'Jung Kook']
TARGET = ROOT / 'examples/survivors/survivor-walk-shapes.mts'
spec = importlib.util.spec_from_file_location('theme_build', HERE/'theme-build.py')
theme_build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(theme_build)


def run(args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', nargs='?', type=Path, default=Path('/workspace/survivors-walk-game-art'))
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    out = args.output.resolve()
    assert not out.is_relative_to(ROOT), 'Generated previews belong outside tracked source'
    out.mkdir(parents=True, exist_ok=True)
    selected_root = Path('/workspace/survivors-bts-game-art')
    selected_hashes = json.loads((HERE/'theme-selection.json').read_text())['approved_native_png_sha256']
    for hero, expected in selected_hashes.items():
        actual = hashlib.sha256((selected_root/f'character-{hero}-native.png').read_bytes()).hexdigest()
        assert actual == expected, f'{hero}: selected idle reference hash changed'
    with tempfile.TemporaryDirectory(prefix='nightfall-walk-') as temp:
        c = Path(temp)/'walk.c'
        binary = Path(temp)/'walk'
        run(['bend', str(HERE/'walk-artwork.bend'), '-o', str(c)])
        run(['clang', '-O0', str(c), '-o', str(binary), '-lm', '-lpthread'])
        emitted = run([str(binary)])
    (out/'sheet.svg').write_text(emitted)
    root = ET.fromstring(emitted)
    assert len(root) == 56
    roster = [[] for _ in NAMES]
    rendered = [[] for _ in NAMES]
    records = []
    selected_images = [Image.open(selected_root/f'character-{hero}-native.png').convert('RGBA') for hero in range(7)]
    selected_svgs = [(selected_root/f'character-{hero}.svg').read_text() for hero in range(7)]
    for group in root:
        hero, frame = int(group.attrib['data-character']), int(group.attrib['data-frame'])
        assert frame == len(roster[hero])
        svg = ET.Element('{http://www.w3.org/2000/svg}svg', {'viewBox':'0 0 64 80', 'width':'64', 'height':'80'})
        svg.append(copy.deepcopy(group))
        text = ET.tostring(svg)
        (out/f'hero-{hero}-frame-{frame}.svg').write_bytes(text)
        image = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=text))).convert('RGBA')
        selected_svg = selected_svgs[hero]
        palette = sorted(set(tuple(bytes.fromhex(c)) for c in re.findall(r'#([0-9a-fA-F]{6})', text.decode()+selected_svg)))
        native, layers = theme_build.pixel_layers(image.resize((32,40), Image.Resampling.NEAREST), palette)
        native.save(out/f'hero-{hero}-frame-{frame}.png')
        assert all(native.getpixel((x,39))[3] == 0 for x in range(32)), f'{hero}/{frame}: foot clips bottom edge'
        selected = selected_images[hero]
        assert native.crop((0,0,32,18)).tobytes() == selected.crop((0,0,32,18)).tobytes(), f'{hero}/{frame}: selected head drift'
        left_bottom = int(group.attrib['data-ground'])-int(group.attrib['data-lift'])
        opposite = root[hero*8+(frame+4)%8]
        right_lift = int(opposite.attrib['data-lift'])
        right_bottom = int(opposite.attrib['data-ground'])-right_lift
        assert int(group.attrib['data-lift']) == 0 or right_lift == 0, 'Both feet airborne'
        following = root[hero*8+(frame+1)%8]
        next_bottom = int(following.attrib['data-ground'])-int(following.attrib['data-lift'])
        assert abs(next_bottom-left_bottom) <= 3, 'Unbounded loop sole transition'
        sole_row = min(left_bottom, right_bottom)//2-1
        assert native.getpixel((16,sole_row))[3] == 0, f'{hero}/{frame}: boot soles merged'
        paths = ''.join(f'<path fill="{color}" d="{path}"/>' for color,path in layers)
        game = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 40" width="24" height="30">{paths}</svg>'.encode()))).convert('RGBA')
        game.save(out/f'hero-{hero}-gameplay-{frame}.png')
        ground, lift = int(group.attrib['data-ground']), int(group.attrib['data-lift'])
        assert 70 <= ground-lift <=76
        if frame <=4:
            assert ground+frame ==76, 'Reference stance foot slides'
        roster[hero].append(layers)
        rendered[hero].append((native,game))
        records.append({'hero':hero, 'frame':frame, 'ground':ground, 'lift':lift, 'selected_head_exact':True, 'boot_lanes_separate':True})
    source = '// Generated by tools/sprite-lab/walk-build.py from Bend geometry.\n'
    source += 'import { at } from "./host-values.mts"\nimport type { SurvivorLayers } from "./survivor-shapes.mts"\n'
    source += 'const walks: readonly (readonly SurvivorLayers[])[] = '+json.dumps(roster,indent=2)+'\n'
    source += '''
export const survivorWalkFrameCount = 8
export const survivorWalkCount = walks.length

export function survivorWalkLayers(id = 0, frame = 0): SurvivorLayers {
  const hero = Number.isInteger(id) && id >= 0 && id < survivorWalkCount ? id : 0
  const pose = Number.isFinite(frame) ? ((Math.floor(frame) % survivorWalkFrameCount) + survivorWalkFrameCount) % survivorWalkFrameCount : 0
  return at(at(walks, hero), pose)
}
'''
    if args.check:
        assert TARGET.read_text() == source, 'Walk data stale; rerun walk-build.py'
    else:
        TARGET.write_text(source)
    for hero, frames in enumerate(rendered):
        for size,name,index in [((32,40),'native',0),((24,30),'gameplay',1)]:
            strip = Image.new('RGB', (size[0]*8,size[1]), '#192b31')
            gif = []
            for frame,(native,game) in enumerate(frames):
                sprite = (native,game)[index]
                strip.paste(sprite,(size[0]*frame,0),sprite)
                bg = Image.new('RGB',size,'#192b31'); bg.paste(sprite,(0,0),sprite); gif.append(bg)
            strip.save(out/f'hero-{hero}-strip-{name}.png')
            strip.resize((strip.width*5,strip.height*5),Image.Resampling.NEAREST).save(out/f'hero-{hero}-strip-{name}-large.png')
            gif[0].save(out/f'hero-{hero}-walk-{name}.gif',save_all=True,append_images=gif[1:],duration=100,loop=0,disposal=2)
    for name in ['walk-artwork.bend','walk-build.py','walk-README.md']:
        shutil.copy2(HERE/name,out/name)
    report = {'scope':'Finite eight-frame frontal cycle for seven heroes. Contact checks use one authoring pixel of reference travel per frame; runtime owns distance-to-phase mapping. Static idle remains the separately selected artwork. Temporal aesthetics are not proved.', 'frames':records,'checks':['56 frames emitted by Bend','selected head exact for every frame','separate boot lanes','bounded sole height','reference stance ground invariant','alternating support','bounded last-to-first sole transition','bottom edge clear'], 'source_sha256':hashlib.sha256((HERE/'walk-artwork.bend').read_bytes()).hexdigest(), 'generated_sha256':hashlib.sha256(source.encode()).hexdigest()}
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    body = ''.join(f'<section><h2>{name}</h2><img src="hero-{hero}-walk-native.gif" width="160" height="200"><img src="hero-{hero}-walk-gameplay.gif" width="24" height="30"><br><img src="hero-{hero}-strip-gameplay-large.png"></section>' for hero,name in enumerate(NAMES))
    (out/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><title>Seven survivor walks</title><style>body{background:#192b31;color:#eee;font:16px system-ui;margin:32px}img{image-rendering:pixelated;margin:12px}a{color:#aee}</style><h1>Shared seven-character walk rig</h1><p>Bend-authored eight-frame frontal cycle. Accepted idle artwork and accessory geometry stay unchanged. Walking uses moving wrists and foreground boots.</p><a href="validation.json">Finite validation</a>'+body+'</html>')
    print(f'PASS: 56 Bend walk frames, seven exact selected heads, native and actual Canvas-scale exports. {out}/index.html')


if __name__ == '__main__':
    main()
