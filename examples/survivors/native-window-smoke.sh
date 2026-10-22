#!/usr/bin/env bash
# Linux-only actual-window smoke. Build separately; no dependencies are installed.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ${1:-} != --worker ]]; then
  source "$script_dir/../common.sh"
  example_timeout 30 bash "$script_dir/native-window-smoke.sh" --worker
  exit $?
fi
binary=${NIGHTFALL_BINARY:-$script_dir/dist/nightfall}
sysroot=${NIGHTFALL_X11_SYSROOT:-/}
xvfb=${XVFB:-$sysroot/usr/bin/Xvfb}
xdotool=${XDOTOOL:-$sysroot/usr/bin/xdotool}
[[ -x "$binary" && -x "$xvfb" && -x "$xdotool" ]]
export LD_LIBRARY_PATH="$sysroot/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
receipt=$(mktemp -d "${TMPDIR:-/tmp}/nightfall-window-XXXXXX")
echo "Native window diagnostic receipt: $receipt"
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
# Xorg exposes XkbBinDirectory as a writable process-global; its upstream
# compiler path has no runtime option. A fixture-local preload relocates only
# this setting when using an unpacked Debian sysroot, without modifying /usr.
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
(cd "$receipt"; exec "$binary") >"$receipt/game.log" 2>&1 &
game_pid=$!
window=
for ((attempt=0;attempt<120;attempt++)); do
  window=$("$xdotool" search --onlyvisible --name '^Nightfall Survivors - Bend$' 2>/dev/null | head -1) || true
  [[ -n "$window" ]] && break
  kill -0 "$game_pid"
  sleep 0.05
done
[[ -n "$window" ]]
"$xdotool" getwindowgeometry --shell "$window" >"$receipt/geometry.txt"
[[ $(sed -n 's/^WIDTH=//p' "$receipt/geometry.txt") == 1024 ]]
[[ $(sed -n 's/^HEIGHT=//p' "$receipt/geometry.txt") == 768 ]]
sleep 0.3
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
capture menu
"$xdotool" key --window "$window" space
sleep 0.5
"$xdotool" keydown --window "$window" d
sleep 0.4
"$xdotool" keyup --window "$window" d
capture gameplay
"$xdotool" key --window "$window" Escape
sleep 0.2
capture paused
sleep 0.25
capture paused-still
cmp "$receipt/paused.ppm" "$receipt/paused-still.ppm"
"$xdotool" key --window "$window" q
sleep 0.2
"$xdotool" key --window "$window" Return
sleep 0.2
capture returned
python3 - "$receipt/menu.ppm" "$receipt/returned.ppm" <<'PYTEST'
import sys
def title(path):
    data=open(path,'rb').read().split(b'\n',3)[3]
    return b''.join(data[y*1024*3:y*1024*3+600*3] for y in range(80))
assert title(sys.argv[1])==title(sys.argv[2]), 'Q did not restore the camp menu title.'
PYTEST
kill -0 "$game_pid"
[[ -s "$receipt/nightfall-profile.txt" ]]
cmp -s "$receipt/menu.ppm" "$receipt/gameplay.ppm" && { echo 'Start input did not change window pixels.' >&2; exit 1; }
cmp -s "$receipt/gameplay.ppm" "$receipt/paused.ppm" && { echo 'Pause input did not change window pixels.' >&2; exit 1; }
# Send the same WM_DELETE_WINDOW ClientMessage as a real window-manager close.
# xdotool windowclose destroys the drawable; that does not exercise Event.Close.
python3 - "$window" <<'PY'
import ctypes as C,ctypes.util,sys
x=C.CDLL(ctypes.util.find_library('X11'))
x.XOpenDisplay.argtypes=[C.c_char_p];x.XOpenDisplay.restype=C.c_void_p
x.XInternAtom.argtypes=[C.c_void_p,C.c_char_p,C.c_int];x.XInternAtom.restype=C.c_ulong
x.XSendEvent.argtypes=[C.c_void_p,C.c_ulong,C.c_int,C.c_long,C.c_void_p]
x.XFlush.argtypes=[C.c_void_p];x.XCloseDisplay.argtypes=[C.c_void_p]
class Data(C.Union):_fields_=[('b',C.c_char*20),('s',C.c_short*10),('l',C.c_long*5)]
class Client(C.Structure):_fields_=[('type',C.c_int),('serial',C.c_ulong),('send_event',C.c_int),('display',C.c_void_p),('window',C.c_ulong),('message_type',C.c_ulong),('format',C.c_int),('data',Data)]
class Event(C.Union):_fields_=[('client',Client),('pad',C.c_long*24)]
d=x.XOpenDisplay(None);assert d
e=Event();e.client.type=33;e.client.display=d;e.client.window=int(sys.argv[1]);e.client.message_type=x.XInternAtom(d,b'WM_PROTOCOLS',0);e.client.format=32;e.client.data.l[0]=x.XInternAtom(d,b'WM_DELETE_WINDOW',0)
assert x.XSendEvent(d,e.client.window,0,0,C.byref(e))
x.XFlush(d);x.XCloseDisplay(d)
PY
for ((attempt=0;attempt<100;attempt++)); do
  kill -0 "$game_pid" 2>/dev/null || break
  sleep 0.05
done
if kill -0 "$game_pid" 2>/dev/null; then echo 'Window close did not stop the native game.' >&2; exit 1; fi
wait "$game_pid"
game_pid=
sha256sum "$binary" "$receipt/"*.ppm "$receipt/nightfall-profile.txt" >"$receipt/SHA256SUMS"
echo "NATIVE WINDOW PASS: start, input delivery, paused pixels stay still, camp return, profile save, graceful close; $receipt"
