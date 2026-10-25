import copy
import unittest
import pickup_qualification as P


class PickupAuthority(unittest.TestCase):
    def setUp(self):
        # Physical handles intentionally differ from semantic actor identities.
        values = [(91, 'EnemySlot', 7, [[1, 3], 12, 1], [2, 17]),
                  (33, 'XpSlot', 1056, [[0, 8, 0], 21, 1], None),
                  (74, 'RelicSlot', 511, [[4, 2], 0, 1], [2, 0]),
                  (18, 'PlayerProjectileSlot', 512, None, None)]
        self.c = {name: [] for name in ('roles','identities','spaces','pickups','enemyPhases')}
        for handle, role, identity, payload, phase in values:
            for name, value in [('roles',role),('identities',identity),('spaces',[1,2,3,4]),
                                ('pickups',payload),('enemyPhases',phase)]:
                self.c[name].append([handle,value,[[0,1],[0,1]]])
        self.layout = dict(xpStart=1056,totalCount=1456)

    def project(self, c=None):
        return P.validate_and_project(self.c if c is None else c, {}, self.layout)

    def test_actual_identity_join(self):
        facts = self.project()
        self.assertEqual(set(facts), {7,511,1056})
        self.assertEqual(facts[1056]['item'], dict(kind='xp',amount=8,accumulator=False))
        self.assertEqual(facts[7]['spatial']['xBits'], 1)

    def test_raw_authority_controls(self):
        self.assertEqual(P.controls(self.c,{},self.layout), ['pickup-amount','pickup-generation','pickup-age','pickup-accumulator'])

    def test_payload_membership(self):
        changed = copy.deepcopy(self.c)
        changed['pickups'][3][1] = [[0,8,0],1,1]
        with self.assertRaises(ValueError): self.project(changed)

    def test_occupied_geometry_and_payload_survive(self):
        original = self.project()
        for name, index, value in [('spaces',0,[5,2,3,4]),('pickups',0,[[1,4],12,1])]:
            changed = copy.deepcopy(self.c)
            changed[name][index][1] = value
            self.assertNotEqual(original,self.project(changed))

    def test_invalid_tag_and_phase(self):
        for name, index, value in [('pickups',1,[[9,8],21,1]),('enemyPhases',0,[0,17])]:
            changed = copy.deepcopy(self.c)
            changed[name][index][1] = value
            with self.assertRaises(ValueError): self.project(changed)


if __name__ == '__main__': unittest.main()
