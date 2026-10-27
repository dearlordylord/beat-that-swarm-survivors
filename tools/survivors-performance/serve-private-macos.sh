#!/bin/bash
# Private HTTPS preview through Tailscale Serve. Keep this terminal open.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
game_dir="$repo_root/examples/survivors/dist/web"
[[ -f "$game_dir/index.html" ]] || { echo "Build missing: $game_dir" >&2; exit 1; }

if command -v tailscale >/dev/null 2>&1; then
  tailscale_cli=$(command -v tailscale)
elif [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
  tailscale_cli=/Applications/Tailscale.app/Contents/MacOS/Tailscale
else
  echo 'Tailscale CLI not found. Install/start Tailscale on this Mac.' >&2
  exit 1
fi
export TAILSCALE_BE_CLI=1
https_port=${SURVIVORS_HTTPS_PORT:-9443}

# Use a separate loopback backend; the old HTTP preview can keep running.
python3 -m http.server 18813 --bind 127.0.0.1 --directory "$game_dir" &
backend_pid=$!
cleanup() {
  kill "$backend_pid" 2>/dev/null || true
  wait "$backend_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Verify our backend started, rather than proxying an unrelated occupied port.
sleep 1
if ! kill -0 "$backend_pid" 2>/dev/null; then
  echo 'Local backend failed to start. Port 18813 may already be occupied.' >&2
  exit 1
fi
echo 'Starting private HTTPS. Open the https:// address printed by Tailscale.'
echo 'Keep this terminal open. Press Ctrl+C to stop.'
echo 'If Tailscale prints an enablement link, open it to enable Serve/HTTPS.'
"$tailscale_cli" serve --https="$https_port" http://127.0.0.1:18813
