#!/usr/bin/env python3
"""Discover and kernel-check every example proof under fixed resource budgets."""
import argparse
import os
from pathlib import Path
import re
import sys
import tempfile

from process_diagnostics import format_failure, format_usage, run_process

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('paths', nargs='*', type=Path)
    args = parser.parse_args()
    proofs = sorted(args.paths or [p for p in (ROOT / 'examples').rglob('*.bend')
                                  if 'proof' in p.stem.lower() and 'dist' not in p.parts])
    if not proofs:
        parser.error('no proof files discovered')
    failed = []
    if not args.paths:
        for laws in (ROOT / 'examples').rglob('*.bend'):
            if 'laws' not in laws.stem.lower() or 'dist' in laws.parts:
                continue
            expected = laws.name.lower().replace('laws','proof')
            paired = next((p for p in laws.parent.glob('*.bend') if p.name.lower() == expected),None)
            if paired is None:
                failed.append(str(laws.relative_to(ROOT)))
                print(f'FAIL no proof entrypoint for {laws.relative_to(ROOT)}', flush=True)
            else:
                imports = re.findall(r'^\s*import\s+(\S+)',paired.read_text(),re.MULTILINE)
                if not any((paired.parent / target.strip('"')).resolve() == laws.resolve() for target in imports):
                    failed.append(str(laws.relative_to(ROOT)))
                    print(f'FAIL {paired.relative_to(ROOT)} does not import its paired laws',flush=True)
    # Prove the kernel is actually invoked, and unsafe proofs cannot pass the gate.
    with tempfile.TemporaryDirectory(prefix='bend-proof-controls-') as directory:
        control = Path(directory) / 'control.bend'
        control.write_text('import Base\nlaw control: {0n == 0n : Nat}\ndef control(): {==}\n')
        environment = dict(os.environ, BENDTT='/usr/bin/false')
        result = run_process([os.environ.get('BEND','bend'), control, '--verdict'],
                             cwd=ROOT, env=environment, wall_timeout_seconds=60, cpu_limit_seconds=10)
        if (not result.normal_exit or result.returncode != 1 or 'ALL PROOFS CHECK' in result.output
                or 'BendTT infrastructure: kernel exited 1 without a verdict' not in result.output):
            print('FAIL kernel refusal control', flush=True)
            print(format_failure(result, 'kernel refusal requires exit 1 and the controlled BendTT infrastructure diagnostic'), flush=True)
            return 1
        control.write_text('import Base\ndef unsafe_claim?() -> {0n == 1n : Nat}: unsafe_claim()\nlaw control: {0n == 1n : Nat}\ndef control(): unsafe_claim()\n')
        result = run_process([os.environ.get('BEND','bend'), control, '--verdict'], cwd=ROOT, wall_timeout_seconds=60, cpu_limit_seconds=10)
        if (not result.normal_exit or result.returncode != 1 or 'unsafe' not in result.output
                or 'SOME PROOFS FAIL' not in result.output):
            print('FAIL unsafe-proof refusal control', flush=True)
            print(format_failure(result, 'unsafe refusal requires exit 1 and unsafe/SOME PROOFS FAIL diagnostics'), flush=True)
            return 1
        print('PASS kernel and unsafe-proof refusal controls', flush=True)
    passed = 0
    for path in proofs:
        result = run_process([os.environ.get('BEND', 'bend'), path, '--verdict'], cwd=ROOT, wall_timeout_seconds=60, cpu_limit_seconds=10)
        ok = result.normal_exit and result.returncode == 0 and 'ALL PROOFS CHECK' in result.output
        label = str(path.relative_to(ROOT)) if path.is_absolute() else str(path)
        timing = f' ({format_usage(result)})' if ok else ''
        print(f'{"PASS" if ok else "FAIL"} {label}{timing}', flush=True)
        if ok:
            passed += 1
        else:
            failed.append(label)
            print(format_failure(result, "proof requires exit 0 and ALL PROOFS CHECK"), flush=True)
    print(f'{passed}/{len(proofs)} proof files passed', flush=True)
    return bool(failed)

if __name__ == '__main__':
    sys.exit(main())
