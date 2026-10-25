#!/usr/bin/env python3
"""Cheap subprocess controls of the measurement harness; executable stubs, not games."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
import current_replay_fixture as F
import replay_compare as R

class MeasurementControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        rows = F.replay()
        for row in rows:row["fixture"] = "seed100-profile0-warm0-end1"
        rows[0].update(seed=100,profile=0,warmup=0,endTick=1)
        rows[-1].update(actions=1,firstTick=0,endTick=1,phase=0)
        rows.insert(-2, {"type":"replay-summary", "fixture":rows[0]["fixture"], "windowMs":10, "windowActions":1, "firstTick":0, "endTick":1, "phase":0, "stateDigest32":7})
        self.payload = self.root / "records.jsonl"
        self.payload.write_text("".join(json.dumps(r)+"\n" for r in rows))
        self.trace = self.root / "fixture.trace"; self.trace.write_text("1313231410 1 0 100 0 1 1 0 1\n0 0 0 0 0\n")
        self.fixtures = self.root / "fixtures.json"; self.fixtures.write_text(json.dumps([str(self.trace)]))
    def binary(self, name, body):
        p = self.root / name
        p.write_text("#!/usr/bin/env python3\nimport pathlib,sys,time,os\nassert sys.argv[1:]==['+RTS','--threads','1','-RTS']\nassert 'BENDRTS' not in os.environ\n" + body + "\n")
        p.chmod(0o700); return p
    def command(self, ref, candidate, output, **options):
        layout = options.get("layout")
        if layout is None:
            layout = self.root / "current-layout.json"
            layout.write_text(json.dumps(F.LAYOUT))
        command = ["python3",str(HERE/"measure-native-step.py"),"--reference",str(ref),"--candidate",str(candidate),"--fixtures",str(self.fixtures),"--output",str(output),"--rounds","1","--timeout",str(options.get("timeout",1)),"--max-seconds","5"]
        command.extend(["--layout", str(layout)])
        return command
    def output_binary(self,name):
        return self.binary(name, f"sys.stdout.write(pathlib.Path({str(self.payload)!r}).read_text())")
    def execute(self, ref, candidate, **options):
        out=self.root/"out"
        result=subprocess.run(self.command(ref,candidate,out,**options),capture_output=True,text=True,timeout=10,env={**os.environ,"PYTHONDONTWRITEBYTECODE":"1","BENDRTS":"--threads 99"})
        return result,out
    def test_completion_and_one_fixture_uncertainty(self):
        result,out=self.execute(self.output_binary("reference"),self.output_binary("candidate"))
        self.assertEqual(result.returncode,0,result.stderr)
        summary=json.loads((out/"summary.json").read_text())
        self.assertIsNone(summary["fixtureClusterBootstrap95"])
        self.assertEqual(json.loads((out/"terminal.json").read_text())["status"],"completed")
    def test_correctness_runner_uses_explicit_rts_and_clears_ambient(self):
        spec = importlib.util.spec_from_file_location("replay_check_control", HERE / "replay_check.py")
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        binary = self.output_binary("correctness")
        with patch.dict(os.environ, {"BENDRTS": "--threads 99"}):
            result = runner.run(binary, self.trace, "fixture", self.root / "correctness-run", 2, 1)
        self.assertEqual(result["command"][1:], ["+RTS", "--threads", "1", "-RTS"])
        self.assertEqual(result["exitCode"], 0)

    def sparse_fixture(self):
        rows = F.replay()
        rows.insert(-2, {"type": "replay-summary", "fixture": rows[0]["fixture"],
                         "windowMs": 10, "windowActions": 1, "firstTick": 0,
                         "endTick": 1, "phase": 0, "stateDigest32": 7})
        self.payload.write_text("".join(json.dumps(row) + "\n" for row in rows))
        layout = self.root / "layout.json"; layout.write_text(json.dumps(F.LAYOUT))
        return layout

    def test_sparse_layout_forwarding_and_evaluator_bindings(self):
        layout = self.sparse_fixture()
        result, out = self.execute(self.output_binary("reference"), self.output_binary("candidate"), layout=layout)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        plan = json.loads((out / "plan.json").read_text())
        evaluator_hashes = plan["bindings"]["evaluators"]
        self.assertEqual(evaluator_hashes[str(layout)], R.file_sha(layout))
        validator = HERE / "current_replay_schema.py"
        self.assertEqual(evaluator_hashes[str(validator)], R.file_sha(validator))
        pair = json.loads((out / "pairs.jsonl").read_text())
        self.assertEqual(pair["oracle"]["comparison"], "exact-sparse-ecs")
        self.assertNotIn("exclusions", pair["oracle"])

    def test_sparse_layout_drift_after_sample_fails_guard(self):
        layout = self.sparse_fixture()
        reference = self.binary("reference", f"pathlib.Path({str(layout)!r}).write_text('{{}}')\nsys.stdout.write(pathlib.Path({str(self.payload)!r}).read_text())")
        result, out = self.execute(reference, self.output_binary("candidate"), layout=layout)
        self.assertNotEqual(result.returncode, 0)
        error = json.loads((out / "terminal.json").read_text())["error"]
        self.assertIn("Frozen input changed", error)
        self.assertIn(str(layout), error)

    def test_nonzero_child_is_incomplete(self):
        result,out=self.execute(self.binary("reference","sys.exit(7)"),self.output_binary("candidate"))
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(json.loads((out/"terminal.json").read_text())["status"],"incomplete")
    def test_timeout_reaps_native_child(self):
        pidfile=self.root/"pid"
        ref=self.binary("reference",f"pathlib.Path({str(pidfile)!r}).write_text(str(os.getpid()))\ntime.sleep(30)")
        result,out=self.execute(ref,self.output_binary("candidate"))
        self.assertNotEqual(result.returncode,0)
        with self.assertRaises(ProcessLookupError):os.kill(int(pidfile.read_text()),0)
        self.assertEqual(json.loads((out/"terminal.json").read_text())["status"],"incomplete")
    def test_sigterm_reaps_native_and_writes_terminal(self):
        pidfile=self.root/"pid"
        ref=self.binary("reference",f"pathlib.Path({str(pidfile)!r}).write_text(str(os.getpid()))\ntime.sleep(30)")
        out=self.root/"out"
        child=subprocess.Popen(self.command(ref,self.output_binary("candidate"),out,timeout=5),stdout=subprocess.PIPE,stderr=subprocess.PIPE,env={**os.environ,"PYTHONDONTWRITEBYTECODE":"1","BENDRTS":"--threads 99"})
        try:
            deadline=time.monotonic()+3
            while not pidfile.exists() and time.monotonic()<deadline:time.sleep(.01)
            self.assertTrue(pidfile.exists())
            child.terminate();child.communicate(timeout=4)
            self.assertNotEqual(child.returncode,0)
            with self.assertRaises(ProcessLookupError):os.kill(int(pidfile.read_text()),0)
            self.assertEqual(json.loads((out/"terminal.json").read_text())["status"],"incomplete")
        finally:
            if child.poll() is None:child.kill();child.communicate()
    def test_fixture_drift_after_sample_fails_guard(self):
        ref=self.binary("reference",f"pathlib.Path({str(self.trace)!r}).write_text('changed')\nsys.stdout.write(pathlib.Path({str(self.payload)!r}).read_text())")
        result,out=self.execute(ref,self.output_binary("candidate"))
        self.assertNotEqual(result.returncode,0)
        self.assertIn("Frozen input changed",json.loads((out/"terminal.json").read_text())["error"])

if __name__=="__main__":unittest.main()
