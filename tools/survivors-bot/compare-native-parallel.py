#!/usr/bin/env python3
"""Compare already-built native batch processes and runtime-thread parallelism."""
import argparse, hashlib, json, os, pathlib, resource, signal, statistics, subprocess, sys, time
from dataclasses import asdict
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "scripts"))
from process_diagnostics import RunResult, format_failure
TASKSET = "/usr/bin/taskset"
P = pathlib.Path
FIELDS = set('type backend policy index seed profile status tick requestedTicks outcome phase hp level xp xpNeed kills gold choices xpPiles uncollectedBaseXp wallMs'.split())

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def save(p, v):
    p.write_text(json.dumps(v, indent=2, allow_nan=False) + '\n')

def records(paths, count, ticks, parallel):
    rows = [json.loads(line) for p in paths for line in p.read_text().splitlines()]
    rows.sort(key=lambda r: r['index'])
    assert len(rows) == count and [r['index'] for r in rows] == list(range(count)), 'missing/duplicate indices'
    for i, r in enumerate(rows):
        assert set(r) == FIELDS, 'unexpected summary fields'
        assert r['type'] == 'summary' and r['backend'] == 'native' and (r['policy'] == 'bend-resource-memory-v1') and (r['status'] == 'completed')
        assert r['seed'] == 100 + i and r['profile'] == ('advanced' if i % 2 else 'fresh') and (r['requestedTicks'] == ticks)
        for k in FIELDS - {'type', 'backend', 'policy', 'profile', 'status', 'outcome', 'wallMs'}:
            assert type(r[k]) is int and r[k] >= 0, k
        assert r['outcome'] == 'bounded-observation' and r['tick'] == ticks and (r['phase'] in [0, 1, 2]) or (r['outcome'] == 'terminal' and r['tick'] <= ticks and (r['phase'] in [3, 4]))
        assert r['wallMs'] is None if parallel else type(r['wallMs']) is int and r['wallMs'] >= 0, 'invalid wallMs'
    return [{k: v for k, v in r.items() if k != 'wallMs'} for r in rows]

def cleanup(children):
    """Stop only live, unreaped native leaders, then reap every owned child.

 Direct native binaries create runtime threads, not subprocesses. Polling a
 completed child reaps it; its numeric group identifier must never be signaled.
 """
    for child in children:
        if child.poll() is not None:
            continue
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    for child in children:
        child.wait(timeout=3)

def cell(binary, mode, budget, cpus, count, ticks, out, deadline):
    out.mkdir()
    children = []
    files = []
    logs = []
    timed_out_ids = set()
    spawn_error = None
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    started = time.monotonic()
    receipt = {'status': 'INCOMPLETE', 'mode': mode, 'budget': budget, 'cpus': cpus}
    try:
        for i in range(budget if mode == 'serial' else 1):
            n = (count + budget - 1 - i) // budget if mode == 'serial' else count
            env = {**os.environ, 'NIGHTFALL_BATCH_COUNT': str(n), 'NIGHTFALL_BATCH_INDEX': str(i if mode == 'serial' else 0), 'NIGHTFALL_BATCH_STRIDE': str(budget if mode == 'serial' else 1), 'NIGHTFALL_BATCH_SEED': '100', 'NIGHTFALL_BATCH_PROFILE': 'both', 'NIGHTFALL_BATCH_TICKS': str(ticks), 'PYTHONDONTWRITEBYTECODE': '1'}
            stdout = out / f'worker-{i}.jsonl'
            stderr = out / f'worker-{i}.stderr'
            a = stdout.open('wb')
            b = stderr.open('wb')
            files += [a, b]
            logs.append(stdout)
            env.pop('BENDRTS', None)
            command = [TASKSET, '-c', ','.join(map(str, cpus)), str(binary), '+RTS', '--threads', str(1 if mode == 'serial' else budget), '-RTS']
            receipt['launchCommand'] = command
            children.append(subprocess.Popen(command, env=env, stdout=a, stderr=b, stdin=subprocess.DEVNULL, start_new_session=True))
        end = min(deadline, started + 360)
        while any((c.poll() is None for c in children)):
            if time.monotonic() >= end:
                timed_out_ids = {child.pid for child in children if child.poll() is None}
                raise TimeoutError('cell/whole execution deadline')
            if any((c.returncode not in [None, 0] for c in children)):
                raise RuntimeError('native child failed')
            time.sleep(0.01)
        assert all((c.returncode == 0 for c in children)), 'native child failed'
        for f in files:
            f.close()
        elapsed = time.monotonic() - started
        after = resource.getrusage(resource.RUSAGE_CHILDREN)
        semantic = records(logs, count, ticks, mode == 'parallel')
        receipt.update(status='PASS', wallSeconds=elapsed, childUserSeconds=after.ru_utime - before.ru_utime, childSystemSeconds=after.ru_stime - before.ru_stime, childrenCumulativeMaxRssKiB=after.ru_maxrss, exitCodes=[c.returncode for c in children], logSHA256={p.name: sha(p) for p in out.iterdir() if p.is_file()})
        return (semantic, receipt)
    except BaseException as error:
        receipt['error'] = repr(error)
        if isinstance(error, OSError) and len(children) < len(logs):
            spawn_error = f'{type(error).__name__}: {error}'
        raise
    finally:
        handlers = {sig: signal.signal(sig, signal.SIG_IGN) for sig in [signal.SIGTERM, signal.SIGINT]}
        try:
            cleanup(children)
        except BaseException as error:
            receipt.update(status='INCOMPLETE', cleanupError=repr(error))
            raise
        finally:
            for f in files:
                f.close()
            receipt['children'] = []
            for index in range(len(logs) if receipt['status'] != 'PASS' else 0):
                child = children[index] if index < len(children) else None
                stdout_path = out / f'worker-{index}.jsonl'
                stderr_path = out / f'worker-{index}.stderr'
                result = RunResult(command=tuple(child.args if child else receipt['launchCommand']), cwd=os.getcwd(),
                                   returncode=child.returncode if child else None,
                                   elapsed_wall_seconds=time.monotonic() - started,
                                   stdout=stdout_path.read_text(errors='replace'), stderr=stderr_path.read_text(errors='replace'),
                                   wall_timeout_seconds=max(0, min(deadline, started + 360) - started),
                                   cpu_limit_seconds=None, wall_timed_out=child is not None and child.pid in timed_out_ids,
                                   spawn_error=spawn_error if child is None else None)
                receipt['children'].append({**asdict(result), 'classification': result.classification,
                                            'signal': result.signal_name, 'stdoutPath': str(stdout_path), 'stderrPath': str(stderr_path)})
                if receipt['status'] != 'PASS' and (not result.normal_exit or result.returncode != 0):
                    print(format_failure(result, receipt.get('error', 'Native child failed')), file=sys.stderr)
            save(out / 'receipt.json', receipt)
            for sig, handler in handlers.items():
                signal.signal(sig, handler)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['serial-binary', 'parallel-binary', 'output-dir']:
        parser.add_argument('--' + name, type=P, required=True)
    parser.add_argument('--ticks', type=int, default=1200)
    parser.add_argument('--count', type=int, default=8)
    parser.add_argument('--repeats', type=int, default=3)
    parser.add_argument('--budgets', default='1,2,4,8')
    parser.add_argument('--deadline', type=float, default=1800)
    a = parser.parse_args()
    budgets = [int(x) for x in a.budgets.split(',')]
    available = sorted(os.sched_getaffinity(0))
    if not budgets or len(set(budgets)) != len(budgets) or any((b < 1 or b > len(available) for b in budgets)) or (not 1 <= a.count <= 10000) or (not 1 <= a.ticks <= 10000000) or (not 1 <= a.repeats <= 100) or (not 0 < a.deadline <= 1800):
        parser.error('invalid count/ticks/repeats/budgets/deadline')
    a.serial_binary = a.serial_binary.resolve(strict=True)
    a.parallel_binary = a.parallel_binary.resolve(strict=True)
    a.output_dir.mkdir(parents=True, exist_ok=False)
    bound = {str(p): sha(p) for p in [a.serial_binary, a.parallel_binary, P(__file__).resolve()]}
    receipt = {'status': 'INCOMPLETE', 'bindings': bound, 'cells': [], 'scope': 'Native execution only; no builds. Parent supplies exclusive heavy lock.'}
    started = time.monotonic()
    deadline = started + a.deadline
    reference = None

    def stop(*_):
        raise KeyboardInterrupt('interrupted')
    prior = {sig: signal.signal(sig, stop) for sig in [signal.SIGTERM, signal.SIGINT]}
    try:
        for repeat in range(a.repeats):
            for budget in budgets:
                order = ['serial', 'parallel'] if repeat % 2 == 0 else ['parallel', 'serial']
                pair = {}
                for mode in order:
                    assert time.monotonic() < deadline, 'whole deadline'
                    assert all((sha(P(p)) == h for p, h in bound.items())), 'binary/runner drift'
                    semantic, result = cell(a.serial_binary if mode == 'serial' else a.parallel_binary, mode, budget, available[:budget], a.count, a.ticks, a.output_dir / f'r{repeat}-b{budget}-{mode}', deadline)
                    assert time.monotonic() <= deadline, 'whole deadline after cell'
                    receipt['cells'].append({'repeat': repeat, **result})
                    pair[mode] = result['wallSeconds']
                    if reference is None:
                        reference = semantic
                    assert semantic == reference, 'semantic divergence across modes/budgets/repetitions'
                receipt.setdefault('pairs', []).append({'repeat': repeat, 'budget': budget, 'order': order, 'serialSeconds': pair['serial'], 'parallelSeconds': pair['parallel'], 'speedup': pair['serial'] / pair['parallel']})
        receipt.update(status='PASS', speedupMedians={str(b): statistics.median((p['speedup'] for p in receipt['pairs'] if p['budget'] == b)) for b in budgets})
    except BaseException as error:
        receipt['error'] = repr(error)
    finally:
        try:
            if any((sha(P(p)) != h for p, h in bound.items())):
                receipt.update(status='INCOMPLETE', error='binary/runner drift')
        except OSError as error:
            receipt.update(status='INCOMPLETE', error='binding postguard: ' + repr(error))
        receipt['wallSeconds'] = time.monotonic() - started
        save(a.output_dir / 'summary.json', receipt)
        for sig, handler in prior.items():
            signal.signal(sig, handler)
    return 0 if receipt['status'] == 'PASS' else 1
if __name__ == '__main__':
    sys.exit(main())
