#!/usr/bin/env python3
"""Require type-correct semantic mutations to be rejected by their named law."""
import argparse
import json
import os
from pathlib import Path
import resource
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def bounded():
    resource.setrlimit(resource.RLIMIT_CPU, (10, 10))

def run(args, cwd):
    try:
        return subprocess.run([os.environ.get('BEND', 'bend'), *map(str,args)], cwd=cwd,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              text=True, timeout=60, preexec_fn=bounded)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args, 124, 'wall time limit exceeded')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifests', nargs='*', type=Path)
    args = parser.parse_args()
    manifests = sorted(args.manifests or (ROOT / 'scripts/law-mutants').glob('*.json'))
    if not manifests:
        parser.error('no mutation manifests')
    rows = [row for path in manifests for row in json.loads(path.read_text())]
    failed = []
    with tempfile.TemporaryDirectory(prefix='bend-law-mutants-') as directory:
        snapshot = Path(directory) / 'source'
        shutil.copytree(ROOT / 'examples', snapshot / 'examples',
                        ignore=shutil.ignore_patterns('dist','node_modules','__pycache__'))
        shutil.copytree(ROOT / 'vendor/bendlib/packages/bend-mathlib',
                        snapshot / 'vendor/bendlib/packages/bend-mathlib')
        for row in rows:
            source = snapshot / row['source']
            original = source.read_text()
            ok = False
            try:
                occurrences = row.get('occurrences',1)
                if original.count(row['old']) != occurrences:
                    raise ValueError('mutation must identify its declared number of source occurrences')
                source.write_text(original.replace(row['old'],row['new'],occurrences))
                compiled = run([row.get('compile_target',row['source']), '-o', Path(directory)/'mutant.mjs'],snapshot)
                if compiled.returncode:
                    raise ValueError('mutated core did not typecheck:\n'+compiled.stdout)
                rejected = run([row['proof']], snapshot)
                # A timeout, signal, parse error or unrelated proof failure is not evidence.
                failure = row.get('fails_in',row['law'])
                ok = (rejected.returncode == 1 and 'SOME PROOFS FAIL' in rejected.stdout
                      and ('Location: Laws.'+failure in rejected.stdout
                           or 'Location: L.'+failure in rejected.stdout
                           or 'Location: '+failure in rejected.stdout))
                if not ok:
                    print(rejected.stdout, flush=True)
            except (ValueError, OSError) as error:
                print(str(error), flush=True)
            finally:
                source.write_text(original)
            diagnostic = f' (fails in {row["fails_in"]}; target {row["law"]})' if 'fails_in' in row else ''
            print(f'{"PASS" if ok else "FAIL"} {row["label"]}{diagnostic}', flush=True)
            if not ok:
                failed.append(row['label'])
    print(f'{len(rows)-len(failed)}/{len(rows)} semantic mutants rejected by proof gates',flush=True)
    return bool(failed)

if __name__ == '__main__':
    sys.exit(main())
