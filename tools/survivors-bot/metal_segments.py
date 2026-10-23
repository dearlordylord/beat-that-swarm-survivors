"""Candidate-specific Bend 2.0.38 segment extraction for bounded diagnostics."""
import hashlib
import re


def transform_metal_segments(source):
    text = source.decode('utf-8')
    begin = 'static Term work_loop(Env e, DEV Term* sp, Term t, u32 seq) {\n'
    trailer = '#if DEVICE\n  default: {\n    err_post(e.mem, ERR_FIDS);\n    return 0;\n  }\n  }\n  }\n}\n#endif'
    host = '// A host self-jump is a tail call: as a loop, clang hoists constants badly.\n#if !DEVICE'
    if any(text.count(site) != 1 for site in (begin, trailer, host)):
        raise ValueError('Segment mode requires the known work-loop boundaries')
    start = text.index(begin)
    body_start = text.index('// Segments\n', start)
    body_end = text.index(trailer, body_start)
    end = body_end + len(trailer)
    original_loop = text[start:end]
    body = text[body_start:body_end]
    names = re.findall(r'^  WL_CASE\((FID_\w+)\)', body, re.M)
    bank = re.search(r'^#define WL_BANK Term ([^;]+);$', text, re.M)
    if not bank:
        raise ValueError('Missing known register bank')
    regs = bank.group(1).split(', ')
    if len(names) != 1073 or len(set(names)) != 1073 or set(regs) != {f'r{i}' for i in range(86)} | {'rp'}:
        raise ValueError('Segment mode requires 1073 unique cases and the known 87 registers')
    if len(re.findall(r'\breturn\b', body)) != len(re.findall(r'^\s*return ([^;\n]+);', body, re.M)):
        raise ValueError('Unexpected segment return syntax')
    body = re.sub(r'^(\s*)return ([^;\n]+);', r'\1return metal_done(s, \2);', body, flags=re.M)
    # Reproduce conditional availability in the tiny direct-call dispatcher.
    dispatch = []
    for line in body.splitlines():
        if line.startswith('#'):
            if line not in ('#if !DEVICE', '#endif'):
                raise ValueError('Unexpected segment preprocessor directive: ' + line)
            dispatch.append(line)
        match = re.match(r'  WL_CASE\((FID_\w+)\)', line)
        if match:
            name = match.group(1)
            dispatch.append(f'    case {name}: done = metal_{name}(e, &s); break;')
    fields = {reg: 'v' + reg[1:] for reg in regs}
    fields.update(sp='qsp', seq='qseq', rn='qrn', fid='qfid', wpoll='qpoll')
    aliases = '\n'.join(f'#define {name} (s->{field})' for name, field in fields.items())
    unaliases = '\n'.join(f'#undef {name}' for name in fields)
    room_start = text.index('#define WL_ROOM(')
    room_end = text.index('\n\n', room_start)
    room = text[room_start:room_end].replace('return 0;', 'return metal_done(s, 0);')
    code = '''#if DEVICE || defined(BEND_SEGMENT_CPU_CHECK)
// Each segment shares the same lane state; a false result requests dispatch.
typedef struct {
  DEV Term* qsp;
  u32 qseq, qrn, qfid, qpoll;
  Term ret;
  Term REGS;
} MetalState;
static bool metal_done(THR MetalState* s, Term result) {
  s->ret = result;
  return true;
}
ALIASES
#undef WL_CASE
#undef WL_OPEN
#undef WL_JMP
#undef WL_DYN
#undef WL_SPIN
#undef WL_SPUN
#undef WL_AGAIN
#undef WL_ROOM
#define WL_CASE(F) FAR bool metal_##F(Env e, THR MetalState* s) {
#define WL_OPEN {
#define WL_JMP(F) { fid = (F); return false; }
#define WL_DYN WL_JMP
#define WL_SPIN for (;;) { if (err_spun(e.mem, &wpoll)) { return metal_done(s, 0); }
#define WL_SPUN } return false;
#define WL_AGAIN(F) continue
ROOM
BODY
UNALIASES
static Term work_loop(Env e, DEV Term* sp, Term t, u32 seq) {
  MetalState s = {0};
  s.qsp = sp;
  s.qseq = seq;
  s.qfid = FID_ENTER;
  s.v0 = t;
  for (;;) {
    if (err_spun(e.mem, &s.qpoll)) { return 0; }
    bool done;
    switch (s.qfid) {
DISPATCH
    default: err_post(e.mem, ERR_FIDS); return 0;
    }
    if (done) { return s.ret; }
  }
}
#else
ORIGINAL
#endif'''
    for key, value in [('REGS', ', '.join(fields[r] for r in regs)), ('UNALIASES', unaliases), ('ALIASES', aliases), ('ROOM', room), ('BODY', body), ('DISPATCH', '\n'.join(dispatch)), ('ORIGINAL', original_loop)]:
        code = re.sub(r'\b' + key + r'\b', lambda _: value, code)
    transformed = (text[:start] + code + text[end:]).replace(host, host + ' && !defined(BEND_SEGMENT_CPU_CHECK)', 1).encode()
    return transformed, {'status': 'APPLIED', 'originalSHA256': hashlib.sha256(source).hexdigest(), 'transformedSHA256': hashlib.sha256(transformed).hexdigest(), 'segmentCount': len(names), 'registerCount': len(regs), 'scope': 'Device direct-call segments with shared lane registers/stack/continuation/polling. Original host branch preserved. BEND_SEGMENT_CPU_CHECK selects diagnostic CPU validation.'}
