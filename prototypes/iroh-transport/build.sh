#!/usr/bin/env bash
set -euo pipefail
app_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
prototype_repo="$(cd -- "$app_dir/../.." && pwd)"
BEND="${BEND:-bend}"
NODE="${NODE:-node}"
iroh_bend_version="$("$BEND" version)"
[[ "$iroh_bend_version" == 'bend 2.0.38' ]] || { echo 'This prototype pins Bend 2.0.38.' >&2; exit 1; }
mkdir -p "$app_dir/dist"
mkdir "$app_dir/dist/.build-lock" 2>/dev/null || { echo 'The protocol prototype is already building.' >&2; exit 75; }
staging="$(mktemp -d "$app_dir/dist/.build-XXXXXX")"
before="$app_dir/dist/.source-before-$$.json"
trap 'rm -rf "$staging"; rm -f "$before"; rmdir "$app_dir/dist/.build-lock"' EXIT
node "$app_dir/receipt.mjs" capture "$before"
"$NODE" "$prototype_repo/examples/run-bounded.mjs" 30 "$BEND" "$app_dir/core/protocol.bend" -o "$staging/core.mjs"
CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/tmp/bendvy-iroh-cargo-target}" cargo build --locked --release --target wasm32-unknown-unknown --manifest-path "$app_dir/transport/Cargo.toml" --jobs 2
mkdir -p "$staging/wasm"
wasm-bindgen "${CARGO_TARGET_DIR:-/tmp/bendvy-iroh-cargo-target}/wasm32-unknown-unknown/release/bendvy_iroh_transport.wasm" --target web --out-dir "$staging/wasm" --out-name iroh_transport
mkdir -p "$staging/dist"
mv "$staging/core.mjs" "$staging/dist/core.mjs"
for asset in index.html style.css app.mjs channel.mjs core-adapter.mjs; do cp "$app_dir/$asset" "$staging/$asset"; done
node "$app_dir/receipt.mjs" finalize "$staging" "$before"
rm -rf "$app_dir/dist/web"
mv "$staging" "$app_dir/dist/web"
echo "Connection prototype: $app_dir/dist/web"
