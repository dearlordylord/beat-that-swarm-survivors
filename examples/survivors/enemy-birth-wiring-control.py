#!/usr/bin/env python3
"""Compile a production-callsite mutant and require the actual birth fixture to reject it."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
FAILURE = 'enemy birth must clear previous status/contact/killer'
CALL = 'case True{}: Enemy.Resolved{Enemy.Born{EnemyLife.birth(candidate)}}'
MUTANT = 'case True{}: Enemy.Resolved{Enemy.Born{enemy_reused_birth(previous,candidate)}}'
HELPER = '''def enemy_reused_birth(previous: Enemy.State,candidate: EnemyLife.Candidate) -> EnemyLife.Newborn:
  match previous:
    case Enemy.State{_,_,_,_,status}: EnemyLife.Newborn{candidate,0,status,1,Some{0}}
'''


def bounded():
    resource.setrlimit(resource.RLIMIT_CPU, (10, 10))


def run(command, *, environment=None):
    result = subprocess.run(command, env=environment, capture_output=True, text=True,
                            timeout=60, preexec_fn=bounded)
    return result.returncode, result.stdout + result.stderr


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='retain receipt/logs in a new directory outside the repository')
    args = parser.parse_args()
    destination = args.output.resolve() if args.output else None
    if destination:
        if destination.is_relative_to(REPO):
            parser.error('generated control artifacts must be outside the repository')
        destination.mkdir(parents=True, exist_ok=False)
    source = (HERE / 'game.bend').read_bytes()
    receipt = dict(status='INCOMPLETE', sourceSha256=hashlib.sha256(source).hexdigest(),
                   cpuSecondsPerProcess=10, wallSecondsPerProcess=60, checks={})
    logs = {}
    try:
        with tempfile.TemporaryDirectory(prefix='survivors-enemy-birth-wiring-') as scratch:
            root = Path(scratch)
            app = root / 'examples' / 'survivors'
            for path in HERE.rglob('*.bend'):
                if 'dist' in path.relative_to(HERE).parts:
                    continue
                copied = app / path.relative_to(HERE)
                copied.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, copied)
            (root / 'vendor').symlink_to(REPO / 'vendor', target_is_directory=True)
            game = app / 'game.bend'
            pristine = root / 'pristine.mjs'
            mutated = root / 'mutant.mjs'
            for label, module in [('pristine', pristine), ('mutant', mutated)]:
                if label == 'mutant':
                    text = game.read_text()
                    if text.count(CALL) != 1 or text.count('def team_enemy_birth_allowed(') != 1:
                        raise AssertionError('production enemy birth callsite changed; update the explicit wiring control')
                    text = text.replace(CALL, MUTANT).replace('def team_enemy_birth_allowed(', HELPER + 'def team_enemy_birth_allowed(')
                    game.write_text(text)
                code, log = run([os.environ.get('BEND', 'bend'), str(game), '-o', str(module)])
                logs[label + '-compile.log'] = log
                receipt['checks'][label + 'CompileExit'] = code
                if code != 0:
                    raise AssertionError(f'{label} must compile successfully; compiler rejection does not detect this wiring mutant\n{log}')
                environment = dict(os.environ, COOP_GAME_MODULE=str(module))
                code, log = run([os.environ.get('NODE', 'node'), str(HERE / 'enemy-birth-check.mjs')], environment=environment)
                logs[label + '-fixture.log'] = log
                receipt['checks'][label + 'FixtureExit'] = code
                if label == 'pristine':
                    if code != 0 or 'PASS production enemy birth admission' not in log:
                        raise AssertionError(f'pristine production fixture must pass\n{log}')
                elif code != 1 or 'AssertionError' not in log or FAILURE not in log:
                    raise AssertionError(f'compiled mutant must fail the named birth assertion; import/runtime failures do not qualify\n{log}')
            if (HERE / 'game.bend').read_bytes() != source:
                raise AssertionError('production Game source changed during the isolated control')
            receipt['status'] = 'PASS'
    finally:
        if destination:
            for name, log in logs.items():
                (destination / name).write_text(log)
            (destination / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print('PASS production enemy birth wiring: pristine passes; compiled stale-status/contact/killer mutant rejected')


if __name__ == '__main__':
    main()
