#!/bin/sh
# Builds every probes/<id>/moonbit/<variant>/ (command in its `cmd` file, release mode) and runs the checker.
# Run inside wasm-exposure-moonbit from the study root:   sh probes/run-moonbit.sh [probe-id ...]
# Per variant: `cmd` (the exact build command), optional `spec` (checker spec, default = probe id).
# A failed build is a recorded result. Full logs: results/moonbit/<id>.<variant>.txt.
set -u
mkdir -p results/moonbit
want="$*"
printf '%-5s %-14s %-8s %s\n' PROBE VARIANT BUILD CHECK
for d in probes/*/moonbit/*/; do
  [ -f "$d/cmd" ] || continue
  id=$(echo "$d" | cut -d/ -f2); var=$(basename "$d")
  if [ -n "$want" ]; then case " $want " in *" $id "*) ;; *) continue;; esac; fi
  spec=$id; [ -f "$d/spec" ] && spec=$(cat "$d/spec")
  log=results/moonbit/$id.$var.txt; rm -rf "$d/out.wasm" "$d/_build"
  { echo "# $id/$var spec=$spec"; echo "\$ $(cat "$d/cmd")"; (cd "$d" && sh -c "$(cat cmd)" 2>&1); } > "$log"
  if [ ! -f "$d/out.wasm" ]; then printf '%-5s %-14s %-8s %s\n' "$id" "$var" FAILED -; echo "BUILD FAILED" >> "$log"; continue; fi
  timeout 20 node check/run.mjs "$spec" "$d/out.wasm" >> "$log" 2>&1; crc=$?
  res=PASS; [ $crc -ne 0 ] && res=FAIL
  [ $crc -eq 124 ] && { res=HANG; echo "CHECKER TIMED OUT after 20s" >> "$log"; }
  printf '%-5s %-14s %-8s %s  (%s bytes)\n' "$id" "$var" ok "$res" "$(wc -c < "$d/out.wasm")"
done
