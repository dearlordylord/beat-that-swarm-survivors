#!/usr/bin/env python3
"""Offline current-schema controls; actual gameplay evidence is captured separately."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
import replay_compare as R
import current_replay_schema as C
import current_replay_fixture as F

class CompareTest(unittest.TestCase):
    def setUp(self):
        self.directory=tempfile.TemporaryDirectory();self.addCleanup(self.directory.cleanup)
        self.a=Path(self.directory.name)/'a.jsonl';self.b=Path(self.directory.name)/'b.jsonl'
    def write(self,a,b):
        for path,rows in ((self.a,a),(self.b,b)):path.write_text(''.join(json.dumps(r)+'\n' for r in rows))
    def compare(self):return R.compare(self.a,self.b,layout=F.LAYOUT)
    def test_equal_ignores_only_outer_timing(self):
        a=F.replay();b=copy.deepcopy(a);b[-1]['wallMs']=1000;self.write(a,b)
        self.assertEqual(self.compare()['checkpoints'],2)
    def test_physical_handles_are_not_semantic_slots(self):
        p=F.payload();C.validate_payload(p,0,F.LAYOUT)
        self.assertNotEqual(p['components']['actorColumns']['identities'][0][0]-1,p['components']['actorColumns']['identities'][0][1])
    def test_actual_authority_changes_compare_unequal(self):
        for family,index,word in [('spaces',1,0),('vitals',1,0),('statuses',1,1),('shots',0,1),('trajectories',0,5),('pickups',2,1)]:
            a=F.replay();b=copy.deepcopy(a);b[2]['payload']['components']['actorColumns'][family][index][1][word]+=1;self.write(a,b)
            with self.assertRaises(R.ReplayError):self.compare()
    def test_equal_malformed_world_is_rejected(self):
        mutations=[lambda p:p['components']['actorColumns']['identities'][1].__setitem__(1,2),
                   lambda p:p['components']['actorColumns']['roles'][0].__setitem__(1,'EnemySlot'),
                   lambda p:p['components']['actorColumns']['vitals'].pop(),
                   lambda p:p['components']['actorColumns']['shots'][1].__setitem__(1,[0,1,1]),
                   lambda p:p['components']['actorColumns']['projectileCandidates'].reverse(),
                   lambda p:p['components']['actorColumns']['bodies'][0].__setitem__(1,[0]*9),
                   lambda p:p['components']['players'][0].__setitem__(1,[0,[],0]),
                   lambda p:p['metadata'].__setitem__('pendingCommands',1),
                   lambda p:p['metadata']['allocator'][5].pop(),
                   lambda p:p['metadata']['clock'][1].append([0,1]),
                   lambda p:p['components']['actorColumns']['spaces'][0][2][1].__setitem__(1,2),
                   lambda p:p['components']['actorColumns'].__setitem__('motions',[])]
        for change in mutations:
            a=F.replay();change(a[2]['payload']);self.write(a,a)
            with self.assertRaises((R.ReplayError,ValueError)):self.compare()
    def test_bool_is_not_u32_even_when_both_equal(self):
        a=F.replay();a[2]['payload']['run'][4]=False;self.write(a,a)
        with self.assertRaises(R.ReplayError):self.compare()
    def test_snapshot_must_match_actual_authority(self):
        a=F.replay();self.write(a,a);self.compare()
        shot=next(s['projectile'] for s in a[2]['payload']['snapshots'] if 'projectile' in s)
        shot['payload']=copy.deepcopy(shot['payload']);shot['payload'][1]=99;self.write(a,a)
        with self.assertRaises(R.ReplayError):self.compare()
    def test_truncation_order_missing_summary_and_unknown_fields(self):
        changes=[lambda a:a.pop(),lambda a:a[2].__setitem__('step',0),lambda a:a[0].__setitem__('extra',1),lambda a:a[2]['payload'].__setitem__('extra',1)]
        for change in changes:
            a=F.replay();change(a);self.write(a,a)
            with self.assertRaises(R.ReplayError):self.compare()
        a=F.replay();self.write(a,a);self.b.write_text(self.b.read_text().rstrip())
        with self.assertRaises(R.ReplayError):self.compare()
    def test_duplicate_json_and_nonfinite_fail(self):
        for text in ['{"type":"start","type":"summary"}\n','{"type":"start","n":NaN}\n']:
            self.a.write_text(text);self.b.write_text(text)
            with self.assertRaises(R.ReplayError):self.compare()
    def test_actual_world_clock_cannot_regress(self):
        a=F.replay();p=a[2]['payload'];p['metadata']['clock'][0]=[0,0]
        for records in p['components']['actorColumns'].values():
            if records and isinstance(records[0],list) and len(records[0])==3 and isinstance(records[0][2],list):
                for row in records:
                    if row[1] is not None:row[2]=[[0,0],[0,0]]
        self.write(a,a)
        with self.assertRaises(R.ReplayError):self.compare()
    def test_trace_binds_actual_schedule(self):
        trace=Path(self.directory.name)/'trace';trace.write_text('1313231410 1 0 100 0 1 1 0 1 0 0 0 0 0')
        self.write(F.replay(),F.replay());R.compare(self.a,self.b,layout=F.LAYOUT,trace=trace)
        trace.write_text(trace.read_text().replace(' 100 ',' 101 '))
        with self.assertRaises(R.ReplayError):R.compare(self.a,self.b,layout=F.LAYOUT,trace=trace)

if __name__=='__main__':unittest.main()
