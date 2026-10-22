#!/usr/bin/env bash
# Offline actual-window bot smoke. Build separately. Entire worker is bounded.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$script_dir/../.." && pwd)
if [[ ${1:-} != --worker ]]; then
  source "$repo/examples/common.sh"
  example_timeout 30 bash "$script_dir/visible-window-smoke.sh" --worker
  exit $?
fi
cd "$repo"
binary=${NIGHTFALL_BOT_BINARY:-$repo/examples/survivors/dist/nightfall-bot}
sysroot=${NIGHTFALL_X11_SYSROOT:-/}
xvfb=${XVFB:-$sysroot/usr/bin/Xvfb}
xdotool=${XDOTOOL:-$sysroot/usr/bin/xdotool}
[[ -x "$binary" && -x "$xvfb" && -x "$xdotool" ]]
export LD_LIBRARY_PATH="$sysroot/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
receipt=$(mktemp -d "${TMPDIR:-/tmp}/nightfall-visible-window-XXXXXX")
echo "Visible bot window diagnostic receipt: $receipt"
x_pid= game_pid=
cleanup() {
  trap - EXIT INT TERM
  if [[ -n "$game_pid" ]] && kill -0 "$game_pid" 2>/dev/null; then kill -TERM "$game_pid" 2>/dev/null || true; fi
  if [[ -n "$x_pid" ]] && kill -0 "$x_pid" 2>/dev/null; then kill -TERM "$x_pid" 2>/dev/null || true; fi
  [[ -z "$game_pid" ]] || wait "$game_pid" 2>/dev/null || true
  [[ -z "$x_pid" ]] || wait "$x_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
xkb_env=()
xkb_args=()
if [[ -d "$sysroot/usr/share/X11/xkb" ]]; then
  xkb_args=(-xkbdir "$sysroot/usr/share/X11/xkb")
fi
if [[ -f "$sysroot/libnightfall-xkb-path.so" ]]; then
  xkb_env=(env "NIGHTFALL_XKB_BIN=$sysroot/usr/bin" "LD_PRELOAD=$sysroot/libnightfall-xkb-path.so${LD_PRELOAD:+:$LD_PRELOAD}")
fi
"${xkb_env[@]}" "$xvfb" "${xkb_args[@]}" -displayfd 3 -screen 0 1024x768x24 -nolisten tcp -ac >"$receipt/xvfb.log" 2>&1 3>"$receipt/display" &
x_pid=$!
for ((attempt=0;attempt<100;attempt++)); do
  [[ -s "$receipt/display" ]] && break
  kill -0 "$x_pid"
  sleep 0.05
done
[[ -s "$receipt/display" ]]
export DISPLAY=":$(cat "$receipt/display")"
"${NODE:-node}" tools/survivors-bot/visible.mjs --mode heuristic --seconds 20 --binary "$binary" --receipts-dir "$receipt/runs" >"$receipt/controller.log" 2>&1 &
game_pid=$!
window=
for ((attempt=0;attempt<120;attempt++)); do
  window=$("$xdotool" search --onlyvisible --name '^Nightfall - Visible Bot' 2>/dev/null | head -1) || true
  [[ -n "$window" ]] && break
  kill -0 "$game_pid"
  sleep 0.05
done
[[ -n "$window" ]]
"$xdotool" getwindowgeometry --shell "$window" >"$receipt/geometry.txt"
[[ $(sed -n 's/^WIDTH=//p' "$receipt/geometry.txt") == 1024 ]]
[[ $(sed -n 's/^HEIGHT=//p' "$receipt/geometry.txt") == 768 ]]
capture() {
  python3 - "$window" "$receipt/$1.ppm" <<'PY'
import ctypes as C, ctypes.util, sys
x=C.CDLL(ctypes.util.find_library('X11'))
x.XOpenDisplay.argtypes=[C.c_char_p]; x.XOpenDisplay.restype=C.c_void_p
x.XGetImage.argtypes=[C.c_void_p,C.c_ulong,C.c_int,C.c_int,C.c_uint,C.c_uint,C.c_ulong,C.c_int]; x.XGetImage.restype=C.c_void_p
x.XGetPixel.argtypes=[C.c_void_p,C.c_int,C.c_int];x.XGetPixel.restype=C.c_ulong
x.XDestroyImage.argtypes=[C.c_void_p];x.XCloseDisplay.argtypes=[C.c_void_p]
d=x.XOpenDisplay(None); assert d
image=x.XGetImage(d,int(sys.argv[1]),0,0,1024,768,C.c_ulong(-1).value,2); assert image
# Actual X11 window pixels, independent of Bend's headless Image capture.
pixels=bytearray()
for y in range(768):
    for col in range(1024):
        p=x.XGetPixel(image,col,y)
        pixels.extend(((p>>16)&255,(p>>8)&255,p&255))
with open(sys.argv[2],'wb') as f:f.write(b'P6\n1024 768\n255\n'+pixels)
x.XDestroyImage(image);x.XCloseDisplay(d)
PY
}
sleep 0.2
capture first
sleep 0.5
capture second
if cmp -s "$receipt/first.ppm" "$receipt/second.ppm"; then
  echo 'Visible bot did not change actual window pixels.' >&2
  exit 1
fi
"$xdotool" keydown --window "$window" Escape
for ((attempt=0;attempt<100;attempt++)); do
  kill -0 "$game_pid" 2>/dev/null || break
  sleep 0.05
done
if kill -0 "$game_pid" 2>/dev/null; then echo 'Escape did not stop visible bot controller.' >&2; exit 1; fi
wait "$game_pid"
game_pid=
if "$xdotool" getwindowgeometry "$window" >/dev/null 2>&1; then echo 'Native child window remained after controller exit.' >&2; exit 1; fi
python3 - "$receipt" <<'PYTEST'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
log=(root/'controller.log').read_text()
paths=[line.removeprefix('Visible bot receipt: ') for line in log.splitlines() if line.startswith('Visible bot receipt: ')]
assert len(paths)==1, 'Missing unique receipt path'
receipt=pathlib.Path(paths[0]); rows=[json.loads(line) for line in receipt.read_text().splitlines()]
summary=[r for r in rows if r['type']=='summary']; assert len(summary)==1
assert summary[0]['outcome']=='window-closed', summary
assert summary[0]['tick']>0, summary
commands=[r for r in rows if r['type']=='command']; assert commands
assert max(r['sequence'] for r in commands)>1
assert not any(r.get('type')=='error' for r in rows)
session=receipt.with_suffix('')
assert json.loads((session/'closed.json').read_text())['closed'] is True
observation=json.loads((session/'observation.json').read_text())
assert observation['sequence']>1 and observation['frame']['tick']>0
(root/'session-receipt.txt').write_text(str(receipt)+'\n')
print('Visible bot summary:', json.dumps(summary[0]))
PYTEST
sha256sum "$binary" "$receipt/"*.ppm >"$receipt/SHA256SUMS"
echo "VISIBLE BOT WINDOW PASS: native 1024x768, actual changing pixels, advancing ECS observation, Escape, controller cleanup and window-closed receipt; $receipt"
