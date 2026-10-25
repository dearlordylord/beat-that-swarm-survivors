#!/usr/bin/env python3
"""Discover and kernel-check every example proof under fixed resource budgets."""
import argparse
import os
from pathlib import Path
import resource
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def bounded():
    resource.setrlimit(resource.RLIMIT_CPU, (10, 10))

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
        result = subprocess.run([os.environ.get('BEND','bend'), str(control), '--verdict'],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                                env=environment, timeout=60, preexec_fn=bounded)
        if result.returncode == 0 or 'ALL PROOFS CHECK' in result.stdout:
            print('FAIL kernel refusal control', flush=True)
            return 1
        control.write_text('import Base\ndef unsafe_claim?() -> {0n == 1n : Nat}: unsafe_claim()\nlaw control: {0n == 1n : Nat}\ndef control(): unsafe_claim()\n')
        result = subprocess.run([os.environ.get('BEND','bend'), str(control), '--verdict'],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                                timeout=60, preexec_fn=bounded)
        if result.returncode != 1 or 'unsafe' not in result.stdout or 'SOME PROOFS FAIL' not in result.stdout:
            print('FAIL unsafe-proof refusal control\n'+result.stdout, flush=True)
            return 1
        print('PASS kernel and unsafe-proof refusal controls', flush=True)
    passed = 0
    for path in proofs:
        try:
            result = subprocess.run([os.environ.get('BEND', 'bend'), str(path), '--verdict'],
                                    cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    text=True, timeout=60, preexec_fn=bounded)
            ok = result.returncode == 0 and 'ALL PROOFS CHECK' in result.stdout
            output = result.stdout
        except subprocess.TimeoutExpired:
            ok, output = False, 'wall time limit exceeded (60 seconds)'
        label = str(path.relative_to(ROOT)) if path.is_absolute() else str(path)
        print(f'{"PASS" if ok else "FAIL"} {label}', flush=True)
        if ok:
            passed += 1
        else:
            failed.append(label)
            print(output, flush=True)
    print(f'{passed}/{len(proofs)} proof files passed', flush=True)
    return bool(failed)

if __name__ == '__main__':
    sys.exit(main())
