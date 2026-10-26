#!/usr/bin/env python3
"""Exercise verifier call sites with real failing children, without game builds."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from process_diagnostics import run_process

ROOT = Path(__file__).resolve().parents[1]


def load(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class VerificationDiagnosticsTests(unittest.TestCase):
    def test_abi_failures_retain_child_diagnostics(self):
        module = load('abi_diagnostics_fixture', 'scripts/test-generate-bend-types.py')
        case = module.GeneratorTests()
        commands = [
            ([sys.executable, '-c', "import sys; print('exit-marker',file=sys.stderr); sys.exit(23)"], 'exit-marker'),
            ([sys.executable, '-c', 'import os,signal; os.kill(os.getpid(),signal.SIGTERM)'], 'SIGTERM'),
            ([sys.executable, '-c', "import time; print('partial-marker',flush=True); time.sleep(5)"], 'partial-marker'),
            ([str(ROOT / 'missing-diagnostics-executable')], 'missing-diagnostics-executable'),
        ]
        def short_run(command, **kwargs):
            return run_process(command, **{**kwargs, 'wall_timeout_seconds': 0.1})
        for command, marker in commands:
            with self.subTest(marker=marker), patch.object(module, 'run_process', short_run):
                with self.assertRaises(AssertionError) as raised:
                    case.run_checked(command)
                message = str(raised.exception)
                self.assertIn(marker, message)
                self.assertIn(str(ROOT), message)
                self.assertIn(command[0], message)

    def test_cache_compiler_failure_retains_diagnostic(self):
        module = load('cache_key_diagnostics_fixture', 'scripts/native-check-cache-key.py')
        with tempfile.TemporaryDirectory() as directory:
            compiler = Path(directory) / 'compiler'
            compiler.write_text('#!/bin/sh\necho compiler-version-marker >&2\nexit 23\n')
            compiler.chmod(0o755)
            with self.assertRaises(RuntimeError) as raised:
                module.cache_key(ROOT, sys.executable, str(compiler), [])
            message = str(raised.exception)
            for expected in ('compiler-version-marker', '23', str(compiler), str(ROOT)):
                self.assertIn(expected, message)

    def test_negative_controls_refuse_infrastructure_failures(self):
        commands = [
            ([sys.executable, '-c', 'import os,signal; os.kill(os.getpid(),signal.SIGTERM)'], 'SIGTERM'),
            ([sys.executable, '-c', "import time; print('partial-control',flush=True); time.sleep(5)"], 'partial-control'),
            ([str(ROOT / 'missing-control-executable')], 'spawn-failure'),
        ]
        birth = load('birth_diagnostics_fixture', 'examples/survivors/enemy-birth-wiring-control.py')
        authority = load('authority_diagnostics_fixture', 'examples/survivors/capability-controls.test.py')
        for command, marker in commands:
            def fault_run(_command, **kwargs):
                return run_process(command, **{**kwargs, 'wall_timeout_seconds': 0.1})
            with self.subTest(marker=marker), patch.object(birth, 'run_process', fault_run):
                with self.assertRaisesRegex(AssertionError, marker):
                    birth.run(command)
            with tempfile.TemporaryDirectory() as directory, patch.object(authority, 'run_process', fault_run):
                with self.assertRaisesRegex(AssertionError, marker):
                    authority.check(Path(directory), 'fault-control', 'import Base\n')
                self.assertIn(marker, (Path(directory) / 'fault-control.log').read_text())


if __name__ == '__main__':
    unittest.main()
