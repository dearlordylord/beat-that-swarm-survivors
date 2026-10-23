#!/usr/bin/env python3
"""Bounded macOS CPU/Metal experiment; Python only orchestrates native Bend."""
import argparse, fcntl, hashlib, json, os, platform, re, shutil, signal, statistics, subprocess, sys, time
from pathlib import Path
from metal_segments import transform_metal_segments

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
FIELDS = set('type backend policy index seed profile status tick requestedTicks outcome phase hp level xp xpNeed kills gold choices xpPiles uncollectedBaseXp wallMs'.split())

class Failure(RuntimeError):
    pass

NOINLINE_SPINS = ('spin_416', 'spin_511', 'spin_382', 'spin_429', 'spin_451', 'spin_526', 'spin_531')


def transform_metal_spins(source):
    """Replace only seven candidate-specific definition prefixes, byte for byte."""
    definitions = re.findall(rb'^#define[ \t]+DFAR[ \t]+(\w+)[ \t]*$', source, re.M)
    layout = rb'^#if DEVICE\r?\n#define DFAR[ \t]+FAR\r?\n(?:(?!^#if|^#elif|^#endif).)*^#else\r?\n#define DFAR[ \t]+INLINE\r?\n'
    if definitions != [b'FAR', b'INLINE'] or not re.search(layout, source, re.M | re.S):
        raise Failure('Noinline mode requires the known device DFAR=FAR and host DFAR=INLINE macro branches')
    if re.findall(rb'^#define[ \t]+FAR[ \t]+([^\r\n]+)', source, re.M) != [b'static __attribute__((noinline))']:
        raise Failure('Noinline mode requires the known FAR noinline definition')
    spans = []
    for name in NOINLINE_SPINS:
        encoded = name.encode('ascii')
        pattern = rb'^INLINE Term ' + encoded + rb'\([^;\r\n]*\) \{'
        matches = list(re.finditer(pattern, source, re.M))
        all_definitions = re.findall(rb'^\w+[ \t]+Term[ \t]+' + encoded + rb'\([^;\r\n]*\)[ \t]*\{', source, re.M)
        if len(matches) != 1 or len(all_definitions) != 1:
            raise Failure('Noinline mode requires exactly one unchanged INLINE definition of ' + name)
        spans.append((matches[0].start(), matches[0].start() + len(b'INLINE')))
    transformed = source
    for start, end in sorted(spans, reverse=True):
        transformed = transformed[:start] + b'DFAR' + transformed[end:]
    metadata = {'status': 'APPLIED', 'mode': 'metal-noinline-spins', 'originalSHA256': hashlib.sha256(source).hexdigest(), 'transformedSHA256': hashlib.sha256(transformed).hexdigest(), 'count': len(spans), 'targets': list(NOINLINE_SPINS), 'scope': 'Candidate-specific generated-C diagnostic only: seven INLINE→DFAR definition prefixes. CPU DFAR expands to the identical INLINE macro; device DFAR expands to existing FAR noinline. No flags, math or scheduling changes. Runtime performance and Metal compile benefit are unproven.'}
    return transformed, metadata


def transform_metal_trace(source):
    """Instrument host APIs only; never modify the embedded device program."""
    replacements = [
        (b'static MTLComputePipelineDescriptor* gpu_desc(void) {', b'static void metal_stage(const char* stage, const char* event) {\n  struct timespec ts;\n  clock_gettime(CLOCK_MONOTONIC, &ts);\n  fprintf(stderr, "[metal-stage] %s %s %.9f\\n", stage, event,\n    (double)ts.tv_sec + (double)ts.tv_nsec / 1e9);\n  fflush(stderr);\n}\n\nstatic MTLComputePipelineDescriptor* gpu_desc(void) {'),
        (b'  id<MTLLibrary> lib = [gpu_dev newLibraryWithSource:', b'  metal_stage("library", "begin");\n  id<MTLLibrary> lib = [gpu_dev newLibraryWithSource:'),
        (b'  if (!lib) {', b'  metal_stage("library", "end");\n  if (!lib) {'),
        (b'  d.computeFunction = [lib newFunctionWithName:@"bend_dev"];', b'  metal_stage("function", "begin");\n  d.computeFunction = [lib newFunctionWithName:@"bend_dev"];\n  metal_stage("function", "end");'),
        (b'  id<MTLBinaryArchive> ar = [gpu_dev\n    newBinaryArchiveWithDescriptor:', b'  metal_stage("archive-create", "begin");\n  id<MTLBinaryArchive> ar = [gpu_dev\n    newBinaryArchiveWithDescriptor:'),
        (b'  if (![ar addComputePipelineFunctionsWithDescriptor:gpu_desc() error:&err]) {', b'  metal_stage("archive-create", "end");\n  MTLComputePipelineDescriptor* d = gpu_desc();\n  metal_stage("archive-add", "begin");\n  bool added = [ar addComputePipelineFunctionsWithDescriptor:d error:&err];\n  metal_stage("archive-add", "end");\n  if (!added) {'),
        (b'  return [ar serializeToURL:[NSURL fileURLWithPath:@(path)] error:&err];', b'  metal_stage("archive-save", "begin");\n  bool saved = [ar serializeToURL:[NSURL fileURLWithPath:@(path)] error:&err];\n  metal_stage("archive-save", "end");\n  return saved;'),
        (b'  id<MTLComputePipelineState> pso = [gpu_dev', b'  metal_stage("pipeline", "begin");\n  id<MTLComputePipelineState> pso = [gpu_dev'),
        (b'  if (!pso && !ar) {', b'  metal_stage("pipeline", "end");\n  if (!pso && !ar) {'),
        (b'    id<MTLBinaryArchive> ar = [gpu_dev newBinaryArchiveWithDescriptor:ad', b'    metal_stage("archive-load", "begin");\n    id<MTLBinaryArchive> ar = [gpu_dev newBinaryArchiveWithDescriptor:ad'),
        (b'    gpu_pso = ar ? gpu_pipe(d, ar) : nil;', b'    metal_stage("archive-load", "end");\n    gpu_pso = ar ? gpu_pipe(d, ar) : nil;'),
    ]
    original = source
    for old, new in replacements:
        if source.count(old) != 1:
            raise Failure('Metal stage tracing requires exactly one known host API site: ' + old.decode())
        source = source.replace(old, new, 1)
    return source, {'status': 'APPLIED', 'originalSHA256': hashlib.sha256(original).hexdigest(), 'transformedSHA256': hashlib.sha256(source).hexdigest(), 'scope': 'Host-only flushed monotonic timestamps around Metal library/function/archive/pipeline APIs. Effective device code unchanged (host sections are preprocessed out).'}


def verify_dispatch_contract(text, source, *, solve_row=(4, 0, 1, 0), boundary='solve!(P.JobContext{ticks,seed,profile},Scheduler.build(count,index,stride))'):
    compact = re.sub('\\s+', '', text)
    match = re.search('^\\s*#define\\s+BANGS\\s+(\\d+)', text, re.M)
    fid = re.search('^\\s*#define\\s+FID_solve\\s+(\\d+)', text, re.M)
    table = re.search(r'CONSTV\s+Fid\s+FID_T\[\]\s*=\s*\{(.*?)\};', text, re.S)
    if not match or int(match.group(1)) != 1 or (not fid) or (not table):
        raise Failure('Expected known Bend2.0.38 BANGS1/FID_solve table contract')
    rows = [tuple(map(int, row)) for row in re.findall(r'\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}', table.group(1))]
    index = int(fid.group(1))
    if index >= len(rows) or rows[index] != tuple(solve_row):
        raise Failure('solve task is not the expected marked GPU function')
    host = re.search('(?:u64|Term)\\s+(\\w+)\\s*=\\s*task_node\\(e,\\s*FID_solve,\\s*WL_CONT,\\s*WL_IDX,\\s*0\\);', text)
    direct = bool(host and re.search('return\\s+term_tsk\\(FID_solve,\\s*' + re.escape(host.group(1)) + '\\);', text[host.end():host.end() + 1000]))
    segmented = bool(host and re.search(r'return\s+metal_done\(s,\s*term_tsk\(FID_solve,\s*' + re.escape(host.group(1)) + r'\)\);', text[host.end():host.end() + 1000]))
    if segmented:
        segment_contract = ['staticboolmetal_done(THRMetalState*s,Termresult){s->ret=result;returntrue;}', '#defineWL_CASE(F)FARboolmetal_##F(Enve,THRMetalState*s){', '#defineWL_JMP(F){fid=(F);returnfalse;}', 'caseFID_solve:done=metal_FID_solve(e,&s);break;', 'if(done){returns.ret;}']
        if any(marker not in compact for marker in segment_contract):
            raise Failure('Segment dispatcher does not preserve the marked task return contract')
    if not direct and not segmented:
        raise Failure('solve host task must have zero pending arguments and return directly')
    required = ['typedefstruct{u8ar,resw,bangs,nofk;}Fid;', '#definefid_bangs(x)FID_T[x].bangs', 'e.mem[loc+ar+1]=((u64)idx<<32)|rem;', 'work_loop(e,io_stk,t,!BANGS&&pool_size==1)', 'if((u32)H[tl+1]!=0)', 'cube_run(H,false);', 'if(io_gpu&&fid_bangs((u32)term_aux(t)))', 'cube_run(H,true);', 'if(gpu==1&&BANGS!=0&&why!=NULL){err_fail(why);}', 'MTLCreateSystemDefaultDevice()', 'gpu_pass(H);', '[gpu_encdispatchThreadgroupsWithIndirectBuffer:gpu_bufindirectBufferOffset:H_GROUPS*8+at*12threadsPerThreadgroup:MTLSizeMake(CUBE_T,1,1)]', '[ccommit];', '[cwaitUntilCompleted];', 'if([cerror]){gpu_fail([cerror]);}']
    if any((marker not in compact for marker in required)):
        raise Failure('Generated runtime does not match audited forced-Metal dispatch/completion contract')
    if boundary not in re.sub('\\s+', '', source):
        raise Failure('Source no longer has the audited unconditional solve! boundary')
    return {'status': 'VERIFIED', 'compiledBangs': 1, 'solveFID': index, 'solveRow': list(rows[index]), 'method': 'Known Bend2.0.38 zero-pending marked task → forced-on GPU route → Darwin Metal dispatch/completion. Completed GPU summaries required; CPU fallback forbidden. Not hardware counters.'}

class Experiment:

    def __init__(self, args, repo):
        self.args = args
        self.repo = Path(repo)
        self.out = Path(args.output).resolve()
        self.out.mkdir(parents=True, exist_ok=False)
        print('Logs and report: ' + str(self.out), flush=True)
        self.started = time.monotonic()
        self.deadline = self.started + args.total_seconds
        self.report = {'status': 'FAIL', 'commands': [], 'population': {'count': args.count, 'ticks': args.ticks, 'seed': args.seed, 'profiles': args.profile, 'repetitions': args.repetitions, 'threads': args.threads}, 'scope': 'Same native binary, CPU off versus GPU on; smoke excluded from measured repetitions. No macOS result exists until this command succeeds on that host.'}
        self.env = dict(os.environ)
        self.env.pop('BENDRTS', None)
        self.report['limits'] = {'emitCSeconds': 300, 'nativeBuildSeconds': 300, 'metalBuildSeconds': args.metal_build_seconds, 'eachRunSeconds': args.run_seconds, 'totalSeconds': args.total_seconds}
        self.child = None
        self.guard_files = {str(Path(__file__).resolve()): sha(__file__)}
        launcher = Path(__file__).with_suffix('.sh')
        if launcher.is_file():
            self.guard_files[str(launcher.resolve())] = sha(launcher)
        segments = Path(__file__).with_name('metal_segments.py').resolve()
        self.guard_files[str(segments)] = sha(segments)
        self.report['measurementLogicSHA256'] = dict(self.guard_files)
        self.source_files = None

    def save(self):
        p = self.out / 'report.json'
        tmp = p.with_suffix('.tmp')
        tmp.write_text(json.dumps(self.report, indent=2) + '\n')
        tmp.replace(p)

    def execute(self, label, argv, seconds, env=None):
        remaining = self.deadline - time.monotonic()
        if remaining <= 0:
            raise Failure('Total experiment deadline exhausted')
        row = {'label': label, 'argv': list(map(str, argv)), 'limitSeconds': min(seconds, remaining), 'status': 'INCOMPLETE'}
        self.report['commands'].append(row)
        self.save()
        print('Running ' + label + ' (limit ' + str(round(row['limitSeconds'], 1)) + 's)…', flush=True)
        begin = time.monotonic()
        with (self.out / (label + '.stdout')).open('wb') as stdout, (self.out / (label + '.stderr')).open('wb') as stderr:
            try:
                self.child = subprocess.Popen(argv, cwd=self.repo, env=env or self.env, stdout=stdout, stderr=stderr, start_new_session=True)
                try:
                    code = self.child.wait(timeout=min(seconds, remaining))
                except subprocess.TimeoutExpired:
                    row['timedOut'] = True
                    self.stop_child()
                    raise Failure(label + ' timed out; partial logs preserved')
                row['exitCode'] = code
                if code != 0:
                    raise Failure(label + ' failed with exit ' + str(code) + '; see ' + label + '.stderr')
                row['status'] = 'PASS'
            finally:
                active_error = sys.exc_info()[0] is not None
                cleanup_error = None
                try:
                    self.stop_child()
                except BaseException as error:
                    cleanup_error = error
                    row['cleanupError'] = repr(error)
                row['wallSeconds'] = time.monotonic() - begin
                events = re.findall(r'^\[metal-stage\] ([a-z-]+) (begin|end) ([0-9.]+)$', (self.out / (label + '.stderr')).read_text(errors='replace'), re.M)
                if events:
                    row['metalStageEvents'] = [{'stage': stage, 'event': event, 'monotonicSeconds': float(stamp)} for stage, event, stamp in events]
                for stream in ('stdout', 'stderr'):
                    row[stream + 'SHA256'] = sha(self.out / (label + '.' + stream))
                self.save()
                print(label + ': ' + row['status'] + ', elapsed ' + format(row['wallSeconds'], '.3f') + 's', flush=True)
                if cleanup_error is not None and not active_error:
                    raise Failure('Owned child cleanup failed: ' + str(cleanup_error))
        return ((self.out / (label + '.stdout')).read_text(errors='replace'), row['wallSeconds'])

    def stop_child(self):
        handlers = {sig: signal.signal(sig, signal.SIG_IGN) for sig in (signal.SIGINT, signal.SIGTERM)}
        try:
            child = self.child
            if child is not None:
                if child.poll() is None:
                    try:
                        os.killpg(child.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                child.wait(timeout=3)
                self.child = None
        finally:
            for sig, handler in handlers.items():
                signal.signal(sig, handler)

    def guard(self):
        for path, digest in self.guard_files.items():
            if sha(path) != digest:
                raise Failure('Bound input/artifact changed: ' + path)
        if self.source_files is not None:
            actual = {str(p): sha(p) for p in (self.repo / 'examples/survivors').rglob('*.bend') if 'dist' not in p.relative_to(self.repo).parts}
            if actual != self.source_files:
                raise Failure('Bend source membership/bytes changed')

    def parity(self, expected, actual, label):
        if expected == actual:
            return
        for index, (left, right) in enumerate(zip(expected, actual)):
            if left != right:
                self.report['semanticDifference'] = {'label': label, 'index': index, 'fields': {key: {'expected': left.get(key), 'actual': right.get(key)} for key in sorted(set(left) | set(right)) if left.get(key) != right.get(key)}}
                break
        else:
            self.report['semanticDifference'] = {'label': label, 'expectedCount': len(expected), 'actualCount': len(actual)}
        self.save()
        print('Semantic difference: ' + json.dumps(self.report['semanticDifference']), flush=True)
        raise Failure(label + ' semantic summaries differ')

    def preflight(self):
        if platform.system() != 'Darwin' or platform.machine() != 'arm64':
            raise Failure('Requires macOS on Apple Silicon (Darwin arm64)')
        bend = shutil.which(os.environ.get('BEND', 'bend'))
        cc = shutil.which(os.environ.get('CC', 'clang'))
        if not bend or not cc:
            raise Failure('Install Bend 2.0.38 and Apple clang 17 or newer; BEND and CC may select their paths')
        self.guard_files.update({bend: sha(bend), cc: sha(cc)})
        self.guard()
        text, _ = self.execute('bend-version', [bend, 'version'], 15)
        if text.strip() != "bend 2.0.38":
            raise Failure('This repository requires Bend 2.0.38')
        clang, _ = self.execute('clang-version', [cc, '--version'], 15)
        match = re.search('Apple clang version (\\d+)', clang)
        if not match or int(match.group(1)) < 17:
            raise Failure('Apple clang 17 or newer is required')
        model, _ = self.execute('hardware-model', ['/usr/sbin/sysctl', '-n', 'hw.model'], 10)
        chip, _ = self.execute('chip-name', ['/usr/sbin/sysctl', '-n', 'machdep.cpu.brand_string'], 10)
        self.guard()
        self.env['CC'] = cc
        self.report['host'] = {'model': model.strip(), 'chip': chip.strip(), 'macOS': platform.mac_ver()[0], 'machine': platform.machine(), 'bendVersion': text.strip(), 'clangVersion': clang.strip(), 'bendPath': bend, 'clangPath': cc, 'bendSHA256': sha(bend), 'clangSHA256': sha(cc)}
        return bend

    def dispatch_evidence(self, cfile, sidecar):
        evidence = verify_dispatch_contract(cfile.read_text(errors='replace'), (self.repo / 'examples/survivors/offline-gpu.bend').read_text())
        if not sidecar.is_file() or sidecar.stat().st_size == 0:
            raise Failure('Missing nonempty GPU sidecar next to executable')
        evidence['status'] = 'STATIC_CONTRACT_VERIFIED'
        evidence['sidecarSHA256'] = sha(sidecar)
        return evidence

    def summaries(self, label, count, ticks):
        rows = []
        for line in (self.out / (label + '.stdout')).read_text().splitlines():
            try:
                row = json.loads(line)
            except ValueError:
                raise Failure(label + ' emitted non-JSON stdout')
            if set(row) != FIELDS:
                raise Failure(label + ' has missing or unexpected summary fields')
            for key in FIELDS - {'type', 'backend', 'policy', 'profile', 'status', 'outcome', 'wallMs'}:
                if type(row[key]) is not int or row[key] < 0:
                    raise Failure(label + ' has invalid integer ' + key)
            if row.get('policy') != 'bend-resource-memory-v1':
                raise Failure(label + ' has unexpected policy')
            if row.get('type') != 'summary' or row.get('backend') != 'native' or row.get('status') != 'completed':
                raise Failure(label + ' emitted invalid summary')
            if row.get('wallMs', 'missing') is not None:
                raise Failure(label + ' must report wallMs:null for joined pure jobs')
            rows.append(row)
        rows.sort(key=lambda row: row['index'])
        if len(rows) != count or [r['index'] for r in rows] != list(range(count)):
            raise Failure(label + ' incomplete or duplicate run identities')
        for index, row in enumerate(rows):
            expected_profile = self.args.profile if self.args.profile != 'both' else 'advanced' if index % 2 else 'fresh'
            if row.get('seed') != (self.args.seed + index) % 4294967296 or row.get('profile') != expected_profile or row.get('requestedTicks') != ticks:
                raise Failure(label + ' has incorrect seed/profile/horizon')
            if not (row.get('outcome') == 'bounded-observation' and row.get('tick') == ticks and (row.get('phase') in (0, 1, 2)) or (row.get('outcome') == 'terminal' and row.get('phase') in (3, 4) and (0 <= row.get('tick', -1) <= ticks))):
                raise Failure(label + ' has invalid completion outcome')
        return [{k: v for k, v in row.items() if k != 'wallMs'} for row in rows]

    def run_case(self, label, gpu, count, ticks):
        self.guard()
        env = dict(self.env, NIGHTFALL_BATCH_COUNT=str(count), NIGHTFALL_BATCH_TICKS=str(ticks), NIGHTFALL_BATCH_SEED=str(self.args.seed), NIGHTFALL_BATCH_PROFILE=self.args.profile, NIGHTFALL_BATCH_INDEX='0', NIGHTFALL_BATCH_STRIDE='1')
        _, elapsed = self.execute(label, [str(self.out / 'nightfall-gpu-batch'), '+RTS', '--gpu', gpu, '--threads', str(self.args.threads), '-RTS'], self.args.run_seconds, env)
        self.guard()
        return (self.summaries(label, count, ticks), elapsed)

    def run(self):
        self.report['limits']['smokeTicks'] = self.args.smoke_ticks
        lock = None
        try:
            lock = open('/tmp/bendvy-parity-heavy.lock', 'a')
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            bend = self.preflight()
            self.source_files = {str(p): sha(p) for p in (self.repo / 'examples/survivors').rglob('*.bend') if 'dist' not in p.relative_to(self.repo).parts}
            self.guard_files.update({**self.source_files, str(self.repo / 'bendhub-dependencies.json'): sha(self.repo / 'bendhub-dependencies.json'), bend: sha(bend), self.env['CC']: sha(self.env['CC'])})
            dependency_manifest = json.loads((self.repo / 'bendhub-dependencies.json').read_text())
            library = Path(self.env.get('BEND_LIB', str(Path.home() / '.bend/lib'))).expanduser().resolve()
            self.report['dependencies'] = {'resolvedBendLib': str(library), 'declaredPublicPin': dependency_manifest, 'scope': 'Declared public pin and installed selected package bytes where present; not a complete compiler/Base/SDK closure proof.'}
            for package in dependency_manifest.get('packages', {}).values():
                package_path = library / package['contentHash']
                if package_path.is_dir():
                    self.guard_files.update({str(p): sha(p) for p in package_path.rglob('*') if p.is_file()})
            source = self.repo / 'examples/survivors/offline-gpu.bend'
            self.report['source'] = {'entry': str(source), 'sha256': sha(source), 'dependencyManifestSHA256': sha(self.repo / 'bendhub-dependencies.json'), 'bendSources': {str(p.relative_to(self.repo)): sha(p) for p in sorted((self.repo / 'examples/survivors').rglob('*.bend')) if 'dist' not in p.relative_to(self.repo).parts}}
            binary = self.out / 'nightfall-gpu-batch'
            cfile = self.out / 'generated.c'
            self.guard()
            self.execute('emit-c', [bend, str(source), '-o', str(cfile)], 300)
            mode = 'metal-noinline-spins' if self.args.metal_noinline_spins else 'standard'
            self.report['metalCodeMode'] = mode
            if self.args.metal_noinline_spins:
                original = cfile.read_bytes()
                raw = self.out / 'generated.original.c'
                raw.write_bytes(original)
                self.guard_files[str(raw)] = sha(raw)
                self.report['metalCodeTransform'] = {'status': 'REQUESTED', 'originalSHA256': sha(raw), 'originalPath': str(raw)}
                self.save()
                transformed, metadata = transform_metal_spins(original)
                self.report['metalCodeMode'] = mode
                self.report['metalCodeTransform'] = metadata
                cfile.write_bytes(transformed)
                self.save()
            if self.args.metal_segment_functions:
                before_segments = self.out / 'generated.pre-segments.c'
                before_segments.write_bytes(cfile.read_bytes())
                self.guard_files[str(before_segments)] = sha(before_segments)
                segmented, metadata = transform_metal_segments(cfile.read_bytes())
                cfile.write_bytes(segmented)
                self.report['metalSegmentFunctions'] = metadata
                self.save()
            if self.args.metal_stage_trace:
                before_trace = self.out / 'generated.pre-trace.c'
                before_trace.write_bytes(cfile.read_bytes())
                self.guard_files[str(before_trace)] = sha(before_trace)
                traced, metadata = transform_metal_trace(cfile.read_bytes())
                cfile.write_bytes(traced)
                self.report['metalStageTrace'] = metadata
                self.save()
            self.guard_files[str(cfile)] = sha(cfile)
            self.report['artifacts'] = {'generatedCSHA256': sha(cfile)}
            self.report['codeMetrics'] = {'cBytes': cfile.stat().st_size, 'fidCount': len(re.findall(r'^\s*#define\s+FID_\w+\s+\d+', cfile.read_text(errors='replace'), re.M))}
            print('Generated C: ' + str(self.report['codeMetrics']['cBytes']) + ' bytes, ' + str(self.report['codeMetrics']['fidCount']) + ' FIDs', flush=True)
            self.report['dispatch'] = verify_dispatch_contract(cfile.read_text(errors='replace'), source.read_text())
            self.report['dispatch']['status'] = 'STATIC_CONTRACT_VERIFIED'
            self.save()
            self.guard()
            # Exact Darwin native-build recipe from the official Bend 2.0.38 CLI.
            native_command = [self.env['CC'], '-DBEND_METAL=1', '-x', 'objective-c', '-fobjc-arc', '-fmodules', '-std=c11', '-O3', str(cfile), '-lpthread', '-lm', '-o', str(binary)]
            self.execute('native-build', native_command, 300)
            if not os.access(binary, os.X_OK):
                raise Failure('Native compiler did not create an executable')
            self.guard_files[str(binary)] = sha(binary)
            self.report['artifacts']['binarySHA256'] = sha(binary)
            self.save()
            self.guard()
            cpu, cpu_seconds = self.run_case('smoke-cpu', 'off', 2, self.args.smoke_ticks)
            self.report['smokeCpu'] = {'status': 'PASS', 'wallSeconds': cpu_seconds, 'summariesExcludingWallMs': cpu}
            self.save()
            # Keep Metal compilation short; retain the CPU smoke if it times out.
            self.execute('metal-build', [str(binary), '+RTS', '--gpu-build', '-RTS'], self.args.metal_build_seconds)
            self.guard()
            sidecar = Path(str(binary) + '.gpu')
            self.report['dispatch'] = self.dispatch_evidence(cfile, sidecar)
            self.guard_files[str(sidecar)] = sha(sidecar)
            self.report['artifacts']['gpuSidecarSHA256'] = sha(sidecar)
            self.save()
            gpu, _ = self.run_case('smoke-gpu', 'on', 2, self.args.smoke_ticks)
            self.parity(cpu, gpu, 'Smoke CPU/GPU')
            self.report['dispatch']['status'] = 'VERIFIED'
            self.report['dispatch']['gpuSmokeCompleted'] = True
            pairs = []
            canonical = None
            for rep in range(self.args.repetitions):
                values = {}
                times = {}
                order = ['cpu', 'gpu'] if rep % 2 == 0 else ['gpu', 'cpu']
                for mode in order:
                    values[mode], times[mode] = self.run_case('rep-' + str(rep) + '-' + mode, 'off' if mode == 'cpu' else 'on', self.args.count, self.args.ticks)
                self.parity(values['cpu'], values['gpu'], 'CPU/GPU repetition ' + str(rep))
                if canonical is None:
                    canonical = values['cpu']
                self.parity(canonical, values['cpu'], 'Canonical CPU repetition ' + str(rep))
                self.parity(canonical, values['gpu'], 'Canonical GPU repetition ' + str(rep))
                pairs.append({'repetition': rep, 'order': order, 'cpuSeconds': times['cpu'], 'gpuSeconds': times['gpu']})
                self.report['pairs'] = pairs
                self.save()
            cpu = statistics.median((p['cpuSeconds'] for p in pairs))
            gpu = statistics.median((p['gpuSeconds'] for p in pairs))
            self.report['timing'] = {'cpuMedianSeconds': cpu, 'gpuMedianSeconds': gpu, 'cpuOverGpu': cpu / gpu, 'scope': 'Whole batch external wall time; excludes compilation and smoke. Descriptive paired repetitions, not universal scaling evidence.'}
            self.report['semanticParity'] = 'PASS'
            self.report['status'] = 'PASS' if self.report['dispatch']['status'] == 'VERIFIED' else 'PARITY_PASS_DISPATCH_UNVERIFIED'
        except BaseException as error:
            self.report['error'] = str(error)
            self.report['status'] = 'FAIL'
        finally:
            try:
                self.stop_child()
            except BaseException as error:
                self.report['cleanupError'] = repr(error)
                self.report['status'] = 'FAIL'
            try:
                self.guard()
            except BaseException as error:
                self.report.setdefault('guardFailures', []).append(str(error))
                self.report['status'] = 'FAIL'
            self.report['totalWallSeconds'] = time.monotonic() - self.started
            self.save()
            if lock is not None:
                lock.close()
        timing = self.report.get('timing', {})
        host = self.report.get('host', {})
        print(('PASS: Metal-required execution (CPU fallback forbidden; runtime contract verified)' if self.report['status'] == 'PASS' else self.report['status']) + ' ' + host.get('model', 'unknown-host') + ' macOS ' + host.get('macOS', 'unknown') + ' count=' + str(self.args.count) + ' ticks=' + str(self.args.ticks))
        print('Bend: ' + host.get('bendVersion', 'unavailable') + '; clang: ' + host.get('clangVersion', 'unavailable').split('\n')[0])
        print('CPU median=' + str(timing.get('cpuMedianSeconds', 'unavailable')) + 's GPU median=' + str(timing.get('gpuMedianSeconds', 'unavailable')) + 's CPU/GPU=' + str(timing.get('cpuOverGpu', 'unavailable')))
        print('Chip: ' + host.get('chip', 'NOT TESTED') + '; threads=' + str(self.args.threads))
        print('Semantic parity: ' + self.report.get('semanticParity', 'NOT TESTED'))
        print('Dispatch: ' + self.report.get('dispatch', {}).get('status', 'NOT TESTED'))
        if 'error' in self.report:
            print('Error: ' + self.report['error'])
            if self.report['commands']:
                label = self.report['commands'][-1]['label']
                log = self.out / (label + '.stderr')
                if log.is_file() and log.stat().st_size:
                    print('Last stderr lines:\n' + '\n'.join(log.read_text(errors='replace').splitlines()[-12:]))
        print('Report: ' + str(self.out / 'report.json'))
        return 0 if self.report['status'] == 'PASS' else 1

def parser():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--count', type=int, default=8)
    p.add_argument('--ticks', type=int, default=120)
    p.add_argument('--seed', type=int, default=100)
    p.add_argument('--profile', choices=['fresh', 'advanced', 'both'], default='both')
    p.add_argument('--threads', type=int, default=min(8, os.cpu_count() or 1))
    p.add_argument('--repetitions', type=int, default=3)
    p.add_argument('--smoke-ticks', type=int, default=60, help='Smoke horizon (1..60); lower values qualify only shorter diagnostics')
    p.add_argument('--run-seconds', type=int, default=180)
    p.add_argument('--metal-segment-functions', action='store_true', help='Experimental device segment dispatcher with shared lane state')
    p.add_argument('--metal-stage-trace', action='store_true', help='Trace host Metal compiler stages with flushed monotonic timestamps')
    p.add_argument('--metal-noinline-spins', action='store_true', help='Experimental candidate-specific Metal-only noinline boundaries; disabled by default')
    p.add_argument('--metal-build-seconds', type=int, default=120)
    p.add_argument('--total-seconds', type=int, default=900)
    p.add_argument('--output', default=None)
    return p

def main():
    p = parser()
    a = p.parse_args()
    if not (1 <= a.smoke_ticks <= 60 and 1 <= a.count <= 10000 and 1 <= a.ticks <= 37000 and (0 <= a.seed <= 4294967295) and (1 <= a.threads <= 128) and (1 <= a.repetitions <= 10) and (1 <= a.run_seconds <= 180) and (1 <= a.metal_build_seconds <= 120) and (1 <= a.total_seconds <= 1800)):
        p.error('Workload or timeout outside documented bounds')
    repo = Path(__file__).resolve().parents[2]
    if a.output is None:
        a.output = str(repo / 'examples/survivors/dist/metal-experiments' / ('run-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-' + str(os.getpid())))
    experiment = Experiment(a, repo)

    def stop(*_):
        raise KeyboardInterrupt('experiment interrupted')
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    return experiment.run()
if __name__ == '__main__':
    sys.exit(main())
