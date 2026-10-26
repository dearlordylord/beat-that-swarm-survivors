#!/usr/bin/env python3
"""Exercise process faults and proof-gate evidence with actual child processes."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import signal
import sys
import tempfile
import time
import unittest
from unittest import mock

from process_diagnostics import format_failure, run_process

SCRIPTS = Path(__file__).resolve().parent


class ProcessDiagnosticsTests(unittest.TestCase):
    def child(self, code, **budgets):
        return run_process([sys.executable, '-c', code], cwd=SCRIPTS, **budgets)

    def test_real_termination_outcomes_keep_both_streams(self):
        prefix = 'import sys;print("stdout retained",flush=True);print("stderr retained",file=sys.stderr,flush=True);'
        cases = [
            ('zero-exit', 'pass', 0, None),
            ('nonzero-exit', 'sys.exit(7)', 7, None),
            ('signal', 'import os,signal;os.kill(os.getpid(),signal.SIGKILL)', -signal.SIGKILL, 'SIGKILL'),
        ]
        for classification, code, expected, signal_name in cases:
            with self.subTest(classification=classification):
                result = self.child(prefix + code, wall_timeout_seconds=2, cpu_limit_seconds=10)
                self.assertEqual(result.classification, classification)
                self.assertEqual(result.returncode, expected)
                self.assertEqual(result.signal_name, signal_name)
                self.assertEqual(result.stdout, 'stdout retained\n')
                self.assertEqual(result.stderr, 'stderr retained\n')
                self.assertEqual(result.normal_exit, classification != 'signal')
                details = format_failure(result, 'required marker absent')
                for fact in [classification, 'command:', 'cwd:', f'exit code: {expected}',
                             'CPU 10s; wall 2s', 'elapsed wall:', 'stdout retained', 'stderr retained']:
                    self.assertIn(fact, details)
                self.assertNotIn('OOM', details)

    def test_optional_limits_are_explicit_and_cpu_limit_is_applied(self):
        result = self.child('import resource;print(resource.getrlimit(resource.RLIMIT_CPU))',
                            wall_timeout_seconds=60, cpu_limit_seconds=10)
        self.assertEqual(result.stdout.strip(), '(10, 10)')
        self.assertEqual(result.cpu_limit_seconds, 10)
        self.assertEqual(result.wall_timeout_seconds, 60)
        unlimited = self.child('pass')
        self.assertIsNone(unlimited.cpu_limit_seconds)
        self.assertIsNone(unlimited.wall_timeout_seconds)
        self.assertIn('CPU not configured; wall not configured', format_failure(unlimited, 'no marker'))

    def test_spawn_failure_reports_actual_command_and_error(self):
        command = [str(SCRIPTS / 'does-not-exist-diagnostics-control')]
        result = run_process(command, cwd=SCRIPTS, wall_timeout_seconds=2)
        self.assertFalse(result.normal_exit)
        self.assertEqual(result.classification, 'spawn-failure')
        self.assertIsNone(result.returncode)
        details = format_failure(result, 'could not start check')
        self.assertIn(command[0], details)
        self.assertIn('FileNotFoundError', details)
        self.assertIn('exit code: unavailable', details)

    def test_wall_timeout_stops_parent_and_descendant_and_preserves_output_once(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / 'descendant-finished'
            descendant = 'import pathlib,time;time.sleep(.5);pathlib.Path(' + repr(str(marker)) + ').touch()'
            code = ('import os,subprocess,sys,time;'
                    f'child=subprocess.Popen([sys.executable,"-c",{descendant!r}]);'
                    'print("parent="+str(os.getpid()),flush=True);'
                    'print("descendant="+str(child.pid),file=sys.stderr,flush=True);time.sleep(5)')
            result = self.child(code, wall_timeout_seconds=.15, cpu_limit_seconds=10)
            self.assertEqual(result.classification, 'wall-timeout')
            self.assertTrue(result.wall_timed_out)
            self.assertFalse(result.normal_exit)
            self.assertEqual(result.returncode, -signal.SIGKILL)
            self.assertEqual(result.stdout.count('parent='), 1)
            self.assertEqual(result.stderr.count('descendant='), 1)
            parent = int(result.stdout.strip().split('=')[1])
            descendant_pid = int(result.stderr.strip().split('=')[1])
            for pid in [parent, descendant_pid]:
                # An orphan can briefly remain a zombie until the container init reaps it.
                stat = Path(f'/proc/{pid}/stat')
                self.assertTrue(not stat.exists() or stat.read_text().split(') ')[1].startswith('Z '))
            time.sleep(.6)
            self.assertFalse(marker.exists(), 'descendant must not continue after the parent timeout')
            self.assertLess(result.elapsed_wall_seconds, 2)
            self.assertIn('wall timeout: true', format_failure(result, 'wall limit'))


def load_wrapper(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), SCRIPTS / name)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ProofGateDiagnosticsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / 'examples').mkdir()
        (self.root / 'vendor/bendlib/packages/bend-mathlib').mkdir(parents=True)
        (self.root / 'examples/core.bend').write_text('original')
        self.proof = self.root / 'examples/PROOF.bend'
        self.proof.write_text('proof fixture')
        self.manifest = self.root / 'mutants.json'
        self.manifest.write_text(json.dumps([dict(source='examples/core.bend', old='original', new='mutated',
                                                    proof='examples/PROOF.bend', law='claim', label='fixture')]))
        self.bend = self.root / 'bend'
        self.bend.write_text('''#!/usr/bin/env python3
import os,signal,sys,time
from pathlib import Path
source=Path(sys.argv[1]).read_text()
if os.environ.get('BENDTT')=='/usr/bin/false':stage='kernel'
elif 'unsafe_claim' in source:stage='unsafe'
elif '--check-only' in sys.argv:stage=('invalid' if 'True{}' in source else 'valid') if 'typecheck-control' in sys.argv[1] else 'compile'
else:stage='proof'
if os.environ.get('FAULT_STAGE')==stage:
 mode=os.environ['FAULT_MODE']
 if mode=='signal':
  print('SOME PROOFS FAIL\\nLocation: Laws.claim',flush=True)
  os.kill(os.getpid(),signal.SIGKILL)
 if mode=='timeout':
  print('partial child output',flush=True);time.sleep(5)
 if mode=='zero':sys.exit(0)
 if mode=='nonzero':print('unrelated exit failure');sys.exit(7)
 if mode=='unrelated-one':print('unrelated exit failure');sys.exit(1)
 if mode=='wrong-law':print('SOME PROOFS FAIL\\nLocation: Laws.other');sys.exit(1)
if stage=='kernel':print('Error: BendTT infrastructure: kernel exited 1 without a verdict');sys.exit(1)
if stage=='unsafe':print('unsafe\\nSOME PROOFS FAIL');sys.exit(1)
if stage=='invalid':sys.exit(1)
if stage in ('valid','compile'):sys.exit(0)
if os.environ.get('GATE')=='mutants':print('SOME PROOFS FAIL\\nLocation: Laws.claim');sys.exit(1)
print('ALL PROOFS CHECK')
''')
        self.bend.chmod(0o755)

    def invoke(self, script, *, stage='', mode='', bend=None):
        module = load_wrapper(script)
        module.ROOT = self.root
        target = self.manifest if 'mutants' in script else self.proof
        environment = dict(BEND=str(bend or self.bend), FAULT_STAGE=stage, FAULT_MODE=mode,
                           GATE='mutants' if 'mutants' in script else 'laws')
        def short_deadline(command, **kwargs):
            kwargs['wall_timeout_seconds'] = .2
            return run_process(command, **kwargs)
        output = io.StringIO()
        with mock.patch.dict(os.environ, environment), mock.patch.object(sys, 'argv', [script, str(target)]), \
                mock.patch.object(module, 'run_process', short_deadline), contextlib.redirect_stdout(output):
            status = module.main()
        return bool(status), output.getvalue()

    def test_zero_exit_without_marker_and_all_actual_faults_fail_proof(self):
        for mode, kind in [('zero', 'zero-exit'), ('nonzero', 'nonzero-exit'),
                           ('signal', 'signal'), ('timeout', 'wall-timeout')]:
            with self.subTest(mode=mode):
                failed, output = self.invoke('check-bend-laws.py', stage='proof', mode=mode)
                self.assertTrue(failed)
                self.assertIn('classification: ' + kind, output)
                self.assertIn('proof requires exit 0 and ALL PROOFS CHECK', output)
        failed, output = self.invoke('check-bend-laws.py')
        self.assertFalse(failed, output)

    def test_negative_controls_require_their_specific_normal_rejection(self):
        for stage in ['kernel', 'unsafe']:
            for mode in ['zero', 'unrelated-one', 'signal', 'timeout']:
                with self.subTest(stage=stage, mode=mode):
                    failed, output = self.invoke('check-bend-laws.py', stage=stage, mode=mode)
                    self.assertTrue(failed)
                    self.assertIn('FAIL', output)
                    self.assertIn('command:', output)
        failed, output = self.invoke('check-bend-laws.py', bend=self.root / 'missing-bend')
        self.assertTrue(failed)
        self.assertIn('classification: spawn-failure', output)

    def test_mutants_require_normal_exit_one_and_the_named_law(self):
        for mode in ['zero', 'nonzero', 'signal', 'timeout', 'wrong-law']:
            with self.subTest(mode=mode):
                failed, output = self.invoke('check-bend-mutants.py', stage='proof', mode=mode)
                self.assertTrue(failed)
                self.assertIn('mutant requires exit 1, SOME PROOFS FAIL and named law claim', output)
        failed, output = self.invoke('check-bend-mutants.py')
        self.assertFalse(failed, output)

    def test_compile_and_typecheck_controls_do_not_accept_process_faults(self):
        for stage in ['valid', 'invalid', 'compile']:
            for mode in ['signal', 'timeout']:
                with self.subTest(stage=stage, mode=mode):
                    failed, output = self.invoke('check-bend-mutants.py', stage=stage, mode=mode)
                    self.assertTrue(failed)
                    self.assertIn('classification:', output)
                    self.assertIn('command:', output)
        failed, output = self.invoke('check-bend-mutants.py', bend=self.root / 'missing-bend')
        self.assertTrue(failed)
        self.assertIn('classification: spawn-failure', output)


if __name__ == '__main__':
    unittest.main()
