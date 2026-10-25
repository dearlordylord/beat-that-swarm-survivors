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
example_emit "$app_dir/game-encoder.bend" "$staging_dir/public/dist/game-encoder.mjs"
example_emit "$app_dir/audio-events.bend" "$staging_dir/public/dist/audio-events.mjs"
cp "$app_dir/dist/menu-progression.mjs" "$staging_dir/public/dist/"
example_emit "$app_dir/coop-core.bend" "$staging_dir/public/dist/coop-core.mjs"
example_emit "$app_dir/coop-encoder.bend" "$staging_dir/public/dist/coop-encoder.mjs"
example_emit "$app_dir/coop-connection.bend" "$staging_dir/public/dist/coop-connection.mjs"
example_emit "$app_dir/coop-input-flow.bend" "$staging_dir/public/dist/coop-input-flow.mjs"
example_emit "$app_dir/coop-session.bend" "$staging_dir/public/dist/coop-session.mjs"
example_emit "$app_dir/coop-protocol.bend" "$staging_dir/public/dist/coop-protocol.mjs"
example_emit "$app_dir/coop-prediction.bend" "$staging_dir/public/dist/coop-prediction.mjs"
example_emit "$app_dir/coop-input-queue.bend" "$staging_dir/public/dist/coop-input-queue.mjs"
for module in coop-client-delivery coop-snapshot-receipts coop-snapshot-flow coop-hit-effects coop-playback coop-playback-wire coop-contact-playback coop-client-clock coop-hit-journal coop-local-projectiles; do
  example_emit "$app_dir/$module.bend" "$staging_dir/public/dist/$module.mjs"
done
bash "$example_repo/tools/iroh-transport/build.sh" "$staging_dir/public/iroh"
for asset in style.css browser.mjs renderer.mjs survivor-art.mjs content.mjs audio.mjs progression.mjs expedition-menu.mjs menu-controls.mjs menu-content.mjs menu-a.css menu-moon.css coop.css coop-ui.mjs coop-presentation.mjs coop-browser.mjs coop-worker.mjs coop-transport.mjs coop-snapshot-codec.mjs; do
  cp "$app_dir/$asset" "$staging_dir/public/$asset"
done
if [[ -f "$app_dir/favicon.svg" ]]; then cp "$app_dir/favicon.svg" "$staging_dir/public/"; fi
cp -R "$app_dir/social" "$staging_dir/public/social"
cp "$example_repo/LICENSE-MIT" "$example_repo/LICENSE-APACHE" "$staging_dir/public/"
NIGHTFALL_WEB_PUBLIC="$staging_dir/public" NIGHTFALL_WEB_OUTPUT="$astro_output" \
  "$NODE" "$app_dir/web/node_modules/astro/bin/astro.mjs" build --root "$app_dir/web"
# Local builds expose their provenance for browser diagnostics. Publication replaces
# this with its immutable release manifest after building the isolated snapshot.
"$NODE" --input-type=module - "$example_repo" "$astro_output" <<'NODE'
import { execFileSync } from 'node:child_process';
import { writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const [repo, output] = process.argv.slice(2);
function git(args) {
  try {
    return execFileSync('git', ['-C', repo, ...args], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

const gitRevision = git(['rev-parse', '--verify', 'HEAD']);
const gitStatus = gitRevision === null
  ? null
  : git(['status', '--porcelain=v1', '--untracked-files=all']);
const version = {
  schemaVersion: 1,
  revision: gitRevision ?? 'unversioned-local-build',
  dirty: gitRevision === null || gitStatus === null || gitStatus.length > 0,
  buildContext: 'local-development',
  builtAt: new Date().toISOString(),
};
await writeFile(join(output, 'version.json'), `${JSON.stringify(version, null, 2)}\n`);
NODE
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
