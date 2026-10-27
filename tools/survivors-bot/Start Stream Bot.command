#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
if ! /bin/bash ./stream-macos.sh start; then
  echo 'Startup failed. Read the error above.'
  read -r -p 'Press Return to close.' _
  exit 1
fi
