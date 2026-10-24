#!/usr/bin/env python3
"""Offline tests of the oracle, not gameplay equivalence evidence."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("replay_compare", Path(__file__).with_name("replay_compare.py"))
R = importlib.util.module_from_spec(spec); spec.loader.exec_module(R)

def payload(tick=0):
    run = [0] * 29; run[1] = tick; run[12] = [0] * 24; run[13] = [0] * 18; run[27] = []
    body = lambda seed: [0, 0, 8, 0, 0, 0, 0, seed, 0]
    stamp = [[0, 1], [0, 1]]
    return {"run": run, "bodies": [], "offers": [], "snapshots": [], "pending": [],
            "components": {"bodies": [[i+1, body(i), stamp] for i in range(1456)],
                           "vitals": [[i+1, [0, 0], stamp] for i in range(1456)],
                           "motions": [[i+1, [0, 0, 0, 0, [], 0, 0, 0, 0], stamp] for i in range(1456)]},
            "metadata": {"namespace": 1, "allocator": [1457, 1456, 2048, 11, [], [], [[0, 2]] * 2048],
                         "clock": [[0, 1], []], "events": 0, "pendingCommands": 0,
                         "registrations": [], "nextSystemId": 0}}

def replay():
    return [{"type": "start", "schemaVersion": 1, "fixture": "synthetic"},
            {"type": "checkpoint", "fixture": "synthetic", "step": 0, "tick": 0, "payload": payload()},
            {"type": "checkpoint", "fixture": "synthetic", "step": 1, "tick": 1, "payload": payload(1)},
            {"type": "summary", "fixture": "synthetic", "wallMs": 10}]

class CompareTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(); self.addCleanup(self.directory.cleanup)
        self.a = Path(self.directory.name) / "baseline.jsonl"; self.b = Path(self.directory.name) / "candidate.jsonl"
    def write(self, a, b):
        for path, records in [(self.a, a), (self.b, b)]:
            path.write_text("".join(json.dumps(record) + "\n" for record in records))
    def test_equal_state_ignores_only_outer_timing(self):
        a = replay(); b = copy.deepcopy(a); b[-1]["wallMs"] = 1000; self.write(a,b)
        self.assertEqual(R.compare(self.a,self.b)["checkpoints"], 2)
    def test_each_authoritative_or_gameplay_mutation_fails(self):
        mutations = [lambda p:p["run"].__setitem__(4, 1), lambda p:p["components"]["bodies"][499][1].__setitem__(8, 0x80000000),
                     lambda p:p["components"]["vitals"][900][1].__setitem__(0, 10), lambda p:p["components"]["motions"][10][1].__setitem__(6, 90),
                     lambda p:p["components"]["motions"][10][1].__setitem__(7, 21), lambda p:p["components"]["motions"][10][1].__setitem__(8, 7),
                     lambda p:p["components"]["bodies"][0][2][1].__setitem__(0, 1), lambda p:p["metadata"]["clock"][0].__setitem__(1, 2),
                     lambda p:p["pending"].append(1), lambda p:p["metadata"]["allocator"][6][50].__setitem__(1, 3)]
        for mutate in mutations:
            a = replay(); b = copy.deepcopy(a); mutate(b[2]["payload"]); self.write(a,b)
            with self.assertRaises(R.ReplayError):R.compare(self.a,self.b)
    def test_bool_never_compares_equal_to_integer(self):
        a=replay(); b=copy.deepcopy(a); b[2]["payload"]["run"][4]=False; self.write(a,b)
        with self.assertRaises(R.ReplayError):R.compare(self.a,self.b)
    def test_missing_slots_and_opaque_commands_fail_even_when_both_match(self):
        for change in [lambda p:p["components"]["vitals"].pop(),lambda p:p["metadata"].__setitem__("pendingCommands",1),lambda p:p["components"]["motions"][0][1].__delitem__(slice(7,None))]:
            a=replay();change(a[2]["payload"]);self.write(a,a)
            with self.assertRaises(R.ReplayError):R.compare(self.a,self.b)
    def test_truncation_duplicate_checkpoint_and_missing_summary_fail(self):
        for change in [lambda a:a.pop(),lambda a:a[2].__setitem__("step",0)]:
            a=replay();change(a);self.write(a,a)
            with self.assertRaises(R.ReplayError):R.compare(self.a,self.b)
        a=replay();self.write(a,a);self.b.write_text(self.b.read_text().rstrip())
        with self.assertRaises(R.ReplayError):R.compare(self.a,self.b)
    def test_trace_binding_rejects_wrong_fixture_and_malformed_actions(self):
        trace = Path(self.directory.name) / "input.trace"
        valid = "1313231410 1 0 100 0 1 1 0 1 0 0 0 0 0"
        trace.write_text(valid)
        a = replay(); fixture = "seed100-profile0-warm0-end1"
        for row in a: row["fixture"] = fixture
        a[0].update(seed=100, profile=0, warmup=0, endTick=1)
        a[-1].update(actions=1, firstTick=0, endTick=1, phase=0)
        self.write(a,a); R.compare(self.a,self.b,trace=trace)
        for text in [valid.replace(" 100 "," 101 "), valid + " 0", valid[:-1] + "2139095040"]:
            trace.write_text(text)
            with self.assertRaises(R.ReplayError): R.compare(self.a,self.b,trace=trace)
    def test_explicit_timing_record_midstream_and_duplicate_rejection(self):
        a = replay(); b = copy.deepcopy(a)
        a.insert(2,{"type":"replay-summary","windowMs":10})
        b.insert(2,{"type":"replay-summary","windowMs":999})
        self.write(a,b); R.compare(self.a,self.b)
        b.insert(2,{"type":"replay-summary","windowMs":1}); self.write(a,b)
        with self.assertRaises(R.ReplayError): R.compare(self.a,self.b)
    def test_duplicate_json_keys_and_nonfinite_fail(self):
        for text in ['{"type":"start","type":"summary"}\n','{"type":"start","n":NaN}\n']:
            self.a.write_text(text);self.b.write_text(text)
            with self.assertRaises(R.ReplayError):R.compare(self.a,self.b)

if __name__ == "__main__":unittest.main()
