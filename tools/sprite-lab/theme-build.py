#!/usr/bin/env python3
"""Render authored Bend geometry and export matching browser/native pixel layers."""
import argparse
import copy
import hashlib
import html
import io
import json
from pathlib import Path
import re
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
import cairosvg
from PIL import Image, ImageDraw, ImageFont
from build import HERE, NS, component_sizes, inspect_svg, run

ROOT = HERE.parents[1]
NAMES = ['RM', 'Jin', 'SUGA', 'j-hope', 'Jimin', 'V', 'Jung Kook']
MOTIFS = ['Indigo / KOYA plush', 'Cream / RJ plush',
          'Charcoal / SHOOKY cookie', 'Ochre / masked MANG plush',
          'Pearl / CHIMMY plush', 'Burgundy / TATA plush',
          'Gold / COOKY plush']


def pixel_layers(image, palette):
    result = Image.new('RGBA', image.size)
    layers = {}
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if a >= 128:
                color = min(palette, key=lambda c: sum((c[i] - (r, g, b)[i]) ** 2 for i in range(3)))
                result.putpixel((x, y), (*color, 255))
    for y in range(result.height):
        x = 0
        while x < result.width:
            color = result.getpixel((x, y))
            if color[3] == 0:
                x += 1
                continue
            start = x
            while x < result.width and result.getpixel((x, y)) == color:
                x += 1
            key = '#%02x%02x%02x' % color[:3]
            layers.setdefault(key, []).append(f'M{start} {y}h{x-start}v1h{start-x}z')
    return result, [[color, ''.join(paths)] for color, paths in layers.items()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    out = args.output.resolve()
    assert not out.is_relative_to(ROOT), 'Previews must stay outside tracked source'
    if out.exists() and any(out.iterdir()):
        raise ValueError('Use a fresh output folder')
    out.mkdir(parents=True, exist_ok=True)
    proof = run(['bend', str(HERE/'PROOF.bend'), '--verdict'])
    assert 'ALL PROOFS CHECK' in proof.stdout + proof.stderr
    run(['bend', str(HERE/'validation-tests.bend'), '--verdict'])
    with tempfile.TemporaryDirectory(prefix='survivors-theme-') as scratch:
        c_file, binary = Path(scratch)/'theme.c', Path(scratch)/'theme'
        run(['bend', str(HERE/'theme-generate.bend'), '-o', str(c_file)])
        run(['clang', '-O0', str(c_file), '-o', str(binary), '-lm', '-lpthread'])
        emitted = run([str(binary)]).stdout
    (out/'sheet.svg').write_text(emitted)
    root = ET.fromstring(emitted)
    assert len(root) == len(NAMES)
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 24)
    smallfont = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    contact = Image.new('RGB', (1400, 510), '#122126')
    draw = ImageDraw.Draw(contact)
    draw.text((20, 12), 'NIGHTFALL / THEMED SEVEN / BEND GEOMETRY', font=font, fill='#f3d99c')
    cards, checks, all_layers = [], [], []
    for id, group in enumerate(root):
        inner = copy.deepcopy(group)
        inner.attrib.pop('transform')
        sprite = ET.Element(NS+'svg', {'viewBox':'0 0 64 80', 'width':'64', 'height':'80'})
        sprite.append(inner)
        inspect_svg(sprite)
        svg = ET.tostring(sprite, encoding='unicode')
        (out/f'character-{id}.svg').write_text(svg)
        rgba = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert('RGBA')
        dark = (16, 23, 41, 255)
        for eye_x in (25, 37):
            assert all(rgba.getpixel((x, y)) == dark for y in range(27, 35) for x in range(eye_x, eye_x+3)), f'{NAMES[id]} visible eye occluded'
        rgba.save(out/f'character-{id}.png')
        palette = sorted(set(tuple(bytes.fromhex(c)) for c in re.findall(r'#([0-9a-fA-F]{6})', svg)))
        native, layers = pixel_layers(rgba.resize((32, 40), Image.Resampling.NEAREST), palette)
        assert len(component_sizes(rgba)) == 1, f'{NAMES[id]} authoring silhouette disconnected'
        assert len(component_sizes(native)) == 1, f'{NAMES[id]} game silhouette disconnected'
        assert all(native.getpixel((16, y))[3] == 0 for y in range(36, 40)), 'Feet must stay separated'
        native.save(out/f'character-{id}-native.png')
        selection = json.loads((HERE/'theme-selection.json').read_text())
        assert hashlib.sha256((out/f'character-{id}-native.png').read_bytes()).hexdigest() == selection['approved_native_png_sha256'][str(id)], 'Production art differs from selected variant D'
        all_layers.append(layers)
        draw.text((id*200+45, 58), NAMES[id], font=font, fill='#e9eedf')
        contact.paste(native.resize((192, 240), Image.Resampling.NEAREST), (id*200+4, 105), native.resize((192, 240), Image.Resampling.NEAREST))
        contact.paste(native, (id*200+84, 365), native)
        for n, line in enumerate(MOTIFS[id].split(' / ')):
            draw.text((id*200+10, 420+n*22), line, font=smallfont, fill='#a8beb9')
        checks.append({'id':id, 'name':NAMES[id], 'authoring_components':1, 'native_components':1,
                       'shared_eyes':[3,8], 'native_palette_size':len(layers)})
        cards.append(f'<figure><h2>{html.escape(NAMES[id])}</h2><img src="character-{id}-native.png" width="192" height="240"><p>{html.escape(MOTIFS[id])}</p><a href="character-{id}.svg">Bend SVG</a></figure>')
    contact.save(out/'contact-sheet.png')
    header = '// Generated from tools/sprite-lab/theme-artwork.bend by theme-build.py.\n'
    header += 'import { at } from "./host-values.mts"\nexport type SurvivorLayers = readonly (readonly [string, string])[]\n'
    body = 'const survivors: readonly SurvivorLayers[] = [\n'
    for index, (name, layers) in enumerate(zip(NAMES, all_layers)):
        body += f'  // {name}\n  [\n'
        formatted = []
        for layer in layers:
            inline = '    '+json.dumps(layer, separators=(', ', ': '))
            formatted.append(inline if len(inline) < 120 else '    [\n      '+json.dumps(layer[0])+',\n      '+json.dumps(layer[1])+'\n    ]')
        body += ',\n'.join(formatted)
        body += '\n  ]'+(',' if index < len(NAMES)-1 else '')+'\n'
    body += ']\n\nexport const survivorCount = survivors.length\n\nexport function survivorLayers(id = 0) {\n'
    body += '  return at(survivors, Number.isInteger(id) && id >= 0 && id < survivorCount ? id : 0)\n}\n'
    target = ROOT/'examples/survivors/survivor-shapes.mts'
    content = header+body
    if args.check:
        assert target.read_text() == content, 'Production art stale; run theme-build.py without --check'
    else:
        target.write_text(content)
    snapshot = out/'source'
    snapshot.mkdir()
    sources = ['theme-artwork.bend','accessories.bend','accessories-native.bend','theme-selection.json','theme-generate.bend','theme-build.py','model.bend','artwork.bend','validation.bend','LAWS.bend','PROOF.bend']
    for source in sources:
        shutil.copy2(HERE/source, snapshot/source)
    selected = Path('/workspace/survivors-nightfall-art/bend-pilot/review-06-fidelity/character-03-native.png')
    if selected.exists():
        shutil.copy2(selected, out/'accepted-style-pilot.png')
    (out/'validation.json').write_text(json.dumps({'checks':checks, 'proofs':proof.stdout+proof.stderr,
        'production_sha256':hashlib.sha256(content.encode()).hexdigest(), 'visual_review':'user-selected-variant-D-see-theme-selection.json',
        'scope':'Seven thematic interpretations. No new locomotion cycle or real-person likeness claim.'}, indent=2)+'\n')
    (out/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>Nightfall themed seven</title><style>body{background:#122126;color:#e9eedf;font:16px system-ui;margin:32px}main{display:flex;flex-wrap:wrap}figure{margin:12px;padding:16px;background:#1b3037}img{image-rendering:pixelated}a{color:#d6c493}</style><h1>Nightfall themed seven</h1><p>Shared Bend face, outline, joints and silhouette construction. User-selected accessory variant D, integrated into browser and native game art. Walking retains the current game presentation.</p><a href="contact-sheet.png">Open contact sheet</a><main>'+''.join(cards)+'</main><h2>Accepted style reference</h2><img src="accepted-style-pilot.png" width="192" height="240">')
    (out/'README.md').write_text('# Nightfall themed seven\n\nOpen on the Mac:\n\n```sh\nopen /Users/firfi/work/survivors-bts-art/index.html\n```\n\nSeven human chibi interpretations, not portrait likenesses. Shared construction follows the accepted Nightfall pilot. Native export samples the authored Bend SVG on the 32x40 game grid, maps anti-aliased samples to authored colors, then serializes exact color row runs. Browser and native consume the same pixel geometry. This pass does not change the walk cycle. Independent visual review is recorded separately.\n')
    print(f'Exported {len(NAMES)} matching production sprites and review page to {out}')


if __name__ == '__main__':
    main()
