#!/usr/bin/env python3
"""Run the Bend generator, inspect its SVG, then render review artifacts."""
import argparse
import copy
import hashlib
import html
import io
import json
from pathlib import Path
import resource
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
NS = '{http://www.w3.org/2000/svg}'
ET.register_namespace('', NS[1:-1])


def limited_cpu():
    resource.setrlimit(resource.RLIMIT_CPU, (10, 10))


def run(args, **kwargs):
    return subprocess.run(args, check=True, timeout=60, preexec_fn=limited_cpu,
                          capture_output=True, text=True, **kwargs)


def component_sizes(image):
    points = {(x, y) for y in range(image.height) for x in range(image.width)
              if image.getpixel((x, y))[3] >= 128}
    sizes = []
    while points:
        pending = [points.pop()]
        size = 0
        while pending:
            x, y = pending.pop()
            size += 1
            for adjacent in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if adjacent in points:
                    points.remove(adjacent)
                    pending.append(adjacent)
        sizes.append(size)
    return sorted(sizes, reverse=True)


def inspect_svg(svg):
    eyes = [node for node in svg.iter(NS+'rect')
            if node.get('fill') == '#101729' and node.get('y') == '27']
    assert len(eyes) == 2, 'Expected two explicit eye primitives'
    assert [(e.get('width'), e.get('height'), e.get('y')) for e in eyes] == [('3','8','27')]*2
    assert [e.get('x') for e in eyes] == ['25','37']
    for node in svg.iter():
        if node.tag == NS+'polyline':
            assert len(node.get('points').split()) == 3, 'Every limb must include its shared joint'
            assert node.get('stroke-linecap') == 'round'
    # Independent serialization check: no unexplained off-canvas coordinates.
    for node in svg.iter(NS+'polygon'):
        for point in node.get('points').split():
            x, y = map(int, point.split(','))
            assert 0 <= x < 64 and 0 <= y < 80


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--reference-root', required=True, type=Path)
    args = parser.parse_args()
    out = args.output.resolve()
    assert not out.is_relative_to(HERE.parents[1]), 'Generated artifacts must stay outside tracked source'
    if out.exists() and any(out.iterdir()):
        raise ValueError('Use a fresh output directory; prior review artifacts are immutable')
    out.mkdir(parents=True, exist_ok=True)
    contract = json.loads((HERE/'reference-contract.json').read_text())
    reference_folder = out/'references'
    reference_folder.mkdir(exist_ok=True)
    reference_images = []
    pilot_references = []
    reference_hashes = {}
    for entry in contract['references']:
        source = args.reference_root.resolve()/entry['path']
        actual_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        if actual_hash != entry['sha256']:
            raise ValueError(f"Reference differs from pinned source: {entry['id']}")
        copied = reference_folder/source.name
        shutil.copy2(source, copied)
        reference_hashes[entry['id']] = actual_hash
        display = copied
        if 'style_crop' in entry:
            display = reference_folder/(entry['id']+'.png')
            Image.open(copied).crop(entry['style_crop']).save(display)
        pilot_references.append((entry['id'], Image.open(copied).convert('RGB').crop(entry['pilot_crop'])))
        reference_images.append(f'<figure><figcaption>{html.escape(entry["role"])}</figcaption><img src="references/{html.escape(display.name)}"></figure>')
    proof = run(['bend', str(HERE/'PROOF.bend'), '--verdict'])
    assert 'ALL PROOFS CHECK' in proof.stdout + proof.stderr
    run(['bend', str(HERE/'validation-tests.bend'), '--verdict'])
    with tempfile.TemporaryDirectory(prefix='nightfall-bend-') as scratch:
        c_file, binary = Path(scratch)/'pilot.c', Path(scratch)/'pilot'
        run(['bend', str(HERE/'generate.bend'), '-o', str(c_file)])
        run(['clang', '-O0', str(c_file), '-o', str(binary), '-lm', '-lpthread'])
        emitted = run([str(binary)]).stdout
    root = ET.fromstring(emitted)
    assert len(root) == 15, 'Seven neutral characters and eight pilot walk frames required'
    (out/'sheet.svg').write_text(emitted)
    (out/'proof-output.txt').write_text(proof.stdout + proof.stderr)
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 18)
    sheet = Image.new('RGB', (1400, 680), '#122126')
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 10), 'BEND GEOMETRY / shared renderer / seven character recipes', fill='#f3d99c', font=font)
    draw.text((20, 350), 'ORANGE PILOT / eight front-walk frames / fixed leg lanes', fill='#f3d99c', font=font)
    frames = []
    checks = []
    for group in root:
        key = group.get('id')
        inner = copy.deepcopy(group)
        inner.attrib.pop('transform')
        sprite = ET.Element(NS+'svg', {'viewBox':'0 0 64 80','width':'64','height':'80'})
        sprite.append(inner)
        inspect_svg(sprite)
        text = ET.tostring(sprite, encoding='unicode')
        (out/f'{key}.svg').write_text(text)
        rgba = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=text.encode()))).convert('RGBA')
        native = rgba.resize((32,40),Image.Resampling.NEAREST)
        rgba.save(out/f'{key}.png')
        native.save(out/f'{key}-native.png')
        components = component_sizes(rgba)
        native_components = component_sizes(native)
        assert len(components) == 1, f'{key}: detached opaque part at authoring resolution'
        assert len(native_components) == 1, f'{key}: detached opaque part at game resolution'
        assert all(rgba.getpixel((32,y))[3] < 128 for y in range(72,79)), f'{key}: merged feet'
        # The visible neutral eye pixels must match the same full rectangle.
        dark = (16,23,41,255)
        for eye_x in (25,37):
            assert all(rgba.getpixel((x,y)) == dark for y in range(27,35) for x in range(eye_x,eye_x+3)), f'{key}: occluded eye'
        checks.append({'id':key,'opaque_components_4_neighbor':len(components),
                       'native_opaque_components_4_neighbor':len(native_components),
                       'equal_visible_eye_rectangles':True,'foot_gap_clear':True})
        if key.startswith('character'):
            i = int(key[-2:])-1
            big = native.resize((192,240),Image.Resampling.NEAREST)
            sheet.paste(big,(i*200+4,45),big)
            sheet.paste(native,(i*200+83,295),native)
            draw.text((i*200+90,325),str(i+1),fill='#b5ccca',font=font)
        else:
            i = int(key[-2:])
            big = native.resize((160,200),Image.Resampling.NEAREST)
            sheet.paste(big,(i*174+4,390),big)
            background = Image.new('RGBA',(256,320),'#122126')
            background.alpha_composite(native.resize((256,320),Image.Resampling.NEAREST))
            frames.append(background.convert('RGB'))
    sheet.save(out/'comparison.png')
    fidelity = Image.new('RGB',(1200,440),'#122126')
    label = ImageDraw.Draw(fidelity)
    for i,(name,reference) in enumerate(pilot_references):
        factor = min(270/reference.width,330/reference.height)
        reference = reference.resize((round(reference.width*factor),round(reference.height*factor)),Image.Resampling.NEAREST)
        fidelity.paste(reference,(i*300+(300-reference.width)//2,65+(330-reference.height)//2))
        label.text((i*300+10,15),name,fill='#f3d99c',font=font)
    current = Image.open(out/'character-03-native.png').convert('RGBA').resize((256,320),Image.Resampling.NEAREST)
    fidelity.paste(current,(922,70),current)
    label.text((910,15),'Bend / current',fill='#f3d99c',font=font)
    fidelity.save(out/'fidelity-comparison.png')
    frames[0].save(out/'orange-front-walk.gif', save_all=True, append_images=frames[1:], duration=110, loop=0, disposal=2)
    # Exercise the checker with damaged artifacts, not success-only fixtures.
    damaged = Image.new('RGBA',(8,8));damaged.putpixel((1,1),(0,0,0,255));damaged.putpixel((6,6),(0,0,0,255))
    assert len(component_sizes(damaged)) == 2
    eye_mutant = copy.deepcopy(sprite)
    changed = [e for e in eye_mutant.iter(NS+'rect') if e.get('fill')=='#101729' and e.get('y')=='27'][0]
    changed.set('height','5')
    try:
        inspect_svg(eye_mutant)
    except AssertionError:
        pass
    else:
        raise AssertionError('Unequal-eye negative control escaped inspection')
    snapshot = out/'source'
    snapshot.mkdir(exist_ok=True)
    for source in HERE.iterdir():
        if source.is_file():
            shutil.copy2(source, snapshot/source.name)
    source_hashes = {p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(HERE.iterdir()) if p.is_file()}
    report={'structural_status':'pass','visual_acceptance':'unreviewed','reference_sha256':reference_hashes,'scope':'Six checked Bend laws plus finite SVG and raster checks. No universal contour or gait proof.',
            'source_sha256':source_hashes,'checks':checks,
            'negative_controls':['detached opaque pixel rejected','unequal eye height rejected'],
            'walk_scope':'Front-facing lift study only. No side view, travel-distance synchronization, or world-space stance lock.'}
    (out/'validation.json').write_text(json.dumps(report,indent=2))
    review = {'artifact_sha256':hashlib.sha256((out/'comparison.png').read_bytes()).hexdigest(),
              'artifact_sha256_by_file':{name:hashlib.sha256((out/name).read_bytes()).hexdigest() for name in ('comparison.png','fidelity-comparison.png','character-03.svg','orange-front-walk.gif')},
              'reference_sha256':reference_hashes,'status':'unreviewed',
              'axes':{axis:{'verdict':'unreviewed','evidence':''} for axis in contract['review_axes']}}
    (out/'style-review.json').write_text(json.dumps(review,indent=2))
    (out/'index.html').write_text('''<!doctype html><meta charset="utf-8"><title>Nightfall Bend pilot</title><style>body{background:#122126;color:#e0ebe7;font:18px system-ui;margin:30px}img{max-width:100%;image-rendering:pixelated}a{color:#86dad6}</style><h1>Nightfall · Bend geometry pilot</h1><p>Structural checks passed. Style fidelity is UNREVIEWED. Compare against the pinned references below before acceptance.</p><h2>Pilot against fixed references</h2><img src="fidelity-comparison.png"><details><summary>Full reference sheets</summary>REFERENCE_IMAGES</details><h2>Current result</h2><p>Seven shared-style recipes. Orange is the first visual pilot; the other six remain family previews.</p><img src="comparison.png"><h2>Front-walk study</h2><img src="orange-front-walk.gif"><p>Joint-connected feet in fixed lanes. This is a front-facing lift study, not a complete locomotion model.</p><p><a href="character-03.svg">Orange SVG</a> · <a href="validation.json">Validation and source hashes</a> · <a href="proof-output.txt">Bend proof checker output</a></p>'''.replace('REFERENCE_IMAGES',''.join(reference_images)))
    print(f'Wrote {out}: structural checks passed; style acceptance remains UNREVIEWED.')


if __name__ == '__main__':
    main()
