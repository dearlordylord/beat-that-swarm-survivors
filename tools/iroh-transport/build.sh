#!/usr/bin/env bash
# Build only the reusable Iroh IO module (no lab UI or Bend application protocol).
set -euo pipefail
app_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
output_dir="${1:?Usage: build-transport.sh OUTPUT_DIRECTORY}"
target_dir="${CARGO_TARGET_DIR:-/tmp/bendvy-iroh-cargo-target}"
cargo build --locked --release --target wasm32-unknown-unknown \
  --manifest-path "$app_dir/transport/Cargo.toml" --target-dir "$target_dir" --jobs 2
mkdir -p "$output_dir"
wasm-bindgen "$target_dir/wasm32-unknown-unknown/release/bendvy_iroh_transport.wasm" \
  --target web --out-dir "$output_dir" --out-name iroh_transport
