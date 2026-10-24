#!/usr/bin/env bash
# Compile Bend rules and simulation, then prerender the menu with Astro.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
app_dir="$example_repo/examples/survivors"
mkdir -p "$app_dir/dist" "$app_dir/web/dist"
staging_dir="$(mktemp -d "$app_dir/dist/.web-XXXXXX")"
astro_output="$(mktemp -d "$app_dir/web/dist/.web-XXXXXX")"
old_dir=""
cleanup() {
  if [[ -n "$old_dir" && -d "$old_dir" && ! -e "$app_dir/dist/web" ]]; then
    mv "$old_dir" "$app_dir/dist/web"
  fi
  rm -rf "$staging_dir" "$astro_output"
  example_cleanup_lock
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$staging_dir/public/dist"
example_emit "$app_dir/menu-catalog.bend" "$app_dir/dist/menu-catalog.mjs"
example_emit "$app_dir/menu-progression.bend" "$app_dir/dist/menu-progression.mjs"
"$NODE" "$app_dir/generate-menu-content.mjs"
example_emit "$app_dir/game.bend" "$staging_dir/public/dist/game.mjs"
cp "$app_dir/dist/menu-progression.mjs" "$staging_dir/public/dist/"
example_emit "$app_dir/coop-core.bend" "$staging_dir/public/dist/coop-core.mjs"
example_emit "$app_dir/coop-session.bend" "$staging_dir/public/dist/coop-session.mjs"
example_emit "$app_dir/coop-protocol.bend" "$staging_dir/public/dist/coop-protocol.mjs"
bash "$example_repo/tools/iroh-transport/build.sh" "$staging_dir/public/iroh"
for asset in style.css browser.mjs renderer.mjs content.mjs audio.mjs progression.mjs expedition-menu.mjs menu-controls.mjs menu-a.css menu-moon.css coop.html coop.css coop-ui.mjs coop-presentation.mjs coop-browser.mjs coop-worker.mjs coop-transport.mjs; do
  cp "$app_dir/$asset" "$staging_dir/public/$asset"
done
if [[ -f "$app_dir/favicon.svg" ]]; then cp "$app_dir/favicon.svg" "$staging_dir/public/"; fi
cp "$example_repo/LICENSE-MIT" "$example_repo/LICENSE-APACHE" "$staging_dir/public/"
NIGHTFALL_WEB_PUBLIC="$staging_dir/public" NIGHTFALL_WEB_OUTPUT="$astro_output" \
  "$NODE" "$app_dir/web/node_modules/astro/bin/astro.mjs" build --root "$app_dir/web"
# All compilation and prerendering must succeed before replacing the served tree.
old_dir="$app_dir/dist/.web-previous-$$"
if [[ -d "$app_dir/dist/web" ]]; then mv "$app_dir/dist/web" "$old_dir"; fi
if ! mv "$astro_output" "$app_dir/dist/web"; then
  if [[ -d "$old_dir" ]]; then mv "$old_dir" "$app_dir/dist/web"; fi
  exit 1
fi
rm -rf "$old_dir"
echo "Static game: $app_dir/dist/web"
echo 'Serve this directory over HTTP; no server-side Bend or Node.js is needed.'
