"""Controls for explicit co-op physical scope and the current column reader."""
import copy
import unittest
import current_replay_schema as C
import current_replay_fixture as F
import coop_world_qualification as W
import qualification_coop_players as P
import replay_compare as R

def party():
    p=F.payload();m=p['metadata'];a=m['allocator']
    a[:4]=[10,9,16,4];a[5].extend([[8,0],[9,0]]);a[6].extend([[0,2],[0,2]]+[[0,0]]*6)
    personal=[0]*16;personal[5]=[0]*24;personal[6]=[0]*18
    p['components']['players'].extend([[8,[0,copy.deepcopy(personal),1],copy.deepcopy(F.STAMP)],[9,[1,copy.deepcopy(personal),0],copy.deepcopy(F.STAMP)]])
    c=p['components']['actorColumns'];c['shots'][0][1]=[1,17,1];c['trajectories'][0][1]=[0,0,20,1,[],0,2,1]
    return p,{8:(0,0),9:(1,0)}

class CoopWorldQualification(unittest.TestCase):
    def validate(self,p,refs):return C.validate_pool(p['components'],p['metadata'],p['snapshots'],0,F.LAYOUT,refs)
    def test_actual_extra_allocator_players_are_not_hidden_as_native(self):
        p,refs=party();self.validate(p,refs)
        self.assertEqual(p['metadata']['allocator'][1],9)
        with self.assertRaises(R.ReplayError):C.validate_payload(p,0,F.LAYOUT)
    def test_retained_disconnected_source_is_valid_but_unknown_source_is_not(self):
        p,refs=party();self.validate(p,refs)
        p['components']['actorColumns']['trajectories'][0][1][7]=2
        with self.assertRaises(R.ReplayError):self.validate(p,refs)
    def test_ref_generation_payload_and_stamps_are_actual(self):
        for change in (lambda p,r:r.__setitem__(9,(1,1)),lambda p,r:p['components']['players'][8][1].__setitem__(0,0),lambda p,r:p['components']['players'][8][2][1].__setitem__(1,2)):
            p,refs=party();change(p,refs)
            with self.assertRaises(R.ReplayError):self.validate(p,refs)
    def test_store_reader_opens_only_actual_canonical_owner(self):
        fields={'$':'StoreFields',**{name:object() for name in ('vitals','motions','statuses','pickups','roles','movement','candidates','players','spaces','enemyPhases','identities','shots')}}
        owner={'$':'Owned','state':fields}
        self.assertIs(C.store_fields(owner),fields)
        self.assertIs(C.store_fields(owner)['spaces'],fields['spaces'])
        for invalid in (
            {'$':'Store',**{k:v for k,v in fields.items() if k!='$'}},
            fields,
            {'$':'Wrapped','inner':owner},
            {'$':'Owned','state':{'$':'Store',**{k:v for k,v in fields.items() if k!='$'}}},
            {'$':'Owned','state':fields,'cached':fields},
            {'$':'Owned','state':{k:v for k,v in fields.items() if k!='identities'}},
        ):
            with self.subTest(layout=invalid['$']):
                with self.assertRaises(R.ReplayError):C.store_fields(invalid)
    def test_player_and_full_readers_reject_obsolete_store_as_replay_error(self):
        row={'physical':{'world':{'namespace':1,'clock':{'now':{'$':'Tick','epoch':0,'low':0},'scopes':{'$':'Nil'}},'store':{'$':'Store','players':{}}}}}
        for reader in (P.validate_row,W.extract):
            with self.subTest(reader=reader.__name__):
                with self.assertRaises(R.ReplayError):reader(row)
    def test_indexed_reader_rejects_authority_outside_issued_scope(self):
        none={'$':'None'};stamp={'$':'Some','value':{'$':'Tick','epoch':0,'low':1}}
        value={'$':'Indexed','state':{'$':'IndexedOrdinaryOwned','state':{'$':'IndexedOrdinaryState','values':[none,{'$':'Some','value':3}],'metadata':{'$':'Metadata','capacity':2,'depth':1,'added':[none,stamp],'changed':[none,stamp],'exceptional':{'$':'Nil'}}}}}
        with self.assertRaises(R.ReplayError):W.column(value,W.number,1,(0,1))
        self.assertEqual(W.column(value,W.number,2,(0,1))[1],[2,3,[[0,1],[0,1]]])
    def test_indexed_reader_does_not_accept_another_backend(self):
        with self.assertRaises(R.ReplayError):W.column({'$':'UnknownColumn'},W.number,1,(0,1))

if __name__=='__main__':unittest.main()
