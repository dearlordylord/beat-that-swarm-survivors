#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/../common.sh"
app_dir="$example_repo/examples/survivors"
physical_tmp="$(mktemp -d /tmp/bendvy-physical-law-XXXXXX)"
trap 'rm -rf "$physical_tmp"; example_cleanup_lock' EXIT
check_proof(){ example_timeout 60 bash -c 'ulimit -t 10; exec "$@"' _ "$BEND" "$1" --verdict; }
check_proof "$app_dir/coop-game-PROOF.bend"
cp "$app_dir/coop-game-LAWS.bend" "$app_dir/coop-game-PROOF.bend" "$physical_tmp/"
reject_mutant(){
  local mutant_label="$1" mutant_law="$2"
  if check_proof "$physical_tmp/coop-game-PROOF.bend" > "$physical_tmp/mutant.log" 2>&1; then
    echo "FAIL $mutant_label mutant survived $mutant_law" >&2; exit 1
  fi
  if ! rg -q "$mutant_law" "$physical_tmp/mutant.log"; then
    cat "$physical_tmp/mutant.log" >&2; echo "FAIL $mutant_label did not reject its law's own proof" >&2; exit 1
  fi
  echo "PASS $mutant_label mutant rejected by $mutant_law"
}
sed 's/^  close(x,y,px,py,radius)$/  Bool.or(U32.is_le(120,age),close(x,y,px,py,radius))/' "$app_dir/pickup-policy.bend" > "$physical_tmp/pickup-policy.bend"
reject_mutant timed-auto-pickup physical_pickup_exact
sed 's/^  F32.is_le(.*$/  True{}/' "$app_dir/pickup-policy.bend" > "$physical_tmp/pickup-policy.bend"
reject_mutant always-true-distance physical_close_exact
