#!/usr/bin/env python3
"""Require the real proof gate and generator to reject damaged geometry."""
from pathlib import Path
import resource
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent


def cpu_limit():
    resource.setrlimit(resource.RLIMIT_CPU, (10,10))


def run(args):
    return subprocess.run(args, capture_output=True, text=True, timeout=60, preexec_fn=cpu_limit)


def copy_sources(destination):
    for path in HERE.glob('*.bend'):
        shutil.copy2(path, destination/path.name)


def proof_rejects(old, new, name):
    with tempfile.TemporaryDirectory(prefix='nightfall-mutant-') as scratch:
        root = Path(scratch)
        copy_sources(root)
        model = root/'model.bend'
        source = model.read_text()
        assert source.count(old) == 1
        model.write_text(source.replace(old,new))
        result = run(['bend', str(root/'PROOF.bend'), '--verdict'])
        assert result.returncode != 0 and 'SOME PROOFS FAIL' in result.stdout+result.stderr, name
        assert 'Error:' in result.stdout+result.stderr, name
        return {'mutant':name,'rejected':True,'output':result.stdout+result.stderr}


def main():
    reports=[]
    gate=runpy.run_path(str(HERE/'check_review.py'))
    complete={axis:{'verdict':'pass','evidence':'Observed against pinned references'} for axis in gate['AXES']}
    assert gate['accepted'](complete)
    for axis in gate['AXES']:
        for verdict in ('fail','unreviewed'):
            assert not gate['accepted']({**complete,axis:{'verdict':verdict,'evidence':'Mismatch or missing observation'}})
        assert not gate['accepted']({**complete,axis:{'verdict':'pass','evidence':''}})
    assert not gate['accepted']({})
    reports.append({'mutant':'failed, unreviewed, missing, or evidence-free style assessment','rejected':True})
    reports.append(proof_rejects(
        'def eye_width_right(pair: EyePair) -> Nat:\n  EyePair{left, right, width, height} = pair\n  width',
        'def eye_width_right(pair: EyePair) -> Nat:\n  EyePair{left, right, width, height} = pair\n  Nat.add(width, 1n)',
        'right eye width differs'))
    reports.append(proof_rejects(
        'def right_start(limb: Limb) -> Point:\n  Limb{root, knee, tip} = limb\n  knee',
        'def right_start(limb: Limb) -> Point:\n  Limb{root, knee, tip} = limb\n  tip',
        'lower segment starts at ankle instead of knee'))
    with tempfile.TemporaryDirectory(prefix='nightfall-invalid-') as scratch:
        root=Path(scratch)
        copy_sources(root)
        artwork=root/'artwork.bend'
        source=artwork.read_text()
        assert source.count('case 2n: Pose{0n, 2n, 2n, 1n}')==1
        artwork.write_text(source.replace('case 2n: Pose{0n, 2n, 2n, 1n}', 'case 2n: Pose{0n, 3n, 2n, 1n}'))
        emitted=run(['bend',str(root/'generate.bend'),'-o',str(root/'generator.c')])
        assert emitted.returncode==0, emitted.stdout+emitted.stderr
        compiled=run(['clang','-O0',str(root/'generator.c'),'-o',str(root/'generator'),'-lm','-lpthread'])
        assert compiled.returncode==0, compiled.stderr
        result=run([str(root/'generator')])
        assert result.returncode!=0 and not result.stdout.strip(), result.stdout+result.stderr
        assert 'Sprite geometry invalid' in result.stderr, result.stderr
        reports.append({'mutant':'excessive authored foot lift','rejected':True,'output':result.stderr})
    import json
    print(json.dumps(reports,indent=2))


if __name__=='__main__':
    main()
