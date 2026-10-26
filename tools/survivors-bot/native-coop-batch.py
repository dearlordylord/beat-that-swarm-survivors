#!/usr/bin/env python3
"""Frozen-source native co-op campaign, with no renderer, Node or classifier."""
from __future__ import annotations
import argparse
import concurrent.futures
import datetime
import hashlib
import json
import math
import os
import platform
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from dataclasses import asdict
from process_diagnostics import run_process, format_failure
APP = ROOT / 'examples/survivors'
ENTRY = APP / 'offline-coop-batch.bend'
PARTY = APP / 'party-difficulty.bend'
IMPORT = re.compile(r'^\s*import\s+(?:"([^"]+)"|(\S+))', re.MULTILINE)
EXTRA = re.compile(rb'(?m)^(def extra_per_player_percent\(\) -> U32: )([0-9]+)([ \t]*)$')
ACTIVE: dict[int, subprocess.Popen] = {}
ACTIVE_LOCK = threading.Lock()
STOP = threading.Event()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fingerprint(files: dict[str, bytes]) -> str:
    return digest(json.dumps({name: digest(data) for name, data in sorted(files.items())},
                             sort_keys=True, separators=(',', ':')).encode())


def closure(entry: Path) -> dict[str, bytes]:
    result: dict[str, bytes] = {}
    pending = [entry]
    while pending:
        source = pending.pop().resolve()
        relative = source.relative_to(ROOT).as_posix()
        if relative in result:
            continue
        data = source.read_bytes()
        result[relative] = data
        for match in IMPORT.finditer(data.decode()):
            name = match.group(1) or match.group(2)
            if name == 'Base' or '@' in name:
                continue
            child = (source.parent / name).resolve()
            child.relative_to(ROOT)  # Reject source-checkout escape.
            pending.append(child)
    return result


def transformed(files: dict[str, bytes], extra: int) -> dict[str, bytes]:
    result = dict(files)
    key = PARTY.relative_to(ROOT).as_posix()
    replacement, count = EXTRA.subn(lambda m: m[1] + str(extra).encode() + m[3], result[key])
    if count != 1:
        raise ValueError('Expected exactly one literal extra_per_player_percent definition')
    result[key] = replacement
    return result


def identities(files: dict[str, bytes], dependency: bytes) -> dict[str, str]:
    files = {**files, 'bendhub-dependencies.json': dependency}
    policy = {name: data for name, data in files.items()
              if name == 'examples/survivors/offline-policy.bend'
              or name.startswith('examples/survivors/offline-policy/')}
    game = {name: data for name, data in files.items()
            if name not in policy and '/offline-coop-' not in name}
    context = dict(game)
    key = PARTY.relative_to(ROOT).as_posix()
    context[key], count = EXTRA.subn(lambda m: m[1] + b'<EXPERIMENT_EXTRA>' + m[3], context[key])
    if count != 1:
        raise ValueError('Cannot bind coefficient-normalized game context')
    return {'sourceHash': fingerprint(files), 'gameHash': fingerprint(game),
            'gameContextHash': fingerprint(context), 'policyHash': fingerprint(policy),
            'runnerHash': fingerprint({name: data for name, data in files.items()
                                       if '/offline-coop-' in name})}


def terminate(process: subprocess.Popen) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=3)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def interrupt(signum, _frame) -> None:
    STOP.set()
    with ACTIVE_LOCK:
        active = list(ACTIVE.values())
    for process in active:
        terminate(process)


def execute(command: list[str], stdout, stderr, *, timeout: float, env=None, cwd=None) -> tuple[int, bool]:
    process = subprocess.Popen(command, stdout=stdout, stderr=stderr, env=env,
                               cwd=cwd, start_new_session=True)
    with ACTIVE_LOCK:
        ACTIVE[process.pid] = process
    timed_out = False
    try:
        if STOP.is_set():
            terminate(process)
        try:
            process.wait(timeout=max(.001, timeout))
        except subprocess.TimeoutExpired:
            timed_out = True
            terminate(process)
        return process.returncode, timed_out
    finally:
        terminate(process)
        with ACTIVE_LOCK:
            ACTIVE.pop(process.pid, None)


def validate_records(path: Path, seed: int, ticks: int) -> dict:
    records = []
    previous = -1
    for number, line in enumerate(path.read_text().splitlines(), 1):
        row = json.loads(line)
        if row.get('type') not in {'sample', 'summary'} or row.get('seed') != seed:
            raise ValueError(f'Invalid type/seed at line {number}')
        if not isinstance(row.get('tick'), int) or not 0 <= row['tick'] <= ticks:
            raise ValueError(f'Invalid tick at line {number}')
        if row['type'] == 'sample':
            if row['tick'] <= previous:
                raise ValueError('Samples must have strictly increasing world ticks')
            previous = row['tick']
        for field in ['population', 'ordinaryPopulation', 'bossPopulation', 'hp0', 'hp1',
                      'maxHp0', 'maxHp1', 'xp', 'level', 'kills', 'choices0', 'choices1']:
            if not isinstance(row.get(field), int) or row[field] < 0:
                raise ValueError(f'Invalid {field} at line {number}')
        for field in ['px0', 'py0', 'px1', 'py1']:
            if not isinstance(row.get(field), (int, float)) or not math.isfinite(row[field]):
                raise ValueError(f'Invalid {field} at line {number}')
        records.append(row)
    summaries = [row for row in records if row['type'] == 'summary']
    if not records or len(summaries) != 1 or records[-1] != summaries[0]:
        raise ValueError('Expected exactly one final summary')
    initial = records[0].get('initialSetup')
    if records[0]['tick'] != 0 or not isinstance(initial, dict) or len(initial.get('players', [])) != 2:
        raise ValueError('Missing actual tick-zero two-player setup')
    summary = summaries[0]
    expected = {3: 'defeat', 4: 'victory', 5: 'aborted'}.get(summary['phase'], 'horizon')
    if summary.get('outcome') != expected:
        raise ValueError('Summary phase and outcome disagree')
    if expected == 'horizon' and summary['tick'] != ticks:
        raise ValueError('Horizon summary must reach the requested world tick')
    return {'sampleCount': len(records) - 1, 'tick': summary['tick'],
            'outcome': summary['outcome'], 'phase': summary['phase'], 'initialSetup': initial}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument('--count', type=int, default=1)
    result.add_argument('--seed', type=int, default=100)
    result.add_argument('--seeds', help='explicit comma-separated U32 cohort; replaces seed/count')
    result.add_argument('--ticks', type=int, default=7200)
    result.add_argument('--extra-percent', type=int, choices=[0, 25, 50, 100], default=25)
    result.add_argument('--profile', choices=['fresh', 'advanced'], default='fresh')
    result.add_argument('--character0', type=int)
    result.add_argument('--character1', type=int)
    result.add_argument('--arcana0', type=int)
    result.add_argument('--arcana1', type=int)
    result.add_argument('--workers', type=int, default=1)
    result.add_argument('--threads', type=int, default=1)
    result.add_argument('--wall-seconds', type=float, default=600,
                        help='whole execution campaign limit, excluding build')
    result.add_argument('--build-seconds', type=float, default=300)
    result.add_argument('--criteria', type=Path)
    result.add_argument('--output-dir', type=Path)
    result.add_argument('--reuse-build', type=Path,
                        help='reuse a matching frozen runner+manifest, never an unchecked binary')
    result.add_argument('--source-root', type=Path, default=ROOT,
                        help='one frozen repository/worktree used by every comparison arm')
    return result


def main(argv=None) -> int:
    global ROOT, APP, ENTRY, PARTY
    args = parser().parse_args(argv)
    ROOT = args.source_root.resolve()
    APP = ROOT / 'examples/survivors'
    ENTRY = APP / 'offline-coop-batch.bend'
    PARTY = APP / 'party-difficulty.bend'
    seeds = [int(value) for value in args.seeds.split(',')] if args.seeds else list(range(args.seed, args.seed + args.count))
    if args.seeds:
        args.count = len(seeds)
    if not (1 <= args.count <= 1000 and len(set(seeds)) == len(seeds) and
            all(0 <= seed <= 4294967295 for seed in seeds) and 1 <= args.ticks <= 37000 and
            0 <= args.seed <= 4294967295 and args.seed + args.count - 1 <= 4294967295 and
            1 <= args.workers <= 16 and 1 <= args.threads <= 128 and
            math.isfinite(args.wall_seconds) and 0 < args.wall_seconds <= 86400 and
            math.isfinite(args.build_seconds) and 0 < args.build_seconds <= 1800):
        raise ValueError('Invalid count/tick/seed/worker/thread/time bound')
    for field, maximum in [('character0', 7), ('character1', 7), ('arcana0', 11), ('arcana1', 11)]:
        value = getattr(args, field)
        if value is not None and not 0 <= value <= maximum:
            raise ValueError(f'Invalid {field}')
        if args.profile == 'fresh' and value not in (None, 0):
            raise ValueError('Fresh setup cannot select locked characters or Arcana')
    advanced = args.profile == 'advanced'
    setup = {'profile': args.profile, 'stage': 0, 'mode': 0,
             'metaPreset': 'existing-native-advanced' if advanced else 'native-economy.fresh',
             'character0': args.character0 if args.character0 is not None else (2 if advanced else 0),
             'character1': args.character1 if args.character1 is not None else (2 if advanced else 0),
             'arcana0': args.arcana0 if args.arcana0 is not None else (9 if advanced else 0),
             'arcana1': args.arcana1 if args.arcana1 is not None else (9 if advanced else 0),
             'meta': 'existing advanced preset 364304237' if advanced else 'native-economy.meta(fresh())',
             'weaponUnlocks': 'advanced full' if advanced else 'native-economy.weapon_mask(fresh())'}
    default_pair = all(getattr(args, field) is None for field in ['character0', 'character1', 'arcana0', 'arcana1'])
    setup_id = f'{args.profile}-{args.profile}-stage0-standard' if default_pair else (
        f'{args.profile}-c{setup["character0"]}-a{setup["arcana0"]}'
        f'-c{setup["character1"]}-a{setup["arcana1"]}-stage0-standard')
    tag = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ') + f'-{os.getpid()}'
    output = (args.output_dir or APP / 'dist/coop-balance' / tag).resolve()
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise ValueError('Output directory must be empty')
    canonical = closure(ENTRY)
    files = transformed(canonical, args.extra_percent)
    dependency = (ROOT / 'bendhub-dependencies.json').read_bytes()
    bend = os.environ.get('BEND', 'bend')
    version_result = run_process([bend, 'version'], wall_timeout_seconds=15)
    if (not version_result.normal_exit or version_result.returncode != 0):
        diagnostic = {**asdict(version_result), 'classification': version_result.classification,
                      'signal': version_result.signal_name}
        (output / 'compiler-version.process.json').write_text(json.dumps(diagnostic, indent=2) + '\n')
        raise ValueError(format_failure(version_result, 'Cannot read Bend compiler version'))
    compiler = version_result.stdout.strip()
    manifest = {'schemaVersion': 1, 'kind': 'native-coop-balance', 'campaignId': tag,
                'status': 'preparing', 'exitCode': None,
                'setupId': setup_id,
                'setup': setup, 'setupHash': digest(json.dumps(setup, sort_keys=True).encode()),
                'styleId': 'resource-memory-pair',
                'policyIds': ['bend-resource-memory-v1', 'bend-resource-memory-v1'],
                'partySize': 2, 'requestedTicks': args.ticks, 'extraPercent': args.extra_percent,
                'seeds': seeds, 'count': args.count,
                'workers': min(args.workers, args.count), 'threadsPerWorker': args.threads,
                'wallSeconds': args.wall_seconds, 'compilerVersion': compiler,
                'platform': platform.platform(), 'machine': platform.machine(),
                'backend': 'native-c', 'entry': ENTRY.relative_to(ROOT).as_posix(),
                'records': ['runs.jsonl'], 'sourceFiles': {name: digest(data) for name, data in sorted(files.items())},
                'dependencyManifestSha256': digest(dependency), **identities(files, dependency),
                'sourceRoot': str(ROOT), 'snapshotDirectory': 'source',
                'supervisorSha256': digest(Path(__file__).read_bytes()),
                'populationTelemetryVersion': 2,
                'populationDefinition': 'all living Body kind0; boss variants20..30 inclusive, ordinary excludes that range',
                'nearEnemiesDefinition': 'living Body kind0 within inclusive radius120 world units; proxy only',
                'limits': ['public Core builds frame JSON before the harness discards it',
                           'HP is net health, not attributed damage; XP level are shared',
                           'one fixed deterministic omniscient controller per player; no learning or classifier']}
    try:
        manifest['revision'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        manifest['dirty'] = bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True))
    except subprocess.CalledProcessError:
        manifest['revision'], manifest['dirty'] = 'unversioned', True
    if args.criteria:
        criteria = args.criteria.resolve().read_bytes()
        json.loads(criteria)
        (output / 'criteria.json').write_bytes(criteria)
        manifest['criteriaSha256'] = digest(criteria)
    receipt = output / 'manifest.json'

    def save():
        receipt.write_text(json.dumps(manifest, indent=2) + '\n')

    save()
    print(f'Native co-op receipts: {output}', file=sys.stderr, flush=True)
    binary = output / 'runner'
    try:
        snapshot = output / 'source'
        for name, data in files.items():
            target = snapshot / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        (snapshot / 'bendhub-dependencies.json').write_bytes(dependency)
        if args.reuse_build:
            previous = json.loads((args.reuse_build / 'manifest.json').read_text())
            prior_binary = args.reuse_build / 'runner'
            if (previous.get('sourceHash') != manifest['sourceHash'] or
                    previous.get('extraPercent') != args.extra_percent or
                    previous.get('compilerVersion') != compiler or
                    digest(prior_binary.read_bytes()) != previous.get('binarySha256')):
                raise ValueError('Reused build does not match source/config/compiler/binary receipt')
            shutil.copy2(prior_binary, binary)
            manifest['buildReusedFrom'] = str(args.reuse_build.resolve())
        else:
            import fcntl
            with open('/tmp/bendvy-parity-heavy.lock', 'a') as lock:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                except BlockingIOError:
                    raise RuntimeError('Backend checks are already running; retry later')
                with (output / 'build.stdout').open('wb') as out, (output / 'build.stderr').open('wb') as err:
                    code, timed = execute([bend, str(snapshot / ENTRY.relative_to(ROOT)), '-o', str(binary)],
                                          out, err, timeout=args.build_seconds, cwd=snapshot)
                if code or timed:
                    manifest['status'] = 'build-timeout' if timed else 'build-failed'
                    manifest['exitCode'] = code
                    save()
                    return 1
        if closure(ENTRY) != canonical or (ROOT / 'bendhub-dependencies.json').read_bytes() != dependency:
            raise RuntimeError('Canonical runtime source changed while building')
        binary.chmod(0o755)
        manifest['binarySha256'] = digest(binary.read_bytes())
        manifest['status'] = 'running'
        save()
        deadline = time.monotonic() + args.wall_seconds

        def run_one(item):
            index, seed = item
            if STOP.is_set() or time.monotonic() >= deadline:
                return {'seed': seed, 'index': index, 'status': 'unstarted'}
            env = dict(os.environ)
            env.pop('BENDRTS', None)
            env.update({'NIGHTFALL_COOP_SEED': str(seed), 'NIGHTFALL_COOP_INDEX': str(index),
                        'NIGHTFALL_COOP_TICKS': str(args.ticks), 'NIGHTFALL_COOP_PROFILE': args.profile})
            for name in ['character0', 'character1', 'arcana0', 'arcana1']:
                env['NIGHTFALL_COOP_' + name.upper()] = str(setup[name])
            rows = output / f'run-{index}.jsonl'
            with rows.open('wb') as out, (output / f'run-{index}.stderr').open('wb') as err:
                code, timed = execute([str(binary), '+RTS', '--threads', str(args.threads), '-RTS'],
                                      out, err, timeout=max(.001, deadline - time.monotonic()), env=env)
            status = 'interrupted' if STOP.is_set() else 'timeout' if timed else 'completed' if code == 0 else 'failed'
            result = {'seed': seed, 'index': index, 'status': status, 'exitCode': code}
            if status == 'completed':
                try:
                    result.update(validate_records(rows, seed, args.ticks))
                except (ValueError, KeyError, TypeError) as error:
                    result.update(status='invalid-receipt', error=str(error))
            return result

        with concurrent.futures.ThreadPoolExecutor(max_workers=manifest['workers']) as pool:
            results = list(pool.map(run_one, enumerate(manifest['seeds'])))
        with (output / 'runs.jsonl').open('wb') as merged:
            for row in sorted(results, key=lambda r: r['index']):
                path = output / f'run-{row["index"]}.jsonl'
                if path.exists():
                    with path.open('rb') as source:
                        shutil.copyfileobj(source, merged)
        manifest['runs'] = results
        initial_setups = [row['initialSetup'] for row in results if row.get('status') == 'completed']
        if initial_setups:
            if any(value != initial_setups[0] for value in initial_setups):
                raise ValueError('Actual initial setup differs across campaign seeds')
            manifest['setup'] = {**setup, 'actual': initial_setups[0]}
            manifest['setupHash'] = digest(json.dumps(manifest['setup'], sort_keys=True).encode())
        complete = all(row['status'] == 'completed' for row in results)
        manifest['status'] = 'completed' if complete else 'interrupted' if STOP.is_set() else 'incomplete'
        manifest['exitCode'] = 0 if complete else 130 if STOP.is_set() else 1
        save()
        print(json.dumps({'status': manifest['status'], 'runs': results, 'output': str(output)}), flush=True)
        return manifest['exitCode']
    except Exception as error:
        manifest.update(status='failed', exitCode=1, error=str(error))
        save()
        raise


if __name__ == '__main__':
    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, interrupt)
    try:
        sys.exit(main())
    except Exception as error:
        print(f'Native co-op campaign failed: {error}', file=sys.stderr)
        sys.exit(1)
