#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/../.."
NODE=${NODE:-node}
# Validate before building, and derive the external fail-safe from the same parser.
batch_wall=$("$NODE" --input-type=module - "$@" <<'JS'
import { validateOptions } from './tools/survivors-bot/batch.mjs';
import { parseArgs } from 'node:util';
const {values}=parseArgs({args:process.argv.slice(2),options:Object.fromEntries(['count','ticks','workers','seed','profile','wall-seconds'].map(k=>[k,{type:'string'}]))});
const o=Object.fromEntries(Object.entries(values).map(([k,v])=>[k==='wall-seconds'?'wallSeconds':k,k==='profile'?v:Number(v)]));
console.log(validateOptions(o).wallSeconds+5);
JS
)
mkdir -p examples/survivors/dist
bash -c 'source examples/common.sh; example_emit examples/survivors/bot-actions.bend examples/survivors/dist/bot-actions.mjs'
"$NODE" examples/run-bounded.mjs "$batch_wall" "$NODE" tools/survivors-bot/batch.mjs "$@"
