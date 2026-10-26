#!/usr/bin/env bash
# Always exercise freshly emitted Bend; never accept stale dist artifacts.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
app="$example_repo/examples/survivors"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/bendvy-coop-reliability.XXXXXX")"
trap 'rm -rf "$scratch"; example_cleanup_lock' EXIT
source_fingerprint() {
  local source_list="$scratch/source-list" status
  {
    find "$app" \( -path "$app/dist" -o -path "$app/web/node_modules" \) -prune -o \
      -type f \( -name '*.bend' -o -name '*.mjs' -o -name '*.mts' -o -name '*.ts' -o -name '*.sh' -o -name '*.json' -o -name '*.py' \) -print || { status=$?; printf 'Source fingerprint find failed: %s (exit %s)\n' "$app" "$status" >&2; return "$status"; }
    find "$example_repo/vendor/bendlib/packages" -type f -name '*.bend' || { status=$?; printf 'Source fingerprint find failed: %s (exit %s)\n' "$example_repo/vendor/bendlib/packages" "$status" >&2; return "$status"; }
    printf '%s\n' "$example_repo/examples/common.sh"
  } | LC_ALL=C sort > "$source_list" || { status=$?; printf 'Source fingerprint file listing failed (exit %s)\n' "$status" >&2; return "$status"; }
  while IFS= read -r source; do
    shasum -a 256 "$source" || { status=$?; printf 'Source fingerprint shasum failed: %s (exit %s)\n' "$source" "$status" >&2; return "$status"; }
  done < "$source_list" | shasum -a 256 | awk '{print $1}' || { status=$?; printf 'Source fingerprint digest pipeline failed (exit %s)\n' "$status" >&2; return "$status"; }
}
source_fingerprint_before="$(source_fingerprint)"
for module in coop-playback coop-contact-playback coop-hit-effects audio-events pickup-state pickup-xp-pool pickup-encoder coop-connection coop-client-delivery coop-hit-journal coop-playback-wire coop-core coop-session game game-encoder coop-encoder; do
  example_emit "$app/$module.bend" "$scratch/$module.mjs"
done
example_node "$app/observations-check.mts" "$scratch"
example_node "$app/audio-subjects-check.mts" "$scratch"
example_node "$app/coop-command-framing-check.mts" "$scratch/coop-client-delivery.mjs"
example_node "$app/player-authority-check.mts" "$scratch"
example_node "$app/pickup-state-check.mts" "$scratch"
example_node "$app/pickup-wiring-check.mts" "$scratch"
example_node "$app/projectile-ownership-check.mts" "$scratch/coop-core.mjs"
example_node --stack_size=192 "$app/coop-playback-wire-check.mts" "$scratch/coop-playback-wire.mjs" "$scratch"
example_node "$app/coop-snapshot-codec-check.mts" "$scratch/coop-connection.mjs"
COOP_ENCODER_MODULE="$scratch/coop-encoder.mjs" COOP_CORE_MODULE="$scratch/coop-core.mjs" COOP_GAME_MODULE="$scratch/game.mjs" example_node "$app/coop-hit-source-check.mts"
COOP_GAME_MODULE="$scratch/game.mjs" example_node "$app/enemy-birth-check.mts"
COOP_ENCODER_MODULE="$scratch/coop-encoder.mjs" COOP_CORE_MODULE="$scratch/coop-core.mjs" COOP_GAME_MODULE="$scratch/game.mjs" COOP_JOURNAL_MODULE="$scratch/coop-hit-journal.mjs" example_node "$app/coop-dense-contact-check.mts"
COOP_JOURNAL_MODULE="$scratch/coop-hit-journal.mjs" example_node --stack_size=192 "$app/coop-dense-contact-check.mts" --journal-only
source_fingerprint_after="$(source_fingerprint)"
if [[ "$source_fingerprint_before" != "$source_fingerprint_after" ]]; then
  printf 'co-op reliability sources changed while the checks were running\n' >&2
  exit 1
fi
