import json, os, pathlib, subprocess, sys, tempfile, unittest
HERE = pathlib.Path(__file__).parent
FAKE = "#!/usr/bin/env python3\nimport json,os,sys,time\nif os.environ.get('FAKE_SLEEP'):time.sleep(10)\nparallel='parallel' in sys.argv[0]\nfor j in range(int(os.environ['NIGHTFALL_BATCH_COUNT'])):\n i=int(os.environ['NIGHTFALL_BATCH_INDEX'])+j*int(os.environ['NIGHTFALL_BATCH_STRIDE']);ticks=int(os.environ['NIGHTFALL_BATCH_TICKS'])\n r={k:0 for k in 'hp level xp xpNeed kills gold choices xpPiles uncollectedBaseXp'.split()}\n r.update(type='summary',backend='native',policy='bend-resource-memory-v1',index=i,seed=100+i,profile='advanced' if i%2 else 'fresh',status='completed',tick=ticks,requestedTicks=ticks,outcome='bounded-observation',phase=0,wallMs=None if parallel else 1)\n if parallel and os.environ.get('FAKE_MISMATCH'):r['gold']=1\n if parallel and os.environ.get('FAKE_NUMERIC_WALL'):r['wallMs']=1\n print(json.dumps(r))\n"

class Comparison(unittest.TestCase):

    def invoke(self, extra=(), env=None):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            for n in ['serial', 'parallel']:
                (root / n).write_text(FAKE)
                (root / n).chmod(493)
            cmd = [sys.executable, '-B', str(HERE / 'compare-native-parallel.py'), '--serial-binary', str(root / 'serial'), '--parallel-binary', str(root / 'parallel'), '--output-dir', str(root / 'out'), '--count', '5', '--ticks', '12', '--repeats', '2', '--budgets', '1,2' if len(os.sched_getaffinity(0)) > 1 else '1', *extra]
            r = subprocess.run(cmd, env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1', **(env or {})}, capture_output=True, timeout=15)
            return (r, json.loads((root / 'out/summary.json').read_text()))

    def test_roundrobin_and_parity(self):
        r, d = self.invoke()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(d['status'], 'PASS')
        self.assertEqual(d['pairs'][0]['order'], ['serial', 'parallel'])
        self.assertEqual(d['pairs'][-1]['order'], ['parallel', 'serial'])

    def test_semantic_failure_is_retained(self):
        r, d = self.invoke(env={'FAKE_MISMATCH': '1'})
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(d['status'], 'INCOMPLETE')
        self.assertIn('semantic divergence', d['error'])

    def test_deadline_cleanup(self):
        r, d = self.invoke(extra=['--deadline', '.15'], env={'FAKE_SLEEP': '1'})
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(d['status'], 'INCOMPLETE')
        self.assertIn('deadline', d['error'])

    def test_parallel_wall_must_be_null(self):
        result, receipt = self.invoke(env={'FAKE_NUMERIC_WALL': '1'})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('invalid wallMs', receipt['error'])
if __name__ == '__main__':
    unittest.main()
