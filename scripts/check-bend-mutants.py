#!/usr/bin/env python3
"""Require type-correct semantic mutations to be rejected by their named law."""
import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

from process_diagnostics import format_failure, run_process

ROOT = Path(__file__).resolve().parents[1]

def run(args, cwd):
    return run_process([os.environ.get('BEND', 'bend'), *args], cwd=cwd, wall_timeout_seconds=60, cpu_limit_seconds=10)

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
        control = Path(directory) / 'typecheck-control.bend'
        control.write_text('import Base\ndef control() -> Nat: 0n\n')
        valid = run([control, '--check-only'], ROOT)
        control.write_text('import Base\ndef control() -> Nat: True{}\n')
        invalid = run([control, '--check-only'], ROOT)
        if (not valid.normal_exit or not invalid.normal_exit
                or valid.returncode != 0 or invalid.returncode != 1):
            print('FAIL check-only typechecking controls', flush=True)
            print(format_failure(valid, "valid typechecking control requires exit 0"), flush=True)
            print(format_failure(invalid, "invalid typechecking control requires exit 1"), flush=True)
            return 1
        print('PASS check-only accepts valid and rejects ill-typed bodies', flush=True)
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
                # Check the complete declared caller/import graph without paying
                # for unused JS emission. Proof checking keeps its fixed limits.
                compiled = run([row.get('compile_target',row['source']), '--check-only'],snapshot)
                if not compiled.normal_exit or compiled.returncode != 0:
                    raise ValueError(format_failure(compiled, "mutated core must typecheck with exit 0"))
                rejected = run([row['proof']], snapshot)
                # A timeout, signal, parse error or unrelated proof failure is not evidence.
                failure = row.get('fails_in',row['law'])
                ok = (rejected.normal_exit and rejected.returncode == 1 and 'SOME PROOFS FAIL' in rejected.output
                      and ('Location: Laws.'+failure in rejected.output
                           or 'Location: L.'+failure in rejected.output
                           or 'Location: '+failure in rejected.output))
                if not ok:
                    print(format_failure(rejected, f"mutant requires exit 1, SOME PROOFS FAIL and named law {failure}"), flush=True)
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
