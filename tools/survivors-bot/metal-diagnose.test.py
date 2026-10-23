#!/usr/bin/env python3
"""Fake small-probe child controls; no Bend/Metal compilation or Mac claims."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('diagnose', Path(__file__).with_name('metal-diagnose.py'))
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)

RUNTIME = '''#!{python}
import json,os,sys,time
from pathlib import Path
name={name!r}
assert sys.argv[1]=='+RTS' and sys.argv[-1]=='-RTS'
assert 'BENDRTS' not in os.environ
if '--gpu-build' in sys.argv:
 if os.environ.get('FAKE_METAL_TIMEOUT')==name:time.sleep(10)
 Path(sys.argv[0]+'.gpu').write_text('fake metal')
 sys.exit(0)
n=int(os.environ['METAL_PROBE_ITERATIONS']);seed=int(os.environ['METAL_PROBE_SEED'])
checksum=(8*n*seed+28*n+4*n*(n+1))%2**32
if os.environ.get('FAKE_WRONG')==name:checksum=(checksum+1)%2**32
print(json.dumps(dict(type='probe',probe=name,checksum=checksum,iterations=n,jobs=8)))
'''


class Controls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        sources = self.root / 'tools/survivors-bot/metal-probes'
        sources.mkdir(parents=True)
        for name in ('arithmetic', 'columns'):
            (sources / (name + '.bend')).write_text('fake ' + name)
        (self.root / 'bendhub-dependencies.json').write_text('{}')
        self.compiler = self.root / 'compiler'
        self.compiler.write_text('#!' + sys.executable + '\nimport sys\nfrom pathlib import Path\n'
                                 'p=Path(sys.argv[sys.argv.index("-o")+1])\n'
                                 'if p.suffix==".c":p.write_text("#define FID_solve 1\\n")\n'
                                 'else:\n p.write_text(' + repr(RUNTIME) + '.format(python=' + repr(sys.executable) + ',name=p.parent.name));p.chmod(0o755)\n')
        self.compiler.chmod(0o755)

    def invoke(self, **environment):
        args = argparse.Namespace(output=str(self.root / 'output'), iterations=128, seed=100, count=8, ticks=128, profile='both', repetitions=1, threads=2, run_seconds=30, metal_build_seconds=1, total_seconds=30)
        with patch.dict(os.environ, {'BENDRTS': '--gpu off'}):
            diagnosis = module.Diagnosis(args, self.root)
        diagnosis.env.update(environment)
        diagnosis.env['CC'] = str(self.compiler)
        with patch.object(diagnosis, 'preflight', return_value=str(self.compiler)), patch.object(module.shared, 'verify_dispatch_contract', return_value={'status': 'VERIFIED'}):
            code = diagnosis.run()
        return code, json.loads((self.root / 'output/report.json').read_text())

    def test_cpu_gpu_match_independent_oracle_and_both_probes(self):
        code, report = self.invoke()
        self.assertEqual(code, 0)
        self.assertEqual(report['status'], 'COMPLETE_SMALL_PROBES')
        self.assertEqual([row['probe'] for row in report['probes']], ['arithmetic', 'columns'])
        self.assertEqual([row['checksum'] for row in report['probes']], [172032, 172032])
        self.assertEqual(len(report['commands']), 10)
        self.assertTrue(all(row['cpuGpuExactJSON'] == 'PASS' for row in report['probes']))

    def test_equal_cpu_gpu_wrong_value_is_rejected_and_stops(self):
        code, report = self.invoke(FAKE_WRONG='arithmetic')
        self.assertEqual(code, 1)
        self.assertIn('independent Python checksum oracle', report['error'])
        self.assertEqual(report['oracleFailure']['expected']['checksum'], 172032)
        self.assertEqual(len(report['probes']), 1)
        self.assertFalse(any(row['label'].startswith('columns-') for row in report['commands']))

    def test_metal_timeout_keeps_native_hash_and_process_snapshot(self):
        code, report = self.invoke(FAKE_METAL_TIMEOUT='arithmetic')
        self.assertEqual(code, 1)
        self.assertIn('metal-build timed out', report['error'])
        self.assertEqual(report['probes'][0]['binarySHA256'], module.shared.sha(self.root / 'output/arithmetic/probe'))
        self.assertTrue(any(row['label'] == 'arithmetic-timeout-processes' for row in report['commands']))
        self.assertFalse(any(row['label'].startswith('columns-') for row in report['commands']))
        self.assertTrue((self.root / 'output/arithmetic-metal-build.stderr').is_file())

    def test_oracle_wraparound(self):
        n, seed = 4096, 4294967295
        expected = sum((seed + job + i) % 2**32 for job in range(8) for i in range(1, n + 1)) % 2**32
        self.assertEqual(module.checksum(n, seed), expected)


if __name__ == '__main__':
    unittest.main()
