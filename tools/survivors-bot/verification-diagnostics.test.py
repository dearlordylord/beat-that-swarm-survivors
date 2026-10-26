"""Fault children exercise diagnostics without compiling or running a game."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

def load(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), HERE / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

class Diagnostics(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)

    def child(self, body):
        path = self.root / 'fault-child'
        path.write_text('#!/usr/bin/env python3\nimport os,signal,sys,time\n' + body + '\n')
        path.chmod(0o700)
        return path

    def test_parallel_cell_retains_exact_failure(self):
        module = load('compare-native-parallel')
        child = self.child("print('PARALLEL_SENTINEL',file=sys.stderr);sys.exit(7)")
        out = self.root / 'cell'
        with self.assertRaisesRegex(AssertionError, 'native child failed'):
            module.cell(child, 'serial', 1, sorted(os.sched_getaffinity(0))[:1], 1, 1, out, time.monotonic() + 2)
        receipt = json.loads((out / 'receipt.json').read_text())
        result = receipt['children'][0]
        self.assertEqual(result['returncode'], 7)
        self.assertEqual(result['classification'], 'nonzero-exit')
        self.assertIn('PARALLEL_SENTINEL', result['stderr'])
        self.assertEqual(result['stderrPath'], str(out / 'worker-0.stderr'))
        self.assertIn('native child failed', receipt['error'])

    def test_measure_retains_exact_failure_and_signal(self):
        module = load('measure-native-step')
        for body, code in [("print('REPLAY_SENTINEL',file=sys.stderr);sys.exit(7)", 7),
                           ("print('REPLAY_SENTINEL',file=sys.stderr,flush=True);os.kill(os.getpid(),signal.SIGTERM)", -signal.SIGTERM)]:
            with self.subTest(code=code):
                child = self.child(body)
                out = self.root / 'replay.jsonl'
                with self.assertRaisesRegex(RuntimeError, f'Replay failed \\({code}\\)'):
                    module.run_sample(child, self.root / 'fixture', out, 1)
                result = json.loads(out.with_suffix('.process.json').read_text())
                self.assertEqual(result['returncode'], code)
                self.assertIn('REPLAY_SENTINEL', result['stderr'])
                self.assertFalse(result['wall_timed_out'])
                if code < 0:self.assertEqual(result['signal'], 'SIGTERM')

    def test_measure_timeout_preserves_partial_stderr(self):
        module = load('measure-native-step')
        child = self.child("print('TIMEOUT_SENTINEL',file=sys.stderr,flush=True);time.sleep(30)")
        out = self.root / 'timeout.jsonl'
        with self.assertRaises(subprocess.TimeoutExpired):
            module.run_sample(child, self.root / 'fixture', out, .05)
        diagnostic = json.loads(out.with_suffix('.process.json').read_text())
        self.assertTrue(diagnostic['wall_timed_out'])
        self.assertEqual(diagnostic['classification'], 'wall-timeout')
        self.assertEqual(diagnostic['returncode'], -signal.SIGKILL)
        self.assertIn('TIMEOUT_SENTINEL', diagnostic['stderr'])

    def test_compiler_version_preserves_stderr_and_exit(self):
        child = self.child("print('COMPILER_SENTINEL',file=sys.stderr);sys.exit(23)")
        out = self.root / 'campaign'
        result = subprocess.run([sys.executable, '-B', str(HERE / 'native-coop-batch.py'), '--count', '1', '--ticks', '1', '--output-dir', str(out)],
                                env={**os.environ, 'BEND': str(child)}, capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertIn('COMPILER_SENTINEL', result.stderr)
        diagnostic = json.loads((out / 'compiler-version.process.json').read_text())
        self.assertEqual(diagnostic['returncode'], 23)
        self.assertIn('COMPILER_SENTINEL', diagnostic['stderr'])

    def test_visible_child_failure_preserves_exit_and_native_stderr(self):
        child = self.child("print('VISIBLE_SENTINEL',file=sys.stderr);sys.exit(7)")
        out = self.root / 'visible'
        result = subprocess.run(['node', str(HERE / 'visible.mts'), '--binary', str(child), '--receipts-dir', str(out), '--seconds', '1'],
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertIn('VISIBLE_SENTINEL', result.stderr)
        receipt = next(out.glob('*.jsonl'))
        error = next(row for row in map(json.loads, receipt.read_text().splitlines()) if row['type'] == 'error')
        self.assertEqual(error['diagnostic']['nativeExit']['code'], 7)
        self.assertIsNone(error['diagnostic']['nativeExit']['signal'])
        self.assertEqual(error['diagnostic']['command'], [str(child)])

    def test_visible_spawn_failure_preserves_eacces(self):
        child = self.child('sys.exit(0)')
        child.chmod(0o600)
        out = self.root / 'visible'
        result = subprocess.run(['node', str(HERE / 'visible.mts'), '--binary', str(child), '--receipts-dir', str(out), '--seconds', '1'],
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertIn('EACCES', result.stderr)
        receipt = next(out.glob('*.jsonl'))
        error = next(row for row in map(json.loads, receipt.read_text().splitlines()) if row['type'] == 'error')
        self.assertEqual(error['diagnostic']['code'], 'EACCES')
        self.assertEqual(error['diagnostic']['path'], str(child))
        self.assertIn('spawn', error['diagnostic']['syscall'])

if __name__ == '__main__':unittest.main()
