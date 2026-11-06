#!/bin/sh
# Usage (inside the language's container, from the study root):  sh capstones/run.sh <capstone> <lang>
# Runs capstones/<capstone>/<lang>/cmd, then the shared host script host/<capstone>.mjs against out.wasm.
set -u
cap=$1; lang=$2; d=capstones/$cap/$lang; mkdir -p results/capstones
log=results/capstones/$cap.$lang.txt
{ echo "# $cap/$lang"; echo "\$ $(cat $d/cmd)"; rm -rf "$d/out.wasm" "$d/_build"; (cd $d && sh -c "$(cat cmd)" 2>&1); } > "$log"
if [ ! -f "$d/out.wasm" ]; then echo "BUILD FAILED" | tee -a "$log"; exit 1; fi
timeout 60 node host/$cap.mjs "$d/out.wasm" >> "$log" 2>&1; rc=$?
[ $rc -eq 124 ] && echo "HOST TIMED OUT after 60s" >> "$log"
tail -1 "$log"; exit $rc
