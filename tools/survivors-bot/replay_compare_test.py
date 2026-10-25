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

class SparseCompareTest(unittest.TestCase):
    def setUp(self):
        # Synthetic schema fixtures qualify the comparator, not actual gameplay.
        import ecs_migration_compare_test as S
        self.schema = S
        self.directory = tempfile.TemporaryDirectory(); self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.a = self.root / "baseline.jsonl"; self.b = self.root / "candidate.jsonl"
        self.layout = dict(S.LAYOUT)

    def write(self, left, right):
        for path, rows in ((self.a, left), (self.b, right)):
            path.write_text("".join(json.dumps(row) + "\n" for row in rows))

    def compare(self):
        return R.compare(self.a, self.b, layout=self.layout)

    def test_exact_sparse_mode_accepts_complete_identical_observations(self):
        left = self.schema.replay(True); right = copy.deepcopy(left)
        right[-1]["wallMs"] = 999
        self.write(left, right)
        result = self.compare()
        self.assertEqual(result["comparison"], "exact-sparse-ecs")
        self.assertEqual(result["layout"], self.layout)
        self.assertEqual(result["checkpoints"], 2)
        self.assertNotIn("exclusions", result)

    def test_actual_valid_new_stamps_and_clock_are_never_projected_away(self):
        changes = [lambda p: p["metadata"]["clock"].__setitem__(0, [0, 101])]
        for family, offset in (("bodies", 0), ("vitals", 0), ("statuses", 0),
                               ("trajectories", 2), ("roles", 0), ("pickups", 5)):
            changes.append(lambda p, family=family, offset=offset:
                           p["components"][family][offset].__setitem__(2, [[0, 2], [0, 90]]))
        for mutate in changes:
            left = self.schema.replay(True); right = copy.deepcopy(left)
            mutate(right[2]["payload"])
            # A valid standalone snapshot can still differ from the reference.
            self.schema.M.validate_payload(right[2]["payload"], 1, self.layout, True)
            self.write(left, right)
            with self.assertRaises(R.ReplayError): self.compare()

    def test_identically_malformed_sparse_payloads_fail_closed(self):
        changes = [lambda p: p["components"].pop("statuses"),
                   lambda p: p["components"].__setitem__("unknown", []),
                   lambda p: p.__setitem__("unknown", []),
                   lambda p: p["metadata"].__setitem__("unknown", 1),
                   lambda p: p["components"]["statuses"][5].__setitem__(1, [0, 0]),
                   lambda p: p["components"]["trajectories"][2].__setitem__(1, None),
                   lambda p: p["components"]["pickups"][5].__setitem__(1, None),
                   lambda p: p["components"]["roles"][0].__setitem__(1, "XpSlot"),
                   lambda p: p["components"]["poolCandidates"].pop()]
        for mutate in changes:
            rows = self.schema.replay(True); mutate(rows[2]["payload"])
            self.write(rows, rows)
            with self.assertRaises(R.ReplayError): self.compare()
        rows = self.schema.replay(True); rows[0]["unknown"] = 1
        self.write(rows, rows)
        with self.assertRaises(R.ReplayError): self.compare()

    def spatial(self):
        rows = self.schema.replay(True)
        for record in rows:
            if record['type'] != 'checkpoint':
                continue
            components = record['payload']['components']
            spaces = []
            for index, (_, body, stamp) in enumerate(components['bodies']):
                enemy = components['roles'][index][1] in self.schema.M.ENEMIES
                spaces.append([index + 1, [body[0], body[1], body[6], body[8]] if enemy else None,
                               copy.deepcopy(stamp if enemy else [None, None])])
                if enemy:
                    body[0], body[1], body[6], body[8] = 0, 0, 0, 0
            components['spaces'] = spaces
        return rows

    def test_spatial_current_schema_compares_all_actual_values_and_stamps(self):
        rows = self.spatial()
        self.write(rows, rows)
        self.assertEqual(self.compare()['checkpoints'], 2)
        for field in range(4):
            changed = copy.deepcopy(rows)
            changed[2]['payload']['components']['spaces'][0][1][field] += 1
            self.schema.M.validate_payload(changed[2]['payload'], 1, self.layout, True)
            self.write(rows, changed)
            with self.assertRaises(R.ReplayError): self.compare()
        changed = copy.deepcopy(rows)
        changed[2]['payload']['components']['spaces'][0][2] = [[0, 2], [0, 90]]
        self.schema.M.validate_payload(changed[2]['payload'], 1, self.layout, True)
        self.write(rows, changed)
        with self.assertRaises(R.ReplayError): self.compare()

    def test_spatial_composition_and_duplicate_authority_are_rejected(self):
        corruptions = [
            lambda c: c['spaces'][0].__setitem__(1, None),
            lambda c: c['spaces'][2].__setitem__(1, [0, 0, 0, 0]),
            lambda c: c['spaces'].pop(),
            lambda c: c['spaces'].reverse(),
            lambda c: c['spaces'][0].__setitem__(2, [[0, 1], [0, 101]]),
            lambda c: c['bodies'][0][1].__setitem__(0, 1),
            lambda c: c['bodies'][0][1].__setitem__(6, 1),
        ]
        for corrupt in corruptions:
            rows = self.spatial()
            corrupt(rows[2]['payload']['components'])
            self.write(rows, rows)
            with self.assertRaises(R.ReplayError): self.compare()

    def test_absent_routing_is_rejected(self):
        left = self.schema.replay(True); right = copy.deepcopy(left)
        for key in ("movementCandidates", "projectileCandidates", "poolCandidates"):
            right[2]["payload"]["components"][key] = None
        with self.assertRaises(self.schema.M.ReplayError):
            self.schema.M.validate_payload(right[2]["payload"], 1, self.layout, True)
        self.write(left, right)
        with self.assertRaises(R.ReplayError): self.compare()

    def test_layout_cli_and_legacy_default_remain_distinct(self):
        import subprocess
        import sys
        rows = self.schema.replay(True); self.write(rows, rows)
        layout = self.root / "layout.json"; layout.write_text(json.dumps(self.layout))
        receipt = self.root / "receipt.json"
        command = [sys.executable, str(Path(__file__).with_name("replay_compare.py")),
                   str(self.a), str(self.b), "--receipt", str(receipt)]
        result = subprocess.run(command + ["--layout", str(layout)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertEqual(json.loads(receipt.read_text())["layoutSha256"], R.file_sha(layout))
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)

if __name__ == "__main__":unittest.main()
