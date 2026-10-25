#!/usr/bin/env python3
"""Supervisor/receipt controls; actual game integration is tested separately."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('native_coop_batch', Path(__file__).with_name('native-coop-batch.py'))
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class NativeCoopSupervisorTests(unittest.TestCase):
    def setUp(self):
        M.STOP.clear()

    def tearDown(self):
        M.STOP.clear()

    def files(self):
        return {'examples/survivors/party-difficulty.bend': b'import Base\ndef extra_per_player_percent() -> U32: 25\n',
                'examples/survivors/game.bend': b'import Base\ndef hp() -> U32: 70\n',
                'examples/survivors/offline-policy.bend': b'import Base\ndef policy() -> U32: 1\n',
                'examples/survivors/offline-coop-batch.bend': b'import Base\ndef runner() -> U32: 1\n'}

    def row(self, kind='sample', tick=0, phase=0, outcome=None):
        row = {'type': kind, 'seed': 100, 'tick': tick, 'phase': phase,
               'population': 120, 'ordinaryPopulation': 120, 'bossPopulation': 0,
               'hp0': 70, 'hp1': 70, 'maxHp0': 70, 'maxHp1': 70,
               'px0': 7200, 'py0': 7200, 'px1': 7232, 'py1': 7200,
               'xp': 0, 'level': 1, 'kills': 0, 'choices0': 0, 'choices1': 0}
        if tick == 0:
            row['initialSetup'] = {'stage': 0, 'mode': 0, 'players': [{}, {}]}
        if outcome is not None:
            row['outcome'] = outcome
        return row

    def validate(self, rows, ticks=120):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'run.jsonl'
            path.write_text(''.join(json.dumps(row) + '\n' for row in rows))
            return M.validate_records(path, 100, ticks)

    def test_only_coefficient_literal_is_replaced(self):
        files = self.files()
        candidate = M.transformed(files, 100)
        self.assertEqual([name for name in files if files[name] != candidate[name]],
                         ['examples/survivors/party-difficulty.bend'])
        self.assertIn(b'-> U32: 100', candidate['examples/survivors/party-difficulty.bend'])
        self.assertIn(b'-> U32: 25', files['examples/survivors/party-difficulty.bend'])

    def test_config_variants_keep_context_and_policy(self):
        base = M.identities(self.files(), b'dependency')
        for extra in (0, 50, 100):
            candidate = M.identities(M.transformed(self.files(), extra), b'dependency')
            self.assertEqual(base['gameContextHash'], candidate['gameContextHash'])
            self.assertEqual(base['policyHash'], candidate['policyHash'])
            self.assertNotEqual(base['gameHash'], candidate['gameHash'])

    def test_other_game_change_does_not_disappear_from_context(self):
        files = self.files()
        before = M.identities(files, b'dependency')
        files['examples/survivors/game.bend'] += b'def damage() -> U32: 1\n'
        self.assertNotEqual(before['gameContextHash'], M.identities(files, b'dependency')['gameContextHash'])

    def test_dependency_change_is_bound(self):
        self.assertNotEqual(M.identities(self.files(), b'old')['gameContextHash'],
                            M.identities(self.files(), b'new')['gameContextHash'])

    def test_duplicate_source_seam_is_rejected(self):
        files = self.files()
        files['examples/survivors/party-difficulty.bend'] *= 2
        with self.assertRaises(ValueError):
            M.transformed(files, 25)

    def test_horizon_is_not_victory(self):
        result = self.validate([self.row(), self.row('summary', 120, 0, 'horizon')])
        self.assertEqual(result['outcome'], 'horizon')
        with self.assertRaises(ValueError):
            self.validate([self.row(), self.row('summary', 120, 0, 'victory')])

    def test_terminal_priority_can_stop_before_horizon(self):
        for phase, outcome in [(3, 'defeat'), (4, 'victory'), (5, 'aborted')]:
            self.assertEqual(self.validate([self.row(), self.row('summary', 60, phase, outcome)])['outcome'], outcome)

    def test_incomplete_horizon_is_rejected(self):
        with self.assertRaises(ValueError):
            self.validate([self.row(), self.row('summary', 60, 0, 'horizon')])

    def test_repeated_sample_tick_is_rejected(self):
        with self.assertRaises(ValueError):
            self.validate([self.row(), self.row(), self.row('summary', 120, 0, 'horizon')])

    def test_missing_actual_setup_is_rejected(self):
        first = self.row()
        del first['initialSetup']
        with self.assertRaises(ValueError):
            self.validate([first, self.row('summary', 120, 0, 'horizon')])

    def test_missing_final_summary_is_rejected(self):
        with self.assertRaises(ValueError):
            self.validate([self.row()])
        with self.assertRaises(ValueError):
            self.validate([])

    def test_nonfinite_positions_are_rejected(self):
        first = self.row()
        first['px0'] = float('nan')
        with self.assertRaises(ValueError):
            self.validate([first, self.row('summary', 120, 0, 'horizon')])

    def test_child_timeout_is_not_success(self):
        code, timed = M.execute([sys.executable, '-c', 'import time;time.sleep(20)'],
                                subprocess.DEVNULL, subprocess.DEVNULL, timeout=.05)
        self.assertTrue(timed)
        self.assertNotEqual(code, 0)
        self.assertEqual(M.ACTIVE, {})

    def test_child_failure_is_not_timeout(self):
        code, timed = M.execute([sys.executable, '-c', 'raise SystemExit(7)'],
                                subprocess.DEVNULL, subprocess.DEVNULL, timeout=5)
        self.assertFalse(timed)
        self.assertEqual(code, 7)

    def test_duplicate_seeds_are_rejected_before_build(self):
        with self.assertRaises(ValueError):
            M.main(['--seeds', '100,100'])

    def test_locked_fresh_character_is_rejected_before_build(self):
        with self.assertRaises(ValueError):
            M.main(['--profile', 'fresh', '--character1', '2'])


if __name__ == '__main__':
    unittest.main()
