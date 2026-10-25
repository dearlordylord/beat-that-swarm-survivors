#!/usr/bin/env python3
"""Source-check actual game grants; callers serialize with the shared check lock."""
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import shutil
import subprocess
import tempfile
import time

HERE = Path(__file__).resolve().parent
GAME = HERE / 'game.bend'
SOURCE = GAME.read_text()
BEND = os.environ.get('BEND', 'bend')


def imported(alias):
    match = re.search(r'^import (bendvy-ecs-core@[^ ]+) as ' + alias + r'$', SOURCE, re.M)
    if not match:
        raise AssertionError(f'game must import its published {alias} dependency')
    return match.group(1)


def cpu_bound():
    resource.setrlimit(resource.RLIMIT_CPU, (10, 10))


# Each refusal uses the same actual game accessor as its accepted control.
# The opaque H and Ops(H) remain universally quantified, as in gameplay bodies.
CASES = [
    ('movement-spatial-health', 'MoveOps', 'move_spatial_cap', 'Space.Spatial',
     'write', 'G.Vitals', 'cross-family'),
    ('movement-metadata-read', 'MoveOps', 'move_body_cap', 'G.Body',
     'read', 'G.Body', 'read-to-write'),
    ('movement-spatial-identity', 'MoveOps', 'move_spatial_cap', 'Space.Spatial',
     'write', 'G.Body', 'cross-family'),
    ('movement-spatial-pickup', 'MoveOps', 'move_spatial_cap', 'Space.Spatial',
     'write', 'G.Pickup', 'cross-family'),
    ('movement-status-read', 'MoveOps', 'move_status_cap', 'G.Status',
     'read', 'G.Status', 'read-to-write'),
    ('pickup-body-read', 'PickupOps', 'pickup_body_cap', 'G.Body',
     'read', 'G.Body', 'read-to-write'),
    ('pickup-payload-read', 'PickupOps', 'pickup_payload_cap', 'G.Pickup',
     'read', 'G.Pickup', 'read-to-write'),
    ('projectile-role-read', 'ProjectileOps', 'projectile_role_cap', 'Role.Role',
     'read', 'Role.Role', 'read-to-write'),
    ('projectile-body-family', 'ProjectileOps', 'projectile_body_cap', 'G.Body',
     'write', 'G.Vitals', 'cross-family'),
]


def module(directory, case, negative):
    _, ops, accessor, field, positive, rejected, _ = case
    component = rejected if negative else field
    header = '\n'.join([
        'import Base',
        f'import {Path(os.path.relpath(HERE / "enemy-spatial.bend", directory)).as_posix()} as Space',
        f'import {Path(os.path.relpath(GAME, directory)).as_posix()} as G',
        f'import {Path(os.path.relpath(HERE / "entity-role.bend", directory)).as_posix()} as Role',
        f'import {imported("Cap")} as Cap',
        f'import {imported("C")} as C',
        '',
    ])
    grant = f'~G.{accessor}(~H,ops)'
    if not negative and positive == 'read':
        signature = f'def control(~H: Type,~ops: G.{ops}<H>,ctx: H,value: {field}) -> H & C.Access<{field}>:'
        body = f'Cap.read(~H,~{field},{grant},ctx)'
    else:
        signature = f'def control(~H: Type,~ops: G.{ops}<H>,ctx: H,value: {component}) -> H:'
        body = f'Cap.set(~H,~{component},~{component},{grant},ctx,value)'
    return header + signature + '\n  ' + body + '\n'


def check(directory, name, source):
    path = directory / f'{name}.bend'
    path.write_text(source)
    started = time.monotonic()
    result = subprocess.run([BEND, str(path), '--check-only'], cwd=HERE,
                            capture_output=True, text=True, timeout=60,
                            preexec_fn=cpu_bound)
    diagnostic = result.stdout + result.stderr
    (directory / f'{name}.log').write_text(diagnostic)
    return {'exitCode': result.returncode, 'elapsedSeconds': time.monotonic() - started,
            'sourceSha256': hashlib.sha256(source.encode()).hexdigest(),
            'source': str(path), 'log': str(directory / f'{name}.log')}, diagnostic


def refuse(diagnostic, case):
    # Restrict rejection to the intended term, type mismatch and constructors.
    # Parse/import/arity/affine failures do not qualify an authority boundary.
    _, _, accessor, field, _, rejected, reason = case
    assert 'Location: control' in diagnostic, diagnostic
    assert re.search(r'expected\s*:', diagnostic), diagnostic
    assert re.search(r'observed\s*:', diagnostic), diagnostic
    assert accessor in diagnostic, diagnostic
    assert not re.search(r'consumed more than once|unfilled|not found|unknown|parse error|expected.*argument',
                         diagnostic, re.I), diagnostic
    expected = re.search(r'expected\s*:\s*([^\n]+)', diagnostic).group(1)
    observed = re.search(r'observed\s*:\s*([^\n]+)', diagnostic).group(1)
    if reason == 'read-to-write':
        assert re.search(r'\bWrite\b', expected) and re.search(r'\bRead\b', observed), diagnostic
    else:
        assert re.search(r'\bWrite\b', expected) and re.search(r'\bWrite\b', observed), diagnostic
        assert rejected.split('.')[-1] in expected and field.split('.')[-1] in observed, diagnostic


def main():
    destination = os.environ.get('SURVIVORS_AUTHORITY_OUTPUT')
    if destination:
        directory = Path(destination).resolve()
        directory.mkdir(parents=True, exist_ok=False)
    else:
        directory = Path(tempfile.mkdtemp(prefix='survivors-authority-'))
    receipt = {'status': 'INCOMPLETE', 'gameSha256': hashlib.sha256(GAME.read_bytes()).hexdigest(),
               'compiler': shutil.which(BEND), 'cpuSecondsPerCheck': 10, 'wallSecondsPerCheck': 60,
               'dependency': imported('Cap'), 'checks': []}
    try:
        for case in CASES:
            name = case[0]
            accepted, positive_log = check(directory, name + '-positive', module(directory, case, False))
            assert accepted['exitCode'] == 0, positive_log
            rejected, negative_log = check(directory, name + '-negative', module(directory, case, True))
            assert rejected['exitCode'] == 1, negative_log
            refuse(negative_log, case)
            receipt['checks'].append({'case': name, 'positive': accepted, 'negative': rejected,
                                      'boundary': case[-1]})
            print(f'PASS {name}: accepted grant use, rejected {case[-1]}', flush=True)
        assert receipt['gameSha256'] == hashlib.sha256(GAME.read_bytes()).hexdigest(), 'game changed during controls'
        receipt['status'] = 'PASS'
    finally:
        (directory / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
        if not destination:
            shutil.rmtree(directory)
    print('PASS game authority: paired actual Ops accessors reject unauthorized writes')


if __name__ == '__main__':
    main()
