#!/usr/bin/env python3
"""Synthetic verifier controls, not game-equivalence evidence."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
import ecs_migration_compare as M

LAYOUT = dict(enemyCount=2, relicSeed=1, playerStart=2, hostileStart=4, xpStart=5, totalCount=6)
STAMP = [[0, 1], [0, 10]]


def payload(tick, migrated):
    run = [0] * 29
    run[1] = tick; run[12] = [0] * 24; run[13] = [0] * 18; run[27] = [1]
    bodies = [[0, 0, 0 if i == 0 else 8, 0, 4, 8, 0, i, 0] for i in range(LAYOUT['totalCount'])]
    motions = [[0, 0, 0, 0, [], 0, 0, 0, 0] for _ in bodies]
    motions[0][5] = 3; motions[2] = [1, 2, 10, 2, [4], 0, 0, 7, 1]
    col = lambda values: [[i + 1, value, copy.deepcopy(STAMP if value is not None else [None, None])] for i, value in enumerate(values)]
    components = {'bodies': col(copy.deepcopy(bodies)), 'vitals': col([[4, 8] for _ in bodies]), 'motions': col(copy.deepcopy(motions))}
    if migrated:
        roles = [M.assigned(i, LAYOUT) for i in range(len(bodies))]
        components['roles'] = col(roles)
        components['pickups'] = col([[bodies[i][4], bodies[i][5], bodies[i][3], int(bodies[i][2] == 2)] if role == 'XpSlot' else None for i, role in enumerate(roles)])
        components['vitals'] = col([[4, 8] if role in M.ENEMIES else None for role in roles])
        components['trajectories'] = col([motions[i][:5] + motions[i][7:] if role in M.PROJECTILES else None for i, role in enumerate(roles)])
        components['statuses'] = col([motions[i][5:7] if role in M.ENEMIES else None for i, role in enumerate(roles)])
        components['motions'] = [[i + 1, motion, None] for i, motion in enumerate(copy.deepcopy(motions))]
        components['movementCandidates'] = [[9, 1, 1]]
        components['projectileCandidates'] = [[9, i + 1, 1] for i, role in enumerate(roles) if role in M.PROJECTILES]
        components['poolCandidates'] = [[9, i + 1, 1] for i, role in enumerate(roles) if role in M.ENEMIES or role == 'XpSlot']
    return {'run': run, 'bodies': copy.deepcopy(bodies), 'offers': [[1, 2, 3]],
            'snapshots': [[copy.deepcopy(bodies[2]), copy.deepcopy(motions[2])]], 'pending': [1], 'components': components,
            'metadata': {'namespace': 9, 'allocator': [7, 6, 8, 3, [], [[i, 1] for i in range(1, 7)], [[0, 0]] + [[1, 2]] * 6 + [[0, 0]]],
                         'clock': [[0, 100 if migrated else 80], []], 'events': 0, 'pendingCommands': 0, 'registrations': [], 'nextSystemId': 0}}


def replay(migrated):
    fixture = 'seed100-profile0-warm0-end1'
    return [{'type': 'start', 'schemaVersion': 1, 'fixture': fixture, 'seed': 100, 'profile': 0, 'warmup': 0, 'endTick': 1},
            {'type': 'checkpoint', 'fixture': fixture, 'step': 0, 'payload': payload(0, migrated)},
            {'type': 'checkpoint', 'fixture': fixture, 'step': 1, 'payload': payload(1, migrated)},
            {'type': 'summary', 'fixture': fixture, 'actions': 1, 'firstTick': 0, 'endTick': 1, 'phase': 0}]


class MigrationTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name); self.a = self.root / 'old.jsonl'; self.b = self.root / 'new.jsonl'; self.trace = self.root / 'trace'
        self.trace.write_text('1313231410 1 0 100 0 1 1 0 1 0 0 0 0 0')

    def write(self, a=None, b=None):
        for path, records in ((self.a, a if a is not None else replay(False)), (self.b, b if b is not None else replay(True))):
            path.write_text(''.join(json.dumps(row) + '\n' for row in records))

    def compare(self):
        return M.compare(self.a, self.b, layout=LAYOUT, trace=self.trace)

    def reject(self, mutate, *, baseline=False):
        a = replay(False); b = replay(True); mutate((a if baseline else b)[2]['payload']); self.write(a, b)
        with self.assertRaises((M.ReplayError, TypeError, IndexError)):
            self.compare()

    def test_allocator_uses_direct_key_indices_with_consumed_sentinel(self):
        meta = payload(0, True)['metadata']
        now, issued = M.validate_metadata(meta, LAYOUT['totalCount'])
        self.assertEqual(meta['allocator'][6][0], [0, 0])
        self.assertEqual(issued[0], [1, 1])
        self.assertEqual(issued[-1], [LAYOUT['totalCount'], 1])
        bad = copy.deepcopy(meta)
        bad['allocator'][6][1] = [1, 0]
        with self.assertRaises(M.ReplayError):
            M.validate_metadata(bad, LAYOUT['totalCount'])
        bad = copy.deepcopy(meta)
        bad['allocator'][1] = bad['allocator'][2]
        with self.assertRaises(M.ReplayError):
            M.validate_metadata(bad, LAYOUT['totalCount'])

    def test_migration_accepts_different_actual_stamps_and_clock(self):
        self.write(); result = self.compare()
        self.assertEqual(result['checkpoints'], 2)
        self.assertEqual(result['comparison'], 'explicit-ecs-schema-migration')
        self.assertEqual(result['exclusions'], M.EXCLUSIONS)

    def test_every_run_scalar_and_list_word_is_compared(self):
        for i in range(29):
            with self.subTest(index=i):
                self.reject(lambda p, i=i: p['run'][i].append(1) if isinstance(p['run'][i], list) else p['run'].__setitem__(i, p['run'][i] + 1))

    def test_every_frame_offer_snapshot_pending_field_is_compared(self):
        for i in range(9):
            self.reject(lambda p, i=i: p['bodies'][0].__setitem__(i, p['bodies'][0][i] + 1))
            self.reject(lambda p, i=i: p['snapshots'][0][0].__setitem__(i, p['snapshots'][0][0][i] + 1))
            self.reject(lambda p, i=i: p['snapshots'][0][1][i].append(8) if i == 4 else p['snapshots'][0][1].__setitem__(i, p['snapshots'][0][1][i] + 1))
        for i in range(3):
            self.reject(lambda p, i=i: p['offers'][0].__setitem__(i, p['offers'][0][i] + 1))
        self.reject(lambda p: p['pending'].append(2))

    def test_authoritative_payloads_and_physical_motion_coherence(self):
        for i in range(9):
            self.reject(lambda p, i=i: p['components']['bodies'][0][1].__setitem__(i, p['components']['bodies'][0][1][i] + 1))
            self.reject(lambda p, i=i: p['components']['motions'][2][1][i].append(8) if i == 4 else p['components']['motions'][2][1].__setitem__(i, p['components']['motions'][2][1][i] + 1))
        for i in range(2):
            self.reject(lambda p, i=i: p['components']['vitals'][0][1].__setitem__(i, 99))
        self.reject(lambda p: p['components']['trajectories'][2][1].__setitem__(0, 99))
        self.reject(lambda p: p['components']['statuses'][0][1].__setitem__(0, 99))
        # Mutating both physical and derived data still must fail old/new equality.
        def coherent(p):
            p['components']['statuses'][0][1][0] = 99; p['components']['motions'][0][1][5] = 99
        self.reject(coherent)
        self.reject(lambda p: p['components']['motions'][0][1].__setitem__(0, 1), baseline=True)

    def test_sparse_presence_roles_and_unknown_fields_fail_closed(self):
        for family, offset, value in [('vitals', 2, [0, 0]), ('statuses', 5, [0, 0]), ('trajectories', 0, [0, 0, 0, 0, [], 0, 0]), ('vitals', 0, None), ('statuses', 0, None), ('trajectories', 2, None)]:
            self.reject(lambda p, family=family, offset=offset, value=value: p['components'][family][offset].__setitem__(1, value))
        self.reject(lambda p: p['components']['roles'][0].__setitem__(1, 'XpSlot'))
        self.reject(lambda p: p['components']['roles'][0].__setitem__(1, 'UnknownSlot'))
        self.reject(lambda p: p['components'].__setitem__('unknown', []))
        self.reject(lambda p: p.__setitem__('unknown', []))
        self.reject(lambda p: p['metadata'].__setitem__('unknown', 0))
        self.reject(lambda p: p['components'].pop('statuses'))
        self.reject(lambda p: p['components']['bodies'].pop())
        self.reject(lambda p: p['components']['bodies'].reverse())

    def test_authoritative_pickup_sparse_payload_and_body_view(self):
        for field in range(4):
            self.reject(lambda p, field=field: p['components']['pickups'][5][1].__setitem__(field, 99))
        self.reject(lambda p: p['components']['pickups'][5][1].__setitem__(3, 1))
        self.reject(lambda p: p['components']['pickups'][5].__setitem__(1, None))
        self.reject(lambda p: p['components']['pickups'][0].__setitem__(1, [0, 0, 0, 0]))
        self.reject(lambda p: p['components']['pickups'][5].__setitem__(2, [[0, 10], [0, 1]]))
        self.reject(lambda p: p['components'].pop('pickups'))
        def coherent_corruption(p):
            p['components']['pickups'][5][1][0] = 99
            p['components']['bodies'][5][1][4] = 99
        self.reject(coherent_corruption)

    def test_candidate_stale_foreign_missing_order_duplicate(self):
        for name in ('movementCandidates', 'projectileCandidates', 'poolCandidates'):
            for column, value in ((0, 88), (1, 99), (2, 99)):
                self.reject(lambda p, name=name, column=column, value=value: p['components'][name][0].__setitem__(column, value))
            self.reject(lambda p, name=name: p['components'][name].append(copy.deepcopy(p['components'][name][0])))
            self.reject(lambda p, name=name: p['components'][name].pop())
        for name in ('projectileCandidates', 'poolCandidates'):
            self.reject(lambda p, name=name: p['components'][name].reverse())
        self.reject(lambda p: p['components'].__setitem__('projectileCandidates', None))
        self.reject(lambda p: p['metadata']['allocator'][5][0].__setitem__(1, 99))
        self.reject(lambda p: p['metadata']['allocator'][6][1].__setitem__(1, 1))
        a = replay(False); b = replay(True)
        for name in ('movementCandidates', 'projectileCandidates', 'poolCandidates'):
            b[2]['payload']['components'][name] = None
        self.write(a, b); self.compare()

    def test_actual_stamp_validity_and_no_invented_unified_stamp(self):
        for stamp in ([None, None], [[0, 11], [0, 10]], [[0, 1], [0, 101]], [[-1, 0], [0, 10]], [[0, True], [0, 10]], [None, [0, 10]]):
            self.reject(lambda p, stamp=stamp: p['components']['bodies'][0].__setitem__(2, stamp))
        self.reject(lambda p: p['components']['statuses'][5].__setitem__(2, copy.deepcopy(STAMP)))
        self.reject(lambda p: p['components']['motions'][0].__setitem__(2, copy.deepcopy(STAMP)))
        self.reject(lambda p: p['metadata']['clock'].__setitem__(1, [[0, 10]]))
        self.reject(lambda p: p['metadata']['clock'].__setitem__(0, [0, 90]))

    def test_strict_records_trace_completion_and_layout(self):
        self.write(); self.b.write_text(self.b.read_text().rstrip())
        with self.assertRaises(M.ReplayError): self.compare()
        for change in (lambda b: b[0].__setitem__('unknown', 1), lambda b: b[-1].__setitem__('actions', True), lambda b: b[0].__setitem__('seed', 101), lambda b: b.pop(), lambda b: b[2].__setitem__('step', 0)):
            b = replay(True); change(b); self.write(b=b)
            with self.assertRaises(M.ReplayError): self.compare()
        for text in ('{"type":"start","type":"summary"}\n', '{"type":"start","n":NaN}\n'):
            self.b.write_text(text)
            with self.assertRaises(M.ReplayError): self.compare()
        for layout in ({**LAYOUT, 'other': 1}, {**LAYOUT, 'playerStart': 0}, {**LAYOUT, 'enemyCount': True}):
            with self.assertRaises(M.ReplayError): M.validate_layout(layout)

    def test_excluded_vitals_and_valid_stamp_changes_do_not_hide_gameplay(self):
        a = replay(False); b = replay(True)
        a[2]['payload']['components']['vitals'][5][1] = [55, 66]
        b[2]['payload']['components']['bodies'][0][2] = [[0, 2], [0, 90]]
        b[-1]['windowMs'] = 999
        self.write(a, b); self.compare()
        self.assertEqual(M.R.compare.__module__, 'replay_compare')


if __name__ == '__main__':
    unittest.main()
