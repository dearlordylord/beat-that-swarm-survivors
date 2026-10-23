#!/usr/bin/env python3
"""Development test: kill a real native batch after its first flushed summary."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

p = argparse.ArgumentParser()
p.add_argument('--repo', default=str(Path(__file__).resolve().parents[2]))
p.add_argument('--output-dir', required=True)
p.add_argument('--ticks', type=int, default=1800)
p.add_argument('--deadline', type=float, default=90)
a = p.parse_args()
out = Path(a.output_dir)
out.mkdir(parents=True, exist_ok=False)
env = {**os.environ, 'NODE': '/nonexistent/node'}
cmd = ['bash', 'tools/survivors-bot/native-batch.sh', '--no-build', '--count', '2', '--ticks', str(a.ticks), '--seed', '100', '--profile', 'both', '--workers', '1', '--output-dir', str(out / 'receipts')]
with (out / 'wrapper.stdout').open('wb') as stdout, (out / 'wrapper.stderr').open('wb') as stderr:
    child = subprocess.Popen(cmd, cwd=a.repo, env=env, stdout=stdout, stderr=stderr)
    try:
        record_file = out / 'receipts/worker-0.jsonl'
        progress_file = out / 'receipts/worker-0.stderr'
        deadline = time.monotonic() + a.deadline
        while time.monotonic() < deadline:
            assert child.poll() is None, 'Batch exited before live flushed summary was observed'
            lines = record_file.read_text().splitlines() if record_file.exists() else []
            progress = progress_file.read_text() if progress_file.exists() else ''
            if len(lines) == 1 and 'Completed native seed 100 ' in progress:
                first = json.loads(lines[0])
                assert first['seed'] == 100 and first['index'] == 0 and first['status'] == 'completed', first
                assert first['requestedTicks'] == a.ticks, first
                child.terminate()
                status = child.wait(timeout=10)
                assert status == 143, status
                retained = record_file.read_text().splitlines()
                assert len(retained) == 1 and json.loads(retained[0]) == first, retained
                (out / 'PASS.json').write_text(json.dumps({'status': 'PASS', 'wrapperExit': status, 'completedRecordsPreserved': len(retained), 'first': first}, indent=2) + '\n')
                print('REAL NATIVE TERM RECEIPT PASS')
                break
            time.sleep(0.02)
        else:
            raise AssertionError('First summary was not flushed while the batch remained active')
    finally:
        if child.poll() is None:
            child.terminate()
            try:
                child.wait(timeout=10)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait(timeout=5)
