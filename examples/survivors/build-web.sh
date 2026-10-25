#!/usr/bin/env bash
# Build a self-contained static browser game from the current Bend sources.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
app_dir="$example_repo/examples/survivors"
mkdir -p "$app_dir/dist"
staging_dir="$(mktemp -d "$app_dir/dist/.web-XXXXXX")"
trap 'rm -rf "$staging_dir"; example_cleanup_lock' EXIT
mkdir -p "$staging_dir/dist"
example_emit "$app_dir/game.bend" "$staging_dir/dist/game.mjs"
for asset in index.html style.css browser.mjs renderer.mjs content.mjs audio.mjs progression.mjs expedition-menu.mjs menu-controls.mjs menu-a.css menu-moon.css; do
  cp "$app_dir/$asset" "$staging_dir/$asset"
done
cp "$example_repo/LICENSE-MIT" "$example_repo/LICENSE-APACHE" "$staging_dir/"
rm -rf "$app_dir/dist/web"
mv "$staging_dir" "$app_dir/dist/web"
echo "Static game: $app_dir/dist/web"
echo 'Serve this directory over HTTP; no server-side Bend or Node.js is needed.'
