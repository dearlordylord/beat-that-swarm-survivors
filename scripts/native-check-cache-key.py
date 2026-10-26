#!/usr/bin/env python3
"""Conservative native-test cache key; generated artifacts are excluded."""
import hashlib
import os
from pathlib import Path
import platform
import shutil
from process_diagnostics import format_failure, run_process
import sys


def cache_key(repo, bend, clang, runtime_roots):
    digest = hashlib.sha256()

    def add(label, data):
        for value in (str(label).encode(), data):
            digest.update(len(value).to_bytes(8, "big"))
            digest.update(value)

    add("cache-format", b"2")
    add("checkout", str(repo.resolve()).encode())
    add("platform", platform.platform().encode())
    add("machine", repr(platform.uname()).encode())
    tools = [('bend', bend), ('clang', clang)]
    if os.environ.get('CC'):
        tools.append(('cc', os.environ['CC']))
    for role, tool in tools:
        resolved = Path(shutil.which(tool) or tool).resolve(strict=True)
        add(role, str(resolved).encode())
        add(resolved, resolved.read_bytes())
        if role != 'bend':
            result = run_process([str(resolved), "--version"], cwd=repo)
            if not result.normal_exit or result.returncode != 0:
                raise RuntimeError(format_failure(result, "native cache compiler version failed"))
            add("version", result.stdout.encode())
    for name in ("PATH", "SDKROOT", "MACOSX_DEPLOYMENT_TARGET", "CC", "CFLAGS", "LDFLAGS", "CPATH", "LIBRARY_PATH", "LD_LIBRARY_PATH", "DYLD_LIBRARY_PATH"):
        add(name, os.environ.get(name, "").encode())
    for name in sorted(name for name in os.environ if name.startswith('BEND_')):
        add(name, os.environ[name].encode())
    for relative in ('examples/common.sh', 'examples/survivors/check-launcher-profile-ui.sh', 'scripts/native-check-cache-key.py'):
        add(relative, (repo / relative).read_bytes())
    # Hash all local Bend sources conservatively, including new untracked files.
    roots = [repo, *runtime_roots]
    if os.environ.get('BEND_LIB'):
        roots.append(Path(os.environ['BEND_LIB']).expanduser().resolve())
    for root in roots:
        add("root", str(root).encode())
        for directory, dirs, files in os.walk(root):
            excluded = {".git", "__pycache__"}
            if root == repo:
                excluded.update({"node_modules", "dist", ".bend", ".bendhub", ".autoresearch"})
            dirs[:] = sorted(d for d in dirs if d not in excluded)
            for name in sorted(files):
                path = Path(directory) / name
                if root != repo or path.suffix in {".bend", ".c", ".h"} or name == "bendhub-dependencies.json":
                    add(path, path.read_bytes())
    return digest.hexdigest()


if __name__ == "__main__":
    repo = Path(sys.argv[1]).resolve()
    bend = sys.argv[2]
    install = Path(shutil.which(bend) or bend).resolve(strict=True).parent.parent
    print(cache_key(repo, bend, sys.argv[3], [install / "bend2", install / "lib"]))
