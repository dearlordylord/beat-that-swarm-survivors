#!/usr/bin/env python3
"""Small arithmetic/Hub-column Metal diagnostics; never build the full game."""
import argparse
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import sys
import time

MODULE_PATH = Path(__file__).with_name('metal-experiment.py')
SPEC = importlib.util.spec_from_file_location('metal_experiment_shared', MODULE_PATH)
shared = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(shared)


def checksum(iterations, seed):
    return (8 * iterations * seed + 28 * iterations + 4 * iterations * (iterations + 1)) % (2 ** 32)


class Diagnosis(shared.Experiment):
    def __init__(self, args, repo):
        super().__init__(args, repo)
        self.guard_files[str(Path(__file__).resolve())] = shared.sha(__file__)
        launcher = Path(__file__).with_suffix('.sh')
        if launcher.is_file():
            self.guard_files[str(launcher.resolve())] = shared.sha(launcher)
        self.report.update(scope='Two small independent arithmetic and public-Hub column controls. Not a full-game build or game performance test.', population={'iterations': args.iterations, 'jobs': 8, 'seed': args.seed, 'threads': args.threads}, probes=[], limits={'emitCSeconds': 60, 'nativeBuildSeconds': 120, 'metalBuildSeconds': args.metal_build_seconds, 'eachRunSeconds': 30, 'totalSeconds': args.total_seconds})
        self.report['measurementLogicSHA256'] = dict(self.guard_files)
        self.probe_sources = None

    def execute(self, label, argv, seconds, env=None):
        try:
            return super().execute(label, argv, seconds, env)
        finally:
            row = next((row for row in reversed(self.report['commands']) if row['label'] == label), None)
            if row is not None and 'wallSeconds' in row:
                print(label + ': elapsed ' + format(row['wallSeconds'], '.3f') + 's', flush=True)

    def guard(self):
        super().guard()
        if self.probe_sources is not None:
            sources = self.repo / 'tools/survivors-bot/metal-probes'
            actual = {str(path): shared.sha(path) for path in sources.rglob('*.bend')}
            if actual != self.probe_sources:
                raise shared.Failure('Probe source membership/bytes changed')

    def probe_output(self, label, name):
        path = self.out / (label + '.stdout')
        try:
            value = json.loads(path.read_text())
        except (ValueError, OSError) as error:
            raise shared.Failure(label + ' did not emit one JSON probe object') from error
        fields = {'type', 'probe', 'checksum', 'iterations', 'jobs'}
        if not isinstance(value, dict) or set(value) != fields:
            raise shared.Failure(label + ' emitted unexpected probe fields')
        expected = {'type': 'probe', 'probe': name, 'checksum': checksum(self.args.iterations, self.args.seed), 'iterations': self.args.iterations, 'jobs': 8}
        for key in ('checksum', 'iterations', 'jobs'):
            if type(value[key]) is not int:
                raise shared.Failure(label + ' emitted invalid integer ' + key)
        if value != expected:
            self.report['oracleFailure'] = {'label': label, 'expected': expected, 'actual': value}
            raise shared.Failure(label + ' failed independent Python checksum oracle')
        return value

    def metal_build(self, name, binary):
        label = name + '-metal-build'
        try:
            self.execute(label, [str(binary), '+RTS', '--gpu-build', '-RTS'], self.args.metal_build_seconds)
        except BaseException:
            timed_out = next((row.get('timedOut', False) for row in self.report['commands'] if row['label'] == label), False)
            if timed_out:
                try:
                    self.execute(name + '-timeout-processes', ['/bin/ps', '-axo', 'pid,ppid,%cpu,etime,command'], 5)
                except BaseException as error:
                    self.report.setdefault('snapshotErrors', []).append(str(error))
            raise

    def probe(self, bend, name):
        source = self.repo / 'tools/survivors-bot/metal-probes' / (name + '.bend')
        directory = self.out / name
        directory.mkdir()
        cfile = directory / 'generated.c'
        binary = directory / 'probe'
        row = {'probe': name, 'status': 'INCOMPLETE', 'sourceSHA256': shared.sha(source)}
        self.report['probes'].append(row)
        self.guard()
        self.execute(name + '-emit-c', [bend, str(source), '-o', str(cfile)], 60)
        self.guard_files[str(cfile)] = shared.sha(cfile)
        text = cfile.read_text(errors='replace')
        row.update(generatedCSHA256=shared.sha(cfile), cBytes=cfile.stat().st_size, fidCount=len(re.findall(r'^\s*#define\s+FID_\w+\s+\d+', text, re.M)))
        row['dispatch'] = shared.verify_dispatch_contract(text, source.read_text(), solve_row=(2, 0, 1, 0), boundary='solve!(iterations,seed)')
        row['dispatch']['status'] = 'STATIC_CONTRACT_VERIFIED'
        self.save()
        print(name + ': C bytes=' + str(row['cBytes']) + ', FIDs=' + str(row['fidCount']), flush=True)
        self.guard()
        command = [self.env['CC'], '-DBEND_METAL=1', '-x', 'objective-c', '-fobjc-arc', '-fmodules', '-std=c11', '-O3', str(cfile), '-lpthread', '-lm', '-o', str(binary)]
        self.execute(name + '-native-build', command, 120)
        if not os.access(binary, os.X_OK):
            raise shared.Failure(name + ' native compiler did not create an executable')
        self.guard_files[str(binary)] = shared.sha(binary)
        row['binarySHA256'] = shared.sha(binary)
        self.save()
        self.guard()
        env = dict(self.env, METAL_PROBE_ITERATIONS=str(self.args.iterations), METAL_PROBE_SEED=str(self.args.seed))
        results = {}
        cpu_label = name + '-cpu'
        _, row['cpuSeconds'] = self.execute(cpu_label, [str(binary), '+RTS', '--gpu', 'off', '--threads', str(self.args.threads), '-RTS'], 30, env)
        self.guard()
        results['cpu'] = self.probe_output(cpu_label, name)
        row['cpuChecksumOracle'] = 'PASS'
        self.save()
        print(name + ': CPU checksum PASS (' + str(results['cpu']['checksum']) + ')', flush=True)
        self.metal_build(name, binary)
        self.guard()
        sidecar = Path(str(binary) + '.gpu')
        if not sidecar.is_file() or sidecar.stat().st_size == 0:
            raise shared.Failure(name + ' Metal build did not produce a nonempty .gpu sidecar')
        self.guard_files[str(sidecar)] = shared.sha(sidecar)
        row['sidecarSHA256'] = shared.sha(sidecar)
        self.guard()
        gpu_label = name + '-gpu'
        _, row['gpuSeconds'] = self.execute(gpu_label, [str(binary), '+RTS', '--gpu', 'on', '--threads', str(self.args.threads), '-RTS'], 30, env)
        self.guard()
        results['gpu'] = self.probe_output(gpu_label, name)
        if results['cpu'] != results['gpu']:
            raise shared.Failure(name + ' CPU/GPU JSON outputs differ')
        row.update(status='PASS', checksum=results['gpu']['checksum'], oracle='PASS', cpuGpuExactJSON='PASS')
        row['dispatch']['status'] = 'VERIFIED'
        row['stages'] = {command['label']: command['wallSeconds'] for command in self.report['commands'] if command['label'].startswith(name + '-')}
        self.save()
        print(name + ': checksum PASS (' + str(row['checksum']) + '); stages seconds=' + json.dumps(row['stages']), flush=True)
        return row['checksum']

    def run(self):
        lock = None
        try:
            lock = open('/tmp/bendvy-parity-heavy.lock', 'a')
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            bend = self.preflight()
            sources = self.repo / 'tools/survivors-bot/metal-probes'
            self.probe_sources = {str(path): shared.sha(path) for path in sources.rglob('*.bend')}
            self.guard_files.update(self.probe_sources)
            manifest = self.repo / 'bendhub-dependencies.json'
            self.guard_files[str(manifest)] = shared.sha(manifest)
            self.report['declaredPublicDependencies'] = json.loads(manifest.read_text())
            library = Path(self.env.get('BEND_LIB', str(Path.home() / '.bend/lib'))).expanduser().resolve()
            self.report['dependencies'] = {'resolvedBendLib': str(library), 'scope': 'Declared public pin and installed selected package bytes where present; not a complete compiler/Base/SDK closure proof.'}
            for package in self.report['declaredPublicDependencies'].get('packages', {}).values():
                directory = library / package['contentHash']
                if directory.is_dir():
                    self.guard_files.update({str(path): shared.sha(path) for path in directory.rglob('*') if path.is_file()})
            self.guard_files.update({bend: shared.sha(bend), self.env['CC']: shared.sha(self.env['CC'])})
            arithmetic = self.probe(bend, 'arithmetic')
            columns = self.probe(bend, 'columns')
            if arithmetic != columns:
                raise shared.Failure('Arithmetic and columns checksums differ')
            self.report.update(status='COMPLETE_SMALL_PROBES', checksumOracle='PASS', cpuGpuParity='PASS', crossProbeChecksum='PASS')
        except BaseException as error:
            self.report.update(status='FAIL', error=str(error))
        finally:
            try:
                self.stop_child()
            except BaseException as error:
                self.report.update(status='FAIL', cleanupError=repr(error))
            try:
                self.guard()
            except BaseException as error:
                self.report.setdefault('guardFailures', []).append(str(error))
                self.report['status'] = 'FAIL'
            self.report['totalWallSeconds'] = time.monotonic() - self.started
            self.save()
            if lock is not None:
                lock.close()
        print(self.report['status'] + ': small Metal diagnostic controls; NOT game performance PASS')
        if 'error' in self.report:
            print('Error: ' + self.report['error'])
            if self.report['commands']:
                failed = next((row for row in reversed(self.report['commands']) if row['status'] != 'PASS'), self.report['commands'][-1])
                label = failed['label']
                path = self.out / (label + '.stderr')
                if path.is_file() and path.stat().st_size:
                    print('Last stderr lines:\n' + '\n'.join(path.read_text(errors='replace').splitlines()[-12:]))
        print('Report: ' + str(self.out / 'report.json'))
        return 0 if self.report['status'] == 'COMPLETE_SMALL_PROBES' else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iterations', type=int, default=128)
    parser.add_argument('--seed', type=int, default=100)
    parser.add_argument('--threads', type=int, default=min(8, os.cpu_count() or 1))
    parser.add_argument('--metal-build-seconds', type=int, default=90)
    parser.add_argument('--total-seconds', type=int, default=600)
    parser.add_argument('--output')
    args = parser.parse_args()
    if not (1 <= args.iterations <= 4096 and 0 <= args.seed <= 4294967295 and 1 <= args.threads <= 128 and 1 <= args.metal_build_seconds <= 90 and 1 <= args.total_seconds <= 600):
        parser.error('iterations 1..4096, seed U32, threads 1..128, Metal cap 90s, total cap 600s')
    args.count, args.ticks, args.profile, args.repetitions, args.run_seconds = 8, args.iterations, 'both', 1, 30
    repo = Path(__file__).resolve().parents[2]
    if args.output is None:
        args.output = str(repo / 'examples/survivors/dist/metal-diagnostics' / ('run-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-' + str(os.getpid())))
    diagnosis = Diagnosis(args, repo)
    def stop(*_):
        raise KeyboardInterrupt('diagnostic interrupted')
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    return diagnosis.run()


if __name__ == '__main__':
    sys.exit(main())
