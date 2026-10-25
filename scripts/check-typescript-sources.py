#!/usr/bin/env python3
"""Keep JavaScript as an emitted format, rather than a second authored language."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
excluded = {'node_modules', 'dist', '.astro', '__pycache__'}
files = sorted(path.relative_to(root) for directory in ('examples', 'tools', 'scripts')
               for path in (root / directory).rglob('*')
               if path.is_file() and not excluded.intersection(path.parts)
               and path.suffix in {'.js', '.mjs', '.cjs', '.jsx'})
if files:
    print('Authored JavaScript must be TypeScript:', *files, sep='\n', file=sys.stderr)
    sys.exit(1)
print('TypeScript source inventory PASS')
