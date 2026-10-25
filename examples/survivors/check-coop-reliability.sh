#!/usr/bin/env bash
# Always exercise freshly emitted Bend; never accept stale dist artifacts.
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
cd "$example_repo"
app="$example_repo/examples/survivors"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/bendvy-coop-reliability.XXXXXX")"
trap 'rm -rf "$scratch"; example_cleanup_lock' EXIT
source_fingerprint() {
  local source_list="$scratch/source-list"
  {
    find "$app" \( -path "$app/dist" -o -path "$app/web/node_modules" \) -prune -o \
      -type f \( -name '*.bend' -o -name '*.mjs' -o -name '*.sh' -o -name '*.json' \) -print
    find "$example_repo/vendor/bendlib/packages" -type f -name '*.bend'
    printf '%s\n' "$example_repo/examples/common.sh"
  } | LC_ALL=C sort > "$source_list"
  while IFS= read -r source; do
    shasum -a 256 "$source"
  done < "$source_list" | shasum -a 256 | awk '{print $1}'
}
source_fingerprint_before="$(source_fingerprint)"
for module in pickup-state pickup-xp-pool pickup-encoder party-difficulty contact-id-set coop-connection coop-client-delivery coop-snapshot-receipts coop-snapshot-flow coop-hit-effects coop-playback coop-client-clock coop-input-flow coop-hit-journal coop-local-projectiles coop-contact-playback coop-playback-wire coop-core coop-prediction game game-encoder coop-encoder; do
  example_emit "$app/$module.bend" "$scratch/$module.mjs"
done
example_node "$app/typed-results-check.mjs" "$scratch"
example_node "$app/coop-command-framing-check.mjs" "$scratch/coop-client-delivery.mjs"
example_node "$app/player-authority-check.mjs" "$scratch"
example_node "$app/pickup-state-check.mjs" "$scratch"
example_node "$app/pickup-wiring-check.mjs" "$scratch"
for module in coop-playback coop-client-clock coop-snapshot-flow coop-snapshot-receipts coop-client-delivery coop-hit-effects; do
  example_node --stack_size=192 "$app/$module-check.mjs" "$scratch/$module.mjs"
done
example_node --stack_size=192 "$app/party-difficulty-check.mjs" "$scratch/party-difficulty.mjs"
CONTACT_ID_SET_MODULE="$scratch/contact-id-set.mjs" example_node --stack_size=192 "$app/contact-id-set-check.mjs"
COOP_FLOW_MODULE="$scratch/coop-input-flow.mjs" example_node --stack_size=192 "$app/coop-input-flow-check.mjs"
COOP_PREDICTION_MODULE="$scratch/coop-prediction.mjs" example_node --stack_size=192 "$app/coop-prediction-check.mjs"
COOP_JOURNAL_MODULE="$scratch/coop-hit-journal.mjs" example_node --stack_size=192 "$app/coop-hit-journal-check.mjs"
COOP_LOCAL_PROJECTILES_MODULE="$scratch/coop-local-projectiles.mjs" example_node --stack_size=192 "$app/coop-local-projectiles-check.mjs"
example_node --stack_size=192 "$app/coop-contact-playback-check.mjs" "$scratch/coop-contact-playback.mjs" "$scratch/coop-playback.mjs"
example_node --stack_size=192 "$app/coop-playback-wire-check.mjs" "$scratch/coop-playback-wire.mjs" "$scratch"
example_node "$app/coop-snapshot-codec-check.mjs" "$scratch/coop-connection.mjs"
COOP_ENCODER_MODULE="$scratch/coop-encoder.mjs" COOP_CORE_MODULE="$scratch/coop-core.mjs" COOP_GAME_MODULE="$scratch/game.mjs" example_node "$app/coop-hit-source-check.mjs"
COOP_GAME_MODULE="$scratch/game.mjs" example_node "$app/enemy-birth-check.mjs"
COOP_ENCODER_MODULE="$scratch/coop-encoder.mjs" COOP_CORE_MODULE="$scratch/coop-core.mjs" COOP_GAME_MODULE="$scratch/game.mjs" COOP_JOURNAL_MODULE="$scratch/coop-hit-journal.mjs" example_node "$app/coop-dense-contact-check.mjs"
COOP_JOURNAL_MODULE="$scratch/coop-hit-journal.mjs" example_node --stack_size=192 "$app/coop-dense-contact-check.mjs" --journal-only
source_fingerprint_after="$(source_fingerprint)"
if [[ "$source_fingerprint_before" != "$source_fingerprint_after" ]]; then
  printf 'co-op reliability sources changed while the checks were running\n' >&2
  exit 1
fi
