#!/usr/bin/env python3
"""Audit example import graphs; this JSON manifest is repository metadata, not a Bend lockfile."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parent.parent
IMPORT = re.compile(r'^\s*import\s+(?:"([^"]+)"|([^\s#]+))', re.MULTILINE)

def audit(online=False):
    config = json.loads((ROOT / 'bendhub-dependencies.json').read_text())
    packages = config['packages']
    errors = []
    files = sorted((ROOT / 'examples').rglob('*.bend'))
    graph, external = {}, set()
    mathlib = ROOT / 'vendor/bendlib/packages/bend-mathlib'
    def proof_source(path):
        return 'proof' in path.stem.lower() or 'laws' in path.stem.lower()
    for source in files:
        graph[source] = []
        for match in IMPORT.finditer(source.read_text()):
            target = match.group(1) or match.group(2)
            if target == 'Base':
                continue
            package = next((name for name in packages if target.startswith(name + '/')), None)
            if package:
                module = target[len(package) + 1:]
                if not module.endswith('.bend') or '..' in Path(module).parts:
                    errors.append(f'{source.relative_to(ROOT)}: invalid Hub module {target}')
                external.add(source)
                continue
            local = (source.parent / target).resolve()
            if local.is_relative_to(mathlib) and local.is_file() and 'proof' in source.stem.lower():
                # Only proof modules may consume the pinned theorem library.
                graph[source].append(local)
                continue
            if not local.is_relative_to(ROOT / 'examples') or not local.is_file():
                errors.append(f'{source.relative_to(ROOT)}: use a declared BendHub package or local example module: {target}')
            else:
                graph[source].append(local)
    def reaches_hub(source, seen):
        if source in external:
            return True
        if source in seen:
            return False
        return any(reaches_hub(child, seen | {source}) for child in graph.get(source, []))
    def reaches_proof(source, seen):
        if proof_source(source) or source.is_relative_to(mathlib):
            return True
        if source in seen:
            return False
        return any(reaches_proof(child, seen | {source}) for child in graph.get(source, []))
    for source in files:
        if not proof_source(source) and reaches_proof(source, set()):
            errors.append(f'{source.relative_to(ROOT)}: runtime modules must not import proofs or mathlib')
        # Art/content helpers may use only Base; each example as a whole must consume Hub ECS.
        if source.parent.name == 'ecs':
            errors.append(f'Vendored ECS directory: {source.parent.relative_to(ROOT)}')
    examples = sorted(path for path in (ROOT / 'examples').iterdir() if path.is_dir() and list(path.glob('*.bend')))
    for example in examples:
        if not any(reaches_hub(source, set()) for source in example.glob('*.bend')):
            errors.append(f'{example.relative_to(ROOT)} does not consume the declared BendHub distribution')
    for source in (ROOT / 'examples').glob('*.bend'):
        if not reaches_hub(source, set()):
            errors.append(f'{source.relative_to(ROOT)} does not consume the declared BendHub distribution')
    if online:
        for name, pin in packages.items():
            registry = config['registry'].rstrip('/')
            with urlopen(registry + '/name/' + name, timeout=20) as response:
                actual = response.read().decode().strip()
            if actual != pin['contentHash']:
                errors.append(f'{name}: registry resolves {actual}, expected {pin["contentHash"]}')
            with urlopen(registry + '/' + pin['contentHash'] + '/manifest', timeout=20) as response:
                manifest = response.read()
            if hashlib.sha256(manifest).hexdigest() != pin['manifestSha256']:
                errors.append(f'{name}: published manifest hash differs from the recorded pin')
    if errors:
        raise ValueError('\n'.join(errors))
    print(f'BendHub dependency audit PASS: {len(examples)} example(s), {len(files)} Bend modules; no source-checkout imports.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--registry', action='store_true', help='also verify immutable public name/manifest bindings')
    try:
        audit(parser.parse_args().registry)
    except Exception as error:
        print(f'Dependency audit failed: {error}', file=sys.stderr)
        sys.exit(1)
