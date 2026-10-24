#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../../examples/common.sh"
app_dir="$example_repo/prototypes/iroh-transport"
mkdir -p "$app_dir/dist"
staging="$(mktemp -d "$app_dir/dist/.build-XXXXXX")"
before="$app_dir/dist/.source-before-$$.json"
trap 'rm -rf "$staging"; rm -f "$before"; example_cleanup_lock' EXIT
node "$app_dir/receipt.mjs" capture "$before"
example_emit "$app_dir/core/protocol.bend" "$staging/core.mjs"
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
