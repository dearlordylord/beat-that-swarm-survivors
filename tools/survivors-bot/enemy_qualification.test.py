#!/usr/bin/env python3
"""Controls for actual membership, issued identities and enemy health semantics."""
import copy
import unittest
import enemy_qualification as E
import replay_compare as R


class EnemyQualification(unittest.TestCase):
    def setUp(self):
        self.layout = dict(enemyCount=2, relicSeed=1, playerStart=2, hostileStart=3, xpStart=4, totalCount=5)
        self.metadata = {'clock': [[0, 10]]}
        identities = [4, 2, 1, 0, 3]  # Issued slots deliberately differ from handles.
        self.components = {key: [] for key in ('enemyPhases', 'vitals', 'statuses', 'spaces', 'bodies', 'roles', 'identities')}
        for handle, slot in enumerate(identities, 1):
            role = E.M.assigned(slot, self.layout)
            values = dict(enemyPhases=[1, 9] if role == 'EnemySlot' else [0, 0] if role == 'RelicSlot' else None,
                          vitals=[50, 100] if role == 'EnemySlot' else None,
                          statuses=[7, 11] if role == 'EnemySlot' else None,
                          spaces=[0, 0, 20, 0], bodies=None, roles=role, identities=slot)
            for key, value in values.items():
                self.components[key].append([handle, value, [[0, 1], [0, 2]] if value is not None else [None, None]])

    def check(self):
        return E.validate_and_project(self.components, self.metadata, self.layout)

    def test_issued_identity_and_named_health(self):
        fact, = self.check()
        self.assertEqual((fact['seed'], fact['variant'], fact['health'], fact['maximum']), (0, 9, 50, 100))
        self.assertEqual(fact['status'], dict(slow=7, burn=11))

    def test_bad_membership_identity_phase_and_clock_rejected(self):
        original = copy.deepcopy(self.components)
        mutations = [
            ('bodies', 3, [0] * 9), ('vitals', 0, [1, 2]),
            ('identities', 0, 0), ('enemyPhases', 3, [3, 9]),
        ]
        for family, index, value in mutations:
            with self.subTest(family=family):
                self.components = copy.deepcopy(original)
                self.components[family][index][1] = value
                with self.assertRaises(R.ReplayError):
                    self.check()
        self.components = original
        self.components['statuses'][3][2] = [[0, 1], [0, 11]]
        with self.assertRaises(R.ReplayError):
            self.check()


if __name__ == '__main__':
    unittest.main()
