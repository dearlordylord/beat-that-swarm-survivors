#!/usr/bin/env python3
"""Small fake-child tests; no Bend compilation or macOS claims."""
import importlib.util, json, os, sys, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
spec = importlib.util.spec_from_file_location('metal', Path(__file__).with_name('metal-experiment.py'))
metal = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metal)

class Tests(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / 'examples/survivors').mkdir(parents=True)
        (self.root / 'examples/survivors/offline-gpu.bend').write_text('fake source')
        (self.root / 'bendhub-dependencies.json').write_text('{}')
        self.compiler = self.root / 'bend'
        self.compiler.write_text('#!' + sys.executable + "\nimport os,sys\nfrom pathlib import Path\np=Path(sys.argv[sys.argv.index('-o')+1])\nif p.suffix=='.c':p.write_text('#define BANGS 1\\n')\nelse:\n if os.environ.get('FAKE_BUILD_FAIL')=='1':sys.exit(9)\n p.write_text(" + repr('#!' + sys.executable + "\nimport json,os,sys,time\nif '--gpu-build' in sys.argv:\n if os.environ.get('FAKE_METAL_TIMEOUT')=='1':time.sleep(10)\n if os.environ.get('FAKE_METAL_FAIL')=='1':sys.exit(8)\n if os.environ.get('FAKE_MISSING_SIDECAR')!='1':Path = __import__('pathlib').Path;Path(sys.argv[0]+'.gpu').write_text('fake metal library')\n sys.exit(0)\nif os.environ.get('FAKE_FAIL')=='1':sys.exit(7)\nif os.environ.get('FAKE_TIMEOUT')=='1':time.sleep(10)\nassert sys.argv[1]=='+RTS' and sys.argv[-1]=='-RTS'\ngpu=sys.argv[sys.argv.index('--gpu')+1]=='on'\nfor i in range(int(os.environ['NIGHTFALL_BATCH_COUNT'])):\n profile=os.environ['NIGHTFALL_BATCH_PROFILE'];profile=('advanced' if i%2 else 'fresh') if profile=='both' else profile\n ticks=int(os.environ['NIGHTFALL_BATCH_TICKS'])\n print(json.dumps(dict(type='summary',backend='native',status='completed',index=i,seed=(int(os.environ['NIGHTFALL_BATCH_SEED'])+i)%4294967296,profile=profile,requestedTicks=ticks,tick=ticks,phase=0,outcome='bounded-observation',wallMs=None,policy='bend-resource-memory-v1',hp=1 if gpu and os.environ.get('FAKE_DIFF')=='1' else 0,level=1,xp=0,xpNeed=1,kills=0,gold=0,choices=0,xpPiles=0,uncollectedBaseXp=0)))\n") + ')\n p.chmod(0o755)\n')
        self.compiler.chmod(493)

    def tearDown(self):
        self.tmp.cleanup()

    def run_fake(self, metal_seconds=2, **env):
        args = metal.parser().parse_args(['--output', str(self.root / 'output'), '--count', '3', '--ticks', '12', '--repetitions', '3', '--run-seconds', '1', '--total-seconds', '30', '--metal-build-seconds', str(metal_seconds)])
        exp = metal.Experiment(args, self.root)
        exp.env['CC'] = str(self.compiler)
        with patch.dict(os.environ, env), patch.object(exp, 'preflight', return_value=str(self.compiler)), patch.object(metal, 'verify_dispatch_contract', return_value={'status': 'VERIFIED', 'method': 'fake-contract'}):
            exp.env.update(env)
            code = exp.run()
        return (code, json.loads((self.root / 'output/report.json').read_text()))

    def test_success_and_alternating_order(self):
        code, r = self.run_fake()
        self.assertEqual(code, 0)
        self.assertEqual(r['semanticParity'], 'PASS')
        self.assertEqual([x['order'] for x in r['pairs']], [['cpu', 'gpu'], ['gpu', 'cpu'], ['cpu', 'gpu']])
        self.assertEqual(len(r['commands']), 11)

    def test_semantic_difference(self):
        code, r = self.run_fake(FAKE_DIFF='1')
        self.assertEqual(code, 1)
        self.assertIn('semantic summaries differ', r['error'])
        self.assertTrue((self.root / 'output/smoke-gpu.stdout').is_file())

    def test_child_failure_preserves_logs(self):
        code, r = self.run_fake(FAKE_FAIL='1')
        self.assertEqual(code, 1)
        self.assertEqual(r['commands'][-1]['exitCode'], 7)
        self.assertTrue((self.root / 'output/smoke-cpu.stderr').is_file())

    def test_timeout_preserves_partial_receipt(self):
        code, r = self.run_fake(FAKE_TIMEOUT='1')
        self.assertEqual(code, 1)
        self.assertTrue(r['commands'][-1]['timedOut'])
        self.assertIn('timed out', r['error'])

    def test_build_failure_preserves_c_and_error(self):
        code, r = self.run_fake(FAKE_BUILD_FAIL='1')
        self.assertEqual(code, 1)
        self.assertEqual(r['commands'][-1]['exitCode'], 9)
        self.assertTrue((self.root / 'output/generated.c').is_file())
        self.assertNotIn('semanticParity', r)

    def test_metal_timeout_retains_successful_native_artifact(self):
        code, r = self.run_fake(metal_seconds=1, FAKE_METAL_TIMEOUT='1')
        self.assertEqual(code, 1)
        self.assertEqual(r['commands'][-1]['label'], 'metal-build')
        self.assertTrue(r['commands'][-1]['timedOut'])
        self.assertEqual(r['commands'][-2]['label'], 'native-build')
        self.assertEqual(r['commands'][-2]['status'], 'PASS')
        self.assertEqual(r['artifacts']['binarySHA256'], metal.sha(self.root / 'output/nightfall-gpu-batch'))
        self.assertNotIn('gpuSidecarSHA256', r['artifacts'])
        self.assertNotIn('semanticParity', r)

    def test_missing_sidecar_fails_after_metal_stage(self):
        code, r = self.run_fake(FAKE_MISSING_SIDECAR='1')
        self.assertEqual(code, 1)
        self.assertEqual(r['commands'][-1]['label'], 'metal-build')
        self.assertEqual(r['commands'][-1]['status'], 'PASS')
        self.assertIn('sidecar', r['error'])
        self.assertIn('binarySHA256', r['artifacts'])

    def test_native_build_uses_official_darwin_recipe(self):
        code, r = self.run_fake()
        self.assertEqual(code, 0)
        row = next((c for c in r['commands'] if c['label'] == 'native-build'))
        self.assertEqual(row['argv'][1:8], ['-DBEND_METAL=1', '-x', 'objective-c', '-fobjc-arc', '-fmodules', '-std=c11', '-O3'])
        self.assertEqual(row['argv'][-4:], ['-lpthread', '-lm', '-o', str(self.root / 'output/nightfall-gpu-batch')])

    def test_static_contract_refusal_precedes_native_build(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        exp.env['CC'] = str(self.compiler)
        with patch.object(exp, 'preflight', return_value=str(self.compiler)), patch.object(metal, 'verify_dispatch_contract', side_effect=metal.Failure('static contract refused')):
            self.assertEqual(exp.run(), 1)
        report = json.loads((exp.out / 'report.json').read_text())
        self.assertEqual([row['label'] for row in report['commands']], ['emit-c'])
        self.assertIn('generatedCSHA256', report['artifacts'])
        self.assertFalse((exp.out / 'nightfall-gpu-batch').exists())

    def test_dispatch_contract_and_refusals(self):
        c = '#define BANGS 1\n#define FID_solve 1\ntypedef struct { u8 ar, resw, bangs, nofk; } Fid;\n#define fid_bangs(x) FID_T[x].bangs\nCONSTV Fid FID_T[] = {{0,0,0,1},{4,0,1,0}};\nu64 task = task_node(e, FID_solve, WL_CONT, WL_IDX, 0); return term_tsk(FID_solve, task);\n' + 'e.mem[loc + ar + 1] = ((u64)idx << 32) | rem;\nwork_loop(e, io_stk, t, !BANGS && pool_size == 1)\nif ((u32)H[tl + 1] != 0) cube_run(H, false);\nif (io_gpu && fid_bangs((u32)term_aux(t))) cube_run(H, true);\nif (gpu == 1 && BANGS != 0 && why != NULL) { err_fail(why); }\nMTLCreateSystemDefaultDevice(); gpu_pass(H);\n[gpu_enc dispatchThreadgroupsWithIndirectBuffer:gpu_buf indirectBufferOffset:H_GROUPS * 8 + at * 12 threadsPerThreadgroup:MTLSizeMake(CUBE_T, 1, 1)];\n[c commit]; [c waitUntilCompleted]; if ([c error]) { gpu_fail([c error]); }\n'
        source = 'solve!(P.JobContext{ticks,seed,profile},Scheduler.build(count,index,stride))'
        self.assertEqual(metal.verify_dispatch_contract(c, source)['status'], 'VERIFIED')
        for bad in [c.replace('BANGS 1', 'BANGS 0'), c.replace('{4,0,1,0}', '{4,0,0,0}'), c.replace('WL_IDX, 0', 'WL_IDX, 1')]:
            with self.assertRaises(metal.Failure):
                metal.verify_dispatch_contract(bad, source)

    def test_missing_field_rejected_even_if_both_modes_match(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        (exp.out / 'sample.stdout').write_text(json.dumps(dict(type='summary', backend='native', status='completed', index=0, wallMs=None)) + '\n')
        with self.assertRaisesRegex(metal.Failure, 'summary fields'):
            exp.summaries('sample', 1, 60)

    def test_canonical_detects_shared_repetition_drift(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        with self.assertRaisesRegex(metal.Failure, 'semantic summaries differ'):
            exp.parity([{'index': 0, 'hp': 1}], [{'index': 0, 'hp': 2}], 'Canonical repetition')
        self.assertEqual(exp.report['semanticDifference']['fields']['hp'], {'expected': 1, 'actual': 2})

    def test_source_guard_detects_change(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        source = self.root / 'examples/survivors/offline-gpu.bend'
        exp.guard_files[str(source)] = metal.sha(source)
        source.write_text('changed')
        with self.assertRaisesRegex(metal.Failure, 'changed'):
            exp.guard()

    def test_final_cleanup_failure_still_saves_report(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        with patch.object(exp, 'preflight', side_effect=metal.Failure('original preflight failure')), patch.object(exp, 'stop_child', side_effect=TimeoutError('injected cleanup timeout')):
            self.assertEqual(exp.run(), 1)
        report = json.loads((self.root / 'output/report.json').read_text())
        self.assertEqual(report['error'], 'original preflight failure')
        self.assertIn('cleanup timeout', report['cleanupError'])

    def test_execute_cleanup_failure_still_saves_raw(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        original = exp.stop_child

        def failed_cleanup():
            original()
            raise TimeoutError('injected cleanup timeout')
        with patch.object(exp, 'stop_child', side_effect=failed_cleanup):
            with self.assertRaisesRegex(metal.Failure, 'cleanup failed'):
                exp.execute('probe', [sys.executable, '-c', 'print("retained")'], 2)
        self.assertEqual((exp.out / 'probe.stdout').read_text(), 'retained\n')
        self.assertIn('cleanupError', json.loads((exp.out / 'report.json').read_text())['commands'][-1])

    def test_wrong_host_has_report(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        with patch.object(metal.platform, 'system', return_value='Linux'):
            self.assertEqual(exp.run(), 1)
        self.assertIn('Apple Silicon', json.loads((self.root / 'output/report.json').read_text())['error'])

    def test_preflight_accepts_new_release_and_rejects_old(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        exp = metal.Experiment(args, self.root)
        with patch.object(metal.platform, 'system', return_value='Darwin'), patch.object(metal.platform, 'machine', return_value='arm64'), patch.object(metal.shutil, 'which', return_value=str(self.compiler)):
            with patch.object(exp, 'execute', side_effect=[('bend 2.0.38\n', 0), ('Apple clang version 17.0.0', 0), ('MacTest', 0), ('Apple M3', 0)]):
                self.assertEqual(exp.preflight(), str(self.compiler))
            with patch.object(exp, 'execute', return_value=('bend 2.0.37\n', 0)):
                with self.assertRaisesRegex(metal.Failure, 'requires Bend 2.0.38'):
                    exp.preflight()

    def test_ambient_runtime_settings_are_removed(self):
        args = metal.parser().parse_args(['--output', str(self.root / 'output')])
        with patch.dict(os.environ, {'BENDRTS': '--gpu off --threads 1'}):
            exp = metal.Experiment(args, self.root)
        self.assertNotIn('BENDRTS', exp.env)
if __name__ == '__main__':
    unittest.main()
