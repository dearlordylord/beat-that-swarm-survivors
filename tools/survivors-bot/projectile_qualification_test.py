#!/usr/bin/env python3
"""Controls for projectile authority and the semantic projection, not gameplay."""
import copy
import unittest
import current_replay_fixture as F
import projectile_qualification as P
import replay_compare as R

def sample():
    value=F.payload();value['components']=value['components']['actorColumns']
    c=value['components']
    for i,row in enumerate(c['roles']):
        if row[1] in P.PROJECTILE_ROLES:
            c['shots'][i][1]=[1,17,1]
            c['trajectories'][i][1]=[0,0,10,2,[],7,2,0 if row[1]=='PlayerProjectileSlot' else None]
    return value

class ProjectileQualification(unittest.TestCase):
    def project(self, value):
        return P.validate_and_project(value['components'], value['metadata'], F.LAYOUT)

    def test_positive_and_damage_source_control(self):
        original = sample()
        facts = self.project(original)
        self.assertEqual(len(facts), 3)
        changed = copy.deepcopy(original)
        changed['components']['shots'][0][1][1] += 1
        self.assertNotEqual(facts, self.project(changed))
        self.assertEqual(self.project(changed)[0]['damage'], 18)

    def test_actual_authority_and_identity_fail_closed(self):
        mutations = [
                        lambda c: c['shots'][1].__setitem__(1, [1, 17, 1]),
            lambda c: c['shots'][0].__setitem__(1, None),
            lambda c: c['identities'][2].__setitem__(1, 3),
            lambda c: c['shots'][0].__setitem__(2, [[0, 1000], [0, 1000]]),
            lambda c: c['spaces'][0].__setitem__(1, None),
            lambda c: c['shots'][0].__setitem__(0, 99),
            lambda c: c['shots'][0][1].__setitem__(2, 7),
            lambda c: c['trajectories'][0][1].__setitem__(4, None),
        ]
        for mutation in mutations:
            value = sample()
            mutation(value['components'])
            with self.subTest(mutation=mutation), self.assertRaises((R.ReplayError, ValueError, TypeError)):
                self.project(value)

    def test_typed_snapshot_has_no_hidden_fields_or_unknown_side(self):
        value = dict(spatial=[0,0,0,0], identity=2, side='player', payload=[1,17,1],
                     trajectory=[0,0,10,2,[],7,2,1])
        P.state(value)
        for changed in ({**value, 'health': 17}, {**value, 'side': 'unknown'}):
            with self.assertRaises(R.ReplayError):
                P.state(changed)

if __name__ == '__main__':
    unittest.main()
